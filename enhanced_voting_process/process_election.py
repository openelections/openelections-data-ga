import argparse
import csv
import json
from pathlib import Path
import re
import sys
from typing import Any, Dict, List, Optional

# Add project root and current folder to sys.path
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(Path(__file__).parent))

from enhanced_voting_process.enhanced_json_model import (  # noqa: E402
    ElectionResults,
    GroupResult,
)
from enhanced_voting_process.cleaner import DataCleaner  # noqa: E402
from enhanced_voting_process.reconciler import ElectionReconciler  # noqa: E402


def extract_vote_groups(
    group_results: Optional[List[GroupResult]]
) -> Optional[Dict[str, int]]:
    """
    Extracts standard Georgia vote group counts from validated GroupResult
    objects. Returns None if group_results is empty or any vote count is None
    (e.g., hidden/suppressed for voter privacy).
    """
    if not group_results:
        return None

    counts = {
        "election_day_votes": 0,
        "advanced_votes": 0,
        "absentee_by_mail_votes": 0,
        "provisional_votes": 0,
    }

    for g in group_results:
        if g.votes is None:
            return None

        name_lower = g.vote_type.lower()
        if "election day" in name_lower:
            counts["election_day_votes"] += g.votes
        elif "advance" in name_lower or "early" in name_lower:
            counts["advanced_votes"] += g.votes
        elif "absentee" in name_lower or "mail" in name_lower:
            counts["absentee_by_mail_votes"] += g.votes
        elif "provisional" in name_lower:
            counts["provisional_votes"] += g.votes

    return counts


def sanitize_filename_slug(election_name: str) -> str:
    s = election_name
    # 1. Strip month names and dates (e.g. 'August 26, 2025', '11/05/2024')
    months = (
        r"(?:january|february|march|april|may|june|july|august|"
        r"september|october|november|december|jan|feb|mar|apr|jun|"
        r"jul|aug|sep|sept|oct|nov|dec)"
    )
    s = re.sub(
        rf"(?i)\b{months}\s+\d{{1,2}}(?:st|nd|rd|th)?(?:,?\s+\d{{4}})?\b",
        " ",
        s
    )
    s = re.sub(rf"(?i)\b{months}\s+\d{{4}}\b", " ", s)
    s = re.sub(r"\b\d{4}-\d{2}-\d{2}\b", " ", s)
    s = re.sub(r"\b\d{1,2}/\d{1,2}/\d{2,4}\b", " ", s)
    s = re.sub(r"\b(19\d\d|20\d\d)\b", " ", s)

    # 2. Lowercase and clean non-alphanumeric to spaces
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", " ", s)

    # 3. Standardize phrases and expand common abbreviations
    s = re.sub(r"\bsd\s*(\d+)\b", r"state senate \1", s)
    s = re.sub(r"\bhd\s*(\d+)\b", r"state house \1", s)
    s = re.sub(r"\bdistrict\s+(\d+)\b", r"\1", s)

    # PSC replacements
    s = re.sub(
        r"public\s+service\s+commissioner\s*\(?psc\)?",
        "psc",
        s
    )
    s = re.sub(r"public\s+service\s+commissioner", "psc", s)
    s = re.sub(
        r"special\s+primary\s+psc\s*(?:/\s*)?special\s+election\s+runoff",
        "special runoff psc",
        s
    )
    s = re.sub(
        r"special\s+primary\s+psc\s*(?:/\s*)?special\s+election",
        "special primary psc",
        s
    )

    s = re.sub(r"\bspecial\s+election\b", "special", s)
    s = re.sub(r"\bgeneral\s+election\b", "general", s)
    s = re.sub(r"\belection\b", "", s)
    s = re.sub(r"\band\b", "", s)

    # 4. Tokenize and join every element with double underscores
    tokens = [w for w in s.split() if w]
    slug = "__".join(tokens)
    return slug


