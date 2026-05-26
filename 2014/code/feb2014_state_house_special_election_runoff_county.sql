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
create or replace table raw.feb2014_state_house_runoff_county
as
select *
from read_json('/Users/skunkworks/Development/openelections-data-ga/2014/code/ga_20140204_county_level_data.json');

select *
from raw.feb2014_state_house_runoff_county;

-- Checking on some of the county|precinct|candidates with 0 total votes...
select *
from raw.feb2014_state_house_runoff_county
where coalesce(total_votes, 0) = 0;

-----------------------------------------------------------------------------------------------
-- Rename vote_types before pivoting the data...
-----------------------------------------------------------------------------------------------
select distinct vote_type
from raw.feb2014_state_house_runoff_county
order by vote_type;

update raw.feb2014_state_house_runoff_county
    set vote_type =
        case
            when vote_type = 'Absentee by Mail' then 'absentee_by_mail_votes'
            when vote_type = 'Advance in Person' then 'advanced_votes'
            when vote_type = 'Election Day' then 'election_day_votes'
            when vote_type = 'Provisional' then 'provisional_votes'
        end;


-----------------------------------------------------------------------------------------------
-- Pivot data and copy to STAGE, begin the cleanup and QC...
-----------------------------------------------------------------------------------------------
create or replace table stage.feb2014_state_house_runoff_county
as
pivot raw.feb2014_state_house_runoff_county
on vote_type
using sum(votes);

alter table stage.feb2014_state_house_runoff_county
    add column district varchar;

select *
from stage.feb2014_state_house_runoff_county;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup OFFICE...
------------------------------------------------------------------------------------------------------------------------
select
    office,
    count(distinct county) as num_counties,
    count(distinct candidate) as num_candidates
from stage.feb2014_state_house_runoff_county
group by office
order by office;

-- STEP #1 - need to find the offices we are going to pull out. We are only looking at Federal
--           and State offices right now. See the readme file in github for a list of them.
--           I typically take the above output and put it in a Google sheet and review them there.

alter table stage.feb2014_state_house_runoff_county
    add column original_office varchar;

update stage.feb2014_state_house_runoff_county
    set original_office = office;

select *
from stage.feb2014_state_house_runoff_county;

select *
from stage.feb2014_state_house_runoff_county
where office ilike 'State%Representative%';

select distinct
    office,
    trim(split(office, ', ')[1]) as new_office,
    trim(replace(split(office, ', ')[2], 'District', '')) as district
from stage.feb2014_state_house_runoff_county
where office ilike 'State%Representative%'
order by office;

update stage.feb2014_state_house_runoff_county
    set office = 'State House',
        district = trim(replace(split(office, ', ')[2], 'District', ''))
where office ilike 'State%Representative%';

select *
-- select count(distinct district)
from stage.feb2014_state_house_runoff_county
where office = 'State House';

------------------------------------------------------------------------------------------------------------------------
-- Cleanup PARTY...
------------------------------------------------------------------------------------------------------------------------
select party, count(*) as cnt
from stage.feb2014_state_house_runoff_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

update stage.feb2014_state_house_runoff_county
    set party = 'Democrat'
where upper(party) = 'DEM';

update stage.feb2014_state_house_runoff_county
    set party = 'Republican'
where upper(party) = 'REP';

select party, count(*) as cnt
from stage.feb2014_state_house_runoff_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

select *
from stage.feb2014_state_house_runoff_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
    and coalesce(party, '') = ''
order by candidate;

select party, count(*) as cnt
from stage.feb2014_state_house_runoff_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup COUNTY...
------------------------------------------------------------------------------------------------------------------------
select county, count(*) as cnt
from stage.feb2014_state_house_runoff_county
group by county
order by county;

update stage.feb2014_state_house_runoff_county
    set county = replace(county, ' County', '');

------------------------------------------------------------------------------------------------------------------------
-- Cleanup CANDIDATE...
------------------------------------------------------------------------------------------------------------------------
alter table stage.feb2014_state_house_runoff_county
    add column original_candidate varchar;

update stage.feb2014_state_house_runoff_county
    set original_candidate = candidate;

select *
from stage.feb2014_state_house_runoff_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
limit 50;

select candidate, count(*) as cnt
from stage.feb2014_state_house_runoff_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by candidate;

update stage.feb2014_state_house_runoff_county
    set candidate = trim(replace(candidate, ' (R)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.feb2014_state_house_runoff_county
    set candidate = trim(replace(candidate, ' (Dem)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.feb2014_state_house_runoff_county
    set candidate = trim(replace(candidate, ' (I)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

select candidate, original_candidate, count(*) as cnt
from stage.feb2014_state_house_runoff_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by candidate, original_candidate
order by candidate;

-----------------------------------------------------------------------------------------------
-- Move data to PROD and QC the data...
-----------------------------------------------------------------------------------------------
create or replace table prod.feb2014_state_house_runoff_county
as
select *
from stage.feb2014_state_house_runoff_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
order by office, party, candidate;

alter table prod.feb2014_state_house_runoff_county
    add column precinct varchar;

update prod.feb2014_state_house_runoff_county
    set precinct = 'not available';

select *
from prod.feb2014_state_house_runoff_county;

-- Make sure vote type counts match total_votes...
select
    candidate,
    total_votes,
    (absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as qc_total_votes
from prod.feb2014_state_house_runoff_county
where total_votes <> qc_total_votes;

-- Check a few precinct race results with the website...
select
    office,
    district,
    candidate,
    party,
    sum(absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as total_votes
from prod.feb2014_state_house_runoff_county
group by office, district, candidate, party
order by office, district, candidate, party;

-- Check a few vote type counts with the website...
select
    county,
    precinct,
    office,
    district,
    candidate,
    party,
    advanced_votes,
    election_day_votes,
    absentee_by_mail_votes,
    provisional_votes
from prod.feb2014_state_house_runoff_county
order by county, office, district, candidate, party;

-- Aggregate to county level and make sure we are still matching...
select
    county,
    office,
    district,
    candidate,
    party,
    sum(absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as total_votes
from prod.feb2014_state_house_runoff_county
group by county, office, district, candidate, party
order by county, office, district, candidate, party;

update prod.feb2014_state_house_runoff_county
    set candidate = trim(candidate);

select
    county,
    precinct,
    office,
    district,
    party,
    candidate,
    election_day_votes,
    advanced_votes,
    absentee_by_mail_votes,
    provisional_votes
from prod.feb2014_state_house_runoff_county
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
        election_day_votes,
        advanced_votes,
        absentee_by_mail_votes,
        provisional_votes
    from prod.feb2014_state_house_runoff_county
    order by county, office, try_cast(district as integer), party, candidate   
) to '/Users/skunkworks/Development/openelections-data-ga/2014/20140204__ga__special__state__house__2__22__runoff__county-level.csv'
(HEADER, DELIMITER ',');

checkpoint;
