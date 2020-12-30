set search_path to dev;
show search_path;

-- drop table dev.ga_general_20121204;

create table dev.ga_general_20121204
    (
        county varchar(100),
        precinct varchar(100),
        input_office varchar(500),
        office varchar(100),
        district varchar(100),
        input_candidate varchar(500),
        candidate varchar(100),
        party varchar(50),
        total_votes varchar(50),
        vote_type varchar(50),
        votes varchar(50)
    );

-- truncate table dev.ga_general_20121204;

select *
from dev.ga_general_20121204
limit 5000;

select count(*) as cnt
from dev.ga_general_20121204;
-- 752

---------------------------------------------------------------
-- Check a couple of big races to make sure numbers match up...
---------------------------------------------------------------
select input_office, count(*) as cnt
from dev.ga_general_20121204
group by input_office
order by input_office;

select input_candidate, input_office, sum(votes::int) as votes
from dev.ga_general_20121204
where input_office ilike ('%State Senator%')
group by input_candidate, input_office
order by input_office, input_candidate;


-- Check if we have all counties...
select county, count(*) as cnt
from dev.ga_general_20121204
group by county
order by county;
-- 8

select *
from dev.ga_general_20121204
limit 5000;

select input_office, count(*) as cnt
from dev.ga_general_20121204
group by input_office
order by input_office;

/*
Possible Offices...
Appeals Court Judge
Attorney General
Commissioner of Agriculture
Commissioner of Insurance
Commissioner of Labor
District Attorney
Governor
Lieutenant Governor
President
Public Service Commissioner
Secretary of State
State House
State School Superintendent
State Senate
Superior Court Judge
Supreme Court Justice
U.S. House
U.S. Senate
Vice President


OFFICES:
- State Senator
*/
------------------------------------------------------------------------------------------------------------------------
-- Standardize State Offices...
------------------------------------------------------------------------------------------------------------------------
-- State Senate
select
    input_office,
    'State Senate' as office,
    trim((regexp_split_to_array(input_office, ' '))[4]) as district
from dev.ga_general_20121204
where input_office ilike '%State Senator%';

update dev.ga_general_20121204
    set office = 'State Senate',
        district = trim((regexp_split_to_array(input_office, ' '))[4])
where input_office ilike '%State Senator%';

-- Double check whats left...
select input_office, count(*) as cnt
from dev.ga_general_20121204
where office is null
group by input_office
order by input_office;

-- Clear out county level races...
delete
from dev.ga_general_20121204
where office is null;

select *
from dev.ga_general_20121204
limit 5000;

------------------------------------------------------------------------------------------------------------------------
-- Fix party information...
------------------------------------------------------------------------------------------------------------------------
select party, count(*) as cnt
from dev.ga_general_20121204
group by party
order by party;

update dev.ga_general_20121204
    set party = 'Republican';

select party, count(*) as cnt
from dev.ga_general_20121204
group by party
order by party;

select input_candidate, party, count(*) as cnt
from dev.ga_general_20121204
where office is not null
group by input_candidate, party
order by input_candidate, party;

update dev.ga_general_20121204
    set candidate = input_candidate;

select input_candidate, candidate, count(*) as cnt
from dev.ga_general_20121204
where office is not null
group by input_candidate, candidate
order by input_candidate, candidate;

-- Run a few QA queries...
-- drop table dev.qc;

select county, candidate, party, office, district, min(total_votes::int) as total_votes, sum(votes::int) as votes
into dev.qc
from dev.ga_general_20121204
where office is not null
group by county, candidate, party, office, district
order by county, candidate, office, district;

select *
from dev.qc
where total_votes <> votes;

-- drop table dev.qc;

select office, district, candidate, party, sum(votes::int) as votes
from dev.ga_general_20121204
where office is not null
group by office, district, candidate, party
order by office, district, votes desc;

select *
from dev.ga_general_20121204
where office is not null
limit 500;

select count(*) as cnt
from dev.ga_general_20121204
where office is not null;
-- 288

select 288/4 as number_output;
-- 72

update dev.ga_general_20121204
    set vote_type = trim(vote_type);

select vote_type, count(*) as cnt
from dev.ga_general_20121204
where office is not null
group by vote_type
order by vote_type;
-- vote_type	    cnt
-- Election Day	    72

