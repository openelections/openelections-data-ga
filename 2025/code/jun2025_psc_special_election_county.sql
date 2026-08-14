-----------------------------------------------------------------------------------------------
-- Before this process I am downloading the JSON file from GA elections and running it through
-- the enhanced_voting_process/load_json.ipynb Jupyter Notebook...
-- As I work through this process a couple of times I will create some documentation around it.
-----------------------------------------------------------------------------------------------

create schema raw;
create schema stage;
create schema prod;

-----------------------------------------------------------------------------------------------
-- Load JSON data...
-----------------------------------------------------------------------------------------------
create or replace table raw.jun2025_psc_special_election_county
as
select *
from read_json(
    '/Users/skunkworks/Development/openelections-data-ga/2025/code/ga_20250617_county_level_data.json',
    format = 'auto',
    columns = {
        'election_name': 'VARCHAR',
        'election_date': 'DATE',
        'county': 'VARCHAR',
        'office': 'VARCHAR',
        'candidate': 'VARCHAR',
        'party': 'VARCHAR',
        'vote_type': 'VARCHAR',
        'votes': 'INTEGER',
        'total_votes': 'INTEGER',
    }
);

select *
from raw.jun2025_psc_special_election_county;

-- Checking on some of the county|precinct|candidates with 0 total votes...
select *
from raw.jun2025_psc_special_election_county
where coalesce(total_votes, 0) = 0;

-----------------------------------------------------------------------------------------------
-- Rename vote_types before pivoting the data...
-----------------------------------------------------------------------------------------------
-- select distinct vote_type
-- from raw.jun2025_psc_special_election_county
-- order by vote_type;

-- update raw.jun2025_psc_special_election_county
--     set vote_type =
--         case
--             when vote_type = 'Absentee by Mail' then 'absentee_by_mail_votes'
--             when vote_type = 'Advance in Person' then 'advanced_votes'
--             when vote_type = 'Election Day' then 'election_day_votes'
--             when vote_type = 'Provisional' then 'provisional_votes'
--         end;


-----------------------------------------------------------------------------------------------
-- Copy to STAGE, begin the cleanup and QC...
-----------------------------------------------------------------------------------------------
-- create or replace table stage.jun2025_psc_special_election_county
-- as
-- pivot raw.jun2025_psc_special_election_county
-- on vote_type
-- using sum(votes);

create or replace table stage.jun2025_psc_special_election_county
as
select 
    county, 
    'not available' as precinct,
    office,
    candidate,
    '' as district,
    party,
    votes
from raw.jun2025_psc_special_election_county;

select *
from stage.jun2025_psc_special_election_county;

select office, count(*) as cnt
from stage.jun2025_psc_special_election_county
group by office
order by office;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup OFFICE...
------------------------------------------------------------------------------------------------------------------------
select
    office,
    count(distinct county) as num_counties,
    count(distinct candidate) as num_candidates
from stage.jun2025_psc_special_election_county
group by office
order by office;

-- STEP #1 - need to find the offices we are going to pull out. We are only looking at Federal
--           and State offices right now. See the readme file in github for a list of them.
--           I typically take the above output and put it in a Google sheet and review them there.

alter table stage.jun2025_psc_special_election_county
    add column original_office varchar;

update stage.jun2025_psc_special_election_county
    set original_office = office;

------------------------------------------------------------------------------------------------------------------------
-- PUBLIC SERVICE COMMISSIONER
------------------------------------------------------------------------------------------------------------------------
select *
from stage.jun2025_psc_special_election_county
where office ilike 'PSC - %';

SELECT
    office,
    trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 1)) AS new_office,
    replace(trim(split_part(trim(split_part(office, ' - ', 2)), ', ', 1)), 'District ', '') AS district,
from stage.jun2025_psc_special_election_county
where office ilike 'PSC - %';


update stage.jun2025_psc_special_election_county
    set office = 'Public Service Commissioner',
        district = replace(trim(split_part(trim(split_part(office, ' - ', 2)), ', ', 1)), 'District ', ''),
where office ilike 'PSC - %';

select *
from stage.jun2025_psc_special_election_county
where office = 'Public Service Commissioner';

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
delete from stage.jun2025_psc_special_election_county
where office != 'Public Service Commissioner';


select office, count(*) as cnt
from stage.jun2025_psc_special_election_county
group by office
order by office;

select office, district, count(*) as cnt
from stage.jun2025_psc_special_election_county
group by office, district
order by office, district;


------------------------------------------------------------------------------------------------------------------------
-- Cleanup PARTY...
------------------------------------------------------------------------------------------------------------------------
select party, count(*) as cnt
from stage.jun2025_psc_special_election_county
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

update stage.jun2025_psc_special_election_county
    set party = 'Democrat'
where upper(party) = 'DEM';

update stage.jun2025_psc_special_election_county
    set party = 'Republican'
where upper(party) = 'REP';

select party, count(*) as cnt
from stage.jun2025_psc_special_election_county
group by party
order by party;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup COUNTY...
------------------------------------------------------------------------------------------------------------------------
select county, count(*) as cnt
from stage.jun2025_psc_special_election_county
group by county
order by county;

update stage.jun2025_psc_special_election_county
    set county = replace(county, ' County', '');

------------------------------------------------------------------------------------------------------------------------
-- Cleanup CANDIDATE...
------------------------------------------------------------------------------------------------------------------------
alter table stage.jun2025_psc_special_election_county
    add column original_candidate varchar;

update stage.jun2025_psc_special_election_county
    set original_candidate = candidate;

select *
from stage.jun2025_psc_special_election_county
limit 50;

select candidate, count(*) as cnt
from stage.jun2025_psc_special_election_county
group by candidate
order by candidate;

update stage.jun2025_psc_special_election_county
    set candidate = trim(replace(candidate, ' (I)', ''));

select candidate, original_candidate, count(*) as cnt
from stage.jun2025_psc_special_election_county
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by candidate, original_candidate
order by candidate;

-----------------------------------------------------------------------------------------------
-- Move data to PROD and QC the data...
-----------------------------------------------------------------------------------------------
create or replace table prod.jun2025_psc_special_election_county
as
select *
from stage.jun2025_psc_special_election_county
order by office, party, candidate;

select *
from prod.jun2025_psc_special_election_county;

-- Check a few precinct race results with the website...
select
    office,
    district,
    candidate,
    party,
    sum(votes) as votes
    -- sum(absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as total_votes
from prod.jun2025_psc_special_election_county
group by office, district, candidate, party
order by office, district, candidate, party;

-- Aggregate to county level and make sure we are still matching...
select
    county,
    office,
    district,
    candidate,
    party,
    sum(votes) as total_votes
from prod.jun2025_psc_special_election_county
group by county, office, district, candidate, party
order by county, office, district, candidate, party;

update prod.jun2025_psc_special_election_county
    set candidate = trim(candidate);

select
    county,
    precinct,
    office,
    district,
    party,
    candidate,
    votes
from prod.jun2025_psc_special_election_county
order by county, office, try_cast(district as integer), party, candidate;

-----------------------------------------------------------------------------------------------
-- Write out CSV file...
-----------------------------------------------------------------------------------------------
COPY
(
    select
        county,
        precinct,
        office,
        district,
        party,
        candidate,
        votes
    from prod.jun2025_psc_special_election_county
    order by county, office, try_cast(district as integer), party, candidate   
) to '/Users/skunkworks/Development/openelections-data-ga/2025/20250617__ga__special__psc__county-level.csv'
(HEADER, DELIMITER ',');

checkpoint;
