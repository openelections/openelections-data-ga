---
name: process-ga-election
description: >-
  Use this skill when processing a new Georgia SOS Enhanced Voting JSON export
  into OpenElections county-level and precinct-level CSVs, tuning
  cleaning_rules.yaml for unmapped offices, preparing clean git commits for
  election data vs. pipeline changes, or drafting an upstream PR to
  openelections/openelections-data-ga.
---

# Process Georgia Enhanced Voting Election Export

Use this runbook when converting a raw Georgia Secretary of State Enhanced
Voting JSON export (`export-*.json`) into standardized OpenElections CSVs and
preparing clean commits or an upstream pull request.

## Step 1: Dry-Run Inspect First

Always inspect the raw JSON before writing CSVs:

```bash
uv run python enhanced_voting_process/process_election.py \
  --input <path/to/export.json> \
  --inspect
```

Review console output carefully:
- **`[INCLUDED]`**: verify every expected Federal and State race is captured
  with the right canonical office name and district.
- **`[EXCLUDED - NON-FEDERAL/STATE]`**: verify no State/Federal race was
  accidentally matched by a local block-list pattern.
- **`[UNMAPPED]`**: inspect every unrecognized office string.
- **County counts & reconciliation summary**: confirm all expected counties for
  each district/statewide race are present and check for any `DISCREPANCY` rows.

## Step 2: Update Rules & Tests (If Needed)

If `[UNMAPPED]` races appeared (or an office/party was misclassified):
1. Add a deterministic regex pattern or override in
   `enhanced_voting_process/cleaning_rules.yaml` (`office_patterns` for
   Federal/State races, `excluded_local_patterns` for local/municipal races).
2. Add parametrized test cases in `tests/test_cleaner.py` (or end-to-end tests
   in `tests/test_process_election.py`).
3. Never drop rows solely because `politicalParty` is `null` — Georgia judicial
   races (`Supreme Court Justice`, `Appeals Court Judge`,
   `Superior Court Judge`) are nonpartisan, and some counties omit
   `politicalParty` while sibling counties provide it.

## Step 3: Export CSVs & Run Quality Checks

1. Generate outputs into the target year directory (e.g. `./2025/` or `./2026/`):
   ```bash
   uv run python enhanced_voting_process/process_election.py \
     --input <path/to/export.json> \
     --outdir ./<YYYY>/
   ```
2. Run unit tests and linting:
   ```bash
   uv run python -m pytest -v
   uv run python -m flake8 --exclude=enhanced_voting_process/archived \
     enhanced_voting_process/ tests/
   ```
3. Run the `validate-ga-sos-results` skill to audit the generated CSVs locally
   and cross-check totals, county/precinct samples, and **Official vs.
   Unofficial** certification status against `https://results.sos.ga.gov`.

## Step 4: Clean Commits & Upstream PR Hygiene

- **Keep code and data commits separate** using Conventional Commits:
  - Pipeline/rule/test changes:
    `fix(enhanced_voting): ...` or `refactor(enhanced_voting): ...`
  - Election results:
    `data(ga): add official results for YYYY-MM-DD <election>`
    *(or `add unofficial results ...` when GA SOS still lists results as
    Unofficial, noting certification status in the commit body)*.
- **Do not commit**: `*.json`, `*reconciliation_report.csv`, `*.db`, `*.duckdb`,
  `.env`, or unrelated scratch edits in `2025/code/qc_race_results.ipynb`.
- **Upstream PR checklist** (`ATLJoeReed/openelections-data-ga` ->
  `openelections/openelections-data-ga`):
  - Include a summary table of every new election CSV with date, contests,
    counties, and **Official vs. Unofficial** status.
  - Note any expected voter-privacy residuals (`0,,,,` precincts or suppressed
    single-precinct county modalities) verified against `results.sos.ga.gov`.
  - Provide the direct compare URL:
    `https://github.com/openelections/openelections-data-ga/compare/master...ATLJoeReed:openelections-data-ga:master?expand=1`
