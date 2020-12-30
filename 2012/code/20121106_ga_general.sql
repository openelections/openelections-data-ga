set search_path to dev;
show search_path;

-- drop table dev.ga_general_20121106;

create table dev.ga_general_20121106
    (
        county varchar(100),
        precinct varchar(100),
        input_office varchar(500),
        office varchar(100),
        district varchar(100),
        input_candidate varchar(500),
        candidate varchar(100),
        party varchar(50),
        total_votes varchar(50),
        vote_type varchar(50),
        votes varchar(50)
    );

-- truncate table dev.ga_general_20121106;

select *
from dev.ga_general_20121106
limit 5000;

select count(*) as cnt
from dev.ga_general_20121106;
-- 341427

---------------------------------------------------------------
-- Check a couple of big races to make sure numbers match up...
---------------------------------------------------------------
select input_office, count(*) as cnt
from dev.ga_general_20121106
group by input_office
order by input_office;

select input_candidate, input_office, sum(votes::int) as votes
from dev.ga_general_20121106
where input_office ilike ('%President%')
group by input_candidate, input_office
order by input_office, input_candidate;


-- Check if we have all counties...
select county, count(*) as cnt
from dev.ga_general_20121106
group by county
order by county;
-- 159

with unique_counties_laoded as
(
    select distinct county
    from dev.ga_general_20121106
)
select *
from dev.georgia_counties as a
    left join unique_counties_laoded as b
        on a.county = b.county
where b.county is null
order by a.county;
-- None missing...


select *
from dev.ga_general_20121106
limit 5000;

select input_office, count(*) as cnt
from dev.ga_general_20121106
group by input_office
order by input_office;

/*
Possible Offices...
Appeals Court Judge
Attorney General
Commissioner of Agriculture
Commissioner of Insurance
Commissioner of Labor
District Attorney
Governor
Lieutenant Governor
President
Public Service Commissioner
Secretary of State
State House
State School Superintendent
State Senate
Superior Court Judge
Supreme Court Justice
U.S. House
U.S. Senate
Vice President


OFFICES:
- District Attorney
- President of the United States
- Public Service Commission
- State Representative
- State Senator
- U.S. Representative
*/
------------------------------------------------------------------------------------------------------------------------
-- Standardize Federal Offices...
------------------------------------------------------------------------------------------------------------------------
-- U.S. House
select
    input_office,
    'U.S. House' as office,
    trim((regexp_split_to_array(input_office, ' '))[4]) as district
from dev.ga_general_20121106
where input_office ilike '%U.S. Representative%';

update dev.ga_general_20121106
    set office = 'U.S. House',
        district = trim((regexp_split_to_array(input_office, ' '))[4])
where input_office ilike '%U.S. Representative%';

------------------------------------------------------------------------------------------------------------------------
-- Standardize State Offices...
------------------------------------------------------------------------------------------------------------------------
-- State Senate
select
    input_office,
    'State Senate' as office,
    trim((regexp_split_to_array(input_office, ' '))[4]) as district
from dev.ga_general_20121106
where input_office ilike '%State Senator%';

update dev.ga_general_20121106
    set office = 'State Senate',
        district = trim((regexp_split_to_array(input_office, ' '))[4])
where input_office ilike '%State Senator%';

-- State House
select
    input_office,
    'State House' as office,
    trim((regexp_split_to_array(input_office, ' '))[4]) as district
from dev.ga_general_20121106
where input_office ilike '%State Representative%';

update dev.ga_general_20121106
    set office = 'State House',
        district = trim((regexp_split_to_array(input_office, ' '))[4])
where input_office ilike '%State Representative%';

-- District Attorney
select
    input_office,
    'District Attorney' as office,
    trim((regexp_split_to_array(input_office, ','))[2]) as district
from dev.ga_general_20121106
where input_office ilike '%District Attorney%';

update dev.ga_general_20121106
    set office = 'District Attorney',
        district = trim((regexp_split_to_array(input_office, ','))[2])
