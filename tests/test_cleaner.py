import pytest
from enhanced_voting_process.cleaner import DataCleaner


@pytest.mark.parametrize(
    "input_office, expected_status, expected_canonical, expected_district",
    [
        # Allow-list (Canonical)
        ("State Senate - District 21", "INCLUDED", "State Senate", "21"),
        ("U.S. House - District 10", "INCLUDED", "U.S. House", "10"),
        (
            "PSC - District 2",
            "INCLUDED",
            "Public Service Commissioner",
            "2",
        ),
        ("Governor", "INCLUDED", "Governor", ""),

        # Block-list (Excluded)
        ("Mayor of Atlanta", "EXCLUDED", None, None),
        ("SPLOST Referendum", "EXCLUDED", None, None),
        ("City Council Member", "EXCLUDED", None, None),
        ("East Point Ward A at Large", "EXCLUDED", None, None),
        ("Bowdon Sunday Pouring Sales", "EXCLUDED", None, None),
        ("Brunch Bill - Troup County", "EXCLUDED", None, None),
        ("City of Decatur BOE Post 1", "EXCLUDED", None, None),
        ("County Commission Chairman", "EXCLUDED", None, None),
        ("Water Fluoridation Question", "EXCLUDED", None, None),
        ("Water Flouridation Question", "EXCLUDED", None, None),
        ("Commissioner - District 2- Jesup", "EXCLUDED", None, None),
        ("Probate Court Judge (Special)", "EXCLUDED", None, None),
        ("Probate/Magistrate Judge", "EXCLUDED", None, None),
        ("Special Augusta Commission District 4", "EXCLUDED", None, None),
        ("Waycross Commission - District 1", "EXCLUDED", None, None),

        # Unmapped (including regression cases for overly broad patterns)
        ("Something Totally Random 123", "UNMAPPED", None, None),
        ("Unknown Office Title", "UNMAPPED", None, None),
        ("Public Service Commission", "UNMAPPED", None, None),
        ("Bill of Rights Amendment", "UNMAPPED", None, None),
        ("Gazeboes Maintenance", "UNMAPPED", None, None),
    ],
)
def test_office_classification(
    input_office, expected_status, expected_canonical, expected_district
):
    cleaner = DataCleaner()
    status, canonical, district = cleaner.classify_office(input_office)
    assert status == expected_status
    assert canonical == expected_canonical
    assert district == expected_district


def test_office_override_preserves_party(tmp_path):
    rules_file = tmp_path / "rules.yaml"
    rules_file.write_text(
        "canonical_offices:\n"
        "  - 'State Senate'\n"
        "office_overrides:\n"
        "  'Special Senate Race':\n"
        "    office: 'State Senate'\n"
        "    district: '14'\n"
        "    party: 'Democrat'\n",
        encoding="utf-8",
    )
    cleaner = DataCleaner(rules_path=rules_file)

    assert cleaner.classify_office("Special Senate Race") == (
        "INCLUDED",
        "State Senate",
        "14",
    )
    assert cleaner.extract_party_hint("Special Senate Race") == "Democrat"


def test_extract_party_hint():
    cleaner = DataCleaner()
    assert cleaner.extract_party_hint("PSC - District 2 - Rep") == "Republican"
    assert cleaner.extract_party_hint("State House - Dem") == "Democrat"
    assert cleaner.extract_party_hint("Governor") is None


def test_basic_cleaners():
    cleaner = DataCleaner()
    assert cleaner.clean_county("Fulton  County") == "Fulton"
    assert cleaner.clean_candidate(
        "Jane   Doe (Rep) (Incumbent)"
    ) == "Jane Doe"
    assert cleaner.clean_precinct("Precinct   01A ") == "Precinct 01A"
    assert cleaner.clean_party("DEM") == "Democrat"
    assert cleaner.clean_party(None) == "Nonpartisan"
