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
    ElectionResults
)
from enhanced_voting_process.cleaner import DataCleaner  # noqa: E402
from enhanced_voting_process.reconciler import ElectionReconciler  # noqa: E402
from enhanced_voting_process.ai_assistant import (  # noqa: E402
    GeminiAssistant
)


def extract_vote_groups(group_results: Optional[List[Any]]) -> Optional[Dict[str, int]]:  # noqa: E501
    """
    Extracts standard Georgia vote group counts from groupResults.
    Returns None if group_results is empty or all vote counts are None.
    """
    if not group_results:
        return None

    counts = {
        "election_day_votes": 0,
        "advanced_votes": 0,
        "absentee_by_mail_votes": 0,
        "provisional_votes": 0,
    }
    has_valid_count = False

    for g in group_results:
        name = getattr(g, "vote_type", None)
        if name is None and isinstance(g, dict):
            name = g.get("groupName", "")
        elif name is None:
            name = getattr(g, "groupName", "")

        votes = getattr(g, "votes", None)
        if votes is None and isinstance(g, dict):
            votes = g.get("voteCount")
        elif votes is None:
            votes = getattr(g, "voteCount", None)

        if votes is not None:
            has_valid_count = True
            name_lower = str(name).lower()
            if "election day" in name_lower:
                counts["election_day_votes"] += votes
            elif "advance" in name_lower or "early" in name_lower:
                counts["advanced_votes"] += votes
            elif "absentee" in name_lower or "mail" in name_lower:
                counts["absentee_by_mail_votes"] += votes
            elif "provisional" in name_lower:
                counts["provisional_votes"] += votes

    return counts if has_valid_count else None


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

    # 2. Lowercase and clean non-alphanumeric
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "_", s).strip("_")

    # 3. Standardize common OpenElections phrases
    long_psc = (
        "special_primary_public_service_commissioner_psc_"
        "special_election_runoff"
    )
    s = s.replace(long_psc, "special__runoff__psc")
    s = s.replace(
        "public_service_commissioner_psc_special_election_runoff",
        "special__runoff__psc"
    )
    s = s.replace("public_service_commissioner_psc", "psc")
    s = s.replace(
        "special_election_state_senate_district_",
        "special__state_senate__"
    )
    s = s.replace(
        "special_election_state_house_district_",
        "special__state_house__"
    )
    s = s.replace("general_primary_runoff", "general__primary__runoff")
    s = s.replace("special_primary_runoff", "special__primary__runoff")
    s = s.replace("special_primary", "special__primary")
    s = s.replace("special_election", "special")
    s = s.replace("general_election", "general")

    # 4. Clean formatting
    s = re.sub(r"_+", "_", s).strip("_")
    s = s.replace("_runoff", "__runoff")
    s = s.replace("_psc", "__psc")
    s = re.sub(r"__+", "__", s).strip("_")
    return s


