-----------------------------------------------------------------------------------------------
-- Load JSON data...
-----------------------------------------------------------------------------------------------
create or replace table raw.jun2025_psc_special_election_precinct
as
select *
from read_json(
    '/Users/skunkworks/Development/openelections-data-ga/2025/code/ga_20250617_precinct_level_data.json',
    format = 'auto',
    columns = {
        'election_name': 'VARCHAR',
        'election_date': 'DATE',
        'county': 'VARCHAR',
        'number_precincts': 'VARCHAR',
        'office': 'VARCHAR',
        'candidate': 'VARCHAR',
        'party': 'VARCHAR',
        'precinct_id': 'VARCHAR',
        'precinct_name': 'VARCHAR',
        'precinct_reporting_status': 'VARCHAR',
        'vote_type': 'VARCHAR',
        'votes': 'INTEGER',
        'total_votes': 'INTEGER',
    }
);

    -- "election_name": "Special Primary Public Service Commissioner (PSC) / Special Election",
    -- "election_date": "2025-06-17",
    -- "county": "Burke County",
    -- "number_precincts": 16,
    -- "office": "PSC - District 2 - Rep",
    -- "candidate": "Tim Echols (I)",
    -- "party": "REP",
    -- "precinct_id": "1",
    -- "precinct_name": "Alexander",
    -- "precinct_reporting_status": "Fully Reported",
    -- "total_votes": 6,
    -- "vote_type": null,
    -- "votes": 6

select *
from raw.jun2025_psc_special_election_precinct;

-- Checking on some of the county|precinct|candidates with 0 total votes...
select *
from raw.jun2025_psc_special_election_precinct
where coalesce(total_votes, 0) = 0;

select *
from raw.jun2025_psc_special_election_precinct
where precinct_id is null;

select *
from raw.jun2025_psc_special_election_precinct
where precinct_name is null;

select county, precinct_name, count(*) as county
from raw.jun2025_psc_special_election_precinct
where county = 'Madison County'
group by county, precinct_name;

select county, precinct_id, count(*) as county
from raw.jun2025_psc_special_election_precinct
group by county, precinct_id;


-- Clear out "top level" header rows...
-- delete from raw.jun2025_psc_special_election_precinct
-- where precinct is null;

-----------------------------------------------------------------------------------------------
-- Copy to STAGE, begin the cleanup and QC...
-- This data is already pivoted correctly...
-----------------------------------------------------------------------------------------------
create or replace table stage.jun2025_psc_special_election_precinct
as
select
    county, 
    precinct_name as precinct,
    office,
    candidate,
    '' as district,
    party,
    votes
from raw.jun2025_psc_special_election_precinct;

select *
from stage.jun2025_psc_special_election_precinct;

select office, count(*) as cnt
from stage.jun2025_psc_special_election_precinct
group by office
order by office;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup OFFICE...
------------------------------------------------------------------------------------------------------------------------
select
    office,
    count(distinct county) as num_counties,
    count(distinct candidate) as num_candidates
from stage.jun2025_psc_special_election_precinct
group by office
order by office;

-- STEP #1 - need to find the offices we are going to pull out. We are only looking at Federal
--           and State offices right now. See the readme file in github for a list of them.
--           I typically take the above output and put it in a Google sheet and review them there.

alter table stage.jun2025_psc_special_election_precinct
    add column original_office varchar;

update stage.jun2025_psc_special_election_precinct
    set original_office = office;


------------------------------------------------------------------------------------------------------------------------
-- PUBLIC SERVICE COMMISSIONER
------------------------------------------------------------------------------------------------------------------------
select *
from stage.jun2025_psc_special_election_precinct
where office ilike 'PSC - %';

SELECT
    office,
    trim(split_part(trim(split_part(office, ' - ', 1)), ', ', 1)) AS new_office,
    replace(trim(split_part(trim(split_part(office, ' - ', 2)), ', ', 1)), 'District ', '') AS district,
from stage.jun2025_psc_special_election_precinct
where office ilike 'PSC - %';


update stage.jun2025_psc_special_election_precinct
    set office = 'Public Service Commissioner',
        district = replace(trim(split_part(trim(split_part(office, ' - ', 2)), ', ', 1)), 'District ', ''),
where office ilike 'PSC - %';

select *
from stage.jun2025_psc_special_election_precinct
where office = 'Public Service Commissioner';

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
delete from stage.jun2025_psc_special_election_precinct
where office != 'Public Service Commissioner';


select office, district, count(*) as cnt
from stage.jun2025_psc_special_election_precinct
group by office, district
order by office, district;

