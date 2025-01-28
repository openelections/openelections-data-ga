-----------------------------------------------------------------------------------------------
-- Before this process I am downloading the JSON file from GA elections and running it through
-- the enhanced_voting_process/load_json.ipynb Jupyter Notebook...
-- As I work through this process a couple of times I will create some documentation around it.
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Load JSON data...
-----------------------------------------------------------------------------------------------
create or replace table raw.nov2024_general_election_county
as
select *
from read_json('/home/skunkworks/development/openelections-data-ga/enhanced_voting_process/county_level_data.json');

select *
from raw.nov2024_general_election_county;

-----------------------------------------------------------------------------------------------
-- Rename vote_types before pivoting the data...
-----------------------------------------------------------------------------------------------
select distinct vote_type
from raw.nov2024_general_election_county;

update raw.nov2024_general_election_county
    set vote_type =
        case
            when vote_type = 'Election Day' then 'election_day_votes'
            when vote_type = 'Absentee by Mail' then 'absentee_by_mail_votes'
            when vote_type = 'Advanced Voting' then 'advanced_votes'
            when vote_type = 'Provisional' then 'provisional_votes'
        end;

-----------------------------------------------------------------------------------------------
-- Pivot data and copy to STAGE, begin the cleanup and QC...
-----------------------------------------------------------------------------------------------
create or replace table stage.nov2024_general_election_county
as
pivot raw.nov2024_general_election_county
on vote_type
using sum(votes);

select *
from stage.nov2024_general_election_county;

alter table stage.nov2024_general_election_county
    add column precinct varchar;

alter table stage.nov2024_general_election_county
    add column district varchar;

select *
from stage.nov2024_general_election_county;

update stage.nov2024_general_election_county
    set precinct = 'not available';

select *
from stage.nov2024_general_election_county;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup OFFICE...
------------------------------------------------------------------------------------------------------------------------
select
    office,
    count(distinct county) as num_counties,
    count(distinct candidate) as num_candidates
from stage.nov2024_general_election_county
group by office
order by office;

-- STEP #1 - need to find the offices we are going to pull out. We are only looking at Federal
--           and State offices right now. See the readme file in github for a list of them.
--           I typically take the above output and put it in a Google sheet and review them there.

select distinct office
from stage.nov2024_general_election_county
where office ilike '%General%'
order by office;

select *
from stage.nov2024_general_election_county
where office ilike '%Clerk%Superior%';
    and county = 'Fulton County';

alter table stage.nov2024_general_election_county
    add column original_office varchar;

update stage.nov2024_general_election_county
    set original_office = office;

select *
from stage.nov2024_general_election_county;

select distinct
    office,
    trim(split(office, ' - ')[1]) as new_office,
    trim(split(office, ' - ')[2]) as district
from stage.nov2024_general_election_county
where office ilike '%District%Attorney%'
order by office;

update stage.nov2024_general_election_county
    set office = trim(split(office, ' - ')[1]),
        district = trim(split(office, ' - ')[2])
where office ilike '%District%Attorney%';

select *
-- select distinct district
from stage.nov2024_general_election_county
where office = 'District Attorney'

update stage.nov2024_general_election_county
    set office = 'President'
where office = 'President of the US';

select *
from stage.nov2024_general_election_county
where office ilike 'State%House%Representatives%';

select distinct
    office,
    trim(split(office, ' - ')[1]) as new_office,
    trim(replace(split(office, ' - ')[2], 'District', '')) as district
from stage.nov2024_general_election_county
where office ilike 'State%House%Representatives%'
order by office;

update stage.nov2024_general_election_county
    set office = 'State House',
        district = trim(replace(split(office, ' - ')[2], 'District', ''))
where office ilike 'State%House%Representatives%';


select *
-- select count(distinct district)
from stage.nov2024_general_election_county
where office = 'State House';

-- State Senate...
select *
from stage.nov2024_general_election_county
where office ilike 'State%Senate%';

select distinct
    office,
    trim(split(office, ' - ')[1]) as new_office,
    trim(replace(split(office, ' - ')[2], 'District', '')) as district
from stage.nov2024_general_election_county
where office ilike 'State%Senate%'
order by office;

update stage.nov2024_general_election_county
    set office = 'State Senate',
        district = trim(replace(split(office, ' - ')[2], 'District', ''))
where office ilike 'State%Senate%';

select *
-- select count(distinct district)
from stage.nov2024_general_election_county
where office = 'State Senate';

