import csv
import json
import pytest

from enhanced_voting_process.process_election import (
    ElectionProcessor,
    build_parser,
    extract_vote_groups,
)


def test_extract_vote_groups_normal():
    groups = [
        {"groupName": "Election Day", "voteCount": 100},
        {"groupName": "Advanced Voting", "voteCount": 50},
        {"groupName": "Absentee by Mail", "voteCount": 10},
        {"groupName": "Provisional", "voteCount": 2},
    ]
    assert extract_vote_groups(groups) == {
        "election_day_votes": 100,
        "advanced_votes": 50,
        "absentee_by_mail_votes": 10,
        "provisional_votes": 2,
    }


def test_extract_vote_groups_suppressed_returns_none():
    all_hidden = [
        {"groupName": "Election Day", "voteCount": None},
        {"groupName": "Advanced Voting", "voteCount": None},
        {"groupName": "Absentee by Mail", "voteCount": None},
        {"groupName": "Provisional", "voteCount": None},
    ]
    partial_hidden = [
        {"groupName": "Election Day", "voteCount": 100},
        {"groupName": "Advanced Voting", "voteCount": None},
        {"groupName": "Absentee by Mail", "voteCount": 5},
        {"groupName": "Provisional", "voteCount": 0},
    ]
    assert extract_vote_groups(all_hidden) is None
    assert extract_vote_groups(partial_hidden) is None
    assert extract_vote_groups([]) is None
    assert extract_vote_groups(None) is None


