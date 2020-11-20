-- drop table dev.ga_general_20201103;

create table dev.ga_general_20201103
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

-- truncate table dev.ga_general_20201103;

select *
from dev.ga_general_20201103
limit 5000;

select count(*) as cnt
from dev.ga_general_20201103;
-- 581524

---------------------------------------------------------------
-- Check a couple of big races to make sure numbers match up...
---------------------------------------------------------------
select input_candidate, sum(votes::int) as votes
from dev.ga_general_20201103
where input_office ilike ('%President%States%')
group by input_candidate
order by input_candidate;

select distinct input_office
from dev.ga_general_20201103
where input_office like ('%President%');

-- Check if we have all counties...
with unique_counties_laoded as
(
    select distinct county
    from dev.ga_general_20201103
)
select *
from dev.georgia_counties as a
    left join unique_counties_laoded as b
        on a.county = b.county
where b.county is null
order by a.county;

select party, count(*) as cnt
from dev.ga_general_20201103
group by party
order by party;

-- Clean-up the data...
update dev.ga_general_20201103
    set party = 'Republican'
where party = 'REP';

update dev.ga_general_20201103
    set party = 'Republican'
where party = 'NP'
    and input_candidate ilike '% (Rep)';

update dev.ga_general_20201103
    set party = 'Democrat'
where party = 'DEM';

update dev.ga_general_20201103
    set party = 'Democrat'
where party = 'NP'
    and input_candidate ilike '% (Dem)';

update dev.ga_general_20201103
    set party = 'Independent'
where party = 'NP'
    and input_candidate ilike '% (Ind)';

update dev.ga_general_20201103
    set party = 'Libertarian'
where party = 'NP'
    and input_candidate ilike '% (Lib)';

update dev.ga_general_20201103
    set party = 'Green'
where party = 'NP'
    and input_candidate ilike '% (Grn)';

update dev.ga_general_20201103
    set party = 'Nonpartisan'
where party = 'NP';

select party, count(*) as cnt
from dev.ga_general_20201103
group by party
order by party;

select *
from dev.ga_general_20201103
where party = 'Democrat'
limit 5000;

-- Move input values over...
update dev.ga_general_20201103
    set candidate = trim(regexp_replace(input_candidate, '\s+', ' ', 'g'));

/*
RESET...
update dev.ga_general_20201103
    set candidate = null;

update dev.ga_general_20201103
    set office = null,
        district = null;
*/

select input_office, office, district, count(*) as cnt
from dev.ga_general_20201103
group by input_office, office, district
order by input_office;

------------------------------------------------------------------------------------------------------------------------
-- Standardize Federal Offices...
------------------------------------------------------------------------------------------------------------------------
-- President
update dev.ga_general_20201103
    set office = 'President'
where input_office like '%President of the United States%'
    and office is null;

-- U.S. Senate
update dev.ga_general_20201103
    set office = 'U.S. Senate (Special)'
where input_office ilike '%US Senate%Special%'
    and office is null;

-- U.S. Senate
update dev.ga_general_20201103
    set office = 'U.S. Senate'
where input_office ilike '%US Senate%'
    and office is null;

-- U.S. House
update dev.ga_general_20201103
    set office = 'U.S. House',
        district = (regexp_split_to_array(input_office, ' '))[array_upper(regexp_split_to_array(input_office, ' '), 1)]
where input_office ilike '%US House%'
    and office is null;

select input_office, office, district, count(*) as cnt
from dev.ga_general_20201103
where office is not null
group by input_office, office, district
order by input_office;

------------------------------------------------------------------------------------------------------------------------
-- Standardize State Offices...
------------------------------------------------------------------------------------------------------------------------
-- Public Service Commission
update dev.ga_general_20201103
    set office = 'Public Service Commission',
        district = (regexp_split_to_array(input_office, ' '))[array_upper(regexp_split_to_array(input_office, ' '), 1)]
where input_office ilike '%Public Service Commission%'
    and office is null;

-- State Senate
update dev.ga_general_20201103
    set office = 'State Senate',
        district = (regexp_split_to_array(input_office, ' '))[array_upper(regexp_split_to_array(input_office, ' '), 1)]
where input_office ilike '%State Senate%'
    and office is null;

-- State House
update dev.ga_general_20201103
    set office = 'State House',
        district = (regexp_split_to_array(input_office, ' '))[array_upper(regexp_split_to_array(input_office, ' '), 1)]
where input_office ilike '%State House%'
    and office is null;

-- District Attorney
update dev.ga_general_20201103
    set office = 'District Attorney',
        district = trim((regexp_split_to_array(input_office, '-'))[array_upper(regexp_split_to_array(input_office, '-'), 1)])
where input_office ilike '%District Attorney%'
    and office is null;

-- Supreme Court Justice
update dev.ga_general_20201103
    set office = 'Supreme Court Justice',
        district = trim((regexp_split_to_array(input_office, '-'))[array_upper(regexp_split_to_array(input_office, '-'), 1)])
where input_office ilike '%Supreme Court%'
    and office is null;

-- Appeals Court Judge
update dev.ga_general_20201103
    set office = 'Appeals Court Judge',
        district = trim((regexp_split_to_array(input_office, '-'))[array_upper(regexp_split_to_array(input_office, '-'), 1)])
where input_office ilike '%Court of Appeals%'
    and office is null;

-- Superior Court Judge
update dev.ga_general_20201103
    set office = 'Superior Court Judge',
        district = trim((regexp_split_to_array(input_office, '-'))[2])
