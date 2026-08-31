from collections import defaultdict
import csv
from pathlib import Path
from typing import Any, Dict, List


def get_row_total_votes(r: Dict[str, Any]) -> int:
    """Computes the total vote count for a row regardless of schema format."""
    if "votes" in r and r["votes"] is not None:
        try:
            return int(r["votes"])
        except ValueError:
            return 0
    ed = int(r.get("election_day_votes") or 0)
    adv = int(r.get("advanced_votes") or 0)
    ab = int(r.get("absentee_by_mail_votes") or 0)
    prov = int(r.get("provisional_votes") or 0)
    return ed + adv + ab + prov


class ElectionReconciler:
    def __init__(self):
        self.records: List[Dict[str, Any]] = []

    def reconcile(
        self,
        county_rows: List[Dict[str, Any]],
        precinct_rows: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        if not precinct_rows:
            self.records = []
            return self.records

        # Aggregate county votes
        county_map: Dict[tuple, int] = defaultdict(int)
        for r in county_rows:
            key = (
                r["county"],
                r["office"],
                str(r.get("district", "")),
                r["candidate"],
                r["party"]
            )
            county_map[key] += get_row_total_votes(r)

        # Aggregate precinct votes
        precinct_map: Dict[tuple, int] = defaultdict(int)
        precinct_count_map: Dict[tuple, int] = defaultdict(int)
        for r in precinct_rows:
            key = (
                r["county"],
                r["office"],
                str(r.get("district", "")),
                r["candidate"],
                r["party"]
            )
            precinct_map[key] += get_row_total_votes(r)
            precinct_count_map[key] += 1

        all_keys = set(county_map.keys()).union(set(precinct_map.keys()))
        self.records = []

        for key in sorted(all_keys):
            county, office, district, candidate, party = key
            c_votes = county_map.get(key, 0)
            p_votes = precinct_map.get(key, 0)
            p_count = precinct_count_map.get(key, 0)
            diff = c_votes - p_votes

            if c_votes > 0:
                coverage_pct = round((p_votes / c_votes) * 100, 2)
            elif p_votes == 0:
                coverage_pct = 100.0
            else:
                coverage_pct = 0.0

            if diff == 0:
                status = "MATCH"
            elif diff > 0 and (diff <= 15 or coverage_pct >= 90.0):
                status = "EXPECTED_RESIDUAL"
            else:
                status = "DISCREPANCY"

            self.records.append({
                "county": county,
                "office": office,
                "district": district,
                "candidate": candidate,
                "party": party,
                "county_votes": c_votes,
                "precinct_votes_sum": p_votes,
                "precinct_count": p_count,
                "diff": diff,
                "coverage_pct": coverage_pct,
                "status": status
            })

        return self.records

    def print_summary(self, max_diff_rows: int = 15):
        if not self.records:
            print("\n[INFO] County-level only election "
                  "(no precinct data in source JSON to reconcile).")
            return

        total_county_votes = sum(r["county_votes"] for r in self.records)
        total_precinct_votes = sum(
            r["precinct_votes_sum"] for r in self.records
        )
        net_diff = total_county_votes - total_precinct_votes
        if total_county_votes:
            overall_cov = round(
                (total_precinct_votes / total_county_votes * 100), 2
            )
        else:
            overall_cov = 100.0

        matches = sum(1 for r in self.records if r["status"] == "MATCH")
        residuals = sum(
            1 for r in self.records if r["status"] == "EXPECTED_RESIDUAL"
        )
        discrepancies = sum(
            1 for r in self.records if r["status"] == "DISCREPANCY"
        )

        print("\n" + "=" * 88)
        print("  ELECTION RECONCILIATION SUMMARY"
              " (County Totals vs. Sum of Precincts)")
        print("=" * 88)
        print(f"Total Contests Checked:     {len(self.records):,}")
        print(f"Total County-Level Votes:   {total_county_votes:,}")
        print(f"Total Precinct-Level Votes: {total_precinct_votes:,}")
        print(f"Net Difference:             {net_diff:,}"
              f" ({overall_cov}% precinct coverage)")
        print(f"Match Status Breakdown:     {matches} Exact Matches"
              f" | {residuals} Expected Residuals"
              f" | {discrepancies} Discrepancies")
        print("-" * 88)

        non_matches = [r for r in self.records if r["status"] != "MATCH"]
        if non_matches:
            print(f"Sample Variances (showing up to {max_diff_rows} of"
                  f" {len(non_matches)} non-matching contests):")
            print(f"{'County':<18} {'Candidate':<24} {'County':>8}"
                  f" {'Precinct':>9} {'Diff':>6} {'Status':<18}")
            print("-" * 88)
            for r in non_matches[:max_diff_rows]:
                c_name = r["county"][:17]
                cand = r["candidate"][:23]
                cv = r["county_votes"]
                pv = r["precinct_votes_sum"]
                df = r["diff"]
                st = r["status"]
                print(f"{c_name:<18} {cand:<24} {cv:>8}"
                      f" {pv:>9} {df:>6} [{st}]")
            if len(non_matches) > max_diff_rows:
                print(f"... and {len(non_matches) - max_diff_rows} more.")
        else:
            print("All county and precinct totals match 100%!")

        print("=" * 88 + "\n")

    def export_csv(self, output_path: Path):
        if not self.records:
            return
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "w", newline="", encoding="utf-8") as f:
            fieldnames = [
                "county", "office", "district", "candidate", "party",
                "county_votes", "precinct_votes_sum", "precinct_count",
                "diff", "coverage_pct", "status"
            ]
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(self.records)