class ElectionProcessor:
    def __init__(
        self,
        rules_path: Optional[Path] = None,
        all_offices: bool = False
    ):
        self.cleaner = DataCleaner(rules_path=rules_path)
        self.reconciler = ElectionReconciler()
        self.all_offices = all_offices

    def process_file(
        self,
        input_path: Path,
        outdir: Optional[Path] = None,
        inspect_mode: bool = False,
        duckdb_path: Optional[Path] = None
    ) -> Dict[str, Any]:
        input_path = input_path.expanduser()
        with input_path.open("r", encoding="utf-8") as f:
            raw_data = json.load(f)

        election = ElectionResults.model_validate(raw_data)
        election_date_clean = election.election_date.replace("-", "")
        election_slug = sanitize_filename_slug(election.election_name)

        print("\n" + "=" * 88)
        print(f"  PROCESSING ELECTION: {election.election_name}")
        print(f"  Election Date:       {election.election_date}")
        print(f"  Counties Found:      {len(election.local_results)}")
        print("=" * 88)

        # 1. Discover unique raw offices, candidates, and check vote types
        raw_offices = set()
        raw_parties = set()
        raw_candidates = set()
        has_county_groups = False
        has_precinct_groups = False

        for county_res in election.local_results:
            for item in county_res.ballot_items:
                raw_offices.add(item.office)
                for opt in item.ballot_options:
                    raw_candidates.add(opt.candidate)
                    if opt.party:
                        raw_parties.add(opt.party)
                    if extract_vote_groups(opt.county_votes):
                        has_county_groups = True
                    for p_res in opt.precinct_results or []:
                        if extract_vote_groups(p_res.precinct_votes):
                            has_precinct_groups = True

        # Classify offices into Federal/State, Excluded Local, or Unmapped
        included_offices = []
        excluded_local_offices = []
        unmapped_offices = []

        for raw_off in sorted(raw_offices):
            status, canonical, dist = self.cleaner.classify_office(raw_off)
            if status == "INCLUDED":
                included_offices.append((raw_off, canonical, dist))
            elif status == "EXCLUDED":
                excluded_local_offices.append(raw_off)
            else:
                unmapped_offices.append(raw_off)

        print(f"\n[OFFICE FILTERING] Found {len(raw_offices)}"
              f" unique race(s):")
        print(f"  • {len(included_offices)} Federal / State race(s)"
              f" [INCLUDED]")
        for raw_o, can_o, d in included_offices:
            dist_str = f" (District {d})" if d else ""
            print(f"    ✓ '{raw_o}' -> '{can_o}'{dist_str}")

        if excluded_local_offices:
            print(f"  • {len(excluded_local_offices)} County/City race(s) "
                  f"[EXCLUDED - NON-FEDERAL/STATE]")
            for ex in excluded_local_offices:
                print(f"    ✗ '{ex}'")

        if unmapped_offices:
            print(f"  • {len(unmapped_offices)} Unrecognized race(s) "
                  f"[UNMAPPED]:")
            for u in unmapped_offices:
                print(f"    ? '{u}'")
            print("    (Add patterns or overrides in cleaning_rules.yaml "
                  "to classify these races.)")

        # 2. Extract County and Precinct Rows
        # Build a cross-county candidate party map so counties omitting
        # politicalParty inherit the explicit party from sibling counties.
        candidate_party_map: Dict[tuple, str] = {}
        for county_res in election.local_results:
            for item in county_res.ballot_items:
                status, canonical, dist = self.cleaner.classify_office(
                    item.office
                )
                if not self.all_offices and status != "INCLUDED":
                    continue
                canonical_office = (
                    canonical if status == "INCLUDED" else item.office
                )
                district = dist or '' if status == "INCLUDED" else ''
                for opt in item.ballot_options:
                    cand = self.cleaner.clean_candidate(opt.candidate)
                    explicit_party = self.cleaner.resolve_party(
                        opt.party,
                        opt.candidate,
                        item.office,
                        default=None
                    )
                    if explicit_party:
                        key = (canonical_office, district, cand)
                        candidate_party_map.setdefault(key, explicit_party)

        county_rows: List[Dict[str, Any]] = []
        precinct_rows: List[Dict[str, Any]] = []

        for county_res in election.local_results:
            county_name = self.cleaner.clean_county(county_res.county)

            for item in county_res.ballot_items:
                status, canonical, dist = self.cleaner.classify_office(
                    item.office
                )
                if not self.all_offices and status != "INCLUDED":
                    continue

                canonical_office = (
                    canonical if status == "INCLUDED" else item.office
                )
                district = dist or '' if status == "INCLUDED" else ''

                for opt in item.ballot_options:
                    candidate = self.cleaner.clean_candidate(opt.candidate)
                    inferred_party = candidate_party_map.get(
                        (canonical_office, district, candidate)
                    )
                    party = self.cleaner.resolve_party(
                        opt.party,
                        opt.candidate,
                        item.office,
                        inferred_party=inferred_party
                    )

                    # County row extraction
                    county_grp = extract_vote_groups(opt.county_votes)
                    if has_county_groups:
                        if county_grp:
                            ed = county_grp["election_day_votes"]
                            adv = county_grp["advanced_votes"]
                            ab = county_grp["absentee_by_mail_votes"]
                            prov = county_grp["provisional_votes"]
                        else:
                            ed = ""
                            adv = ""
                            ab = ""
                            prov = ""
                        county_rows.append({
                            "county": county_name,
                            "precinct": "not available",
                            "office": canonical_office,
                            "district": district,
                            "party": party,
                            "candidate": candidate,
                            "votes": opt.total_votes,
                            "election_day_votes": ed,
                            "advanced_votes": adv,
                            "absentee_by_mail_votes": ab,
                            "provisional_votes": prov
                        })
                    else:
                        county_rows.append({
                            "county": county_name,
                            "precinct": "not available",
                            "office": canonical_office,
                            "district": district,
                            "party": party,
                            "candidate": candidate,
                            "votes": opt.total_votes
                        })

                    # Precinct rows extraction
                    if opt.precinct_results:
                        for p_res in opt.precinct_results:
                            precinct_name = self.cleaner.clean_precinct(
                                p_res.precinct_name
                            )
                            p_grp = extract_vote_groups(p_res.precinct_votes)
                            if has_precinct_groups:
                                if p_grp:
                                    ed = p_grp["election_day_votes"]
                                    adv = p_grp["advanced_votes"]
                                    ab = p_grp["absentee_by_mail_votes"]
                                    prov = p_grp["provisional_votes"]
                                else:
                                    ed = ""
                                    adv = ""
                                    ab = ""
                                    prov = ""
                                precinct_rows.append({
                                    "county": county_name,
                                    "precinct": precinct_name,
                                    "office": canonical_office,
                                    "district": district,
                                    "party": party,
                                    "candidate": candidate,
                                    "votes": p_res.total_votes,
                                    "election_day_votes": ed,
                                    "advanced_votes": adv,
                                    "absentee_by_mail_votes": ab,
                                    "provisional_votes": prov
                                })
                            else:
                                precinct_rows.append({
                                    "county": county_name,
                                    "precinct": precinct_name,
                                    "office": canonical_office,
                                    "district": district,
                                    "party": party,
                                    "candidate": candidate,
                                    "votes": p_res.total_votes
                                })

        # Sort according to OpenElections conventions
        def sort_key(row):
            try:
                dist_int = int(row["district"]) if row["district"] else 0
            except ValueError:
                dist_int = 0
            return (
                row["county"],
                row["office"],
                dist_int,
                row["party"],
                row["candidate"],
                row.get("precinct", "")
            )

        county_rows.sort(key=sort_key)
        precinct_rows.sort(key=sort_key)

        # 3. Reconciliation / QC
        recon_records = self.reconciler.reconcile(county_rows, precinct_rows)
        self.reconciler.print_summary()

        # 4. Save Outputs if not inspect mode
        if inspect_mode:
            print("[Inspect Mode] Dry run complete. No files written.")
            return {
                "county_rows": county_rows,
                "precinct_rows": precinct_rows,
                "reconciliation": recon_records
            }

        target_outdir = (
            outdir.expanduser() if outdir else input_path.parent
        )
        target_outdir.mkdir(parents=True, exist_ok=True)

        county_filename = (
            f"{election_date_clean}__ga__{election_slug}__county-level.csv"
        )
        precinct_filename = (
            f"{election_date_clean}__ga__{election_slug}__precinct-level.csv"
        )
        recon_filename = (
            f"{election_date_clean}__ga__{election_slug}"
            f"__reconciliation_report.csv"
        )

        county_file = target_outdir / county_filename
        precinct_file = target_outdir / precinct_filename
        recon_file = target_outdir / recon_filename

        # Dynamic fieldnames depending on whether vote types are present
        if has_county_groups:
            county_fields = [
                "county", "precinct", "office", "district", "party",
                "candidate", "votes", "election_day_votes", "advanced_votes",
                "absentee_by_mail_votes", "provisional_votes"
            ]
        else:
            county_fields = [
                "county", "precinct", "office", "district", "party",
                "candidate", "votes"
            ]

        if has_precinct_groups:
            precinct_fields = [
                "county", "precinct", "office", "district", "party",
                "candidate", "votes", "election_day_votes", "advanced_votes",
                "absentee_by_mail_votes", "provisional_votes"
            ]
        else:
            precinct_fields = [
                "county", "precinct", "office", "district", "party",
                "candidate", "votes"
            ]

        with county_file.open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=county_fields)
            writer.writeheader()
            writer.writerows(county_rows)
        print(f"[Exported] County-level CSV:   {county_file}"
              f" ({len(county_rows):,} rows)")

        if precinct_rows:
            with precinct_file.open("w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=precinct_fields)
                writer.writeheader()
                writer.writerows(precinct_rows)
            print(f"[Exported] Precinct-level CSV: {precinct_file}"
                  f" ({len(precinct_rows):,} rows)")
        else:
            precinct_file = None
            print("[INFO] No precinct data in source JSON. "
                  "Skipped precinct-level CSV export.")

        if recon_records:
            self.reconciler.export_csv(recon_file)
            print(f"[Exported] QC Recon Report:    {recon_file}")
        else:
            recon_file = None

        # Optional DuckDB insertion
        if duckdb_path:
            import duckdb
            db_file = duckdb_path.expanduser()
            db_file.parent.mkdir(parents=True, exist_ok=True)
            try:
                con = duckdb.connect(str(db_file))
                tbl_base = f"ga_{election_date_clean}_{election_slug}".replace(
                    "-", "_"
                )
                con.execute(
                    f"CREATE TABLE IF NOT EXISTS {tbl_base}_county AS "
                    f"SELECT * FROM read_csv_auto('{county_file}')"
                )
                if precinct_file:
                    con.execute(
                        f"CREATE TABLE IF NOT EXISTS {tbl_base}_precinct AS "
                        f"SELECT * FROM read_csv_auto('{precinct_file}')"
                    )
                con.close()
                print(f"[DuckDB] Loaded tables into:  {db_file}")
            except Exception as e:
                err_msg = str(e)
                if "lock" in err_msg.lower():
                    print(
                        f"\n[WARNING] DuckDB database is currently locked by "
                        f"another application (e.g. DataGrip, DBeaver).\n"
                        f"          CSVs were exported successfully, but "
                        f"tables were not loaded into:\n"
                        f"          {db_file}\n"
                        f"          Close the database in DataGrip/DBeaver "
                        f"and re-run if you wish to load the tables."
                    )
                else:
                    print(
                        f"\n[WARNING] Could not load tables into DuckDB: "
                        f"{err_msg}\n"
                        f"          CSVs were exported successfully to "
                        f"{target_outdir}."
                    )

        print("=" * 88 + "\n")
        return {
            "county_file": county_file,
            "precinct_file": precinct_file,
            "recon_file": recon_file
        }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="OpenElections Georgia Voter Results Processor"
    )
    parser.add_argument(
        "-i", "--input", required=True, type=Path,
        help="Path to raw JSON election export file"
    )
    parser.add_argument(
        "-o", "--outdir", type=Path, default=None,
        help="Output directory for generated CSV files"
    )
    parser.add_argument(
        "--inspect", action="store_true",
        help="Inspect / dry-run mode (does not write CSVs)"
    )
    parser.add_argument(
        "--all-offices", action="store_true",
        help="Process all offices (including non-standard local races)"
    )
    parser.add_argument(
        "--duckdb", type=Path, default=None,
        help="Optional path to DuckDB file to load cleaned tables"
    )
    parser.add_argument(
        "--rules", type=Path, default=None,
        help="Custom path to cleaning_rules.yaml"
    )
    return parser


def main():
    args = build_parser().parse_args()

    processor = ElectionProcessor(
        rules_path=args.rules,
        all_offices=args.all_offices
    )

    processor.process_file(
        input_path=args.input,
        outdir=args.outdir,
        inspect_mode=args.inspect,
        duckdb_path=args.duckdb
    )


if __name__ == "__main__":
    main()
