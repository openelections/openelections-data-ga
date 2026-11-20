import csv
import json

from enhanced_voting_process.process_election import (
    ElectionProcessor,
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
