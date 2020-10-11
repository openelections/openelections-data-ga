-- drop table dev.ga_general_20120731;

create table dev.ga_general_20120731
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

-- truncate table dev.ga_general_20120731;

select *
from dev.ga_general_20120731
limit 5000;

select count(*) as cnt
from dev.ga_general_20120731;
-- 1006243

---------------------------------------------------------------
-- Check a couple of big races to make sure numbers match up...
---------------------------------------------------------------
select input_office, count(*) as cnt
from dev.ga_general_20120731
group by input_office
order by input_office;

select input_candidate, sum(votes::int) as votes
from dev.ga_general_20120731
-- where input_office ilike ('%US%House%')
group by input_candidate
order by input_candidate;


-- Check if we have all counties...
select county, count(*) as cnt
from dev.ga_general_20120731
group by county
order by county;
-- 154

with unique_counties_laoded as
(
    select distinct county
    from dev.ga_general_20120731
)
select *
from dev.georgia_counties as a
    left join unique_counties_laoded as b
        on a.county = b.county
where b.county is null
order by a.county;
-- Missing (5) counties; Coweta, Dooly, Lowndes, McIntosh & Oglethorpe...these just don't have xml files...
------------------------------------------------------------------------------------------------------------------------
-- This is the fix for the missing (5) counties...
------------------------------------------------------------------------------------------------------------------------
-- drop table dev.ga_general_20120731_fix

select office, count(*) as cnt
from dev.ga_general_20120731_original
group by office
order by office;

select *
into dev.ga_general_20120731_fix
from dev.ga_general_20120731_original
where county in ('Coweta', 'Dooly', 'Lowndes', 'McIntosh', 'Oglethorpe');

select office, count(*) as cnt
from dev.ga_general_20120731_fix
group by office
order by office;

-- Fix offices...
update dev.ga_general_20120731_fix
    set office = 'Public Service Commissioner'
where office = 'Public Service Commission';

update dev.ga_general_20120731_fix
    set office = 'State House'
where office = 'State Representative';

update dev.ga_general_20120731_fix
    set office = 'U.S. House'
where office = 'U.S. Representative';

select *
from dev.ga_general_20120731_fix;

delete from dev.ga_general_20120731_fix
where precinct is null;

update dev.ga_general_20120731_fix
    set district = trim(replace(district, 'District', ''));

update dev.ga_general_20120731_fix
    set party = 'Republican'
where party = 'REP';

update dev.ga_general_20120731_fix
    set party = 'Democrat'
where party = 'DEM';

update dev.ga_general_20120731_fix
    set party = 'Nonpartisan'
where party = 'NP';

select *
from dev.ga_general_20120731_fix;

-- Remove the Incumbent (I) from candidate
update dev.ga_general_20120731_fix
    set candidate = replace(candidate, ' (I)', '')
where office is not null
    and candidate like '% (I)';

select office, district, count(*) as cnt
from dev.ga_general_20120731_fix
group by office, district
order by office, district;

select county, precinct, count(*) as cnt
from dev.ga_general_20120731_fix
group by county, precinct
order by county, precinct;

select *
from dev.ga_general_20120731_fix;

select candidate, count(*) as cnt
from dev.ga_general_20120731_fix
where office is not null
group by candidate
order by candidate;

-- Fix "CHIP" FLANEGAN...
update dev.ga_general_20120731_fix
    set candidate = 'CHIP FLANEGAN'
where candidate = '"CHIP" FLANEGAN';

select *
from dev.ga_general_20120731_fix;

------------------------------------------------------------------------------------------------------------------------
-- End of the fix...
------------------------------------------------------------------------------------------------------------------------

select party, count(*) as cnt
from dev.ga_general_20120731
group by party
order by party;

-- Clean-up the data...
update dev.ga_general_20120731
    set party = 'Republican'
where party = 'REP';

update dev.ga_general_20120731
    set party = 'Democrat'
where party = 'DEM';

update dev.ga_general_20120731
    set party = 'Nonpartisan'
where party = 'NP';

select party, count(*) as cnt
from dev.ga_general_20120731
group by party
order by party;

select *
from dev.ga_general_20120731
limit 5000;

select input_office, count(*) as cnt
from dev.ga_general_20120731
group by input_office
order by input_office;