def test_suppressed_county_preserves_votes_with_blank_modalities(tmp_path):
    appling_groups = [
        {"groupName": "Election Day", "voteCount": 913},
        {"groupName": "Advanced Voting", "voteCount": 630},
        {"groupName": "Absentee by Mail", "voteCount": 10},
        {"groupName": "Provisional", "voteCount": 0},
    ]
    suppressed_groups = [
        {"groupName": "Election Day", "voteCount": None},
        {"groupName": "Advanced Voting", "voteCount": None},
        {"groupName": "Absentee by Mail", "voteCount": None},
        {"groupName": "Provisional", "voteCount": None},
    ]
    raw_export = {
        "electionName": "November 4, 2025 - Special PSC Election",
        "electionDate": "2025-11-04",
        "localResults": [
            {
                "name": "Appling",
                "ballotItems": [
                    {
                        "name": "PSC - District 2",
                        "ballotOptions": [
                            {
                                "name": "Tim Echols (I) (Rep)",
                                "voteCount": 1553,
                                "politicalParty": "Rep",
                                "groupResults": appling_groups,
                                "precinctResults": [
                                    {
                                        "id": "1B",
                                        "name": "1B",
                                        "voteCount": 1553,
                                        "reportingStatus": "Fully Reported",
                                        "groupResults": appling_groups,
                                    }
                                ],
                            }
                        ],
                    }
                ],
            },
            {
                "name": "Candler",
                "ballotItems": [
                    {
                        "name": "PSC - District 2",
                        "ballotOptions": [
                            {
                                "name": "Tim Echols (I) (Rep)",
                                "voteCount": 878,
                                "politicalParty": "Rep",
                                "groupResults": suppressed_groups,
                                "precinctResults": [
                                    {
                                        "id": "1",
                                        "name": "Jack Strickland Center",
                                        "voteCount": 878,
                                        "reportingStatus": "Fully Reported",
                                        "groupResults": suppressed_groups,
                                    }
                                ],
                            }
                        ],
                    }
                ],
            },
        ],
    }

    input_json = tmp_path / "export.json"
    input_json.write_text(json.dumps(raw_export), encoding="utf-8")

    processor = ElectionProcessor()
    result = processor.process_file(input_path=input_json, outdir=tmp_path)

    with open(result["county_file"], newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        assert reader.fieldnames == [
            "county",
            "precinct",
            "office",
            "district",
            "party",
            "candidate",
            "votes",
            "election_day_votes",
            "advanced_votes",
            "absentee_by_mail_votes",
            "provisional_votes",
        ]
        rows = {r["county"]: r for r in reader}

    assert rows["Appling"]["votes"] == "1553"
    assert rows["Appling"]["election_day_votes"] == "913"
    assert rows["Appling"]["advanced_votes"] == "630"
    assert rows["Appling"]["absentee_by_mail_votes"] == "10"
    assert rows["Appling"]["provisional_votes"] == "0"

    assert rows["Candler"]["votes"] == "878"
    assert rows["Candler"]["election_day_votes"] == ""
    assert rows["Candler"]["advanced_votes"] == ""
    assert rows["Candler"]["absentee_by_mail_votes"] == ""
    assert rows["Candler"]["provisional_votes"] == ""


def test_missing_political_party_inferred_across_counties(tmp_path):
    raw_export = {
        "electionName": "November 18, 2025 - State Senate 35 Special Election",
        "electionDate": "2025-11-18",
        "localResults": [
            {
                "name": "Cobb",
                "ballotItems": [
                    {
                        "name": "State Senate - District 35",
                        "ballotOptions": [
                            {
                                "name": "Jaha V. Howard",
                                "voteCount": 3343,
                                "politicalParty": "Dem",
                                "groupResults": None,
                                "precinctResults": None,
                            },
                            {
                                "name": "Josh Tolbert",
                                "voteCount": 2622,
                                "politicalParty": "Rep",
                                "groupResults": None,
                                "precinctResults": None,
                            },
                        ],
                    }
                ],
            },
            {
                "name": "Fulton",
                "ballotItems": [
                    {
                        "name": "State Senate - District 35",
                        "ballotOptions": [
                            {
                                "name": "Jaha V. Howard",
                                "voteCount": 1792,
                                "politicalParty": None,
                                "groupResults": None,
                                "precinctResults": None,
                            },
                            {
                                "name": "Josh Tolbert (Rep)",
                                "voteCount": 500,
                                "politicalParty": None,
                                "groupResults": None,
                                "precinctResults": None,
                            },
                            {
                                "name": "Corenza Morris (Ind)",
                                "voteCount": 100,
                                "politicalParty": None,
                                "groupResults": None,
                                "precinctResults": None,
                            },
                        ],
                    }
                ],
            },
        ],
    }

    input_json = tmp_path / "sd35.json"
    input_json.write_text(json.dumps(raw_export), encoding="utf-8")

    result = ElectionProcessor().process_file(
        input_path=input_json, outdir=tmp_path
    )
    with open(result["county_file"], newline="", encoding="utf-8") as f:
        rows = {(r["county"], r["candidate"]): r for r in csv.DictReader(f)}

    assert len(rows) == 5
    assert rows[("Cobb", "Jaha V. Howard")]["party"] == "Democrat"
    assert rows[("Fulton", "Jaha V. Howard")]["party"] == "Democrat"
    assert rows[("Fulton", "Jaha V. Howard")]["votes"] == "1792"
    assert rows[("Fulton", "Josh Tolbert")]["party"] == "Republican"
    assert rows[("Fulton", "Corenza Morris")]["party"] == "Independent"


def test_nonpartisan_judicial_race_is_preserved(tmp_path):
    raw_export = {
        "electionName": "May 21, 2024 - General Primary Election",
        "electionDate": "2024-05-21",
        "localResults": [
            {
                "name": "Fulton",
                "ballotItems": [
                    {
                        "name": "Supreme Court Justice - Seat 1",
                        "ballotOptions": [
                            {
                                "name": "Andrew Pinson (I)",
                                "voteCount": 1000,
                                "politicalParty": None,
                                "groupResults": None,
                                "precinctResults": None,
                            },
                            {
                                "name": "John Barrow",
                                "voteCount": 900,
                                "politicalParty": None,
                                "groupResults": None,
                                "precinctResults": None,
                            },
                        ],
                    }
                ],
            }
        ],
    }

    input_json = tmp_path / "judicial.json"
    input_json.write_text(json.dumps(raw_export), encoding="utf-8")

    result = ElectionProcessor().process_file(
        input_path=input_json, outdir=tmp_path
    )
    with open(result["county_file"], newline="", encoding="utf-8") as f:
        rows = {r["candidate"]: r for r in csv.DictReader(f)}

    assert len(rows) == 2
    assert rows["Andrew Pinson"]["party"] == "Nonpartisan"
    assert rows["Andrew Pinson"]["votes"] == "1000"
    assert rows["John Barrow"]["party"] == "Nonpartisan"
    assert rows["John Barrow"]["votes"] == "900"


def test_cli_parser_has_no_ai_flags():
    parser = build_parser()
    args = parser.parse_args(["--input", "export.json", "--inspect"])
    assert str(args.input) == "export.json"
    assert args.inspect is True
    assert args.all_offices is False

    for removed_flag in ("--ai", "--save-ai-rules", "--api-key"):
        with pytest.raises(SystemExit):
            parser.parse_args(["--input", "export.json", removed_flag])


def test_unmapped_office_reported_and_excluded_in_inspect(tmp_path, capsys):
    raw_export = {
        "electionName": "November 4, 2025 - Special Election",
        "electionDate": "2025-11-04",
        "localResults": [
            {
                "name": "Fulton",
                "ballotItems": [
                    {
                        "name": "Mystery Special Board Seat",
                        "ballotOptions": [
                            {
                                "name": "Jane Doe",
                                "voteCount": 42,
                                "politicalParty": None,
                                "groupResults": None,
                                "precinctResults": None,
                            }
                        ],
                    }
                ],
            }
        ],
    }
    input_json = tmp_path / "unmapped.json"
    input_json.write_text(json.dumps(raw_export), encoding="utf-8")

    result = ElectionProcessor().process_file(
        input_path=input_json, inspect_mode=True
    )
    output = capsys.readouterr().out
    assert result["county_rows"] == []
    assert "[UNMAPPED]" in output
    assert "Mystery Special Board Seat" in output
    assert "cleaning_rules.yaml" in output
