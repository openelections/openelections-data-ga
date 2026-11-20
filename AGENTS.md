# AGENTS.md

Guidance for AI coding agents working in `openelections-data-ga`.

## Repository Purpose

This repository (`openelections-data-ga`) stores standardized, machine-readable election results for Georgia as part of the [OpenElections](https://openelections.net/) project.

- Election results are organized by year (`2000/`–`2025/`) as canonical OpenElections CSVs:
  - `YYYYMMDD__ga__<election_details>__county-level.csv`
  - `YYYYMMDD__ga__<election_details>__precinct-level.csv`
- Raw sources come from the Georgia Secretary of State: pre-2011 elections were scraped/pre-processed from SOS HTML pages and PDF files; starting in 2012 the state used Clarity, and recent elections use Enhanced Voting JSON exports.
- `archived_code/` and `enhanced_voting_process/archived/` contain legacy scripts and notebooks; prefer `enhanced_voting_process/` for current Enhanced Voting JSON workflows.

## Environment & Tooling

- **Python**: `>=3.13` (see `pyproject.toml`)
- **Package manager**: `uv` (dependencies locked in `uv.lock`)
- Key libraries: `pydantic`, `pandas`, `duckdb`, `pyyaml`, `google-genai`, `flake8`.

Run Python commands from the repository root with `uv run`:

```bash
uv run python <script.py>
```

## Running `enhanced_voting_process`

`enhanced_voting_process/` is the CLI pipeline that converts raw Georgia SOS / Enhanced Voting JSON exports (`export-*.json`) into OpenElections county-level and precinct-level CSVs.

### Core Commands

1. **Inspect / Dry-Run** (prints detected races, excluded local contests, and reconciliation QC without writing files):
   ```bash
   uv run python enhanced_voting_process/process_election.py \
     --input <path/to/export.json> \
     --inspect
   ```

2. **Generate OpenElections CSVs**:
   ```bash
   uv run python enhanced_voting_process/process_election.py \
     --input <path/to/export.json> \
     --outdir ./2025/
   ```
   This writes the county-level CSV, precinct-level CSV, and a diagnostic `*_reconciliation_report.csv` into `--outdir` (defaults to the input file's directory if omitted).

3. **Optional Flags**:
   - `--ai`: Enable Gemini AI (`gemini-2.5-flash`) to classify unmapped office strings and summarize reconciliation anomalies. Requires `GEMINI_API_KEY` in `enhanced_voting_process/.env` (copy from `enhanced_voting_process/.env.example`) or `--api-key`.
   - `--save-ai-rules`: Persist AI-approved mappings into `enhanced_voting_process/cleaning_rules.yaml`.
   - `--all-offices`: Include local/municipal offices instead of filtering to canonical Federal and State offices.
   - `--duckdb <path/to/file.duckdb>`: Load cleaned tables into a DuckDB database.
   - `--rules <path/to/cleaning_rules.yaml>`: Use a custom rules YAML file.

### Module Layout (`enhanced_voting_process/`)

- `process_election.py` — Main CLI entrypoint (`ElectionProcessor`).
- `enhanced_json_model.py` — Pydantic schema validation for raw Enhanced Voting JSON.
- `cleaner.py` — Deterministic office/party/candidate normalization and Federal/State vs. local filtering.
- `cleaning_rules.yaml` — Canonical office list, party mappings, and local exclusion patterns.
- `reconciler.py` — Non-blocking QC comparing county totals against sums of precinct totals.
- `ai_assistant.py` — Optional Google Gemini integration (falls back cleanly if no API key is set).

## Data Conventions & Important Gotchas

- **Canonical Offices & Parties**:
  - OpenElections Georgia tracks 19 canonical Federal and State offices (also listed in `enhanced_voting_process/cleaning_rules.yaml`). Local/municipal races (e.g., Mayor, Sheriff, SPLOST, Board of Education) are excluded by default:
    - `President`, `Vice President`, `U.S. Senate`, `U.S. House`
    - `Governor`, `Lieutenant Governor`, `Secretary of State`, `Attorney General`, `Commissioner of Agriculture`, `Commissioner of Insurance`, `Commissioner of Labor`, `Public Service Commissioner`, `State School Superintendent`
    - `State Senate`, `State House`
    - `Supreme Court Justice`, `Appeals Court Judge`, `Superior Court Judge`, `District Attorney`
  - Standard party names: `Democrat`, `Republican`, `Libertarian`, `Independent`, `Nonpartisan`, `Green`, `Write-In`, `Unknown`.
- **County vs. Precinct Vote Breakouts** (see `2025/Precinct_Votes_README.md`):
  - **County-level CSVs** use `precinct = not available` and contain certified totals across `election_day_votes`, `advanced_votes`, `absentee_by_mail_votes`, and `provisional_votes`.
  - **Precinct-level CSVs** use the `votes` column for total precinct votes. Vote-method breakout columns at the precinct level are often blank (`,,,,`) when counties tabulate early/absentee ballots centrally or withhold small-precinct breakdowns for voter privacy. Never sum precinct breakout columns to estimate countywide modality totals.
  - Minor residuals between county totals and precinct sums can occur due to suppressed small precincts or countywide provisional/overseas ballots.
- **Gitignored Files** (see `.gitignore`):
  - `*.json`, `*reconciliation_report.csv`, `*.db`, and `.env` are gitignored. Do not commit raw JSON exports, reconciliation reports, DuckDB files, or API keys.

## Validation & CI Checks

- **Automated CI**: `.github/workflows/data_tests.yml` runs `openelections/openelections-data-tests` (`v2.2.0`) on push and pull requests for:
  - `duplicate_entries`
  - `file_format`
  - `missing_values`
  - `vote_breakdown_totals`
- **Manual / Website Validation**: When validating generated CSVs against `https://results.sos.ga.gov`, verify:
  1. County-level vote-method columns (`election_day_votes`, `advanced_votes`, `absentee_by_mail_votes`, `provisional_votes`) match the county results pages.
  2. Precinct-level `votes` (and any non-blank vote-method columns) match the drilled-down precinct tables.
  3. Precinct `votes` sum to county totals (or any variance is documented in `*_reconciliation_report.csv`).
