#!/usr/bin/env python3
"""Validate OpenElections Georgia county-level and precinct-level CSVs.

Checks structural integrity (mirroring openelections-data-tests), computes
statewide/district totals with privacy-suppressed county tracking, and
reconciles county totals against precinct sums.
"""

import argparse
from collections import Counter, defaultdict
import csv
from pathlib import Path
import sys
from typing import Dict, List, Optional, Tuple

VOTE_MODALITIES = (
    "election_day_votes",
    "advanced_votes",
    "absentee_by_mail_votes",
    "provisional_votes",
)
REQUIRED_COLS = (
    "county",
    "precinct",
    "office",
    "party",
    "candidate",
    "votes",
)


def load_csv(path: Path) -> Tuple[List[str], List[Dict[str, str]]]:
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = list(reader.fieldnames or [])
        rows = list(reader)
    return fieldnames, rows


def check_table(
    label: str,
    header: List[str],
    rows: List[Dict[str, str]],
    is_county: bool,
) -> List[str]:
    errors: List[str] = []
    has_votes = "votes" in header
    has_mods = all(col in header for col in VOTE_MODALITIES)

    req_cols = [c for c in REQUIRED_COLS if c != "votes" or has_votes]
    missing_header = [c for c in req_cols if c not in header]
    if missing_header:
        errors.append(f"[{label}] Missing columns: {missing_header}")
        return errors

    key_counts = Counter(
        (
            r["county"],
            r["precinct"],
            r["office"],
            r.get("district", ""),
            r["party"],
            r["candidate"],
        )
        for r in rows
    )
    dups = [k for k, cnt in key_counts.items() if cnt > 1]
    ws_count = 0
    req_missing = 0
    bad_numeric = 0
    bad_precinct = 0
    partial_null = 0
    math_mismatch = 0

    for r in rows:
        if any(v != v.strip() for v in r.values() if v is not None):
            ws_count += 1
        if any(r.get(col, "") == "" for col in req_cols):
            req_missing += 1
        if is_county and r.get("precinct") != "not available":
            bad_precinct += 1

        num_cols = (["votes"] if has_votes else []) + (
            list(VOTE_MODALITIES) if has_mods else []
        )
        parsed: Dict[str, Optional[int]] = {}
        row_bad_num = False
        for col in num_cols:
            raw = r.get(col, "")
            if raw == "":
                parsed[col] = None
            else:
                try:
                    val = int(raw)
                    if val < 0:
                        row_bad_num = True
                    parsed[col] = val
                except ValueError:
                    row_bad_num = True
        if row_bad_num:
            bad_numeric += 1
            continue

        if has_mods:
            mod_vals = [parsed[col] for col in VOTE_MODALITIES]
            non_null = [v for v in mod_vals if v is not None]
            if 0 < len(non_null) < len(VOTE_MODALITIES):
                partial_null += 1
            elif len(non_null) == len(VOTE_MODALITIES) and has_votes:
                if parsed["votes"] is not None and (
                    sum(non_null) != parsed["votes"]
                ):
                    math_mismatch += 1

    print(
        f"[{label}] rows={len(rows):,} | dups={len(dups)} | "
        f"whitespace={ws_count} | req_missing={req_missing} | "
        f"bad_numeric={bad_numeric} | bad_precinct={bad_precinct} | "
        f"partial_null={partial_null} | math_mismatch={math_mismatch}"
    )

    if dups:
        errors.append(f"[{label}] {len(dups)} duplicate key(s): {dups[:3]}")
    if ws_count:
        errors.append(f"[{label}] {ws_count} row(s) with stray whitespace")
    if req_missing:
        errors.append(f"[{label}] {req_missing} row(s) missing required value")
    if bad_numeric:
        errors.append(f"[{label}] {bad_numeric} row(s) with bad/negative ints")
    if bad_precinct:
        errors.append(
            f"[{label}] {bad_precinct} county row(s) != 'not available'"
        )
    if partial_null:
        errors.append(
            f"[{label}] {partial_null} row(s) with partial-null modalities"
        )
    if math_mismatch:
        errors.append(
            f"[{label}] {math_mismatch} row(s) where modality sum != votes"
        )
    return errors


