import json
import os
from pathlib import Path
import re
from typing import Any, Dict, List, Optional

# Try loading .env if present
try:
    env_file = Path(__file__).parent / ".env"
    if env_file.exists():
        with open(env_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    val = v.strip().strip("'\"")
                    os.environ.setdefault(k.strip(), val)
except Exception:
    pass


class GeminiAssistant:
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.environ.get("GEMINI_API_KEY")
        self.client = None
        if self.api_key:
            try:
                from google import genai
                self.client = genai.Client(api_key=self.api_key)
            except Exception as e:
                print(f"[AI Assistant] GenAI init note: {e}")

    def is_available(self) -> bool:
        return bool(self.client and self.api_key)

    def suggest_office_mappings(
        self,
        unmapped_offices: List[str],
        canonical_offices: List[str]
    ) -> Dict[str, Dict[str, Any]]:
        """
        Uses Gemini to suggest canonical office and district mappings.
        """
        if not unmapped_offices:
            return {}

        if not self.is_available():
            print("[AI Assistant] GEMINI_API_KEY not set. Using heuristics.")
            return self._heuristic_office_mapping(
                unmapped_offices, canonical_offices
            )

        prompt = f"""
You are an expert on Georgia election results and the OpenElections format.
Standard OpenElections Georgia office names are:
{json.dumps(canonical_offices, indent=2)}

Please parse each raw office string into standard OpenElections format.
Raw Offices:
{json.dumps(unmapped_offices, indent=2)}

Respond ONLY with valid JSON in this exact structure:
{{
  "raw_office_string": {{
    "office": "<Canonical Office Name or original if local>",
    "district": "<District number e.g. 1, 21, or empty string>",
    "party": "<Democrat|Republican|Libertarian|Nonpartisan or null>"
  }}
}}
"""

        try:
            response = self.client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
                config={"response_mime_type": "application/json"}
            )
            data = json.loads(response.text)
            return data
        except Exception as e:
            print(f"[AI Assistant] Gemini call failed: {e}. Using heuristics.")
            return self._heuristic_office_mapping(
                unmapped_offices, canonical_offices
            )

    def _heuristic_office_mapping(
        self,
        unmapped_offices: List[str],
        canonical_offices: List[str]
    ) -> Dict[str, Dict[str, Any]]:
        """Rule-based fallback when no API key is provided"""
        results = {}
        for raw in unmapped_offices:
            office = raw
            district = ""
            party = None

            dist_match = re.search(r"District\s*(\d+)", raw, re.I)
            if dist_match:
                district = dist_match.group(1)

            if re.search(r"\bDem(?:ocrat)?\b", raw, re.I):
                party = "Democrat"
            elif re.search(r"\bRep(?:ublican)?\b", raw, re.I):
                party = "Republican"

            if "PSC" in raw or "Public Service" in raw:
                office = "Public Service Commissioner"
            elif "Senate" in raw:
                office = "State Senate"
            elif "House" in raw:
                office = "State House"

            results[raw] = {
                "office": office,
                "district": district,
                "party": party
            }
        return results

    def analyze_anomalies(
        self,
        reconciliation_data: List[Dict[str, Any]]
    ) -> str:
        """Generates an AI assessment of any election anomalies"""
        if not self.is_available():
            return "Gemini AI Assistant is not enabled (set GEMINI_API_KEY)."

        discrepancies = [
            r for r in reconciliation_data if r["status"] == "DISCREPANCY"
        ]
        if not discrepancies:
            return "Reconciliation: All county and precinct votes aligned."

        prompt = f"""
Review Georgia election reconciliation discrepancies.
Summarize reasons (unassigned early votes, withheld small precincts)
and flag items for manual review:

{json.dumps(discrepancies[:20], indent=2)}
"""
        try:
            response = self.client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt
            )
            return response.text
        except Exception as e:
            return f"AI analysis failed: {e}"
