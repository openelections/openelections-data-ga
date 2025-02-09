-----------------------------------------------------------------------------------------------
-- Before this process I am downloading the JSON file from GA elections and running it through
-- the enhanced_voting_process/load_json.ipynb Jupyter Notebook...
-- As I work through this process a couple of times I will create some documentation around it.
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Load JSON data...
-----------------------------------------------------------------------------------------------
create or replace table raw.nov2024_general_election_precinct
as
select *
from read_json('/home/skunkworks/development/openelections-data-ga/enhanced_voting_process/precinct_level_data.json');

select *
from raw.nov2024_general_election_precinct;

-- Checking on some of the county|precinct|candidates with 0 total votes...
select *
from raw.nov2024_general_election_precinct
where coalesce(total_votes, 0) = 0;

-----------------------------------------------------------------------------------------------
-- Copy to STAGE, begin the cleanup and QC...
-----------------------------------------------------------------------------------------------
create or replace table stage.nov2024_general_election_precinct
as
select *
from raw.nov2024_general_election_precinct;

alter table stage.nov2024_general_election_precinct
    add column district varchar;

select *
from stage.nov2024_general_election_precinct;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup OFFICE...
------------------------------------------------------------------------------------------------------------------------
select
    office,
    count(distinct county) as num_counties,
    count(distinct candidate) as num_candidates
from stage.nov2024_general_election_precinct
group by office
order by office;

-- STEP #1 - need to find the offices we are going to pull out. We are only looking at Federal
--           and State offices right now. See the readme file in github for a list of them.
--           I typically take the above output and put it in a Google sheet and review them there.

select distinct office
from stage.nov2024_general_election_precinct
where office ilike '%General%'
order by office;

select *
from stage.nov2024_general_election_precinct
where office ilike '%Clerk%Superior%'
    and county = 'Fulton County';

alter table stage.nov2024_general_election_precinct
    add column original_office varchar;

update stage.nov2024_general_election_precinct
    set original_office = office;

select *
from stage.nov2024_general_election_precinct;

select distinct
    office,
    trim(split(office, ' - ')[1]) as new_office,
    trim(split(office, ' - ')[2]) as district
from stage.nov2024_general_election_precinct
where office ilike '%District%Attorney%'
order by office;

update stage.nov2024_general_election_precinct
    set office = trim(split(office, ' - ')[1]),
        district = trim(split(office, ' - ')[2])
where office ilike '%District%Attorney%';

select *
-- select distinct district
from stage.nov2024_general_election_precinct
where office = 'District Attorney';

update stage.nov2024_general_election_precinct
    set office = 'President'
where office = 'President of the US';

select *
from stage.nov2024_general_election_precinct
where office ilike 'State%House%Representatives%';

select distinct
    office,
    trim(split(office, ' - ')[1]) as new_office,
    trim(replace(split(office, ' - ')[2], 'District', '')) as district
from stage.nov2024_general_election_precinct
where office ilike 'State%House%Representatives%'
order by office;

update stage.nov2024_general_election_precinct
    set office = 'State House',
        district = trim(replace(split(office, ' - ')[2], 'District', ''))
where office ilike 'State%House%Representatives%';


select *
-- select count(distinct district)
from stage.nov2024_general_election_precinct
where office = 'State House';

-- State Senate...
select *
from stage.nov2024_general_election_precinct
where office ilike 'State%Senate%';

select distinct
    office,
    trim(split(office, ' - ')[1]) as new_office,
    trim(replace(split(office, ' - ')[2], 'District', '')) as district
from stage.nov2024_general_election_precinct
where office ilike 'State%Senate%'
order by office;

update stage.nov2024_general_election_precinct
    set office = 'State Senate',
        district = trim(replace(split(office, ' - ')[2], 'District', ''))
where office ilike 'State%Senate%';

select *
-- select count(distinct district)
from stage.nov2024_general_election_precinct
where office = 'State Senate';

-- US House...
select *
from stage.nov2024_general_election_precinct
where office ilike 'US%House%Representative%';

select distinct
    office,
    trim(split(office, ' - ')[1]) as new_office,
    trim(replace(split(office, ' - ')[2], 'District', '')) as district