delete from stage.jun2025_psc_special_election_precinct
where office not in (
    'Appeals Court Judge',
    'Attorney General',
    'Commissioner Of Agriculture',
    'Commissioner Of Insurance',
    'Commissioner Of Labor',
    'District Attorney',
    'Governor',
    'Lieutenant Governor',
    'President',
    'Public Service Commissioner',
    'Secretary Of State',
    'State House',
    'State School Superintendent',
    'State Senate',
    'Superior Court Judge',
    'Supreme Court Justice',
    'U.S. House',
    'U.S. Senate',
    'Vice President'
);

------------------------------------------------------------------------------------------------------------------------
-- Cleanup PARTY...
------------------------------------------------------------------------------------------------------------------------
select party, count(*) as cnt
from stage.jun2025_psc_special_election_precinct
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

update stage.jun2025_psc_special_election_precinct
    set party = 'Republican'
where upper(party) = 'REP';

update stage.jun2025_psc_special_election_precinct
    set party = 'Democrat'
where upper(party) = 'DEM';

select party, count(*) as cnt
from stage.jun2025_psc_special_election_precinct
group by party
order by party;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup COUNTY...
------------------------------------------------------------------------------------------------------------------------
select county, count(*) as cnt
from stage.jun2025_psc_special_election_precinct
group by county
order by county;

update stage.jun2025_psc_special_election_precinct
    set county = replace(county, ' County', '');

------------------------------------------------------------------------------------------------------------------------
-- Cleanup CANDIDATE...
------------------------------------------------------------------------------------------------------------------------
alter table stage.jun2025_psc_special_election_precinct
    add column original_candidate varchar;

update stage.jun2025_psc_special_election_precinct
    set original_candidate = candidate;

select *
from stage.jun2025_psc_special_election_precinct
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
limit 50;

update stage.jun2025_psc_special_election_precinct
    set candidate = trim(replace(candidate, ' (I)', ''));

select candidate, original_candidate, count(*) as cnt
from stage.jun2025_psc_special_election_precinct
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by candidate, original_candidate
order by candidate;

-----------------------------------------------------------------------------------------------
-- Move data to PROD and QC the data...
-----------------------------------------------------------------------------------------------
create or replace table prod.jun2025_psc_special_election_precinct
as
select *
from stage.jun2025_psc_special_election_precinct
order by office, party, candidate;

select *
from prod.jun2025_psc_special_election_precinct;

-- Check a few precinct race results with the website...
select
    office,
    district,
    candidate,
    party,
    sum(votes) as votes
from prod.jun2025_psc_special_election_precinct
group by office, district, candidate, party
order by office, district, candidate, party;

select candidate, sum(votes) as votes
from raw.jun2025_psc_special_election_precinct
group by candidate
order by candidate;

-- Check a few vote type counts with the website...
select
    county,
    precinct,
    office,
    district,
    candidate,
    party,
    votes,
from prod.jun2025_psc_special_election_precinct
order by county, office, district, candidate, party, precinct;

select *
from prod.jun2025_psc_special_election_county;

-- create or replace temp table qc
-- as
with county_votes as
(
    select county, candidate, votes
    from prod.jun2025_psc_special_election_county
),
precinct_votes as
(
    select county, candidate, sum(votes) as votes
    from prod.jun2025_psc_special_election_precinct
    group by county, candidate
)
-- select b.county, b.candidate, a.votes - b.votes as diff
select *
from county_votes as a
    inner join precinct_votes as b
        on a.county = b.county
            and a.candidate = b.candidate
where a.votes != b.votes
order by a.candidate, a.county;

select county, candidate, sum(diff) as diff
from qc
group by county, candidate
order by candidate, county;

-- Aggregate to county level and make sure we are still matching...
select
    county,
    office,
    district,
    candidate,
    party,
    sum(absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as total_votes
from prod.jun2025_psc_special_election_precinct
group by county, office, district, candidate, party
order by county, office, district, candidate, party;

select *
from prod.may2014_general_primary_county
order by county, office, district, candidate, party;


update prod.jun2025_psc_special_election_precinct
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
from prod.jun2025_psc_special_election_precinct
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
    from prod.jun2025_psc_special_election_precinct
    order by county, office, try_cast(district as integer), party, candidate   
) to '/Users/skunkworks/Development/openelections-data-ga/2014/20140722__ga__general__primary__runoff__precinct-level_UNOFFICIAL.csv'
(HEADER, DELIMITER ',');

checkpoint;
