# OpenElections Georgia — Enhanced Voting Results Processor

A unified, deterministic CLI pipeline for standardizing Georgia election results directly from raw Secretary of State / Enhanced Voting JSON exports into canonical OpenElections CSVs (`county-level.csv`, `precinct-level.csv`), complete with Federal/State race filtering, privacy-safe vote-method extraction, and non-blocking reconciliation QC.

---

## Table of Contents
1. [Overview & Architecture](#1-overview--architecture)
2. [How Office Filtering Works](#2-how-office-filtering-works)
3. [Output Schemas & Vote-Method Breakouts](#3-output-schemas--vote-method-breakouts)
4. [Reconciliation & Quality Control](#4-reconciliation--quality-control)
5. [CLI Reference & Options](#5-cli-reference--options)
6. [Step-by-Step Usage Guide](#6-step-by-step-usage-guide)
7. [Agent-Assisted Workflow & Prompts](#7-agent-assisted-workflow--prompts)
8. [Testing & Linting](#8-testing--linting)
9. [Directory & File Layout](#9-directory--file-layout)

---

## 1. Overview & Architecture

Previously, standardizing election results required multiple disconnected steps:
1. Running a Jupyter notebook (`load_json.ipynb`) with an interactive file chooser.
2. Generating intermediate flattened JSON files on disk.
3. Loading intermediate JSONs into DuckDB and manually executing multi-step SQL scripts (`jun2025_psc_special_election_county.sql`).
4. Manually updating SQL strings for office/party cleanup and running `COPY` commands.

### The Streamlined Pipeline
The processor replaces the multi-stage workflow with a single offline, deterministic pipeline:

```mermaid
flowchart TD
    A["Raw Election JSON Export<br>(export-*.json)"] --> B["ElectionProcessor CLI<br>(process_election.py)"]

    subgraph Core ["Core Pipeline"]
        B --> C["1. Schema Validation<br>(Pydantic ElectionResults)"]
        C --> D["2. Office & Race Filtering<br>(Include Federal/State | Exclude Local)"]
        D --> E["3. Deterministic Normalization<br>(County, Candidate, Precinct & Party cleanup)"]
        E --> F["4. Multi-Level Extraction<br>(County-Level & Precinct-Level Rows)"]
        F --> G["5. Diagnostic Reconciliation QC<br>(County Totals vs. Sum of Precincts)"]
    end

    G --> I["Final OpenElections County CSV<br>YYYYMMDD__ga__*__county-level.csv"]
    G --> J["Final OpenElections Precinct CSV<br>YYYYMMDD__ga__*__precinct-level.csv"]
    G --> K["Reconciliation Diagnostic Report<br>YYYYMMDD__ga__*__reconciliation_report.csv"]
    G -.-> L["(Optional) DuckDB Database Tables"]
```

---

## 2. How Office Filtering Works

OpenElections tracks **Federal and State offices** in Georgia. In major or municipal elections, state JSON exports often bundle county and local ballot items (e.g. `Tax Commissioner`, `Mayor`, `Sheriff`, `Board of Education`, `SPLOST` referendums) that are excluded by default.

### Classification Precedence (`cleaner.py`)
Each raw office string is classified deterministically against [`cleaning_rules.yaml`](cleaning_rules.yaml) in the following order:

1. **Exact Overrides (`office_overrides`)** — Immediately classified as `[INCLUDED]` using the configured canonical office, district, and optional party hint.
2. **Canonical Office Patterns (`office_patterns`)** — Allow-list regex patterns for the 19 standard OpenElections Georgia offices (with automatic district extraction):
   - **Federal**: `President`, `Vice President`, `U.S. Senate`, `U.S. House`
   - **State Executive**: `Governor`, `Lieutenant Governor`, `Secretary of State`, `Attorney General`, `State School Superintendent`, `Commissioner of Agriculture`, `Commissioner of Insurance`, `Commissioner of Labor`, `Public Service Commissioner`
   - **State Legislative**: `State Senate`, `State House`
   - **State Judicial**: `Supreme Court Justice`, `Appeals Court Judge`, `Superior Court Judge`, `District Attorney`
3. **Direct Canonical Match (`canonical_offices`)** — If the raw string already matches one of the 19 canonical office names, it is `[INCLUDED]` with an empty district.
4. **Known Local / Municipal Patterns (`excluded_local_patterns`)** — Block-list patterns (e.g. `Tax Commissioner`, `Sheriff`, `Coroner`, `County Commission`, `Mayor`, `City Council`, `Board of Education`, `SPLOST`, `Referendum`, `Probate`, alcohol/tax questions) are categorized as `[EXCLUDED - NON-FEDERAL/STATE]` and dropped by default.
5. **Unrecognized Races (`UNMAPPED`)** — Any office matching neither allow-list nor block-list is flagged as `[UNMAPPED]` in console output (and dropped unless `--all-offices` is passed or a pattern/override is added to [`cleaning_rules.yaml`](cleaning_rules.yaml)).
6. **Optional Local Inclusion (`--all-offices`)** — Includes all races (preserving raw office titles for non-canonical contests).

---

## 3. Output Schemas & Vote-Method Breakouts

CSV columns are chosen dynamically based on whether the source JSON includes vote-method breakdowns (`groupResults`):

- **When vote-method breakdowns are present:**
  - **County-level CSV** (`precinct = not available`):
    `county, precinct, office, district, party, candidate, votes, election_day_votes, advanced_votes, absentee_by_mail_votes, provisional_votes`
  - **Precinct-level CSV**:
    `county, precinct, office, district, party, candidate, votes, election_day_votes, advanced_votes, absentee_by_mail_votes, provisional_votes`
- **When no vote-method breakdowns are present (totals-only exports):**
  - Both CSVs use: `county, precinct, office, district, party, candidate, votes`

### Privacy-Suppressed Breakdowns
Georgia SOS / Enhanced Voting hides vote-method counts (`voteCount: null`, displayed as `-` on the SOS website) when too few ballots were cast to protect voter privacy—this occurs frequently at the precinct level and occasionally at the county level in single-precinct counties.

- If **any** vote-method entry in a row's `groupResults` is `None` (or `groupResults` is empty), `extract_vote_groups()` returns `None`.
- Both county-level and precinct-level rows retain the certified total in `votes` and leave all four vote-method columns blank (`,,,,`), preventing fabricated `0`s or misattribution to `election_day_votes`.
- If the source JSON has no `precinctResults`, precinct CSV and reconciliation report exports are skipped cleanly.

### Party Resolution Across Counties
If an individual county omits `politicalParty` in the JSON, the processor resolves party in priority order:
1. Explicit `politicalParty` from the JSON
2. Parenthesized party suffix in the candidate string (e.g. `(Dem)`, `(Rep)`, `(Ind)` — ignoring `(I)` for Incumbent)
3. Party hint from the office title or `office_overrides`
4. Explicit party for the same `(office, district, candidate)` from another county in the same election
5. Default `'Nonpartisan'` (preserving nonpartisan judicial races such as `Supreme Court Justice`, `Appeals Court Judge`, and `Superior Court Judge`)

---

## 4. Reconciliation & Quality Control

In Georgia SOS / Enhanced Voting exports, **precinct sums occasionally differ slightly from county totals**:
- Very small precincts may have even their total votes suppressed (`-` on SOS, `0` in JSON) for voter privacy.
- Certain ballot categories (such as countywide provisional, challenged, or overseas ballots) can be tabulated at the county level without precinct assignment.

### How QC is Handled
Instead of a rigid assertion that aborts export, [`reconciler.py`](reconciler.py) compares every county-candidate total against the sum of its precinct `votes`:
- $\text{Diff} = \text{County Total} - \sum(\text{Precincts})$
- `MATCH`: $\text{Diff} = 0$
- `EXPECTED_RESIDUAL`: $\text{Diff} > 0$ and ($\text{Diff} \le 15$ or coverage $\ge 90\%$)
- `DISCREPANCY`: Any larger or negative variance flagged for manual review
- The CLI prints a diagnostic summary table and writes a companion `*_reconciliation_report.csv` file (gitignored).

---

## 5. CLI Reference & Options

Run the CLI from the repository root using `uv run python enhanced_voting_process/process_election.py [OPTIONS]`:

```text
usage: process_election.py [-h] -i INPUT [-o OUTDIR] [--inspect]
                           [--all-offices] [--duckdb DUCKDB] [--rules RULES]

OpenElections Georgia Voter Results Processor

options:
  -h, --help            show this help message and exit
  -i INPUT, --input INPUT
                        Path to raw JSON election export file
  -o OUTDIR, --outdir OUTDIR
                        Output directory for generated CSV files (defaults to input dir)
  --inspect             Inspect / dry-run mode (does not write CSVs)
  --all-offices         Process all offices (including non-standard local races)
  --duckdb DUCKDB       Optional path to DuckDB file to load cleaned tables
  --rules RULES         Custom path to cleaning_rules.yaml
```

---

## 6. Step-by-Step Usage Guide

### Step 1: Inspect a New File (Dry Run)
Verify detected races, excluded local contests, unmapped offices, and county-vs-precinct reconciliation without writing files:
```bash
uv run python enhanced_voting_process/process_election.py \
  --input ~/Development/openelections-sources-ga/2025/export-2025PSCPrimaryRunoff.json \
  --inspect
```
If any `[UNMAPPED]` offices appear, add a matching pattern or entry in [`cleaning_rules.yaml`](cleaning_rules.yaml) (and add a regression case in `tests/test_cleaner.py`).

### Step 2: Generate Final OpenElections CSVs
Produce county-level CSV, precinct-level CSV, and reconciliation diagnostic CSV:
```bash
uv run python enhanced_voting_process/process_election.py \
  --input ~/Development/openelections-sources-ga/2025/export-2025PSCPrimaryRunoff.json \
  --outdir ./2025/
```

### Step 3: Load into DuckDB (Optional)
Insert the generated CSVs into tables (`<tbl_base>_county` and `<tbl_base>_precinct`) in a DuckDB database. If the database is locked by another tool (e.g., DataGrip or DBeaver), CSV export still succeeds and a warning is printed:
```bash
uv run python enhanced_voting_process/process_election.py \
  --input ~/Development/openelections-sources-ga/2025/export-2025PSCPrimaryRunoff.json \
  --outdir ./2025/ \
  --duckdb 2025/code/openelections_2025.duckdb
```

---

## 7. Agent-Assisted Workflow & Prompts

This repository includes two workspace skills under `.agents/skills/` (`process-ga-election` and `validate-ga-sos-results`) so an AI coding agent can run the full pipeline, cross-check the live Georgia SOS portal (`results.sos.ga.gov`), and draft clean commits.

### Example Prompts

- **Process, validate against GA SOS, and preview a commit plan:**
  > `Process ~/Development/openelections-sources-ga/2026/export-January20SpecialElection.json into 2026/ and validate them and if they look good please show me your plan for the commit.`

- **Validate already-generated CSVs against a specific GA SOS URL:**
  > `Validate 2025/20251104__ga__municipal__general__special__psc__county-level.csv and 2025/20251104__ga__municipal__general__special__psc__precinct-level.csv against https://results.sos.ga.gov/results/public/Georgia/elections/MunicipalGeneralSpecialElectionPSC11042025`

- **Update the commit plan after renaming files (or draft an upstream PR):**
  > `I've updated the csv file names, please show me an updated commit plan for this now`
  > `Draft a PR title and description to push from ATLJoeReed/openelections-data-ga to openelections/openelections-data-ga.`

### Standalone Local Validation Script

You can also run the bundled zero-dependency validator directly from your terminal (it auto-detects the matching `__precinct-level.csv` file):

```bash
python3 .agents/skills/validate-ga-sos-results/scripts/validate_csvs.py \
  --county 2026/20260120__ga__state__senate__18__special__county-level.csv
```

---

## 8. Testing & Linting

Run unit tests (`tests/test_cleaner.py`, `tests/test_process_election.py`) and PEP 8 linting from the repository root:

```bash
# Unit tests
uv run pytest -v

# Linting (79-char line limit)
uv run flake8 --exclude=enhanced_voting_process/archived enhanced_voting_process/ tests/
```

*(If invoking after moving the repo directory, run `uv sync` first or use `uv run python -m pytest -v` / `uv run python -m flake8 --exclude=enhanced_voting_process/archived enhanced_voting_process/ tests/`.)*

---

## 9. Directory & File Layout

```text
enhanced_voting_process/
├── __init__.py             # Package marker
├── process_election.py     # Main CLI entrypoint (ElectionProcessor)
├── cleaner.py              # Office classification & string normalization engine
├── reconciler.py           # County vs. Precinct diagnostic reconciliation QC
├── cleaning_rules.yaml     # Canonical offices, party map, regex rules & local exclusions
├── enhanced_json_model.py  # Pydantic schema validator for raw Enhanced Voting JSON
├── archived/               # Legacy notebooks and SQL processing scripts
└── README.md               # Pipeline documentation
```
