-- drop table dev.ga_general_runoff_20120821;

create table dev.ga_general_runoff_20120821
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

-- truncate table dev.ga_general_runoff_20120821;

select *
from dev.ga_general_runoff_20120821
limit 5000;

select count(*) as cnt
from dev.ga_general_runoff_20120821;
-- 29282

---------------------------------------------------------------
-- Check a couple of big races to make sure numbers match up...
---------------------------------------------------------------
select input_office, count(*) as cnt
from dev.ga_general_runoff_20120821
group by input_office
order by input_office;

select input_candidate, sum(votes::int) as votes
from dev.ga_general_runoff_20120821
-- where input_office ilike ('%US%House%')
group by input_candidate
order by input_candidate;


-- Check if we have all counties...
select county, count(*) as cnt
from dev.ga_general_runoff_20120821
group by county
order by county;
-- 124

with unique_counties_laoded as
(
    select distinct county
    from dev.ga_general_runoff_20120821
)
select *
from dev.georgia_counties as a
    left join unique_counties_laoded as b
        on a.county = b.county
where b.county is null
order by a.county;

select party, count(*) as cnt
from dev.ga_general_runoff_20120821
group by party
order by party;

-- Clean-up the data...
update dev.ga_general_runoff_20120821
    set party = 'Republican'
where party = 'REP';

update dev.ga_general_runoff_20120821
    set party = 'Democrat'
where party = 'DEM';

update dev.ga_general_runoff_20120821
    set party = 'Nonpartisan'
where party = 'NP';

select party, count(*) as cnt
from dev.ga_general_runoff_20120821
group by party
order by party;

select *
from dev.ga_general_runoff_20120821
limit 5000;

select input_office, count(*) as cnt
from dev.ga_general_runoff_20120821
group by input_office
order by input_office;

/*
OFFICES:
- District Attorney
- State Representative --> State House
- State Senator
- Superior Court Judge
- U.S. Representative --> U.S. House

*/
------------------------------------------------------------------------------------------------------------------------
-- Standardize Federal Offices...
------------------------------------------------------------------------------------------------------------------------
-- U.S. House
select
    input_office,
    'U.S. House' as office,
    trim((regexp_split_to_array(input_office, ' '))[4]) as district
from dev.ga_general_runoff_20120821
where input_office ilike '%U.S. Representative%';

update dev.ga_general_runoff_20120821
    set office = 'U.S. House',
        district = trim((regexp_split_to_array(input_office, ' '))[4])
where input_office ilike '%U.S. Representative%';

------------------------------------------------------------------------------------------------------------------------
-- Standardize State Offices...
------------------------------------------------------------------------------------------------------------------------
-- State Senate
select
    input_office,
    'State Senate' as office,
    trim((regexp_split_to_array(input_office, ' '))[4]) as district
from dev.ga_general_runoff_20120821
where input_office ilike '%State Senator%';

update dev.ga_general_runoff_20120821
    set office = 'State Senate',
        district = trim((regexp_split_to_array(input_office, ' '))[4])
where input_office ilike '%State Senator%';

-- State House
select
    input_office,
    'State House' as office,
    trim((regexp_split_to_array(input_office, ' '))[4]) as district
from dev.ga_general_runoff_20120821
where input_office ilike '%State Representative%';

update dev.ga_general_runoff_20120821
    set office = 'State House',
        district = trim((regexp_split_to_array(input_office, ' '))[4])
where input_office ilike '%State Representative%';

-- District Attorney
select
    input_office,
    'District Attorney' as office,
    trim((regexp_split_to_array(input_office, ','))[2]) as district
from dev.ga_general_runoff_20120821
where input_office ilike '%District Attorney%';

update dev.ga_general_runoff_20120821
    set office = 'District Attorney',
        district = trim((regexp_split_to_array(input_office, ','))[2])
where input_office ilike '%District Attorney%';

update dev.ga_general_runoff_20120821
    set district = replace(district, ' - DEM', '')
where input_office ilike '%District Attorney%';

update dev.ga_general_runoff_20120821
    set district = replace(district, ' - REP', '')
where input_office ilike '%District Attorney%';

select *
from dev.ga_general_runoff_20120821
where input_office ilike '%District Attorney%';

-- Superior Court Judge
select
    candidate,
    input_office,
    'Superior Court Judge' as office,
    trim((regexp_split_to_array(input_office, ','))[2]) as district
from dev.ga_general_runoff_20120821
where input_office ilike 'Superior Court Judge%';

update dev.ga_general_runoff_20120821
    set office = 'Superior Court Judge',
        district = trim((regexp_split_to_array(input_office, ','))[2])
where input_office ilike 'Superior Court Judge%';

select
    candidate,
    input_office,
    'Superior Court Judge' as office,
    trim((regexp_split_to_array(district, '\('))[1]) as new_district
from dev.ga_general_runoff_20120821
where input_office ilike 'Superior Court Judge%';

update dev.ga_general_runoff_20120821
    set district = trim((regexp_split_to_array(district, '\('))[1])
where input_office ilike 'Superior Court Judge%';

select
    candidate,
    input_office,
    office,
    district
from dev.ga_general_runoff_20120821
where input_office ilike 'Superior Court Judge%';

select office, district, input_office, count(*) as cnt
from dev.ga_general_runoff_20120821
where office is not null
group by office, district, input_office
order by office, district, input_office;

-- Double check whats left...
select input_office, count(*) as cnt
from dev.ga_general_runoff_20120821
where office is null
group by input_office
order by input_office;

select *
from dev.ga_general_runoff_20120821
where input_office = 'US House 12';

select *
from dev.ga_general_runoff_20120821
where input_office = 'State House 158';

select *
from dev.ga_general_runoff_20120821
where input_office = 'State Senate 23';