from stage.nov2024_general_election_precinct
where office ilike 'US%House%Representative%'
order by office;

update stage.nov2024_general_election_precinct
    set office = 'U.S. House',
        district = trim(replace(split(office, ' - ')[2], 'District', ''))
where office ilike 'US%House%Representative%';

select *
-- select count(distinct district)
from stage.nov2024_general_election_precinct
where office = 'U.S. House';

------------------------------------------------------------------------------------------------------------------------
-- Cleanup PARTY...
------------------------------------------------------------------------------------------------------------------------
select party, count(*) as cnt
from stage.nov2024_general_election_precinct
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

update stage.nov2024_general_election_precinct
    set party = 'Democrat'
where upper(party) = 'DEM';

update stage.nov2024_general_election_precinct
    set party = 'Green'
where upper(party) = 'GRN';

update stage.nov2024_general_election_precinct
    set party = 'Independent'
where upper(party) = 'IND';

update stage.nov2024_general_election_precinct
    set party = 'Libertarian'
where upper(party) = 'LIB';

update stage.nov2024_general_election_precinct
    set party = 'Republican'
where upper(party) = 'REP';

select party, count(*) as cnt
from stage.nov2024_general_election_precinct
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

select *
from stage.nov2024_general_election_precinct
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
    and coalesce(party, '') = ''
order by candidate;

update stage.nov2024_general_election_precinct
    set party = 'Democrat'
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
    and coalesce(party, '') = ''
    and candidate ilike '% (Dem)';

select party, count(*) as cnt
from stage.nov2024_general_election_precinct
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup COUNTY...
------------------------------------------------------------------------------------------------------------------------
select county, count(*) as cnt
from stage.nov2024_general_election_precinct
group by county
order by county;

update stage.nov2024_general_election_precinct
    set county = replace(county, ' County', '');

------------------------------------------------------------------------------------------------------------------------
-- Cleanup CANDIDATE...
------------------------------------------------------------------------------------------------------------------------
alter table stage.nov2024_general_election_precinct
    add column original_candidate varchar;

update stage.nov2024_general_election_precinct
    set original_candidate = candidate;

select *
from stage.nov2024_general_election_precinct
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
limit 50;

select candidate, count(*) as cnt
from stage.nov2024_general_election_precinct
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by candidate;

update stage.nov2024_general_election_precinct
    set candidate = trim(replace(candidate, ' (Rep)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.nov2024_general_election_precinct
    set candidate = trim(replace(candidate, ' (Dem)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.nov2024_general_election_precinct
    set candidate = trim(replace(candidate, ' (I)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.nov2024_general_election_precinct
    set candidate = trim(replace(candidate, ' (Lib)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.nov2024_general_election_precinct
    set candidate = trim(replace(candidate, ' (Ind)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.nov2024_general_election_precinct
    set candidate = trim(replace(candidate, ' (Grn)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

select candidate, original_candidate, count(*) as cnt
from stage.nov2024_general_election_precinct
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by candidate, original_candidate
order by candidate;

-----------------------------------------------------------------------------------------------
-- Move data to PROD and QC the data...
-----------------------------------------------------------------------------------------------
create or replace table prod.nov2024_general_election_precinct
as
select *
from stage.nov2024_general_election_precinct
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
order by office, party, candidate;

select *
from prod.nov2024_general_election_precinct;

-- Check a few precinct race results with the website...
select
    county,
    precinct_name,
    office,
    district,
    candidate,
    party,
    total_votes
from prod.nov2024_general_election_precinct
order by office, district, candidate, party, county, precinct_name;

-- Aggregate to county level and make sure we are still matching...
select
    county,
    office,
    district,
    candidate,
    party,
    sum(total_votes) as total_votes
from prod.nov2024_general_election_precinct
group by county, office, district, candidate, party
order by county, office, district, candidate, party;

-----------------------------------------------------------------------------------------------
-- Write out CSV file...
-----------------------------------------------------------------------------------------------
select
    county,
    precinct_name as precinct,
    office,
    district,
    party,
    candidate,
    total_votes
from prod.nov2024_general_election_precinct
order by county, office, try_cast(district as integer), party, candidate;