where input_office ilike 'Superior Court%'
    and office is null;

-- Special fixes...
update dev.ga_general_20201103
    set office = 'State Senate',
        district = '39'
where input_office = 'State Senate District 39 - Special Democratic Primary';

update dev.ga_general_20201103
    set office = 'District Attorney',
        district = 'Western'
where input_office = 'District Attorney - Western - Special';

update dev.ga_general_20201103
    set office = 'District Attorney',
        district = 'Cobb'
where input_office = 'District Attorney - Cobb - Special';

update dev.ga_general_20201103
    set office = 'District Attorney',
        district = 'Douglas'
where input_office = 'District Attorney - Douglas - Special';

update dev.ga_general_20201103
    set office = 'District Attorney',
        district = 'Southwestern'
where input_office = 'District Attorney - Southwestern - Special';

update dev.ga_general_20201103
    set office = 'District Attorney',
        district = 'Clayton'
where input_office = 'District Attorney - Clayton - Special Election';


select office, district, input_office, count(*) as cnt
from dev.ga_general_20201103
where office is not null
group by office, district, input_office
order by office, district, input_office;

select input_office, count(*) as cnt
from dev.ga_general_20201103
where office is null
group by input_office
order by input_office;

------------------------------------------------------------------------------------------------------------------------
-- Fix candidate names...
------------------------------------------------------------------------------------------------------------------------
select input_candidate, candidate, count(*) as cnt
from dev.ga_general_20201103
where office is not null
group by input_candidate, candidate
order by input_candidate;

update dev.ga_general_20201103
    set candidate = replace(candidate, ' (Rep)', '')
where office is not null
    and candidate ilike '% (Rep)';

update dev.ga_general_20201103
    set candidate = replace(candidate, ' (Dem)', '')
where office is not null
    and candidate like '% (Dem)';

update dev.ga_general_20201103
    set candidate = replace(candidate, ' (Ind)', '')
where office is not null
    and candidate like '% (Ind)';

update dev.ga_general_20201103
    set candidate = replace(candidate, ' (Lib)', '')
where office is not null
    and candidate like '% (Lib)';

update dev.ga_general_20201103
    set candidate = replace(candidate, ' (Grn)', '')
where office is not null
    and candidate like '% (Grn)';

-- Remove the Incumbent (I) from candidate
update dev.ga_general_20201103
    set candidate = replace(candidate, ' (I)', '')
where office is not null
    and candidate like '% (I)';

-- Remove the double double quotes from "nick name"...
update dev.ga_general_20201103
    set candidate = replace(candidate, '""', '''')
where office is not null
    and candidate like '%""%'
    and candidate not like '"%';

-- Remove the double quotes from "nick name"...
update dev.ga_general_20201103
    set candidate = replace(candidate, '"', '''')
where office is not null
    and candidate like '%"%'
    and candidate not like '"%';


select input_candidate, candidate, count(*) as cnt
from dev.ga_general_20201103
where office is not null
group by input_candidate, candidate
order by input_candidate;

-- Fix one off name...
update dev.ga_general_20201103
    set candidate = 'Mokah Jasmine Johnson'
where candidate = '""Mokah"" Jasmine Johnson';

-- Remove comma from candidate...
update dev.ga_general_20201103
    set candidate = replace(candidate, ',', '')
where office is not null
    and candidate like '%,%';

-- Remove double spaces...
update dev.ga_general_20201103
    set candidate = trim(regexp_replace(candidate, '\s+', ' ', 'g'))
where office is not null;

select candidate, input_candidate, count(*) as cnt
from dev.ga_general_20201103
where office is not null
--     and party = 'Nonpartisan'
group by candidate, input_candidate
order by candidate, input_candidate;


-- Run a few QA queries...

-- drop table qc;

create temp table qc
as
select county, candidate, party, min(total_votes::int) as total_votes, sum(votes::int) as votes
from dev.ga_general_20201103
where office is not null
group by county, candidate, party
order by county, candidate;

select *
from qc
where total_votes <> votes;

select *
from qc
order by county, candidate;

select office, candidate, party, sum(votes::int) as votes
from dev.ga_general_20201103
where office in ('President')
group by office, candidate, party
order by office, candidate;


select office, district, candidate, party, sum(votes::int) as votes
from dev.ga_general_20201103
where office is not null
group by office, district, candidate, party
order by office, district, candidate;

select *
from dev.ga_general_20201103
where office is not null
limit 500;

select count(*) as cnt
from dev.ga_general_20201103
where office is not null;
-- 408108

select 408108/4 as number_output
-- 102027

-- Output final csv data...
with election_day_votes as
(
    select county, precinct, office, district, party, candidate, votes as election_day_votes
    from dev.ga_general_20201103
    where office is not null
        and vote_type = 'Election Day Votes'
),
advanced_votes as
(
    select county, precinct, office, district, party, candidate, votes as advanced_votes
    from dev.ga_general_20201103
    where office is not null
        and vote_type = 'Advanced Voting Votes'
),
absentee_by_mail_votes as
(
    select county, precinct, office, district, party, candidate, votes as absentee_by_mail_votes
    from dev.ga_general_20201103
    where office is not null
        and vote_type = 'Absentee by Mail Votes'
),
provisional_votes as
(
    select county, precinct, office, district, party, candidate, votes as provisional_votes
    from dev.ga_general_20201103
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
