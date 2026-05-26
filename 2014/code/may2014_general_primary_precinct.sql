-----------------------------------------------------------------------------------------------
-- Load CSV data...
-----------------------------------------------------------------------------------------------
create or replace table raw.may2014_general_primary_precinct
as
SELECT *
FROM read_csv(
    '/Users/skunkworks/Development/openelections-data-ga/2014/Archive/*.csv',
    header = False,
    skip = 1,
    names = [
        'county', 'precinct', 'office', 'district', 'party',
        'candidate', 'total_votes', 'absentee_by_mail', 'election_day',
        'advance_in_person', 'provisional'
    ],
    types = {
        'county': 'VARCHAR',
        'precinct': 'VARCHAR',
        'office': 'VARCHAR',
        'district': 'VARCHAR',
        'party': 'VARCHAR',
        'candidate': 'VARCHAR',
        'total_votes': 'INTEGER',
        'absentee_by_mail': 'INTEGER',
        'election_day': 'INTEGER',
        'advance_in_person': 'INTEGER',
        'provisional': 'INTEGER'
    },
    nullstr = ''
);


select *
from raw.may2014_general_primary_precinct;

-- Checking on some of the county|precinct|candidates with 0 total votes...
select *
from raw.may2014_general_primary_precinct
where coalesce(total_votes, 0) = 0;

select *
from raw.may2014_general_primary_precinct
where precinct is null;

-- Clear out "top level" header rows...
delete from raw.may2014_general_primary_precinct
where precinct is null;

-----------------------------------------------------------------------------------------------
-- Pivot data and copy to STAGE, begin the cleanup and QC...
-- This data is already pivoted correctly...
-----------------------------------------------------------------------------------------------
create or replace table stage.may2014_general_primary_precinct
as
select *
from raw.may2014_general_primary_precinct;

select *
from stage.may2014_general_primary_precinct;

select office, count(*) as cnt
from stage.may2014_general_primary_precinct
group by office
order by office;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup OFFICE...
------------------------------------------------------------------------------------------------------------------------
select
    office,
    count(distinct county) as num_counties,
    count(distinct candidate) as num_candidates
from stage.may2014_general_primary_precinct
group by office
order by office;

-- STEP #1 - need to find the offices we are going to pull out. We are only looking at Federal
--           and State offices right now. See the readme file in github for a list of them.
--           I typically take the above output and put it in a Google sheet and review them there.

alter table stage.may2014_general_primary_precinct
    add column original_office varchar;

update stage.may2014_general_primary_precinct
    set original_office = office;

------------------------------------------------------------------------------------------------------------------------
-- APPEALS COURT JUDGE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'Appeals Court Judge%';

update stage.may2014_general_primary_precinct
    set office = 'Appeals Court Judge'
where office ilike 'Appeals Court Judge%';

update stage.may2014_general_primary_precinct
    set party = 'Nonpartisan'
where office ilike 'Appeals Court Judge%';

update stage.may2014_general_primary_precinct
    set district = null
where office ilike 'Appeals Court Judge%';

select *
from stage.may2014_general_primary_precinct
where office ilike 'Appeals Court Judge%';

------------------------------------------------------------------------------------------------------------------------
-- ATTORNEY GENERAL
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'Attorney General%';

------------------------------------------------------------------------------------------------------------------------
-- COMMISSIONER OF %
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'Commissioner Of%';

select
    office,
    count(distinct county) as num_counties,
    count(distinct candidate) as num_candidates
from stage.may2014_general_primary_precinct
where office ilike 'Commissioner Of%'
group by office
order by office;

------------------------------------------------------------------------------------------------------------------------
-- DISTRICT ATTORNEY
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'District Attorney%';

SELECT
    office,
    trim(split_part(office, ', ', 1)) as new_office,
    trim(split_part(office, ', ', 2)) as district
from stage.may2014_general_primary_precinct
where office ilike 'District Attorney%';

update stage.may2014_general_primary_precinct
    set office = trim(split_part(office, ', ', 1)),
        district = trim(split_part(office, ', ', 2))
