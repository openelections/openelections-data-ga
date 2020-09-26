-- drop table dev.ga_primary_20200609;

create table dev.ga_primary_20200609
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

-- truncate table dev.ga_primary_20200609;

select *
from dev.ga_primary_20200609
limit 5000;

select count(*) as cnt
from dev.ga_primary_20200609;
-- 990036

---------------------------------------------------------------
-- Check a couple of big races to make sure numbers match up...
---------------------------------------------------------------
select input_candidate, sum(votes::int) as votes
from dev.ga_primary_20200609
where input_office ilike ('%US%Senate%')
group by input_candidate
order by input_candidate;

select distinct input_office
from dev.ga_primary_20200609
where input_office like ('%President%');

-- Check if we have all counties...
with unique_counties_laoded as
(
    select distinct county
    from dev.ga_primary_20200609
)
select *
from dev.georgia_counties as a
    left join unique_counties_laoded as b
        on a.county = b.county
where b.county is null
order by a.county;

select party, count(*) as cnt
from dev.ga_primary_20200609
group by party
order by party;

-- Clean-up the data...
update dev.ga_primary_20200609
    set party = 'Republican'
where party = 'REP';

update dev.ga_primary_20200609
    set party = 'Democrat'
where party = 'DEM';

update dev.ga_primary_20200609
    set party = 'Nonpartisan'
where party = 'NP';

select party, count(*) as cnt
from dev.ga_primary_20200609
group by party
order by party;

select *
from dev.ga_primary_20200609
limit 5000;

select input_office, count(*) as cnt
from dev.ga_primary_20200609
group by input_office
order by input_office;

-- Move input values over...
update dev.ga_primary_20200609
    set candidate = trim(input_candidate);

/*
RESET...
update dev.ga_primary_20200609
    set candidate = null;
*/

------------------------------------------------------------------------------------------------------------------------
-- Standardize Federal Offices...
------------------------------------------------------------------------------------------------------------------------
-- President
update dev.ga_primary_20200609
    set office = 'President'
where input_office like '%President of the United States%';

-- U.S. Senate
update dev.ga_primary_20200609
    set office = 'U.S. Senate'
where input_office ilike '%US Senate%';

-- U.S. House
update dev.ga_primary_20200609
    set office = 'U.S. House',
        district = (regexp_split_to_array(input_office, ' '))[array_upper(regexp_split_to_array(input_office, ' '), 1)]
where input_office ilike '%US House%';

------------------------------------------------------------------------------------------------------------------------
-- Standardize State Offices...
------------------------------------------------------------------------------------------------------------------------
-- Public Service Commission
update dev.ga_primary_20200609
    set office = 'Public Service Commission',
        district = (regexp_split_to_array(input_office, ' '))[array_upper(regexp_split_to_array(input_office, ' '), 1)]
where input_office ilike '%Public Service Commission%';

-- State Senate
update dev.ga_primary_20200609
    set office = 'State Senate',
        district = (regexp_split_to_array(input_office, ' '))[array_upper(regexp_split_to_array(input_office, ' '), 1)]
where input_office ilike '%State Senate%';

-- State House
update dev.ga_primary_20200609
    set office = 'State House',
        district = (regexp_split_to_array(input_office, ' '))[array_upper(regexp_split_to_array(input_office, ' '), 1)]
where input_office ilike '%State House%';

-- District Attorney
update dev.ga_primary_20200609
    set office = 'District Attorney',
        district = trim((regexp_split_to_array(input_office, '-'))[array_upper(regexp_split_to_array(input_office, '-'), 1)])
where input_office ilike '%District Attorney%';

-- Supreme Court Justice
update dev.ga_primary_20200609
    set office = 'Supreme Court Justice',
        district = trim((regexp_split_to_array(input_office, '-'))[array_upper(regexp_split_to_array(input_office, '-'), 1)])
where input_office ilike '%Supreme Court%';

-- Appeals Court Judge
update dev.ga_primary_20200609
    set office = 'Appeals Court Judge',
        district = trim((regexp_split_to_array(input_office, '-'))[array_upper(regexp_split_to_array(input_office, '-'), 1)])
where input_office ilike '%Court of Appeals%';

-- Superior Court Judge
update dev.ga_primary_20200609
    set office = 'Superior Court Judge',
        district = trim((regexp_split_to_array(input_office, '-'))[2])
where input_office ilike 'Superior Court%';

select office, district, input_office, count(*) as cnt
from dev.ga_primary_20200609
where office is not null
group by office, district, input_office
order by office, district, input_office;

------------------------------------------------------------------------------------------------------------------------
-- Fix candidate names...
------------------------------------------------------------------------------------------------------------------------
-- Remove the Incumbent (I) from candidate
update dev.ga_primary_20200609
    set candidate = replace(candidate, ' (I)', '')
where office is not null
    and candidate like '% (I)';

-- Remove the double double quotes from "nick name"...
update dev.ga_primary_20200609
    set candidate = replace(candidate, '""', '''')
where office is not null
    and candidate like '%""%'
    and candidate not like '"%';

-- Remove the double quotes from "nick name"...
update dev.ga_primary_20200609
    set candidate = replace(candidate, '"', '''')
where office is not null
    and candidate like '%"%'
    and candidate not like '"%';

-- Fix one off name...
update dev.ga_primary_20200609
    set candidate = 'Mokah Jasmine Johnson'
where candidate = '""Mokah"" Jasmine Johnson';

-- Remove comma from candidate...
update dev.ga_primary_20200609
    set candidate = replace(candidate, ',', '')
where office is not null
    and candidate like '%,%';

-- Remove double spaces...
update dev.ga_primary_20200609
    set candidate = trim(regexp_replace(candidate, '\s+', ' ', 'g'))
where office is not null;

select candidate, input_candidate, count(*) as cnt
from dev.ga_primary_20200609
where office is not null
group by candidate, input_candidate
order by candidate, input_candidate;


-- Run a few QA queries...
select county, candidate, party, min(total_votes::int) as total_votes, sum(votes::int) as votes
from dev.ga_primary_20200609
where office is not null
group by county, candidate, party
order by county, candidate;


select office, candidate, party, sum(votes::int) as votes
from dev.ga_primary_20200609
where office in ('President')
group by office, candidate, party
order by office, candidate;


select office, district, candidate, party, sum(votes::int) as votes
from dev.ga_primary_20200609
where office is not null
group by office, district, candidate, party
order by office, district, candidate;

select *
from dev.ga_primary_20200609
where office is not null
limit 500;

select count(*) as cnt
from dev.ga_primary_20200609
where office is not null;
-- 563940

select 563940/4 as number_output
-- 140985

-- Output final csv data...
with election_day_votes as
(
    select county, precinct, office, district, party, candidate, votes as election_day_votes
    from dev.ga_primary_20200609
    where office is not null
        and vote_type = 'Election Day Votes'
),
advanced_votes as
(
    select county, precinct, office, district, party, candidate, votes as advanced_votes
    from dev.ga_primary_20200609
    where office is not null
        and vote_type = 'Advanced Voting Votes'
),
absentee_by_mail_votes as
(
    select county, precinct, office, district, party, candidate, votes as absentee_by_mail_votes
    from dev.ga_primary_20200609
    where office is not null
        and vote_type = 'Absentee by Mail Votes'
),
provisional_votes as
(
    select county, precinct, office, district, party, candidate, votes as provisional_votes
    from dev.ga_primary_20200609
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
where a.office <> 'President'
order by candidate, county, precinct;
