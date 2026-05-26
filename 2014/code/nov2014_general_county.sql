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
create or replace table raw.nov2014_general_county
as
select *
from read_json(
    '/Users/skunkworks/Development/openelections-data-ga/2014/code/ga_20141104_county_level_data.json',
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
from raw.nov2014_general_county;

-- Checking on some of the county|precinct|candidates with 0 total votes...
select *
from raw.nov2014_general_county
where coalesce(total_votes, 0) = 0;

-----------------------------------------------------------------------------------------------
-- Rename vote_types before pivoting the data...
-----------------------------------------------------------------------------------------------
select distinct vote_type
from raw.nov2014_general_county
order by vote_type;

update raw.nov2014_general_county
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
create or replace table stage.nov2014_general_county
as
pivot raw.nov2014_general_county
on vote_type
using sum(votes);

alter table stage.nov2014_general_county
    add column district varchar;

select *
from stage.nov2014_general_county;

select office, count(*) as cnt
from stage.nov2014_general_county
group by office
order by office;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup OFFICE...
------------------------------------------------------------------------------------------------------------------------
select
    office,
    count(distinct county) as num_counties,
    count(distinct candidate) as num_candidates
from stage.nov2014_general_county
group by office
order by office;

-- STEP #1 - need to find the offices we are going to pull out. We are only looking at Federal
--           and State offices right now. See the readme file in github for a list of them.
--           I typically take the above output and put it in a Google sheet and review them there.

alter table stage.nov2014_general_county
    add column original_office varchar;

update stage.nov2014_general_county
    set original_office = office;

delete from stage.nov2014_general_county
where office ilike 'Constitutional Amendment #%';

delete from stage.nov2014_general_county
where office ilike 'Statewide Referendum%';

------------------------------------------------------------------------------------------------------------------------
-- ATTORNEY GENERAL
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'Attorney General%';

------------------------------------------------------------------------------------------------------------------------
-- COMMISSIONER OF %
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'Commissioner Of%';

------------------------------------------------------------------------------------------------------------------------
-- DISTRICT ATTORNEY
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'District Attorney%';

SELECT
    office,
    trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 1)) AS new_office,
    trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 2)) AS district
from stage.nov2014_general_county
where office ilike 'District Attorney%';

update stage.nov2014_general_county
    set office = trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 1)),
        district = trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 2))
where office ilike 'District Attorney%';

select *
from stage.nov2014_general_county
where office ilike 'District Attorney%';

------------------------------------------------------------------------------------------------------------------------
-- GOVERNOR
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'Governor%';

------------------------------------------------------------------------------------------------------------------------
-- LIEUTENANT GOVERNOR
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'Lieutenant Governor%';

------------------------------------------------------------------------------------------------------------------------
-- PUBLIC SERVICE COMMISSIOINER
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'Public Service Commission%';

SELECT
    office,
    trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 1)) AS new_office,
    replace(trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 2)), 'District ', '') AS district
from stage.nov2014_general_county
where office ilike 'Public Service Commission%';

update stage.nov2014_general_county
    set office = trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 1)),
        district = replace(trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 2)), 'District ', '')
where office ilike 'Public Service Commission%';

update stage.nov2014_general_county
    set office = trim(office) || 'er'
where office ilike 'Public Service Commission%';

select *
from stage.nov2014_general_county
where office ilike 'Public Service Commission%';

------------------------------------------------------------------------------------------------------------------------
-- STATE HOUSE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'State Representative%';

SELECT
    office,
    trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 1)) AS new_office,
    replace(trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 2)), 'District ', '') AS district
from stage.nov2014_general_county
where office ilike 'State Representative%';

update stage.nov2014_general_county
    set office = 'State House',
        district = replace(trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 2)), 'District ', '')
where office ilike 'State Representative%';

select *
from stage.nov2014_general_county
where office ilike 'State House%';

------------------------------------------------------------------------------------------------------------------------
-- STATE SCHOOL SUPERINTENDENT
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'State School Superintendent%';

------------------------------------------------------------------------------------------------------------------------
-- STATE SENATE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'State Senat%';

SELECT
    office,
    trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 1)) AS new_office,
    replace(trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 2)), 'District ', '') AS district
from stage.nov2014_general_county
where office ilike 'State Senat%';

update stage.nov2014_general_county
    set office = 'State Senate',
        district = replace(trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 2)), 'District ', '')
where office ilike 'State Senat%';

select *
from stage.nov2014_general_county
where office ilike 'State Senate%'
order by district;

------------------------------------------------------------------------------------------------------------------------
-- SECRETARY OF STATE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'Secretary Of State%';

------------------------------------------------------------------------------------------------------------------------
-- U.S. HOUSE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'U.S. Representative%';

select
    office,
    trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 1)) AS new_office,
    replace(trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 2)), 'District ', '') AS district
from stage.nov2014_general_county
where office ilike 'U.S. Representative%';

update stage.nov2014_general_county
    set office = 'U.S. House',
        district = replace(trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 2)), 'District ', '')
where office ilike 'U.S. Representative%';

select *
from stage.nov2014_general_county
where office ilike 'U.S. House%';

------------------------------------------------------------------------------------------------------------------------
-- U.S. SENATE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.nov2014_general_county
where office ilike 'United States Senator%';