where office ilike 'District Attorney%';

select *
from stage.may2014_general_primary_precinct
where office ilike 'District Attorney%';

------------------------------------------------------------------------------------------------------------------------
-- GOVERNOR
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'Governor%';

------------------------------------------------------------------------------------------------------------------------
-- LIEUTENANT GOVERNOR
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'Lieutenant Governor%';

------------------------------------------------------------------------------------------------------------------------
-- PUBLIC SERVICE COMMISSIOINER
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'Public Service Commission%';

update stage.may2014_general_primary_precinct
    set office = 'Public Service Commissioner'
where office ilike 'Public Service Commission%';

select *
from stage.may2014_general_primary_precinct
where office ilike 'Public Service Commission%';

------------------------------------------------------------------------------------------------------------------------
-- STATE HOUSE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'State Representative%';

update stage.may2014_general_primary_precinct
    set office = 'State House'
where office ilike 'State Representative%';

select *
from stage.may2014_general_primary_precinct
where office ilike 'State House%';

------------------------------------------------------------------------------------------------------------------------
-- STATE SCHOOL SUPERINTENDENT
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'State School Superintendent%';

------------------------------------------------------------------------------------------------------------------------
-- STATE SENATE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'State Senat%';

update stage.may2014_general_primary_precinct
    set office = 'State Senate'
where office ilike 'State Senat%';

update stage.may2014_general_primary_precinct
    set district = '42'
where office = 'State Senate'
    and district is null;

select *
from stage.may2014_general_primary_precinct
where office ilike 'State Senate%'
order by district;

------------------------------------------------------------------------------------------------------------------------
-- SUPERIOR COURT JUDGE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'Superior Court Judge%';

select
    district,
    trim(string_split(district, '(')[1]) AS district
from stage.may2014_general_primary_precinct
where office ilike 'Superior Court Judge%';

update stage.may2014_general_primary_precinct
    set district =  trim(string_split(district, '(')[1]),
        party = 'Nonpartisan'
where office ilike 'Superior Court Judge%';

select *
from stage.may2014_general_primary_precinct
where office ilike 'Superior Court Judge%';

------------------------------------------------------------------------------------------------------------------------
-- SUPREME COURT JUSTICE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'Supreme Court Justice%';

update stage.may2014_general_primary_precinct
    set party = 'Nonpartisan',
        district = null
where office ilike 'Supreme Court Justice%';

select *
from stage.may2014_general_primary_precinct
where office ilike 'Supreme Court Justice%';

------------------------------------------------------------------------------------------------------------------------
-- SECRETARY OF STATE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'Secretary Of State%';

------------------------------------------------------------------------------------------------------------------------
-- U.S. HOUSE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'U.S. Representative%'
--     and county ilike 'Dekalb'
order by district;

update stage.may2014_general_primary_precinct
    set office = 'U.S. House'
where office ilike 'U.S. Representative%';

select *
from stage.may2014_general_primary_precinct
where office ilike 'U.S. House%';

------------------------------------------------------------------------------------------------------------------------
-- U.S. SENATE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.may2014_general_primary_precinct
where office ilike 'United States Senator%';

update stage.may2014_general_primary_precinct
    set office = 'U.S. Senate'
where office ilike 'United States Senator%';

select *
from stage.may2014_general_primary_precinct
where office ilike 'U.S. Senate%';

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

select office, count(*) as cnt
from stage.may2014_general_primary_precinct
WHERE office IN (
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
)
group by office
order by office;


select office, district, count(*) as cnt
from stage.may2014_general_primary_precinct
group by office, district
order by office, district;

delete from stage.may2014_general_primary_precinct
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
)

------------------------------------------------------------------------------------------------------------------------
-- Cleanup PARTY...
------------------------------------------------------------------------------------------------------------------------
select party, count(*) as cnt
from stage.may2014_general_primary_precinct
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

update stage.may2014_general_primary_precinct
    set party = 'Democrat'
