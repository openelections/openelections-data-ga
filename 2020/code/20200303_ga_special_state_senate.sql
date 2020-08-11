create table dev.ga_special_state_senate_20200303
  (
    county varchar(100),
    precinct varchar(100),
    office varchar(100),
    district varchar(50),
    candidate varchar(100),
    party varchar(50),
    total_votes varchar(50),
    vote_type varchar(50),
    votes varchar(50)
  );

-- truncate table dev.ga_special_state_senate_20200303;

select *
from dev.ga_special_state_senate_20200303;

-- Clean-up the data...
update dev.ga_special_state_senate_20200303
    set district = '13',
        office = 'State Senate';

update dev.ga_special_state_senate_20200303
    set party = 'Republican'
where party = 'REP';

update dev.ga_special_state_senate_20200303
    set party = 'Democrat'
where party = 'DEM';

-- Run a few QA queries...
select county, candidate, party, min(total_votes::int) as total_votes, sum(votes::int) as votes
from dev.ga_special_state_senate_20200303
group by county, candidate, party
order by county, candidate;

select candidate, party, sum(votes::int) as votes
from dev.ga_special_state_senate_20200303
group by candidate, party;

-- Output final csv data...
with election_day_votes as
(
    select county, precinct, office, district, party, candidate, votes as election_day_votes
    from dev.ga_special_state_senate_20200303
    where vote_type = 'Election Day Votes'
),
advanced_votes as
(
    select county, precinct, office, district, party, candidate, votes as advanced_votes
    from dev.ga_special_state_senate_20200303
    where vote_type = 'Advanced Voting Votes'
),
absentee_by_mail_votes as
(
    select county, precinct, office, district, party, candidate, votes as absentee_by_mail_votes
    from dev.ga_special_state_senate_20200303
    where vote_type = 'Absentee by Mail Votes'
),
provisional_votes as
(
    select county, precinct, office, district, party, candidate, votes as provisional_votes
    from dev.ga_special_state_senate_20200303
    where vote_type = 'Provisional Votes'
)
select a.*, b.advanced_votes, c.absentee_by_mail_votes, d.provisional_votes
from election_day_votes as a
    inner join advanced_votes as b
        on a.county = b.county
            and a.precinct = b.precinct
            and a.office = b.office
            and coalesce(a.district, '') = coalesce(b.district, '')
            and coalesce(a.party, '') = coalesce(b.party, '')
            and a.candidate = b.candidate
    inner join absentee_by_mail_votes as c
        on a.county = c.county
            and a.precinct = c.precinct
            and a.office = c.office
            and coalesce(a.district, '') = coalesce(c.district, '')
            and coalesce(a.party, '') = coalesce(c.party, '')
            and a.candidate = c.candidate
    inner join provisional_votes as d
        on a.county = d.county
            and a.precinct = d.precinct
            and a.office = d.office
            and coalesce(a.district, '') = coalesce(d.district, '')
            and coalesce(a.party, '') = coalesce(d.party, '')
            and a.candidate = d.candidate
order by candidate, county, precinct;