def row_total_votes(row: Dict[str, str], has_votes: bool) -> int:
    if has_votes and row.get("votes", "") != "":
        return int(row["votes"])
    return sum(int(row.get(c) or 0) for c in VOTE_MODALITIES)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate OpenElections GA county and precinct CSV files."
    )
    parser.add_argument(
        "--county", required=True, type=Path, help="Path to county-level CSV"
    )
    parser.add_argument(
        "--precinct",
        type=Path,
        default=None,
        help="Path to precinct-level CSV (auto-detected if omitted)",
    )
    parser.add_argument(
        "--max-diffs",
        type=int,
        default=30,
        help="Maximum reconciliation diff rows to display (default: 30)",
    )
    args = parser.parse_args()

    county_path = args.county.expanduser()
    if not county_path.exists():
        print(f"ERROR: County CSV not found: {county_path}", file=sys.stderr)
        return 2

    precinct_path = args.precinct
    if precinct_path is None:
        candidate = Path(
            str(county_path).replace(
                "__county-level.csv", "__precinct-level.csv"
            )
        )
        if candidate != county_path and candidate.exists():
            precinct_path = candidate
    else:
        precinct_path = precinct_path.expanduser()

    c_header, c_rows = load_csv(county_path)
    c_has_votes = "votes" in c_header
    c_has_mods = all(col in c_header for col in VOTE_MODALITIES)

    print("=" * 80)
    print(f"County CSV:   {county_path}")
    if precinct_path and precinct_path.exists():
        print(f"Precinct CSV: {precinct_path}")
    else:
        print("Precinct CSV: (none)")
    print("=" * 80)

    errors = check_table("county", c_header, c_rows, is_county=True)

    p_header: List[str] = []
    p_rows: List[Dict[str, str]] = []
    if precinct_path and precinct_path.exists():
        p_header, p_rows = load_csv(precinct_path)
        errors.extend(check_table("precinct", p_header, p_rows, False))

    # Aggregate statewide / district totals from county CSV
    overall = defaultdict(
        lambda: {
            "votes": 0,
            "ed": 0,
            "adv": 0,
            "abm": 0,
            "prov": 0,
            "counties": set(),
            "suppressed_counties": set(),
        }
    )
    c_map: Dict[tuple, int] = {}
    cands_per_cty_race = defaultdict(set)

    for r in c_rows:
        tot = row_total_votes(r, c_has_votes)
        key = (r["office"], r.get("district", ""), r["party"], r["candidate"])
        s = overall[key]
        s["votes"] += tot
        s["counties"].add(r["county"])
        if c_has_mods:
            if r["election_day_votes"] == "":
                s["suppressed_counties"].add(r["county"])
            else:
                s["ed"] += int(r["election_day_votes"])
                s["adv"] += int(r["advanced_votes"])
                s["abm"] += int(r["absentee_by_mail_votes"])
                s["prov"] += int(r["provisional_votes"])
        c_key = (
            r["county"],
            r["office"],
            r.get("district", ""),
            r["party"],
            r["candidate"],
        )
        c_map[c_key] = tot
        race_key = (r["county"], r["office"], r.get("district", ""))
        cands_per_cty_race[race_key].add((r["party"], r["candidate"]))

    print("\n=== CONTEST & OVERALL TOTALS (COUNTY CSV) ===")
    by_race = defaultdict(list)
    for k, s in overall.items():
        by_race[(k[0], k[1])].append((k, s))

    for (office, dist), items in sorted(by_race.items()):
        race_tot = sum(s["votes"] for _, s in items)
        dist_lbl = f" District {dist}" if dist else ""
        cty_count = max(len(s["counties"]) for _, s in items)
        print(
            f"\n{office}{dist_lbl} "
            f"(counties={cty_count}, total_votes={race_tot:,}):"
        )
        suppressed_any = set()
        for k, s in sorted(items, key=lambda x: -x[1]["votes"]):
            pct = (100.0 * s["votes"] / race_tot) if race_tot else 0.0
            suppressed_any |= s["suppressed_counties"]
            if c_has_mods:
                mod_sum = s["ed"] + s["adv"] + s["abm"] + s["prov"]
                unalloc = s["votes"] - mod_sum
                print(
                    f"  {k[3]} ({k[2]}): votes={s['votes']:,} ({pct:.2f}%) | "
                    f"ED={s['ed']:,} Adv={s['adv']:,} Mail={s['abm']:,} "
                    f"Prov={s['prov']:,} | "
                    f"suppressed_ctys={len(s['suppressed_counties'])} "
                    f"unallocated={unalloc:,}"
                )
            else:
                print(f"  {k[3]} ({k[2]}): votes={s['votes']:,} ({pct:.2f}%)")
        if suppressed_any:
            print(
                f"  Privacy-suppressed counties (blank modalities): "
                f"{sorted(suppressed_any)}"
            )

    # Precinct reconciliation & zero-vote audit
    if p_rows:
        p_has_votes = "votes" in p_header
        p_has_mods = all(col in p_header for col in VOTE_MODALITIES)
        p_map: Dict[tuple, int] = defaultdict(int)
        precs_per_cty_race = defaultdict(set)
        zero_precs = defaultdict(lambda: {"suppressed": 0, "true_zero": 0})

        for r in p_rows:
            v = row_total_votes(r, p_has_votes)
            p_key = (
                r["county"],
                r["office"],
                r.get("district", ""),
                r["party"],
                r["candidate"],
            )
            p_map[p_key] += v
            race_key = (r["county"], r["office"], r.get("district", ""))
            precs_per_cty_race[race_key].add(r["precinct"])
            if v == 0:
                z_key = (*race_key, r["precinct"])
                if p_has_mods and r["election_day_votes"] == "":
                    zero_precs[z_key]["suppressed"] += 1
                else:
                    zero_precs[z_key]["true_zero"] += 1

        expected_rect = sum(
            len(cands_per_cty_race[rk]) * len(precs_per_cty_race[rk])
            for rk in cands_per_cty_race
        )
        all_keys = sorted(set(c_map) | set(p_map))
        diffs = []
        for k in all_keys:
            cv = c_map.get(k)
            pv = p_map.get(k)
            if cv != pv:
                diffs.append((k, cv, pv, (cv or 0) - (pv or 0)))

        print("\n=== COUNTY VS PRECINCT RECONCILIATION ===")
        print(
            f"County-candidate combos: {len(all_keys)} | "
            f"exact matches: {len(all_keys) - len(diffs)} | "
            f"residuals/diffs: {len(diffs)}"
        )
        print(
            f"Rectangular precinct check: actual={len(p_rows):,}, "
            f"expected={expected_rect:,} "
            f"({'PASS' if len(p_rows) == expected_rect else 'MISMATCH'})"
        )
        for k, cv, pv, diff in diffs[: args.max_diffs]:
            note = ""
            if pv is None:
                note = " [MISSING_IN_PRECINCT]"
            elif cv is None:
                note = " [MISSING_IN_COUNTY]"
            print(
                f"  DIFF: {k[0]} | {k[1]} D{k[2]} | {k[4]} ({k[3]}): "
                f"county={cv}, precinct_sum={pv}, diff={diff:+d}{note}"
            )
        if len(diffs) > args.max_diffs:
            print(
                f"  ... and {len(diffs) - args.max_diffs} more diffs "
                f"(pass --max-diffs to show more)."
            )

        suppressed_zeros = {
            k: v for k, v in sorted(zero_precs.items()) if v["suppressed"] > 0
        }
        if suppressed_zeros:
            print(
                f"\nPrivacy-suppressed zero-vote precincts (0,,,,): "
                f"{len(suppressed_zeros)}"
            )
            for (cty, off, dist, prec), counts in list(
                suppressed_zeros.items()
            )[:25]:
                print(
                    f"  {cty} | {off} D{dist} | {prec} "
                    f"(suppressed_rows={counts['suppressed']})"
                )
            if len(suppressed_zeros) > 25:
                print(f"  ... and {len(suppressed_zeros) - 25} more.")

    print("\n=== VERDICT ===")
    if errors:
        print("FAIL — structural/integrity errors found:")
        for err in errors:
            print(f"  - {err}")
        return 1

    print("PASS — all structural, math, and schema checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