where input_office ilike '%District Attorney%';

select *
from dev.ga_general_20121106
where input_office ilike '%District Attorney%';

-- Public Service Commissioner
select
    candidate,
    input_office,
    'Public Service Commissioner' as office,
    trim((regexp_split_to_array(input_office, ' '))[5]) as district
from dev.ga_general_20121106
where input_office ilike 'Public Service Commission%';

update dev.ga_general_20121106
    set office = 'Public Service Commissioner',
        district = trim((regexp_split_to_array(input_office, ' '))[5])
where input_office ilike 'Public Service Commission%';

-- President of the United States
select
    candidate,
    input_office,
    'President' as office
from dev.ga_general_20121106
where input_office = 'President of the United States';

update dev.ga_general_20121106
    set office = 'President'
where input_office = 'President of the United States';

select office, district, input_office, count(*) as cnt
from dev.ga_general_20121106
where office is not null
group by office, district, input_office
order by office, district, input_office;

-- Double check whats left...
select input_office, count(*) as cnt
from dev.ga_general_20121106
where office is null
group by input_office
order by input_office;

------------------------------------------------------------------------------------------------------------------------
-- Fix party information...
------------------------------------------------------------------------------------------------------------------------
select party, count(*) as cnt
from dev.ga_general_20121106
group by party
order by party;

-- Clean-up the data...
update dev.ga_general_20121106
    set party = 'Republican'
where party = 'REP';

select party, count(*) as cnt
from dev.ga_general_20121106
group by party
order by party;

select input_candidate, party, count(*) as cnt
from dev.ga_general_20121106
where office is not null
group by input_candidate, party
order by input_candidate, party;

update dev.ga_general_20121106
    set party = 'Republican'
where party is null
    and input_candidate ilike '%(I)R';

update dev.ga_general_20121106
    set party = 'Republican'
where party is null
    and input_candidate ilike '%(I) R';

update dev.ga_general_20121106
    set party = 'Republican'
where party is null
    and input_candidate ilike '%(I)(R';

update dev.ga_general_20121106
    set party = 'Republican'
where party is null
    and input_candidate ilike '% (R';

update dev.ga_general_20121106
    set party = 'Republican'
where party is null
    and input_candidate ilike '%(R)';

update dev.ga_general_20121106
    set party = 'Democrat'
where party is null
    and input_candidate ilike '%(I)D';

update dev.ga_general_20121106
    set party = 'Democrat'
where party is null
    and input_candidate ilike '%(I)(D';

update dev.ga_general_20121106
    set party = 'Democrat'
where party is null
    and input_candidate ilike '%(I) D';

update dev.ga_general_20121106
    set party = 'Democrat'
where party is null
    and input_candidate ilike '%(D)';

update dev.ga_general_20121106
    set party = 'Democrat'
where party is null
    and input_candidate ilike '% (D';

update dev.ga_general_20121106
    set party = 'Republican'
where party is null
    and trim(input_candidate) in ('ASHLEY WRIGHT (I)', 'BARBARA SIMS (I)', 'CHUCK EATON', 'J. CHRIS VAUGHN',
        'JESSE STONE (I)', 'JOHN HOUSE R', 'LEE ANDERSON', 'MIKE DUDGEON (I)', 'STAN WISE', 'STAN WISE (I)',
        'STAN WISE (I)R', 'TOM GRAVES (I)', 'TREY KELLEY');

update dev.ga_general_20121106
    set party = 'Democrat'
where party is null
    and trim(input_candidate) in ('BARACK OBAMA (I)', 'EVITA A. PASCHALL', 'GLORIA FRAZIER (I)',
        'JOHN BARROW (I)', 'KAREN BENNETT', 'QUINCY  MURPHY (I)', 'ROBERT INGHAM');

select input_candidate, party, count(*) as cnt
from dev.ga_general_20121106
where office is not null
    and party is null
group by input_candidate, party
order by input_candidate, party;