-- US House...
select *
from stage.nov2024_general_election_county
where office ilike 'US%House%Representative%';

select distinct
    office,
    trim(split(office, ' - ')[1]) as new_office,
    trim(replace(split(office, ' - ')[2], 'District', '')) as district
from stage.nov2024_general_election_county
where office ilike 'US%House%Representative%'
order by office;

update stage.nov2024_general_election_county
    set office = 'U.S. House',
        district = trim(replace(split(office, ' - ')[2], 'District', ''))
where office ilike 'US%House%Representative%';

select *
-- select count(distinct district)
from stage.nov2024_general_election_county
where office = 'U.S. House';

------------------------------------------------------------------------------------------------------------------------
-- Cleanup PARTY...
------------------------------------------------------------------------------------------------------------------------
select party, count(*) as cnt
from stage.nov2024_general_election_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

update stage.nov2024_general_election_county
    set party = 'Democrat'
where upper(party) = 'DEM';

update stage.nov2024_general_election_county
    set party = 'Green'
where upper(party) = 'GRN';

update stage.nov2024_general_election_county
    set party = 'Independent'
where upper(party) = 'IND';

update stage.nov2024_general_election_county
    set party = 'Libertarian'
where upper(party) = 'LIB';

update stage.nov2024_general_election_county
    set party = 'Republican'
where upper(party) = 'REP';

select party, count(*) as cnt
from stage.nov2024_general_election_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

select *
from stage.nov2024_general_election_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
    and coalesce(party, '') = ''
order by candidate;

update stage.nov2024_general_election_county
    set party = 'Democrat'
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
    and coalesce(party, '') = ''
    and candidate ilike '% (Dem)';

select party, count(*) as cnt
from stage.nov2024_general_election_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup COUNTY...
------------------------------------------------------------------------------------------------------------------------
select county, count(*) as cnt
from stage.nov2024_general_election_county
group by county
order by county;

update stage.nov2024_general_election_county
    set county = replace(county, ' County', '');

------------------------------------------------------------------------------------------------------------------------
-- Cleanup CANDIDATE...
------------------------------------------------------------------------------------------------------------------------
alter table stage.nov2024_general_election_county
    add column original_candidate varchar;

update stage.nov2024_general_election_county
    set original_candidate = candidate;

select *
from stage.nov2024_general_election_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
limit 50;

select candidate, count(*) as cnt
from stage.nov2024_general_election_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by candidate;

update stage.nov2024_general_election_county
    set candidate = trim(replace(candidate, ' (Rep)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.nov2024_general_election_county
    set candidate = trim(replace(candidate, ' (Dem)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.nov2024_general_election_county
    set candidate = trim(replace(candidate, ' (I)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.nov2024_general_election_county
    set candidate = trim(replace(candidate, ' (Lib)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.nov2024_general_election_county
    set candidate = trim(replace(candidate, ' (Ind)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.nov2024_general_election_county
    set candidate = trim(replace(candidate, ' (Grn)', ''))
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

select candidate, original_candidate, count(*) as cnt
from stage.nov2024_general_election_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by candidate, original_candidate
order by candidate;

-----------------------------------------------------------------------------------------------
-- Move data to PROD and QC the data...
-----------------------------------------------------------------------------------------------
create or replace table prod.nov2024_general_election_county
as
select *
from stage.nov2024_general_election_county
where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
order by office, party, candidate;

select *
from prod.nov2024_general_election_county;

-- Make sure vote type counts match total_votes...
select
    candidate,
    total_votes,
    (absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as qc_total_votes
from prod.nov2024_general_election_county
where total_votes <> qc_total_votes;

-- Check a few race results with the website...
select
    office,
    district,
    candidate,
    party,
    sum(absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as total_votes
from prod.nov2024_general_election_county
group by office, district, candidate, party
order by office, district, candidate, party;

-- Check a few vote type counts with the website...
select
    county,
    office,
    district,
    candidate,
    party,
    advanced_votes,
    election_day_votes,
    absentee_by_mail_votes,
    provisional_votes
from prod.nov2024_general_election_county
where county = 'Fulton'
order by county, office, district, candidate, party;

-----------------------------------------------------------------------------------------------
-- Write out CSV file...
-----------------------------------------------------------------------------------------------
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
from prod.nov2024_general_election_county
order by county, office, try_cast(district as integer), party, candidate;