class ElectionProcessor:
    def __init__(
        self,
        rules_path: Optional[Path] = None,
        all_offices: bool = False,
        use_ai: bool = False,
        api_key: Optional[str] = None
    ):
        self.cleaner = DataCleaner(rules_path=rules_path)
        self.reconciler = ElectionReconciler()
        self.all_offices = all_offices
        self.use_ai = use_ai
        self.ai = GeminiAssistant(api_key=api_key)

    def process_file(
        self,
        input_path: Path,
        outdir: Optional[Path] = None,
        inspect_mode: bool = False,
        duckdb_path: Optional[Path] = None,
        save_ai_rules: bool = False
    ) -> Dict[str, Any]:
        input_path = input_path.expanduser()
        with open(input_path, "r", encoding="utf-8") as f:
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
            canonical, dist, _ = self.cleaner.clean_office_and_district(
                raw_off
            )
            if self.cleaner.is_canonical_office(canonical):
                included_offices.append((raw_off, canonical, dist))
            elif self.cleaner.is_known_local_office(raw_off):
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

            if self.use_ai or self.ai.is_available():
                print("\n[AI Assistant] Querying Gemini"
                      " for office mappings...")
                suggestions = self.ai.suggest_office_mappings(
                    unmapped_offices,
                    sorted(list(self.cleaner.canonical_offices))
                )
                print(json.dumps(suggestions, indent=2))
                if save_ai_rules and suggestions:
                    for raw_k, mapping in suggestions.items():
                        self.cleaner.add_office_override(
                            raw_k,
                            mapping.get("office", raw_k),
                            str(mapping.get("district", "")),
                            mapping.get("party")
                        )
                    print("[AI Assistant] Rules updated"
                          " in cleaning_rules.yaml!")

        # 2. Extract County and Precinct Rows
        county_rows: List[Dict[str, Any]] = []
        precinct_rows: List[Dict[str, Any]] = []

        for county_res in election.local_results:
            county_name = self.cleaner.clean_county(county_res.county)

            for item in county_res.ballot_items:
                canonical_office, district, party_hint = (
                    self.cleaner.clean_office_and_district(item.office)
                )

                if (
                    not self.all_offices
                    and not self.cleaner.is_canonical_office(canonical_office)
                ):
                    continue

                for opt in item.ballot_options:
                    candidate = self.cleaner.clean_candidate(opt.candidate)
                    party = self.cleaner.clean_party(opt.party or party_hint)

                    # County row extraction
                    county_grp = extract_vote_groups(opt.county_votes)
                    if has_county_groups:
                        ed = county_grp["election_day_votes"] if county_grp else opt.total_votes  # noqa: E501
                        adv = county_grp["advanced_votes"] if county_grp else 0
                        ab = county_grp["absentee_by_mail_votes"] if county_grp else 0  # noqa: E501
                        prov = county_grp["provisional_votes"] if county_grp else 0  # noqa: E501
                        county_rows.append({
                            "county": county_name,
                            "precinct": "not available",
                            "office": canonical_office,
                            "district": district,
                            "party": party,
                            "candidate": candidate,
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
                                ed = p_grp["election_day_votes"] if p_grp else p_res.total_votes  # noqa: E501
                                adv = p_grp["advanced_votes"] if p_grp else 0
                                ab = p_grp["absentee_by_mail_votes"] if p_grp else 0  # noqa: E501
                                prov = p_grp["provisional_votes"] if p_grp else 0  # noqa: E501
                                precinct_rows.append({
                                    "county": county_name,
                                    "precinct": precinct_name,
                                    "office": canonical_office,
                                    "district": district,
                                    "party": party,
                                    "candidate": candidate,
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

        if self.use_ai and self.ai.is_available():
            discrepancies = [
                r for r in recon_records if r["status"] == "DISCREPANCY"
            ]
            if discrepancies:
                print("[AI Assistant] Anomaly Analysis:")
                analysis = self.ai.analyze_anomalies(recon_records)
                print(analysis)

        # 4. Save Outputs if not inspect mode
        if inspect_mode:
            print("[Inspect Mode] Dry run complete. No files written.")
            return {
                "county_rows": county_rows,
                "precinct_rows": precinct_rows,
                "reconciliation": recon_records
            }

        target_outdir = (
            outdir.expanduser() if outdir else Path(input_path.parent)
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
                "candidate", "election_day_votes", "advanced_votes",
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
                "candidate", "election_day_votes", "advanced_votes",
                "absentee_by_mail_votes", "provisional_votes"
            ]
        else:
            precinct_fields = [
                "county", "precinct", "office", "district", "party",
                "candidate", "votes"
            ]

        with open(county_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=county_fields)
            writer.writeheader()
            writer.writerows(county_rows)
        print(f"[Exported] County-level CSV:   {county_file}"
              f" ({len(county_rows):,} rows)")

        with open(precinct_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=precinct_fields)
            writer.writeheader()
            writer.writerows(precinct_rows)
        print(f"[Exported] Precinct-level CSV: {precinct_file}"
              f" ({len(precinct_rows):,} rows)")

        self.reconciler.export_csv(recon_file)
        print(f"[Exported] QC Recon Report:    {recon_file}")

        # Optional DuckDB insertion
        if duckdb_path:
            import duckdb
            db_file = duckdb_path.expanduser()
            db_file.parent.mkdir(parents=True, exist_ok=True)
            con = duckdb.connect(str(db_file))
            tbl_base = f"ga_{election_date_clean}_{election_slug}".replace(
                "-", "_"
            )
            con.execute(
                f"CREATE TABLE IF NOT EXISTS {tbl_base}_county AS "
                f"SELECT * FROM read_csv_auto('{county_file}')"
            )
            con.execute(
                f"CREATE TABLE IF NOT EXISTS {tbl_base}_precinct AS "
                f"SELECT * FROM read_csv_auto('{precinct_file}')"
            )
            con.close()
            print(f"[DuckDB] Loaded tables into:  {duckdb_path}")

        print("=" * 88 + "\n")
        return {
            "county_file": county_file,
            "precinct_file": precinct_file,
            "recon_file": recon_file
        }


def main():
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
        "--ai", action="store_true",
        help="Enable Gemini AI assistant for mappings & anomaly analysis"
    )
    parser.add_argument(
        "--save-ai-rules", action="store_true",
        help="Auto-save AI approved mappings to cleaning_rules.yaml"
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
    parser.add_argument(
        "--api-key", type=str, default=None,
        help="Google Gemini API Key (or set GEMINI_API_KEY env var)"
    )

    args = parser.parse_args()

    processor = ElectionProcessor(
        rules_path=args.rules,
        all_offices=args.all_offices,
        use_ai=args.ai,
        api_key=args.api_key
    )

    processor.process_file(
        input_path=args.input,
        outdir=args.outdir,
        inspect_mode=args.inspect,
        duckdb_path=args.duckdb,
        save_ai_rules=args.save_ai_rules
    )


if __name__ == "__main__":
    main()