update dev.ga_general_20121106
    set party = 'Libertarian'
where party is null
    and input_candidate ilike '%(LIB)';

update dev.ga_general_20121106
    set party = 'Libertarian'
where party is null
    and input_candidate ilike '%(L)';

update dev.ga_general_20121106
    set party = 'Independent'
where party is null
    and input_candidate ilike '%(I)';

select input_candidate, party, count(*) as cnt
from dev.ga_general_20121106
where office is not null
group by input_candidate, party
order by input_candidate, party;

update dev.ga_general_20121106
    set party = 'Libertarian'
where party is null
    and trim(input_candidate) in ('DAVID STAPLES');

update dev.ga_general_20121106
    set party = 'Independent'
where party is null
    and trim(input_candidate) in ('E.CULVER KIDD(I)(Ind');

update dev.ga_general_20121106
    set party = 'Republican'
where party is null
    and trim(input_candidate) in ('DAVID HOPPER', 'KENNETH  QUARTERMAN');

------------------------------------------------------------------------------------------------------------------------
-- Fix candidate names...
------------------------------------------------------------------------------------------------------------------------
-- Move input values over...
update dev.ga_general_20121106
    set candidate = trim(input_candidate)
where office is not null;

/*
RESET...
update dev.ga_general_20121106
    set candidate = null;
*/

select input_candidate, candidate, count(*) as cnt
from dev.ga_general_20121106
where office is not null
group by input_candidate, candidate
order by input_candidate, candidate;

-- Remove the Incumbent (I) from candidate
update dev.ga_general_20121106
    set candidate = replace(candidate, ' (I)', '')
where office is not null
    and candidate like '% (I)';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (D)', '')
where office is not null
    and candidate like '% (D)';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (R)', '')
where office is not null
    and candidate like '% (R)';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (I)(R)', '')
where office is not null
    and candidate like '% (I)(R)';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (I)(D)', '')
where office is not null
    and candidate like '% (I)(D)';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (I)D', '')
where office is not null
    and candidate like '% (I)D';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (I) R', '')
where office is not null
    and candidate like '% (I) R';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (I)R', '')
