from pathlib import Path
import re
from typing import Optional, Tuple
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
        self.office_patterns = self.rules.get('office_patterns', [])
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
        for pat in self.candidate_strip_patterns:
            name = pat.sub('', name).strip()
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

    def is_known_local_office(self, raw_office: str) -> bool:
        if not raw_office:
            return False
        for pat in self.excluded_local_patterns:
            if pat.search(raw_office):
                return True
        return False

    def clean_office_and_district(
        self,
        raw_office: str
    ) -> Tuple[str, str, Optional[str]]:
        """
        Returns (canonical_office, district, party_hint)
        """
        if not raw_office:
            return ('', '', None)

        raw = raw_office.strip()

        # 1. Check exact overrides
        if raw in self.office_overrides:
            override = self.office_overrides[raw]
            return (
                override.get('office', raw),
                str(override.get('district', '')),
                override.get('party')
            )

        # 2. Check regex patterns
        for item in self.office_patterns:
            pattern = item.get('pattern')
            match = re.search(pattern, raw)
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

                party_hint = None
                if re.search(r'\bDem(?:ocrat)?\b', raw, re.I):
                    party_hint = 'Democrat'
                elif re.search(r'\bRep(?:ublican)?\b', raw, re.I):
                    party_hint = 'Republican'
                elif re.search(r'\bLib(?:ertarian)?\b', raw, re.I):
                    party_hint = 'Libertarian'

                return (canonical, district, party_hint)

        # 3. Fallback: if already a known canonical office
        if raw in self.canonical_offices:
            return (raw, '', None)

        return (raw, '', None)

    def is_canonical_office(self, office: str) -> bool:
        return office in self.canonical_offices

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
