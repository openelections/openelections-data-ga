select *
from ga_primary_state_senate_20100720_fullnames
order by district, party, candidate;

alter table ga_primary_state_senate_20100720_fullnames
    add column last_name text;

update ga_primary_state_senate_20100720_fullnames
  set last_name = split_part(candidate, ' ', 2);

select district, candidate, last_name
from ga_primary_state_senate_20100720_fullnames
order by last_name;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Johnson'
where rtrim(candidate) = 'Jordan ''Alex'' Johnson'
    and district = 41;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Pollard'
where rtrim(candidate) = 'Frances ''Beth'' Pollard'
    and district = 6;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Carter'
where rtrim(candidate) = 'Earl ''Buddy'' Carter'
    and district = 1;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Hurst'
where rtrim(candidate) = 'Joseph ''Joe'' Hurst'
    and district = 29;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Billingslea'
where rtrim(candidate) = 'Zannie (Tiger) Billingslea'
    and district = 34;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Ramsey'
where rtrim(candidate) = 'Ronald B. Ramsey, Sr.'
    and district = 43;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Belle Isle'
where rtrim(candidate) = 'David Christian Belle Isle'
    and district = 56;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Fleming'
where rtrim(candidate) = 'Ester Fleming, Jr'
    and district = 17;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Jackson'
where rtrim(candidate) = 'Lester G. Jackson'
    and district = 2;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Bennett'
where rtrim(candidate) = 'Tracy Gene Bennett'
    and district = 31;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Wiles'
where rtrim(candidate) = 'John J. Wiles'
    and district = 37;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Griffin'
where rtrim(candidate) = 'Floyd L. Griffin'
    and district = 25;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Johnson'
where rtrim(candidate) = 'Torrey O. Johnson'
    and district = 35;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Day'
where rtrim(candidate) = 'Nicholas P. Day'
    and district = 17;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Jackson'
where rtrim(candidate) = 'William S.(Bill) Jackson'
    and district = 24;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Ligon'
where rtrim(candidate) = 'William T. Ligon Jr.'
    and district = 3;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Anderson'
where rtrim(candidate) = 'Evelyn Thompson Anderson'
    and district = 29;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Sims'
where rtrim(candidate) = 'Freddie Powell Sims'
    and district = 12;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Unterman'
where rtrim(candidate) = 'Renee S. Unterman'
    and district = 45;

-- Match vote counts...
update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Powell Sims'
where rtrim(candidate) = 'Freddie Powell Sims'
    and district = 12;

update ga_primary_state_senate_20100720_fullnames
  set last_name = 'Crosby'
where rtrim(candidate) = 'John Dickey Crosby'
    and district = 13;


select district, candidate, last_name
from ga_primary_state_senate_20100720_fullnames
order by last_name;

-- Check that we have good clean data...
select *
from ga_primary_state_senate_20100720_fullnames
order by district, party;

---------------------------------------------------------
---------------------------------------------------------
-- drop table ga_primary_state_senate_20100720_county_votes;
-- truncate table ga_primary_state_senate_20100720_county_votes;

create table ga_primary_state_senate_20100720_county_votes
  (
    district int,
    party text,
    last_name text,
    total_votes int,
    county_name text,
    county_votes int
);

-- Run Python script here...
-- 20060718_ga_primary_state_senate_county_votes.py

select *
from ga_primary_state_senate_20100720_county_votes
order by district, party, last_name, county_name;

-------------------------------------------------------------------------------
-- QC Checks
-------------------------------------------------------------------------------
-- Check votes...
with votes as
(
    select district, party, last_name,
    max(total_votes) as total_votes,
        sum(county_votes) as agg_total_votes
    from ga_primary_state_senate_20100720_county_votes
    group by district, party, last_name
)
select *
from votes
where total_votes <> agg_total_votes;

update ga_primary_state_senate_20100720_county_votes
  set last_name = 'McKoon'
where last_name = 'Mckoon'
  and district = 29;

-- QC to make sure we are matching both sides...
select *
from ga_primary_state_senate_20100720_county_votes as a
  left join ga_primary_state_senate_20100720_fullnames as b
    on a.last_name = b.last_name
      and a.district = b.district
      and a.party = b.party
where b.last_name is null;

select *
from ga_primary_state_senate_20100720_fullnames as a
  left join ga_primary_state_senate_20100720_county_votes as b
    on a.last_name = b.last_name
      and a.district = b.district
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
select *
from ga_primary_state_senate_20100720_county_votes as a
  left join ga_primary_state_senate_20100720_fullnames as b
    on a.last_name = b.last_name
      and a.district = b.district
      and a.party = b.party
      and a.total_votes = b.total_votes
where b.last_name is null;

-- Generate the final output .csv file...
select b.county_name as country, 'State Senate' as office,
  a.district, a.party as party, a.candidate, b.county_votes as votes
from ga_primary_state_senate_20100720_fullnames as a
  inner join ga_primary_state_senate_20100720_county_votes as b
    on a.last_name = b.last_name
      and a.district = b.district
      and a.party = b.party
order by a.district, a.party, b.county_name, a.candidate