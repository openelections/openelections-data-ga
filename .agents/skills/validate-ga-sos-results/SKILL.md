---
name: validate-ga-sos-results
description: >-
  Use this skill when the user asks to validate, audit, or spot-check Georgia
  OpenElections county-level and/or precinct-level CSV files against the live
  Georgia Secretary of State Enhanced Voting website (results.sos.ga.gov) or
  run pre-commit structural and reconciliation checks on Georgia election CSVs.
---

# Validate Georgia SOS Election Results

Follow this runbook whenever validating OpenElections Georgia CSVs
(`YYYYMMDD__ga__*__county-level.csv` and `YYYYMMDD__ga__*__precinct-level.csv`)
against official Georgia Secretary of State results at
`https://results.sos.ga.gov`.

## Step 1: Run Local Structural & Reconciliation Audit

Run the bundled zero-dependency validation script first:

```bash
python3 .agents/skills/validate-ga-sos-results/scripts/validate_csvs.py \
  --county <path/to/county-level.csv> \
  --precinct <path/to/precinct-level.csv>
```

Check the output for:
1. **Hard CI checks** (must all be `0`): duplicate keys, stray whitespace,
   missing required values, negative/non-integer counts, county rows where
   `precinct != 'not available'`, partial-null vote-method columns, and
   modality math mismatches (`votes != ED + Adv + Mail + Prov`).
2. **Rectangular precinct check**: confirms every `(county, office, district)`
   has rows for all `precincts × candidates`.
3. **Privacy-suppressed counties (`unallocated > 0`)**: note which counties
   have blank vote-method columns (`,,,,`) in the county CSV (common in
   single-precinct counties) and their exact `unallocated` vote sums.
4. **County-vs-precinct residuals (`DIFF`)**: note any non-zero diffs and
   whether the same county has privacy-suppressed zero-vote precincts (`0,,,,`).

## Step 2: Cross-Check Against Live GA SOS Portal (When URL Provided)

Delegate browsing `https://results.sos.ga.gov/...` directly to the `browser`
subagent (never scrape the SPA with `curl` or Python HTTP clients). Ask the
browser subagent to collect:

1. **Certification status & timestamp**: confirm whether the portal displays
   **Official Results** or **Unofficial Results** and note the last-updated
   timestamp (crucial for accurate git commit messages and PR notes).
2. **Complete State & Federal contest list & county counts**: confirm no
   State/Federal race or participating county was dropped (skip municipal/local
   races unless `--all-offices` was requested).
3. **Statewide / district totals & vote-method breakdowns**:
   - Total `votes` for every candidate must match the SOS summary page **100%**.
   - If `suppressed_ctys == 0`, all four vote-method totals (`Election Day`,
     `Advanced Voting`, `Absentee by Mail`, `Provisional`) must also match SOS
     to the exact vote.
   - If `suppressed_ctys > 0`, verify that each CSV modality sum is `<=` the
     SOS statewide modality total and that the sum of the four modality gaps
     equals `unallocated` from Step 1 (proving all non-suppressed counties match
     100%).
4. **Targeted county & precinct drill-downs**:
   - Spot-check 2–5 representative counties (including any county with
     suppressed modalities to confirm SOS displays `-` across all 4 modality
     columns).
   - Spot-check 3–5 precincts in 1–2 counties (confirming totals, populated
     breakdowns, and blank suppressed breakdowns match SOS).
   - For any county with a county-vs-precinct `DIFF`, inspect its `0,,,,`
     precincts on SOS to confirm SOS displays `-` for `Total Votes` (voter
     privacy suppression) rather than a real zero or missing precinct.

## Step 3: Report Verdict Clearly

Summarize results concisely for the user:
- **Overall verdict** (`PASS` / `ISSUES FOUND`) and **Official vs. Unofficial**
  status from GA SOS.
- **Contest summary table** comparing CSV vs. SOS totals (and modality gaps if
  any counties are privacy-suppressed).
- **County & precinct spot-check results** and confirmation of any expected
  privacy-suppression residuals.
- **Actionable fixes** (pointing to `enhanced_voting_process/process_election.py`,
  `cleaner.py`, or `cleaning_rules.yaml`) if any discrepancy is found.