/*
OFFICES:
- Appeals Court Judge
- District Attorney
- Public Service Commission
- State Representative
- State Senator
- Superior Court Judge
- Supreme Court Justice
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
from dev.ga_general_20120731
where input_office ilike '%U.S. Representative%';

update dev.ga_general_20120731
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
from dev.ga_general_20120731
where input_office ilike '%State Senator%';

update dev.ga_general_20120731
    set office = 'State Senate',
        district = trim((regexp_split_to_array(input_office, ' '))[4])
where input_office ilike '%State Senator%';

-- State House
select
    input_office,
    'State House' as office,
    trim((regexp_split_to_array(input_office, ' '))[4]) as district
from dev.ga_general_20120731
where input_office ilike '%State Representative%';

update dev.ga_general_20120731
    set office = 'State House',
        district = trim((regexp_split_to_array(input_office, ' '))[4])
where input_office ilike '%State Representative%';

-- District Attorney
select
    input_office,
    'District Attorney' as office,
    trim((regexp_split_to_array(input_office, ','))[2]) as district
from dev.ga_general_20120731
where input_office ilike '%District Attorney%';

update dev.ga_general_20120731
    set office = 'District Attorney',
        district = trim((regexp_split_to_array(input_office, ','))[2])
where input_office ilike '%District Attorney%';

update dev.ga_general_20120731
    set district = replace(district, ' - DEM', '')
where input_office ilike '%District Attorney%';

update dev.ga_general_20120731
    set district = replace(district, ' - REP', '')
where input_office ilike '%District Attorney%';

select *
from dev.ga_general_20120731
where input_office ilike '%District Attorney%';

-- Superior Court Judge
select
    candidate,
    input_office,
    'Superior Court Judge' as office,
    trim((regexp_split_to_array(input_office, ','))[2]) as district
from dev.ga_general_20120731
where input_office ilike 'Superior Court Judge%';

update dev.ga_general_20120731
    set office = 'Superior Court Judge',
        district = trim((regexp_split_to_array(input_office, ','))[2])
where input_office ilike 'Superior Court Judge%';

select
    candidate,
    input_office,
    'Superior Court Judge' as office,
    trim((regexp_split_to_array(district, '\('))[1]) as new_district
from dev.ga_general_20120731
where input_office ilike 'Superior Court Judge%';

update dev.ga_general_20120731
    set district = trim((regexp_split_to_array(district, '\('))[1])
where input_office ilike 'Superior Court Judge%';

select
    candidate,
    input_office,
    office,
    district
from dev.ga_general_20120731
where input_office ilike 'Superior Court Judge%';

-- Supreme Court Justice
select
    candidate,
    input_office,
    'Supreme Court Justice' as office,
    trim((regexp_split_to_array(input_office, ','))[2]) as district
from dev.ga_general_20120731
where input_office ilike 'Supreme Court Justice%';

update dev.ga_general_20120731
    set office = 'Supreme Court Justice',
        district = trim((regexp_split_to_array(input_office, ','))[2])
where input_office ilike 'Supreme Court Justice%';

-- Appeals Court Judge
select
    candidate,
    input_office,
    'Appeals Court Judge' as office,
    trim((regexp_split_to_array(input_office, ','))[2]) as district
from dev.ga_general_20120731
where input_office ilike 'Appeals Court Judge%';

update dev.ga_general_20120731
    set office = 'Appeals Court Judge',
        district = trim((regexp_split_to_array(input_office, ','))[2])
where input_office ilike 'Appeals Court Judge%';

-- Public Service Commissioner
select
    candidate,
    input_office,
    'Public Service Commissioner' as office,
    trim((regexp_split_to_array(input_office, ' '))[5]) as district
from dev.ga_general_20120731
where input_office ilike 'Public Service Commission%';

update dev.ga_general_20120731
    set office = 'Public Service Commissioner',
        district = trim((regexp_split_to_array(input_office, ' '))[5])
where input_office ilike 'Public Service Commission%';



select office, district, input_office, count(*) as cnt
from dev.ga_general_20120731
where office is not null
group by office, district, input_office
order by office, district, input_office;

-- Double check whats left...
select input_office, count(*) as cnt
from dev.ga_general_20120731
where office is null
group by input_office
order by input_office;

------------------------------------------------------------------------------------------------------------------------
-- Fix candidate names...
------------------------------------------------------------------------------------------------------------------------
-- Move input values over...
update dev.ga_general_20120731
    set candidate = trim(input_candidate);

/*
RESET...
update dev.ga_general_20120731
    set candidate = null;
*/

select candidate, count(*) as cnt
from dev.ga_general_20120731
group by candidate
order by candidate;

-- Remove the Incumbent (I) from candidate
update dev.ga_general_20120731
    set candidate = replace(candidate, ' (I)', '')
where office is not null
    and candidate like '% (I)';

