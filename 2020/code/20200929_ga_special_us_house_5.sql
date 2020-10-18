-- drop table dev.ga_primary_special_20200929;

create table dev.ga_primary_special_20200929
    (
        county varchar(100),
        precinct varchar(100),
        input_office varchar(100),
        office varchar(100),
        district varchar(100),
        input_candidate varchar(100),
        candidate varchar(100),
        party varchar(50),
        total_votes varchar(50),
        vote_type varchar(50),
        votes varchar(50)
    );

-- truncate table dev.ga_primary_special_20200929;

select *
from dev.ga_primary_special_20200929
limit 5000;

select count(*) as cnt
from dev.ga_primary_special_20200929;
-- 7168

---------------------------------------------------------------
-- Check a couple of big races to make sure numbers match up...
---------------------------------------------------------------
select input_office, count(*) as cnt
from dev.ga_primary_special_20200929
group by input_office
order by input_office;

select input_candidate, sum(votes::int) as votes
from dev.ga_primary_special_20200929
where input_office ilike ('%US%House%')
group by input_candidate
order by input_candidate;


-- Check if we have all counties...
select county, count(*) as cnt
from dev.ga_primary_special_20200929
group by county
order by county;
-- 3 counties --> 159 - 3 = 156 not present...

with unique_counties_laoded as
(
    select distinct county
    from dev.ga_primary_special_20200929
)
select *
from dev.georgia_counties as a
    left join unique_counties_laoded as b
        on a.county = b.county
where b.county is null
order by a.county;

select party, count(*) as cnt
from dev.ga_primary_special_20200929
group by party
order by party;

-- Site has NP for everybody and I don't thing this is accurate...

-- Special fixes...
update dev.ga_primary_special_20200929
    set party = 'Democrat';

update dev.ga_primary_special_20200929
    set party = 'Libertarian'
where input_candidate ilike  '% (Lib)';

update dev.ga_primary_special_20200929
    set party = 'Independent'
where input_candidate ilike  '% (Ind)';

select input_candidate, party, sum(votes::int) as votes
from dev.ga_primary_special_20200929
group by input_candidate, party
order by input_candidate;

select party, count(*) as cnt
from dev.ga_primary_special_20200929
group by party
order by party;

select *
from dev.ga_primary_special_20200929
limit 5000;

select input_office, count(*) as cnt
from dev.ga_primary_special_20200929
group by input_office
order by input_office;

-- Move input values over...
update dev.ga_primary_special_20200929
    set candidate = trim(input_candidate);

/*
RESET...
update dev.ga_primary_special_20200929
    set candidate = null;
*/

select input_office, count(*) as cnt
from dev.ga_primary_special_20200929
group by input_office
order by input_office;

------------------------------------------------------------------------------------------------------------------------
-- Standardize Federal Offices...
------------------------------------------------------------------------------------------------------------------------
-- U.S. House
update dev.ga_primary_special_20200929
    set office = 'U.S. House',
        district = '5'
where input_office ilike '%US House%';

------------------------------------------------------------------------------------------------------------------------
-- Fix candidate names...
------------------------------------------------------------------------------------------------------------------------
-- Remove the (Dem) from candidate
update dev.ga_primary_special_20200929
    set candidate = replace(candidate, ' (Dem)', '')
where office is not null
    and candidate like '% (Dem)';

-- Remove the (Ind) from candidate
update dev.ga_primary_special_20200929
    set candidate = replace(candidate, ' (Ind)', '')
where office is not null
    and candidate like '% (Ind)';

-- Remove the (Lib) from candidate
update dev.ga_primary_special_20200929
    set candidate = replace(candidate, ' (Lib)', '')
where office is not null
    and candidate like '% (Lib)';


select input_candidate, candidate, count(*) as cnt
from dev.ga_primary_special_20200929
where office is not null
group by input_candidate, candidate
order by candidate;

-- Special Fix...
update dev.ga_primary_special_20200929
    set candidate = 'Able Mable Thomas'
where candidate = '""Able"" Mable Thomas';

-- Remove double spaces...
update dev.ga_primary_special_20200929
    set candidate = trim(regexp_replace(candidate, '\s+', ' ', 'g'))
where office is not null;

-- Remove comma from candidate...
update dev.ga_primary_special_20200929
    set candidate = replace(candidate, ',', '')
where office is not null
    and candidate like '%,%';

select candidate, input_candidate, count(*) as cnt
from dev.ga_primary_special_20200929
where office is not null
group by candidate, input_candidate
order by candidate, input_candidate;


-- Run a few QA queries...
select county, candidate, party, min(total_votes::int) as total_votes, sum(votes::int) as votes
from dev.ga_primary_special_20200929
where office is not null
group by county, candidate, party
order by county, candidate;

select office, district, candidate, party, sum(votes::int) as votes
from dev.ga_primary_special_20200929
where office is not null
group by office, district, candidate, party
order by office, district, votes desc;

select *
from dev.ga_primary_special_20200929
where office is not null
limit 500;

select count(*) as cnt
from dev.ga_primary_special_20200929
where office is not null;
-- 7168

select 7168/4 as number_output
-- 1792

-- Output final csv data...
with election_day_votes as
(
    select county, precinct, office, district, party, candidate, votes as election_day_votes
    from dev.ga_primary_special_20200929
    where office is not null
        and vote_type = 'Election Day Votes'
),
advanced_votes as
(
    select county, precinct, office, district, party, candidate, votes as advanced_votes
    from dev.ga_primary_special_20200929
    where office is not null
        and vote_type = 'Advanced Voting Votes'
),
absentee_by_mail_votes as
(
    select county, precinct, office, district, party, candidate, votes as absentee_by_mail_votes
    from dev.ga_primary_special_20200929
    where office is not null
        and vote_type = 'Absentee by Mail Votes'
),
provisional_votes as
(
    select county, precinct, office, district, party, candidate, votes as provisional_votes
    from dev.ga_primary_special_20200929
    where office is not null
        and vote_type = 'Provisional Votes'
)
select a.*, b.advanced_votes, c.absentee_by_mail_votes, d.provisional_votes
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
