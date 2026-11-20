from pathlib import Path
import re
from typing import Optional
import yaml

DEFAULT_RULES_PATH = Path(__file__).parent / 'cleaning_rules.yaml'


class DataCleaner:
    def __init__(self, rules_path: Optional[Path] = None):
        self.rules_path = rules_path or DEFAULT_RULES_PATH
        self.rules = {}
        self.canonical_offices = set()
        self.parties = {}
        self.office_patterns = []
        self.office_overrides = {}
        self.candidate_strip_patterns = []
        self.county_strip_patterns = []
        self.excluded_local_patterns = []
        self.load_rules()

    def load_rules(self):
        if self.rules_path.exists():
            with open(self.rules_path, 'r', encoding='utf-8') as f:
                self.rules = yaml.safe_load(f) or {}
        else:
            self.rules = {}

        self.canonical_offices = set(self.rules.get('canonical_offices', []))
        self.parties = self.rules.get('parties', {})
        self.office_patterns = [
            {
                **item,
                'regex': re.compile(item['pattern']),
            }
            for item in self.rules.get('office_patterns', [])
            if item.get('pattern')
        ]
        self.office_overrides = self.rules.get('office_overrides', {})

        strip_cand = self.rules.get(
            'cleaning_patterns', {}
        ).get('strip_candidate_suffixes', [])
        self.candidate_strip_patterns = [re.compile(p) for p in strip_cand]

        strip_county = self.rules.get(
            'cleaning_patterns', {}
        ).get('strip_county_suffixes', [])
        self.county_strip_patterns = [re.compile(p) for p in strip_county]

        excluded_locals = self.rules.get('excluded_local_patterns', [])
        self.excluded_local_patterns = [re.compile(p) for p in excluded_locals]

    def clean_county(self, county: str) -> str:
        if not county:
            return ''
        name = county.strip()
        for pat in self.county_strip_patterns:
            name = pat.sub('', name).strip()
        # Collapse multiple internal whitespace into a single space
        name = re.sub(r'\s+', ' ', name).strip()
        return name

    def clean_candidate(self, candidate: str) -> str:
        if not candidate:
            return ''
        name = candidate.strip()
        changed = True
        while changed:
            changed = False
            for pat in self.candidate_strip_patterns:
                new_name = pat.sub('', name).strip()
                if new_name != name:
                    name = new_name
                    changed = True
        # Collapse multiple internal whitespace / spaces into a single space
        name = re.sub(r'\s+', ' ', name).strip()
        return name

    def clean_precinct(self, precinct: str) -> str:
        if not precinct:
            return ''
        # Collapse multiple internal whitespace / spaces into a single space
        return re.sub(r'\s+', ' ', precinct).strip()

    def clean_party(
        self,
        party: Optional[str],
        default: str = 'Nonpartisan'
    ) -> str:
        if not party:
            return default
        raw = party.strip()
        if raw in self.parties:
            return self.parties[raw]
        if raw.upper() in self.parties:
            return self.parties[raw.upper()]
        return raw

    def classify_office(
        self,
        raw_office: str
    ) -> tuple[str, Optional[str], Optional[str]]:
        """
        Classifies a raw office string into INCLUDED, EXCLUDED, or UNMAPPED.
        Returns: (status, canonical_office, district)
        """
        if not raw_office:
            return "UNMAPPED", None, None

        raw = raw_office.strip()

        # 1. Check exact overrides (Implicitly INCLUDED)
        if raw in self.office_overrides:
            override = self.office_overrides[raw]
            return (
                "INCLUDED",
                override.get('office', raw),
                str(override.get('district', ''))
            )

        # 2. Try Allow-list (Canonical Patterns)
        for item in self.office_patterns:
            match = item['regex'].search(raw)
            if match:
                canonical = item.get('canonical_office')
                district_group = item.get('district_group')
                district = ''
                if district_group is not None:
                    try:
                        extracted = match.group(district_group)
                        if extracted:
                            district = extracted.replace(
                                'District', ''
                            ).strip()
                    except IndexError:
                        district = ''
                return "INCLUDED", canonical, district

        # 3. Fallback: if already a known canonical office
        if raw in self.canonical_offices:
            return "INCLUDED", raw, ''

        # 4. Try Block-list (Excluded Patterns)
        for pat in self.excluded_local_patterns:
            if pat.search(raw):
                return "EXCLUDED", None, None

        # 5. Final Fallback to Unmapped
        return "UNMAPPED", None, None

    def extract_party_hint(self, raw_office: str) -> Optional[str]:
        """Extract an optional party hint from overrides or office text."""
        if not raw_office:
            return None
        raw = raw_office.strip()
        if raw in self.office_overrides:
            return self.office_overrides[raw].get('party')
        if re.search(r'\bDem(?:ocrat)?\b', raw, re.I):
            return 'Democrat'
        if re.search(r'\bRep(?:ublican)?\b', raw, re.I):
            return 'Republican'
        if re.search(r'\bLib(?:ertarian)?\b', raw, re.I):
            return 'Libertarian'
        return None

    def add_office_override(
        self,
        raw_office: str,
        canonical_office: str,
        district: str = '',
        party: Optional[str] = None
    ):
        self.office_overrides[raw_office] = {
            'office': canonical_office,
            'district': district,
            'party': party
        }
        self.rules['office_overrides'] = self.office_overrides
        with open(self.rules_path, 'w', encoding='utf-8') as f:
            yaml.dump(self.rules, f, sort_keys=False, default_flow_style=False)