-- Remove the double double quotes from "nick name"...
update dev.ga_general_20120731
    set candidate = replace(candidate, '""', '''')
where office is not null
    and candidate like '%""%'
    and candidate not like '"%';

-- Remove the double quotes from "nick name"...
update dev.ga_general_20120731
    set candidate = replace(candidate, '"', '''')
where office is not null
    and candidate like '%"%'
    and candidate not like '"%';

-- Remove the Incumbent (I from candidate
update dev.ga_general_20120731
    set candidate = replace(candidate, ' (I', '')
where office is not null
    and candidate like '% (I';

-- Remove the Incumbent (I from candidate
update dev.ga_general_20120731
    set candidate = replace(candidate, '(I)', '')
where office is not null
    and candidate like '%(I)';

select candidate, count(*) as cnt
from dev.ga_general_20120731
where office is not null
group by candidate
order by candidate;

select *
from dev.ga_general_20120731
where office is not null
    and candidate like '%,%';

-- Remove comma from candidate...
update dev.ga_general_20120731
    set candidate = replace(candidate, ',', '')
where office is not null
    and candidate like '%,%';

-- Remove double spaces...
update dev.ga_general_20120731
    set candidate = trim(regexp_replace(candidate, '\s+', ' ', 'g'))
where office is not null;

select candidate, input_candidate, count(*) as cnt
from dev.ga_general_20120731
where office is not null
group by candidate, input_candidate
order by candidate, input_candidate;

-- Manually Fix a some candidates...
update dev.ga_general_20120731
    set candidate = 'ABLE MABLE THOMAS'
where candidate = '"ABLE" MABLE THOMAS';

update dev.ga_general_20120731
    set candidate = 'CHIP FLANEGAN'
where candidate = '"CHIP" FLANEGAN';

update dev.ga_general_20120731
    set candidate = 'BILL HAMRICK'
where candidate = 'BILL HAMRICK (Incumb';

update dev.ga_general_20120731
    set candidate = 'C ''CHUCK'' SEELIGER'
where candidate = 'C ''CHUCK'' SEELIGER I';

update dev.ga_general_20120731
    set candidate = 'CALVIN SMYRE'
where candidate = 'CALVIN SMYRE (Incumb';

update dev.ga_general_20120731
    set candidate = 'CARSON D PERKINS'
where candidate = 'CARSON D. PERKINS(I_';

update dev.ga_general_20120731
    set candidate = 'CHUCK EATON'
where candidate = 'CHUCK EATON (Incumbe';

update dev.ga_general_20120731
    set candidate = 'CURRIE MINGLEDORFF'
where candidate = 'CURRIE MINGLEDORFF(I';

update dev.ga_general_20120731
    set candidate = 'D DAWKINS-HAIGLER'
where candidate = 'D. DAWKINS-HAIGLER(I';

update dev.ga_general_20120731
    set candidate = 'DAVID L. DICKINSON'
where candidate = 'DAVID L. DICKINSON(I';

update dev.ga_general_20120731
    set candidate = 'DAVID RALSTON'
where candidate = 'DAVID RALSTON (Incum';

update dev.ga_general_20120731
    set candidate = 'H. G. FLANDERS JR.'
where candidate = 'H. G. FLANDERS JR.(I';

update dev.ga_general_20120731
    set candidate = 'H. PATRICK HAGGARD'
where candidate = 'H. PATRICK HAGGARD(I';

update dev.ga_general_20120731
    set candidate = 'H. WINGFIELD III'
where candidate = 'H. WINGFIELD IIl';

update dev.ga_general_20120731
    set candidate = 'HENRY JOHNSON JR.'
where candidate = 'HENRY JOHNSON JR.(I';

update dev.ga_general_20120731
    set candidate = 'HORACE JOHNSON JR.'
where candidate = 'HORACE JOHNSON JR.(I';

update dev.ga_general_20120731
    set candidate = 'HUGH P. THOMPSON'
where candidate = 'HUGH P. THOMPSON (In';

update dev.ga_general_20120731
    set candidate = 'JAMES L. CLINE JR.'
where candidate = 'JAMES L. CLINE JR.(I';

update dev.ga_general_20120731
    set candidate = 'JOHN BULLOCH'
where candidate = 'JOHN BULLOCH (Incumb';

update dev.ga_general_20120731
    set candidate = 'JOHN J. ELLINGTON'
where candidate = 'JOHN J. ELLINGTON(I';

update dev.ga_general_20120731
    set candidate = 'LAWTON E. STEPHENS'
where candidate = 'LAWTON E. STEPHENS(I';

update dev.ga_general_20120731
    set candidate = 'RICHARD A. MALLARD'
where candidate = 'RICHARD A. MALLARD(I';

update dev.ga_general_20120731
    set candidate = 'ROBERT LAVENDER'
where candidate = 'ROBERT LAVENDER (l)';

update dev.ga_general_20120731
    set candidate = 'ROGER DUNAWAY JR.'
where candidate = 'ROGER DUNAWAY JR.(I';

update dev.ga_general_20120731
    set candidate = 'Write-in'
where candidate = 'Write-in 20';

select candidate, input_candidate, count(*) as cnt
from dev.ga_general_20120731
where office is not null
group by candidate, input_candidate
order by candidate, input_candidate;


-- Run a few QA queries...
-- drop table dev.qc;

select county, candidate, party, office, district, min(total_votes::int) as total_votes, sum(votes::int) as votes
into dev.qc
from dev.ga_general_20120731
where office is not null
group by county, candidate, party, office, district
order by county, candidate, office, district;


select *
from dev.qc
where total_votes <> votes;

-- drop table dev.qc;

select *
from dev.ga_general_20120731
where county = 'Walker'
    and office = 'Superior Court Judge'
    and district = 'Lookout Mountain Circuit';

select office, district, candidate, party, sum(votes::int) as votes
from dev.ga_general_20120731
where office is not null
group by office, district, candidate, party
order by office, district, votes desc;

select *
from dev.ga_general_20120731
where office is not null
limit 500;

select count(*) as cnt
from dev.ga_general_20120731
where office is not null;
-- 459099

select 459099/4 as number_output
-- 114774

select vote_type, count(*) as cnt
from dev.ga_general_20120731
where office is not null
group by vote_type
order by vote_type;
-- 107842

select 88497+19345

-- Check advanced voting...
select sum(votes::int) as sum_votes
from dev.ga_general_20120731
where office = 'Public Service Commissioner'
    and candidate = 'CHUCK EATON'
    and vote_type ilike ('Advance%')

select sum(advance_in_person::int) as sum_votes
from dev.ga_general_20120731_fix
where office = 'Public Service Commissioner'
    and candidate = 'CHUCK EATON';

select 118657+3956


-- Check advanced voting...
select sum(votes::int) as sum_votes
from dev.ga_general_20120731
where office = 'Public Service Commissioner'
    and candidate = 'CHUCK EATON'
    and vote_type ilike ('Absentee%')

select sum(absentee_by_mail::int) as sum_votes
from dev.ga_general_20120731_fix
where office = 'Public Service Commissioner'
    and candidate = 'CHUCK EATON';

select 19483+591



select count(*) as cnt
from dev.ga_general_20120731
where office is not null
    and vote_type ilike 'Advance in Person%';
-- 135573

select count(*) as cnt
from dev.ga_general_20120731
where office is not null
    and vote_type ilike 'Absentee%';
-- 107842


-- drop table dev.results;


-- Output final csv data...
with election_day_votes as
(
    select county, precinct, office, district, party, candidate, sum(votes::int) as election_day_votes
    -- select count(distinct concat(county, precinct, office, district, party, candidate)) as cnt
    from dev.ga_general_20120731
    where office is not null
        and vote_type = 'Election Day'
    group by county, precinct, office, district, party, candidate
),
advanced_votes as
(
    select county, precinct, office, district, party, candidate, sum(votes::int) as advanced_votes
    -- select count(distinct concat(county, precinct, office, district, party, candidate)) as cnt
    from dev.ga_general_20120731
    where office is not null
--         and vote_type in ('Advance in Person', 'Advance in Person 1')
        and vote_type ilike 'Advance%'
    group by county, precinct, office, district, party, candidate
),
absentee_by_mail_votes as
(
    select county, precinct, office, district, party, candidate, sum(votes::int) as absentee_by_mail_votes
    -- select count(distinct concat(county, precinct, office, district, party, candidate)) as cnt
    from dev.ga_general_20120731
    where office is not null
        and vote_type ilike 'Absentee%'
    group by county, precinct, office, district, party, candidate
),
provisional_votes as
(
    select county, precinct, office, district, party, candidate, sum(votes::int) as provisional_votes
    -- select count(distinct concat(county, precinct, office, district, party, candidate)) as cnt
    from dev.ga_general_20120731
    where office is not null
        and vote_type = 'Provisional'
    group by county, precinct, office, district, party, candidate
)
select a.*, b.advanced_votes, c.absentee_by_mail_votes, d.provisional_votes
into dev.results
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
order by candidate, county, precinct;

select count(*) as cnt
from dev.results;

select count(distinct county) as num_counties
from dev.results;

select county, precinct, office, district, party, candidate, election_day_votes, advanced_votes, absentee_by_mail_votes, provisional_votes
from dev.results;

select *
from dev.ga_general_20120731_fix;

insert into dev.results
    (county, precinct, office, district, party, candidate, election_day_votes, advanced_votes, absentee_by_mail_votes, provisional_votes)
select county, precinct, office, district, party, candidate, election_day, advance_in_person, absentee_by_mail, provisional
from dev.ga_general_20120731_fix;

select count(distinct county) as num_counties
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
order by office, district, candidate;

select *
from dev.results;
