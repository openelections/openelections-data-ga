-- Postgres
-- host: localhost
-- database: openelections

set search_path to raw, stage, working;
show search_path;


-- drop table stage.ga_special_20210309;

create table stage.ga_special_20210309
(
    county varchar(100),
    precinct varchar(100),
    input_office varchar(100),
    office varchar(100),
    district varchar(100),
    input_candidate varchar(100),
    candidate varchar(100),
    party varchar(50),
    total_votes varchar(50),
    vote_type varchar(50),
    votes varchar(50)
);

-- truncate table stage.ga_special_20210309;

select *
from stage.ga_special_20210309
limit 5000;

select count(*) as cnt
from stage.ga_special_20210309;
-- 12

---------------------------------------------------------------
-- Check a couple of big races to make sure numbers match up...
---------------------------------------------------------------
select input_candidate, sum(votes::int) as votes
from stage.ga_special_20210309
group by input_candidate
order by input_candidate;

-- Check if we have all counties...
with unique_counties_laoded as
(
    select distinct county
    from stage.ga_special_20210309
)
select *
from stage.georgia_counties as a
    left join unique_counties_laoded as b
        on a.county = b.county
where b.county is null
order by a.county;

select party, count(*) as cnt
from stage.ga_special_20210309
group by party
order by party;

-- Clean-up the data...
update stage.ga_special_20210309
    set party = 'Republican'
where input_candidate ilike '% (Rep)';

update stage.ga_special_20210309
    set party = 'Democrat'
where input_candidate ilike '% (Dem)';

update stage.ga_special_20210309
    set party = 'Democrat'
where party = 'DEM';

select party, count(*) as cnt
from stage.ga_special_20210309
group by party
order by party;

select *
from stage.ga_special_20210309
where party = 'Democrat'
limit 5000;

-- Move input values over...
update stage.ga_special_20210309
    set candidate = trim(regexp_replace(input_candidate, '\s+', ' ', 'g'));

/*
RESET...
update stage.ga_special_20210309
    set candidate = null;

update stage.ga_special_20210309
    set office = null,
        district = null;
*/

select input_office, office, district, count(*) as cnt
from stage.ga_special_20210309
group by input_office, office, district
order by input_office;

------------------------------------------------------------------------------------------------------------------------
-- Standardize State Offices...
------------------------------------------------------------------------------------------------------------------------
update stage.ga_special_20210309
    set office = 'District Attorney'
where input_office = 'District Attorney - Special'
    and office is null;

update stage.ga_special_20210309
    set office = 'State House',
        district = '90'
where input_office = 'State House District 90 - Special'
    and office is null;

select office, district, input_office, count(*) as cnt
from stage.ga_special_20210309
where office is not null
group by office, district, input_office
order by office, district, input_office;

select input_office, count(*) as cnt
from stage.ga_special_20210309
where office is null
group by input_office
order by input_office;

------------------------------------------------------------------------------------------------------------------------
-- Fix candidate names...
------------------------------------------------------------------------------------------------------------------------
select input_candidate, candidate, party, count(*) as cnt
from stage.ga_special_20210309
where office is not null
group by input_candidate, candidate, party
order by input_candidate;

update stage.ga_special_20210309
    set candidate = replace(candidate, '(I) (Rep)', '')
where office is not null
    and candidate ilike '% (I) (Rep)';

update stage.ga_special_20210309
    set candidate = replace(candidate, ' (Dem)', '')
where office is not null
    and candidate like '% (Dem)';

select input_candidate, candidate, count(*) as cnt
from stage.ga_special_20210309
where office is not null
group by input_candidate, candidate
order by input_candidate;

-- Remove double spaces...
update stage.ga_special_20210309
    set candidate = trim(regexp_replace(candidate, '\s+', ' ', 'g'))
where office is not null;

-- Remove comma from candidate...
update stage.ga_special_20210309
    set candidate = replace(candidate, ',', '')
where office is not null
    and candidate like '%,%';

-- Run a few QA queries...

-- drop table qc;

create temp table qc
as
select county, candidate, party, min(total_votes::int) as total_votes, sum(votes::int) as votes
from stage.ga_special_20210309
where office is not null
group by county, candidate, party
order by county, candidate;

select *
from qc
where total_votes <> votes;

select *
from qc
order by county, candidate;

select office, district, candidate, party, sum(votes::int) as votes
from stage.ga_special_20210309
where office is not null
group by office, district, candidate, party
order by office, district, candidate;

select *
from stage.ga_special_20210309
where office is not null
limit 500;

select count(*) as cnt
from stage.ga_special_20210309
where office is not null;
-- 120

select 120/4 as number_output;
-- 30

-- drop table results;

-- Output final csv data...
create temporary table results
as
with election_day_votes as
(
    select county, precinct, office, district, party, candidate, votes as election_day_votes
    from stage.ga_special_20210309
    where office is not null
        and vote_type = 'Election Day Votes'
),
advanced_votes as
(
    select county, precinct, office, district, party, candidate, votes as advanced_votes
    from stage.ga_special_20210309
    where office is not null
        and vote_type = 'Advanced Voting Votes'
),
absentee_by_mail_votes as
(
    select county, precinct, office, district, party, candidate, votes as absentee_by_mail_votes
    from stage.ga_special_20210309
    where office is not null
        and vote_type = 'Absentee by Mail Votes'
),
provisional_votes as
(
    select county, precinct, office, district, party, candidate, votes as provisional_votes
    from stage.ga_special_20210309
    where office is not null
        and vote_type = 'Provisional Votes'
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
where a.office is not null
order by candidate, county, precinct;

select *
from results;

select county, count(*) as cnt
from results
group by county
order by county;

select *
from results
order by county, office, party, candidate;
