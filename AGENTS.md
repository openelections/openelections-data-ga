# AGENTS.md

Guidance for AI coding agents working in `openelections-data-ga`.

## Repository Purpose

This repository (`openelections-data-ga`) stores standardized, machine-readable election results for Georgia as part of the [OpenElections](https://openelections.net/) project.

- Election results are organized by year (`2000/`–`2026/`) as canonical OpenElections CSVs:
  - `YYYYMMDD__ga__<election_details>__county-level.csv`
  - `YYYYMMDD__ga__<election_details>__precinct-level.csv`
- Raw sources come from the Georgia Secretary of State: pre-2011 elections were scraped/pre-processed from SOS HTML pages and PDF files; starting in 2012 the state used Clarity, and recent elections use Enhanced Voting JSON exports.
- `archived_code/` and `enhanced_voting_process/archived/` contain legacy scripts and notebooks; prefer `enhanced_voting_process/` for current Enhanced Voting JSON workflows.

## Environment & Tooling

- **Python**: `>=3.13` (see `pyproject.toml`)
- **Package manager**: `uv` (dependencies locked in `uv.lock`; `pytest` is in `[dependency-groups] dev`)
- Key libraries: `pydantic`, `pandas`, `duckdb`, `pyyaml`, `flake8`, `pytest`.

Run Python commands from the repository root with `uv run` (run `uv sync` first if setting up or after moving the repo directory):

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
   - `--all-offices`: Include local/municipal offices instead of filtering to canonical Federal and State offices.
   - `--duckdb <path/to/file.duckdb>`: Load cleaned tables into a DuckDB database.
   - `--rules <path/to/cleaning_rules.yaml>`: Use a custom rules YAML file.

### Module Layout (`enhanced_voting_process/`)

- `process_election.py` — Main CLI entrypoint (`ElectionProcessor`).
- `enhanced_json_model.py` — Pydantic schema validation for raw Enhanced Voting JSON.
- `cleaner.py` — Deterministic office/party/candidate normalization and Federal/State vs. local filtering.
- `cleaning_rules.yaml` — Canonical office list, party mappings, and local exclusion patterns.
- `reconciler.py` — Non-blocking QC comparing county totals against sums of precinct totals.

## Data Conventions & Important Gotchas

- **Canonical Offices & Parties**:
  - OpenElections Georgia tracks 19 canonical Federal and State offices (also listed in `enhanced_voting_process/cleaning_rules.yaml`). Local/municipal races (e.g., Mayor, Sheriff, SPLOST, Board of Education) are excluded by default:
    - `President`, `Vice President`, `U.S. Senate`, `U.S. House`
    - `Governor`, `Lieutenant Governor`, `Secretary of State`, `Attorney General`, `Commissioner of Agriculture`, `Commissioner of Insurance`, `Commissioner of Labor`, `Public Service Commissioner`, `State School Superintendent`
    - `State Senate`, `State House`
    - `Supreme Court Justice`, `Appeals Court Judge`, `Superior Court Judge`, `District Attorney`
  - Standard party names: `Democrat`, `Republican`, `Libertarian`, `Independent`, `Nonpartisan`, `Green`, `Write-In`, `Unknown`.
  - **Party resolution across counties**: When a county omits `politicalParty` in raw JSON, `process_election.py` resolves party in order: `opt.party` → parenthesized suffix in `opt.candidate` (e.g. `(Dem)`, `(Rep)`, `(Ind)` — ignoring `(I)`, which Georgia SOS uses for Incumbent) → office-level hint / `office_overrides` → explicit party for the same `(office, district, candidate)` in sibling counties → default `'Nonpartisan'`. Never drop rows solely because `politicalParty` is `null` (Georgia judicial races — `Supreme Court Justice`, `Appeals Court Judge`, `Superior Court Judge` — are nonpartisan).
- **County vs. Precinct Vote Breakouts** (see `2025/Precinct_Votes_README.md`):
  - **County-level CSVs** use `precinct = not available`, include `votes` for certified totals, and populate `election_day_votes`, `advanced_votes`, `absentee_by_mail_votes`, and `provisional_votes` when vote-method breakdowns are reported. If a county's breakdown is privacy-suppressed (`-` / `voteCount: null`, common in single-precinct counties), `votes` retains the certified total and the four modality columns are left blank (`,,,,`).
  - **Precinct-level CSVs** use the `votes` column for total precinct votes. Vote-method breakout columns at the precinct level are often blank (`,,,,`) when counties tabulate early/absentee ballots centrally or withhold small-precinct breakdowns for voter privacy. Never sum precinct breakout columns to estimate countywide modality totals.
  - Minor residuals between county totals and precinct sums can occur due to suppressed small precincts or countywide provisional/overseas ballots.
- **Gitignored Files** (see `.gitignore`):
  - `*.json`, `*reconciliation_report.csv`, `*.db`, `*.duckdb`, and `.env` are gitignored. Do not commit raw JSON exports, reconciliation reports, DuckDB files, or local `.env` files.

## Testing, Linting & Validation

### Unit Tests (`pytest`)

Unit tests live in `tests/` (`tests/test_cleaner.py`, `tests/test_process_election.py`), with `pythonpath = ["."]` configured in `pyproject.toml`:

```bash
uv run pytest -v
# Or invoke via Python module directly:
uv run python -m pytest -v
```

### Linting (`flake8`)

Check PEP 8 / style compliance (79-character line limit) before committing Python changes:

```bash
uv run flake8 --exclude=enhanced_voting_process/archived enhanced_voting_process/ tests/
# Or invoke via Python module directly:
uv run python -m flake8 --exclude=enhanced_voting_process/archived enhanced_voting_process/ tests/
```

### OpenElections Data CI & Website Validation

- **Automated CI**: `.github/workflows/data_tests.yml` runs `openelections/openelections-data-tests` (`v2.2.0`) on push and pull requests for:
  - `duplicate_entries`
  - `file_format`
  - `missing_values`
  - `vote_breakdown_totals`
- **Local Pre-Commit Validator**: Run `python3 .agents/skills/validate-ga-sos-results/scripts/validate_csvs.py --county <path/to/county-level.csv>` for structural, modality-math, rectangular precinct, and county-vs-precinct reconciliation checks.
- **Post-Conversion QC Notebook**: `2025/code/qc_race_results.ipynb` uses DuckDB to inspect overall totals, county reconciliation, precinct drill-downs, and integrity checks alongside the SOS portal.
- **Manual / Website Validation**: When validating generated CSVs against `https://results.sos.ga.gov`, verify:
  1. Statewide totals match the SOS summary page (noting that counties with privacy-suppressed `-` breakdowns have blank modality columns in the county CSV even though statewide totals include them).
  2. County-level `votes` and vote-method columns (`election_day_votes`, `advanced_votes`, `absentee_by_mail_votes`, `provisional_votes`) match the county results pages.
  3. Precinct-level `votes` (and any non-blank vote-method columns) match the drilled-down precinct tables.
  4. Precinct `votes` sum to county totals (or any minor variance is confirmed as privacy-suppressed precincts and documented in `*_reconciliation_report.csv`).

## Agent Skills (`.agents/skills/`)

Two workspace skills codify repeatable workflows for Georgia elections:
- **`process-ga-election`** (`.agents/skills/process-ga-election/SKILL.md`): End-to-end runbook for `--inspect`, tuning `cleaning_rules.yaml`, exporting CSVs, running `pytest`/`flake8`, and preparing clean commits or upstream PRs.
- **`validate-ga-sos-results`** (`.agents/skills/validate-ga-sos-results/SKILL.md`): Runs local structural/reconciliation checks via `.agents/skills/validate-ga-sos-results/scripts/validate_csvs.py` and cross-checks certification status (`Official` vs. `Unofficial`), totals, and county/precinct samples against `https://results.sos.ga.gov`.