select
    relname                                               as tablename,
    to_char(seq_scan, '999,999,999,999')                  as totalseqscan,
    to_char(idx_scan, '999,999,999,999')                  as totalindexscan,
    to_char(n_live_tup, '999,999,999,999')                as tablerows,
    pg_size_pretty(pg_relation_size(relname :: regclass)) as tablesize
from pg_stat_all_tables
where schemaname = 'dev'
--     and relname = 'ga_general_20121204'
--     and 50 * seq_scan > idx_scan -- more then 2%
--     and n_live_tup > 10000
order by relname asc;

-- drop index dev.ga_general_20121204_vote_type_idx;
create index ga_general_20121204_vote_type_office_idx
    on dev.ga_general_20121204(vote_type, office);

-- Let's create some materialized views w/indexes so the below final query runs fast...
create materialized view dev.vw_election_day_voting
as
select county, precinct, office, district, party, candidate, sum(votes::int) as election_day_votes
from dev.ga_general_20121204
where office is not null
    and vote_type = 'Election Day'
group by county, precinct, office, district, party, candidate;

create index vw_election_day_voting_idx
    on dev.vw_election_day_voting(county, precinct, office, district, party, candidate);

create materialized view vw_advace_voting
as
select county, precinct, office, district, party, candidate, sum(votes::int) as advanced_votes
from dev.ga_general_20121204
where office is not null
    and vote_type ilike 'Advance%'
group by county, precinct, office, district, party, candidate;

create index vw_advace_voting_idx
    on dev.vw_advace_voting(county, precinct, office, district, party, candidate);

create materialized view vw_absentee_voting
as
select county, precinct, office, district, party, candidate, sum(votes::int) as absentee_by_mail_votes
from dev.ga_general_20121204
where office is not null
    and vote_type ilike 'Absentee%'
group by county, precinct, office, district, party, candidate

create index vw_absentee_voting_idx
    on dev.vw_absentee_voting(county, precinct, office, district, party, candidate);

create materialized view vw_provisional_voting
as
select county, precinct, office, district, party, candidate, sum(votes::int) as provisional_votes
from dev.ga_general_20121204
where office is not null
    and vote_type = 'Provisional'
group by county, precinct, office, district, party, candidate

create index vw_provisional_voting_idx
    on dev.vw_provisional_voting(county, precinct, office, district, party, candidate);


-- drop table dev.results;

-- Output final csv data...
select a.*, b.advanced_votes, c.absentee_by_mail_votes, d.provisional_votes
into dev.results
from vw_election_day_voting as a
    inner join vw_advace_voting as b
        on a.county = b.county
            and a.precinct = b.precinct
            and a.office = b.office
            and coalesce(a.district, '') = coalesce(b.district, '')
            and coalesce(a.party, '') = coalesce(b.party, '')
            and a.candidate = b.candidate
    inner join vw_absentee_voting as c
        on a.county = c.county
            and a.precinct = c.precinct
            and a.office = c.office
            and coalesce(a.district, '') = coalesce(c.district, '')
            and coalesce(a.party, '') = coalesce(c.party, '')
            and a.candidate = c.candidate
    inner join vw_provisional_voting as d
        on a.county = d.county
            and a.precinct = d.precinct
            and a.office = d.office
            and coalesce(a.district, '') = coalesce(d.district, '')
            and coalesce(a.party, '') = coalesce(d.party, '')
            and a.candidate = d.candidate
order by candidate, county, precinct;

select count(*) as cnt
from dev.results;

select count(distinct county) as num_counties
from dev.results;

select county, precinct, office, district, party, candidate, election_day_votes, advanced_votes, absentee_by_mail_votes, provisional_votes
from dev.results;

select
    office,
    district,
    candidate,
    party,
    sum(election_day_votes::int + advanced_votes::int + absentee_by_mail_votes::int + provisional_votes::int) as total_votes,
    sum(election_day_votes::int) as election_day_votes,
    sum(advanced_votes::int) as advanced_votes,
    sum(absentee_by_mail_votes::int) as absentee_by_mail_votes,
    sum(provisional_votes::int) as provisional_votes
from dev.results
group by office, district, candidate, party
order by office, district, party;

select *
from dev.results
order by office, county, district, party;

-- Tear down the materialized views...
drop materialized view vw_absentee_voting;
drop materialized view vw_advace_voting;
drop materialized view vw_election_day_voting;
drop materialized view vw_provisional_voting;
