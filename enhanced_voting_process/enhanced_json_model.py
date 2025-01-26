from typing import List, Optional

from pydantic import BaseModel, Field


class GroupResult(BaseModel):
    vote_type: str = Field(alias='groupName')
    votes: Optional[int] | None = Field(None, alias='voteCount')


class PrecinctResult(BaseModel):
    precinct_id: str = Field(alias='id')
    precinct_name: str = Field(alias='name')
    total_votes: int = Field(alias='voteCount')
    reporting_status: str = Field(alias='reportingStatus')
    precinct_votes: List[GroupResult] = Field(alias='groupResults')


class BallotOption(BaseModel):
    candidate: str = Field(alias='name')
    total_votes: int = Field(alias='voteCount')
    party: str = Field(alias='politicalParty')
    county_votes: List[GroupResult] = Field(alias='groupResults')
    precinct_results: Optional[List[PrecinctResult]] = Field(alias='precinctResults') # noqa


class BallotItem(BaseModel):
    office: str = Field(alias='name')
    ballot_options: List[BallotOption] = Field(alias='ballotOptions')


class LocalResult(BaseModel):
    county: str = Field(alias='name')
    ballot_items: List[BallotItem] = Field(alias='ballotItems')


class ElectionResults(BaseModel):
    election_name: str = Field(alias='electionName')
    election_date: str = Field(alias='electionDate')
    local_results: List[LocalResult] = Field(alias='localResults')