update stage.nov2014_general_county
    set office = 'U.S. Senate'
where office ilike 'United States Senator%';

select *
from stage.nov2014_general_county
where office ilike 'U.S. Senate%';

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

select office, count(*) as cnt
from stage.nov2014_general_county
group by office
order by office;

select office, district, count(*) as cnt
from stage.nov2014_general_county
group by office, district
order by office, district;


------------------------------------------------------------------------------------------------------------------------
-- Cleanup PARTY...
------------------------------------------------------------------------------------------------------------------------
select party, count(*) as cnt
from stage.nov2014_general_county
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

update stage.nov2014_general_county
    set party = 'Democrat'
where upper(party) = 'DEM';

update stage.nov2014_general_county
    set party = 'Republican'
where upper(party) = 'REP';

update stage.nov2014_general_county
    set party = 'Independent'
where upper(party) = 'IND';

update stage.nov2014_general_county
    set party = 'Libertarian'
where upper(party) = 'LIB';

update stage.nov2014_general_county
    set party = 'Independent'
where candidate = 'E. CULVER "RUSTY" KIDD (I)Ind';

select party, count(*) as cnt
from stage.nov2014_general_county
-- where office in ('District Atto/rney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup COUNTY...
------------------------------------------------------------------------------------------------------------------------
select county, count(*) as cnt
from stage.nov2014_general_county
group by county
order by county;

update stage.nov2014_general_county
    set county = replace(county, ' County', '');

------------------------------------------------------------------------------------------------------------------------
-- Cleanup CANDIDATE...
------------------------------------------------------------------------------------------------------------------------
alter table stage.nov2014_general_county
    add column original_candidate varchar;

update stage.nov2014_general_county
    set original_candidate = candidate;

select *
from stage.nov2014_general_county
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
limit 50;

select candidate, count(*) as cnt
from stage.nov2014_general_county
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by candidate
order by candidate;

update stage.nov2014_general_county
    set candidate = trim(replace(candidate, ' (R)', ''));

update stage.nov2014_general_county
    set candidate = trim(replace(candidate, ' (D)', ''));

update stage.nov2014_general_county
    set candidate = trim(replace(candidate, ' (L)', ''));

update stage.nov2014_general_county
    set candidate = trim(replace(candidate, ' (I)R', ''));

update stage.nov2014_general_county
    set candidate = trim(replace(candidate, ' (I)D', ''));

update stage.nov2014_general_county
    set candidate = trim(replace(candidate, ' (I) D', ''));

update stage.nov2014_general_county
    set candidate = trim(replace(candidate, ' (I) R', ''));

select candidate, count(*) as cnt
from stage.nov2014_general_county
group by candidate
order by candidate;

update stage.nov2014_general_county
    set candidate = trim(replace(candidate, '(R)', ''))
where candidate ilike '%(R)';

update stage.nov2014_general_county
    set candidate = trim(replace(candidate, '(D)', ''))
where candidate ilike '%(D)';

update stage.nov2014_general_county
    set candidate = trim(replace(candidate, '(I)R', ''))
where candidate ilike '%(I)R';

update stage.nov2014_general_county
    set candidate = trim(replace(candidate, '(I)D', ''))
where candidate ilike '%(I)D';

update stage.nov2014_general_county
    set candidate = 'E. CULVER "RUSTY" KIDD'
where candidate = 'E. CULVER "RUSTY" KIDD (I)Ind';

update stage.nov2014_general_county
    set candidate = 'W. H. "BILL" BOZARTH'
where candidate = 'W. H. "BILL" BOZARTH (Ind)';

update stage.nov2014_general_county
    set candidate = regexp_replace(candidate, ' +', ' ', 'g');

update stage.nov2014_general_county
    set candidate = trim(candidate);

select candidate, original_candidate, count(*) as cnt
from stage.nov2014_general_county
group by candidate, original_candidate
order by candidate;

-----------------------------------------------------------------------------------------------
-- Move data to PROD and QC the data...
-----------------------------------------------------------------------------------------------
create or replace table prod.nov2014_general_county
as
select *
from stage.nov2014_general_county
order by office, party, candidate;

alter table prod.nov2014_general_county
    add column precinct varchar;

update prod.nov2014_general_county
    set precinct = 'not available';

select *
from prod.nov2014_general_county;

-- Make sure vote type counts match total_votes...
select
    candidate,
    total_votes,
    (absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as qc_total_votes
from prod.nov2014_general_county
where total_votes <> qc_total_votes;

-- Check a few precinct race results with the website...
select
    office,
    district,
    candidate,
    party,
    sum(absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as total_votes
from prod.nov2014_general_county
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
from prod.nov2014_general_county
order by county, office, district, candidate, party;

-- Aggregate to county level and make sure we are still matching...
select
    county,
    office,
    district,
    candidate,
    party,
    sum(absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as total_votes
from prod.nov2014_general_county
group by county, office, district, candidate, party
order by county, office, district, candidate, party;

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
from prod.nov2014_general_county
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
    from prod.nov2014_general_county
    order by county, office, try_cast(district as integer), party, candidate   
) to '/Users/skunkworks/Development/openelections-data-ga/2014/20141104__ga__general__county-level.csv'
(HEADER, DELIMITER ',');

checkpoint;
