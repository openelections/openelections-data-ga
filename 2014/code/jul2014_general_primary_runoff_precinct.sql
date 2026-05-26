-----------------------------------------------------------------------------------------------
-- Load CSV data...
-----------------------------------------------------------------------------------------------
create or replace table raw.jul2014_general_primary_runoff_precinct
as
SELECT *
FROM read_csv(
    '/Users/skunkworks/Development/openelections-data-ga/2014/Archive/20140722*.csv',
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
from raw.jul2014_general_primary_runoff_precinct;

-- Checking on some of the county|precinct|candidates with 0 total votes...
select *
from raw.jul2014_general_primary_runoff_precinct
where coalesce(total_votes, 0) = 0;

select *
from raw.jul2014_general_primary_runoff_precinct
where precinct is null;

-- Clear out "top level" header rows...
delete from raw.jul2014_general_primary_runoff_precinct
where precinct is null;

-----------------------------------------------------------------------------------------------
-- Pivot data and copy to STAGE, begin the cleanup and QC...
-- This data is already pivoted correctly...
-----------------------------------------------------------------------------------------------
create or replace table stage.jul2014_general_primary_runoff_precinct
as
select *
from raw.jul2014_general_primary_runoff_precinct;

select *
from stage.jul2014_general_primary_runoff_precinct;

select office, count(*) as cnt
from stage.jul2014_general_primary_runoff_precinct
group by office
order by office;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup OFFICE...
------------------------------------------------------------------------------------------------------------------------
select
    office,
    count(distinct county) as num_counties,
    count(distinct candidate) as num_candidates
from stage.jul2014_general_primary_runoff_precinct
group by office
order by office;

-- STEP #1 - need to find the offices we are going to pull out. We are only looking at Federal
--           and State offices right now. See the readme file in github for a list of them.
--           I typically take the above output and put it in a Google sheet and review them there.

alter table stage.jul2014_general_primary_runoff_precinct
    add column original_office varchar;

update stage.jul2014_general_primary_runoff_precinct
    set original_office = office;

------------------------------------------------------------------------------------------------------------------------
-- STATE SCHOOL SUPERINTENDENT
------------------------------------------------------------------------------------------------------------------------
select *
from stage.jul2014_general_primary_runoff_precinct
where office ilike 'State School Superintendent%';

update stage.jul2014_general_primary_runoff_precinct
    set office = 'State School Superintendent'
where office ilike 'State School Superintendent%';

------------------------------------------------------------------------------------------------------------------------
-- STATE SENATE
------------------------------------------------------------------------------------------------------------------------
select *
from stage.jul2014_general_primary_runoff_precinct
where office ilike 'State Senat%';

update stage.jul2014_general_primary_runoff_precinct
    set office = 'State Senate'
where office ilike 'State Senat%';

select *
from stage.jul2014_general_primary_runoff_precinct
where office ilike 'State Senate%'
order by district;

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

select office, count(*) as cnt
from stage.jul2014_general_primary_runoff_precinct
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
from stage.jul2014_general_primary_runoff_precinct
group by office, district
order by office, district;

delete from stage.jul2014_general_primary_runoff_precinct
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
from stage.jul2014_general_primary_runoff_precinct
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by party
order by party;

update stage.jul2014_general_primary_runoff_precinct
    set party = 'Republican'
where upper(party) = 'REP';

select party, count(*) as cnt
from stage.jul2014_general_primary_runoff_precinct
group by party
order by party;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup COUNTY...
------------------------------------------------------------------------------------------------------------------------
select county, count(*) as cnt
from stage.jul2014_general_primary_runoff_precinct
group by county
order by county;

------------------------------------------------------------------------------------------------------------------------
-- Cleanup CANDIDATE...
------------------------------------------------------------------------------------------------------------------------
alter table stage.jul2014_general_primary_runoff_precinct
    add column original_candidate varchar;

update stage.jul2014_general_primary_runoff_precinct
    set original_candidate = candidate;

select *
from stage.jul2014_general_primary_runoff_precinct
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
limit 50;

select candidate, count(*) as cnt
from stage.jul2014_general_primary_runoff_precinct
-- where office in ('District Attorney', 'President', 'State House', 'State Senate', 'U.S. House')
group by candidate
order by candidate;

-----------------------------------------------------------------------------------------------
-- Move data to PROD and QC the data...
-----------------------------------------------------------------------------------------------
create or replace table prod.jul2014_general_primary_runoff_precinct
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
from stage.jul2014_general_primary_runoff_precinct
order by office, party, candidate;

select *
from prod.jul2014_general_primary_runoff_precinct;


-- Make sure vote type counts match total_votes...
select
    candidate,
    total_votes,
    (absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as qc_total_votes
from prod.jul2014_general_primary_runoff_precinct
where total_votes <> qc_total_votes;

-- These precinct votes are not matching...
with invalid_vote_counts as
(
    select
        candidate,
        total_votes,
        (absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as qc_total_votes
    from prod.jul2014_general_primary_runoff_precinct
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
from prod.jul2014_general_primary_runoff_precinct
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
from prod.jul2014_general_primary_runoff_precinct
order by county, office, district, candidate, party;

-- Aggregate to county level and make sure we are still matching...
select
    county,
    office,
    district,
    candidate,
    party,
    sum(absentee_by_mail_votes + advanced_votes + election_day_votes + provisional_votes) as total_votes
from prod.jul2014_general_primary_runoff_precinct
group by county, office, district, candidate, party
order by county, office, district, candidate, party;

select *
from prod.may2014_general_primary_county
order by county, office, district, candidate, party;


update prod.jul2014_general_primary_runoff_precinct
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
from prod.jul2014_general_primary_runoff_precinct
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
    from prod.jul2014_general_primary_runoff_precinct
    order by county, office, try_cast(district as integer), party, candidate   
) to '/Users/skunkworks/Development/openelections-data-ga/2014/20140722__ga__general__primary__runoff__precinct-level_UNOFFICIAL.csv'
(HEADER, DELIMITER ',');

checkpoint;