where upper(party) = 'DEM';

update stage.may2014_general_primary_precinct
    set party = 'Republican'
where upper(party) = 'REP';

select distinct candidate
from stage.may2014_general_primary_precinct
where party is null;
-- ELENA C. PARENT --> Democrat
-- R. KYLE WILLIAMS --> Democrat

update stage.may2014_general_primary_precinct
    set party = 'Democrat'
where party is null;

select *
from stage.may2014_general_primary_county
where candidate ilike 'R. KYLE WILLIAMS';

select party, count(*) as cnt
from stage.may2014_general_primary_precinct
group by party
order by party;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup COUNTY...
------------------------------------------------------------------------------------------------------------------------
select county, count(*) as cnt
from stage.may2014_general_primary_precinct
group by county
order by county;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup CANDIDATE...
------------------------------------------------------------------------------------------------------------------------
alter table stage.may2014_general_primary_precinct
    add column original_candidate varchar;

update stage.may2014_general_primary_precinct
    set original_candidate = candidate;

select *
from stage.may2014_general_primary_precinct
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
limit 50;

select candidate, count(*) as cnt
from stage.may2014_general_primary_precinct
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by candidate
order by candidate;

update stage.may2014_general_primary_precinct
    set candidate = trim(replace(candidate, ' (I)', ''));
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House');

update stage.may2014_general_primary_precinct
    set candidate = trim(replace(candidate, '(I)', ''))
where candidate ilike '%(I)';

update stage.may2014_general_primary_precinct
    set candidate = trim(replace(candidate, ' (I', ''))
where candidate ilike '% (I';

update stage.may2014_general_primary_precinct
    set candidate = 'SAMUEL S. OLENS'
where candidate = 'SAMUEL S. OLENS (Inc';

select candidate, original_candidate, count(*) as cnt
from stage.may2014_general_primary_precinct
group by candidate, original_candidate
order by candidate;

-----------------------------------------------------------------------------------------------
-- Move data to PROD and QC the data...
-----------------------------------------------------------------------------------------------
create or replace table prod.may2014_general_primary_precinct
as
select
    county,
    precinct,
    office,
    district,
    party,
    candidate,
    total_votes,
    election_day as election_day_votes,
    advance_in_person as advanced_votes,
    absentee_by_mail as absentee_by_mail_votes,
    provisional as provisional_votes
from stage.may2014_general_primary_precinct
order by office, party, candidate;

select *
from prod.may2014_general_primary_precinct;

-- Make sure vote type counts match total_votes...
select
    candidate,
    total_votes,
    (absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as qc_total_votes
from prod.may2014_general_primary_precinct
where total_votes <> qc_total_votes;

-- These precinct votes are not matching...
with invalid_vote_counts as
(
    select
        candidate,
        total_votes,
        (absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as qc_total_votes
    from prod.may2014_general_primary_precinct
    where total_votes <> qc_total_votes
)
select distinct candidate
from invalid_vote_counts
order by candidate;

-- Check a few precinct race results with the website...
select
    office,
    district,
    candidate,
    party,
    sum(absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as total_votes
from prod.may2014_general_primary_precinct
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
from prod.may2014_general_primary_precinct
order by county, office, district, candidate, party;

-- Aggregate to county level and make sure we are still matching...
select
    county,
    office,
    district,
    candidate,
    party,
    sum(absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as total_votes
from prod.may2014_general_primary_precinct
group by county, office, district, candidate, party
order by county, office, district, candidate, party;

select *
from prod.may2014_general_primary_county
order by county, office, district, candidate, party;


update prod.may2014_general_primary_precinct
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
from prod.may2014_general_primary_precinct
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
    from prod.may2014_general_primary_precinct
    order by county, office, try_cast(district as integer), party, candidate   
) to '/Users/skunkworks/Development/openelections-data-ga/2014/20140520__ga__general__primary__precinct-level_UNOFFICIAL.csv'
(HEADER, DELIMITER ',');

checkpoint;