------------------------------------------------------------------------------------------------------------------------
-- Fix candidate names...
------------------------------------------------------------------------------------------------------------------------
-- Move input values over...
update dev.ga_general_runoff_20120821
    set candidate = trim(input_candidate);

/*
RESET...
update dev.ga_general_runoff_20120821
    set candidate = null;
*/

select candidate, count(*) as cnt
from dev.ga_general_runoff_20120821
where office is not null
group by candidate
order by candidate;

-- Remove the Incumbent (I) from candidate
update dev.ga_general_runoff_20120821
    set candidate = replace(candidate, ' (I)', '')
where office is not null
    and candidate like '% (I)';

-- Remove the double double quotes from "nick name"...
update dev.ga_general_runoff_20120821
    set candidate = replace(candidate, '""', '''')
where office is not null
    and candidate like '%""%'
    and candidate not like '"%';

-- Remove the double quotes from "nick name"...
update dev.ga_general_runoff_20120821
    set candidate = replace(candidate, '"', '''')
where office is not null
    and candidate like '%"%'
    and candidate not like '"%';

-- Remove the Incumbent (I from candidate
update dev.ga_general_runoff_20120821
    set candidate = replace(candidate, ' (I', '')
where office is not null
    and candidate like '% (I';

-- Remove the Incumbent (I from candidate
update dev.ga_general_runoff_20120821
    set candidate = replace(candidate, '(I)', '')
where office is not null
    and candidate like '%(I)';

select candidate, count(*) as cnt
from dev.ga_general_runoff_20120821
where office is not null
group by candidate
order by candidate;

select *
from dev.ga_general_runoff_20120821
where office is not null
    and candidate like '%,%';

-- Remove comma from candidate...
update dev.ga_general_runoff_20120821
    set candidate = replace(candidate, ',', '')
where office is not null
    and candidate like '%,%';

-- Remove double spaces...
update dev.ga_general_runoff_20120821
    set candidate = trim(regexp_replace(candidate, '\s+', ' ', 'g'))
where office is not null;

select candidate, input_candidate, count(*) as cnt
from dev.ga_general_runoff_20120821
where office is not null
group by candidate, input_candidate
order by candidate, input_candidate;

-- Manually Fix a some candidates...
update dev.ga_general_runoff_20120821
    set candidate = 'T.J. COPELAND'
where candidate = 'T. J. COPELAND';

-- Run a few QA queries...
-- drop table dev.qc;

select county, candidate, party, office, district, min(total_votes::int) as total_votes, sum(votes::int) as votes
from dev.ga_general_runoff_20120821
where office is not null
group by county, candidate, party, office, district
order by county, candidate, office, district;


select office, district, candidate, party, sum(votes::int) as votes
from dev.ga_general_runoff_20120821
where office is not null
group by office, district, candidate, party
order by office, district, votes desc;

select *
from dev.ga_general_runoff_20120821
where office is not null
limit 500;

select count(*) as cnt
from dev.ga_general_runoff_20120821
where office is not null;
-- 9698

select 9698/4 as number_output
-- 2424

select vote_type, count(*) as cnt
from dev.ga_general_runoff_20120821
where office is not null
group by vote_type
order by vote_type;
-- 2400

-- drop table dev.results;

-- Output final csv data...
with election_day_votes as
(
    select county, precinct, office, district, party, candidate, sum(votes::int) as election_day_votes
    -- select count(distinct concat(county, precinct, office, district, party, candidate)) as cnt
    from dev.ga_general_runoff_20120821
    where office is not null
        and vote_type = 'Election Day'
    group by county, precinct, office, district, party, candidate
),
advanced_votes as
(
    select county, precinct, office, district, party, candidate, sum(votes::int) as advanced_votes
    -- select count(distinct concat(county, precinct, office, district, party, candidate)) as cnt
    from dev.ga_general_runoff_20120821
    where office is not null
--         and vote_type in ('Advance in Person', 'Advance in Person 1')
        and vote_type ilike 'Advance%'
    group by county, precinct, office, district, party, candidate
),
absentee_by_mail_votes as
(
    select county, precinct, office, district, party, candidate, sum(votes::int) as absentee_by_mail_votes
    -- select count(distinct concat(county, precinct, office, district, party, candidate)) as cnt
    from dev.ga_general_runoff_20120821
    where office is not null
        and vote_type ilike 'Absentee%'
    group by county, precinct, office, district, party, candidate
),
provisional_votes as
(
    select county, precinct, office, district, party, candidate, sum(votes::int) as provisional_votes
    -- select count(distinct concat(county, precinct, office, district, party, candidate)) as cnt
    from dev.ga_general_runoff_20120821
    where office is not null
        and vote_type = 'Provisional'
    group by county, precinct, office, district, party, candidate
)
select a.*, b.advanced_votes, c.absentee_by_mail_votes, d.provisional_votes
into dev.results
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
order by office, district, candidate;

-- Fix a few names...
update dev.results
    set candidate = 'RICK ALLEN'
where candidate = 'RICK W. ALLEN'
    and office = 'U.S. House'
    and district = '12';

update dev.results
    set candidate = 'GAIL DAVENPORT'
where candidate = 'GAIL P. DAVENPORT'
    and office = 'State Senate'
    and district = '44';

update dev.results
    set candidate = 'LADAWN B. JONES'
where candidate = 'LADAWN ''LBJ'' B. JONE'
    and office = 'State House'
    and district = '62';

update dev.results
    set candidate = ''
where candidate = ''
    and office = ''
    and district = '';

update dev.results
    set candidate = ''
where candidate = ''
    and office = ''
    and district = '';


select *
from dev.results
order by county, precinct, office, district, candidate;