where office is not null
    and candidate like '% (I)R';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (R', '')
where office is not null
    and candidate like '% (R';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (I) D', '')
where office is not null
    and candidate like '% (I) D';

update dev.ga_general_20121106
    set candidate = replace(candidate, '(I)R', '')
where office is not null
    and candidate like '%(I)R';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (I)(D', '')
where office is not null
    and candidate like '% (I)(D';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (I)(R', '')
where office is not null
    and candidate like '% (I)(R';

update dev.ga_general_20121106
    set candidate = replace(candidate, '(D)', '')
where office is not null
    and candidate like '%(D)';

update dev.ga_general_20121106
    set candidate = replace(candidate, ' (L)', '')
where office is not null
    and candidate like '% (L)';

update dev.ga_general_20121106
    set candidate = replace(candidate, '(I)(R)', '')
where office is not null
    and candidate like '%(I)(R)';

update dev.ga_general_20121106
    set candidate = replace(candidate, '(LIB)', '')
where office is not null
    and candidate like '%(LIB)';

select input_candidate, candidate, count(*) as cnt
from dev.ga_general_20121106
where office is not null
group by input_candidate, candidate
order by input_candidate, candidate;

update dev.ga_general_20121106
    set candidate = 'DAVID E. LUCAS SR'
where office is not null
    and candidate = 'DAVID E. LUCAS SR (D';

update dev.ga_general_20121106
    set candidate = 'DEMETRIUS DOUGLAS'
where office is not null
    and candidate = 'DEMETRIUS DOUGLAS (D';

update dev.ga_general_20121106
    set candidate = 'DENNIS SANDERS'
where office is not null
    and candidate = 'DENNIS SANDERS(I)';

update dev.ga_general_20121106
    set candidate = 'E. CULVER KIDD'
where office is not null
    and candidate = 'E. CULVER KIDD(I)(I)';

update dev.ga_general_20121106
    set candidate = 'E.CULVER KIDD'
where office is not null
    and candidate = 'E.CULVER KIDD(I)(Ind';

update dev.ga_general_20121106
    set candidate = 'FREDDIE POWELL'
where office is not null
    and candidate = 'FREDDIE POWELL(I)D';

update dev.ga_general_20121106
    set candidate = 'GLORIA FRAZIER'
where office is not null
    and candidate = 'GLORIA FRAZIER(I)';

update dev.ga_general_20121106
    set candidate = 'H. JOHNSON JR'
where office is not null
    and candidate = 'H. JOHNSON JR.(I)';

update dev.ga_general_20121106
    set candidate = 'HAYWARD ALTMAN'
where office is not null
    and candidate = 'HAYWARD ALTMAN(I)';

update dev.ga_general_20121106
    set candidate = 'HENRY "WAYNE" HOWARD'
where office is not null
    and candidate = 'HENRY "WAYNE" HOWARD (I)';

update dev.ga_general_20121106
    set candidate = 'J.L. CALDWELL JR'
where office is not null
    and candidate = 'J.L. CALDWELL JR.(R)';

update dev.ga_general_20121106
    set candidate = 'JAN TANKERSLEY'
where office is not null
    and candidate = 'JAN TANKERSLEY(I)(R)';

update dev.ga_general_20121106
    set candidate = 'JOHN BARROW'
where office is not null
    and candidate = 'JOHN BARROW(I)D';

update dev.ga_general_20121106
    set candidate = 'JOHN D. CROSBY'
where office is not null
    and candidate = 'JOHN D. CROSBY(I)(R)';

update dev.ga_general_20121106
    set candidate = 'JOHN HOUSE'
where office is not null
    and candidate = 'JOHN HOUSE R';

update dev.ga_general_20121106
    set candidate = 'JOHN WILKINSON'
where office is not null
    and candidate = 'JOHN WILKINSON(I)(R)';

update dev.ga_general_20121106
    set candidate = 'LEE ANDERSON'
where office is not null
    and candidate = 'LEE ANDERSON(R)';

update dev.ga_general_20121106
    set candidate = 'LESTER G JACKSON'
where office is not null
    and candidate = 'LESTER G JACKSON(I)D';

update dev.ga_general_20121106
    set candidate = 'PAM STEPHENSON'
where office is not null
    and candidate = 'PAM STEPHENSON(I)';

update dev.ga_general_20121106
    set candidate = 'R. RAMSEY SR'
where office is not null
    and candidate = 'R. RAMSEY SR.(I)';

update dev.ga_general_20121106
    set candidate = 'ROB WOODALL'
where office is not null
    and candidate = 'ROB WOODALL (I)';

update dev.ga_general_20121106
    set candidate = 'S BEASLEY-TEAGUE'
where office is not null
    and candidate = 'S BEASLEY-TEAGUE(I)D';

update dev.ga_general_20121106
    set candidate = 'SANFORD BISHOP'
where office is not null
    and candidate = 'SANFORD BISHOP(I)D';

update dev.ga_general_20121106
    set candidate = 'STAN WISE'
where office is not null
    and candidate = 'STAN WISE (I)';

update dev.ga_general_20121106
    set candidate = 'STEPHEN ALLISON'
where office is not null
    and candidate = 'STEPHEN ALLISON(I)(R';

update dev.ga_general_20121106
    set candidate = 'T. CRAIG EARNEST'
where office is not null
    and candidate = 'T. CRAIG EARNEST(I)D';

update dev.ga_general_20121106
    set candidate = 'TIMOTHY G VAUGHN'
where office is not null
    and candidate = 'TIMOTHY G VAUGHN(I)D';

update dev.ga_general_20121106
    set candidate = 'TIMOTHY VAUGHN'
where office is not null
    and candidate = 'TIMOTHY VAUGHN(I)';

-- Remove the double double quotes from "nick name"...
update dev.ga_general_20121106
    set candidate = replace(candidate, '""', '''')
where office is not null
    and candidate like '%""%'
    and candidate not like '"%';

-- Remove the double quotes from "nick name"...
update dev.ga_general_20121106
    set candidate = replace(candidate, '"', '''')
where office is not null
    and candidate like '%"%'
    and candidate not like '"%';

-- Remove comma from candidate...
update dev.ga_general_20121106
    set candidate = replace(candidate, ',', '')
where office is not null
    and candidate like '%,%';

update dev.ga_general_20121106
    set candidate = 'ABLE M. THOMAS'
where office is not null
    and candidate = '"ABLE" M. THOMAS';

-- Remove double spaces...
update dev.ga_general_20121106
    set candidate = trim(regexp_replace(candidate, '\s+', ' ', 'g'))
where office is not null;

select input_candidate, candidate, count(*) as cnt
from dev.ga_general_20121106
where office is not null
group by input_candidate, candidate
order by input_candidate, candidate;

-- Run a few QA queries...
-- drop table dev.qc;

select county, candidate, party, office, district, min(total_votes::int) as total_votes, sum(votes::int) as votes
into dev.qc
from dev.ga_general_20121106
where office is not null
group by county, candidate, party, office, district
order by county, candidate, office, district;

select *
from dev.qc
where total_votes <> votes;

-- drop table dev.qc;

select office, district, candidate, party, sum(votes::int) as votes
from dev.ga_general_20121106
where office is not null
group by office, district, candidate, party
order by office, district, votes desc;

select *
from dev.ga_general_20121106
where office is not null
limit 500;

select count(*) as cnt
from dev.ga_general_20121106
where office is not null;
-- 163699

select 163699/4 as number_output;
-- 40924

update dev.ga_general_20121106
    set vote_type = trim(vote_type);

select vote_type, count(*) as cnt
from dev.ga_general_20121106
where office is not null
group by vote_type
order by vote_type;
-- vote_type	    cnt
-- Election Day	    37907

select count(*) as cnt
from dev.ga_general_20121106
where office is not null
    and vote_type ilike 'Absentee%';
-- 37907

select count(*) as cnt
from dev.ga_general_20121106
where office is not null
    and vote_type ilike 'Advance%';
-- 49978

-- While this number doesn't match the 37,907 it does appear that we need all of them.
-- Once we aggregate them it comes out to the 37,907 number we are looking for. See
-- the below materialized view below...

-- We do a quick QC here for advance votes...make sure they match the website...
select sum(votes::int) as sum_votes
from dev.ga_general_20121106
where office = 'President'
    and candidate = 'MITT ROMNEY'
    and vote_type ilike ('Advance%');
-- 884185

select sum(votes::int) as sum_votes
from dev.ga_general_20121106
where office = 'President'
    and candidate = 'BARACK OBAMA'
    and vote_type ilike ('Advance%');
-- 811441

select sum(votes::int) as sum_votes
from dev.ga_general_20121106
where office = 'President'
    and candidate = 'GARY JOHNSON'
    and vote_type ilike ('Advance%');
-- 10610

-- President of the United States
-- Choice	            Election Day	Absentee by Mail	Advance in Person	Provisional
-- MITT ROMNEY (R)	    1,069,214	    122,870	            884,185	            2,419
-- BARACK OBAMA (I)D	868,156	        87,487	            811,441	            6,743
-- GARY JOHNSON (L)	    32,234	        2,338	            10,610	            142

select
    relname                                               as tablename,
    to_char(seq_scan, '999,999,999,999')                  as totalseqscan,
    to_char(idx_scan, '999,999,999,999')                  as totalindexscan,
    to_char(n_live_tup, '999,999,999,999')                as tablerows,
    pg_size_pretty(pg_relation_size(relname :: regclass)) as tablesize
from pg_stat_all_tables
where schemaname = 'dev'
--     and relname = 'ga_general_20121106'
--     and 50 * seq_scan > idx_scan -- more then 2%
--     and n_live_tup > 10000
order by relname asc;

-- drop index dev.ga_general_20121106_vote_type_idx;
create index ga_general_20121106_vote_type_office_idx
    on dev.ga_general_20121106(vote_type, office);

-- Let's create some materialized views w/indexes so the below final query runs fast...
create materialized view dev.vw_election_day_voting
as
select county, precinct, office, district, party, candidate, sum(votes::int) as election_day_votes
from dev.ga_general_20121106
where office is not null
    and vote_type = 'Election Day'
group by county, precinct, office, district, party, candidate;

create index vw_election_day_voting_idx
    on dev.vw_election_day_voting(county, precinct, office, district, party, candidate);

create materialized view vw_advace_voting
as
select county, precinct, office, district, party, candidate, sum(votes::int) as advanced_votes
from dev.ga_general_20121106
where office is not null
    and vote_type ilike 'Advance%'
group by county, precinct, office, district, party, candidate;

create index vw_advace_voting_idx
    on dev.vw_advace_voting(county, precinct, office, district, party, candidate);

create materialized view vw_absentee_voting
as
select county, precinct, office, district, party, candidate, sum(votes::int) as absentee_by_mail_votes
from dev.ga_general_20121106
where office is not null
    and vote_type ilike 'Absentee%'
group by county, precinct, office, district, party, candidate

create index vw_absentee_voting_idx
    on dev.vw_absentee_voting(county, precinct, office, district, party, candidate);

create materialized view vw_provisional_voting
as
select county, precinct, office, district, party, candidate, sum(votes::int) as provisional_votes
from dev.ga_general_20121106
where office is not null
    and vote_type = 'Provisional'
group by county, precinct, office, district, party, candidate

create index vw_provisional_voting_idx
    on dev.vw_provisional_voting(county, precinct, office, district, party, candidate);


-- drop table dev.results;

-- Output final csv data...
select a.*, b.advanced_votes, c.absentee_by_mail_votes, d.provisional_votes
into dev.results
from vw_election_day_voting as a
    inner join vw_advace_voting as b
        on a.county = b.county
            and a.precinct = b.precinct
            and a.office = b.office
            and coalesce(a.district, '') = coalesce(b.district, '')
            and coalesce(a.party, '') = coalesce(b.party, '')
            and a.candidate = b.candidate
    inner join vw_absentee_voting as c
        on a.county = c.county
            and a.precinct = c.precinct
            and a.office = c.office
            and coalesce(a.district, '') = coalesce(c.district, '')
            and coalesce(a.party, '') = coalesce(c.party, '')
            and a.candidate = c.candidate
    inner join vw_provisional_voting as d
        on a.county = d.county
            and a.precinct = d.precinct
            and a.office = d.office
            and coalesce(a.district, '') = coalesce(d.district, '')
            and coalesce(a.party, '') = coalesce(d.party, '')
            and a.candidate = d.candidate
order by candidate, county, precinct;

select count(*) as cnt
from dev.results;

select count(distinct county) as num_counties
from dev.results;

select county, precinct, office, district, party, candidate, election_day_votes, advanced_votes, absentee_by_mail_votes, provisional_votes
from dev.results;

select
    office,
    district,
    candidate,
    party,
    sum(election_day_votes::int + advanced_votes::int + absentee_by_mail_votes::int + provisional_votes::int) as total_votes,
    sum(election_day_votes::int) as election_day_votes,
    sum(advanced_votes::int) as advanced_votes,
    sum(absentee_by_mail_votes::int) as absentee_by_mail_votes,
    sum(provisional_votes::int) as provisional_votes
from dev.results
group by office, district, candidate, party
order by office, district, party;

select *
from dev.results
order by office, county, district, party;

-- Tear down the materialized views...
drop materialized view vw_absentee_voting;
drop materialized view vw_advace_voting;
drop materialized view vw_election_day_voting;
drop materialized view vw_provisional_voting;
