create table ga_general_state_house_20061107_fullnames
  (
    name varchar(50),
    last_name varchar(50),
    party varchar(50),
    district_number varchar(50),
    votes varchar(50),
    percent varchar(50)
  );

-- Run Python script here...
-- 20061107_ga_primary_state_house_fullnames.py

truncate table ga_general_state_house_20061107_fullnames;

select *
from ga_general_state_house_20061107_fullnames
order by district_number::int, party, last_name;


-- Clean up some name issues and then split out the
-- last name. Finally we fix a few last names that
-- didn't parse out correctly...
update ga_general_state_house_20061107_fullnames
  set name = replace(name, '  ', ' ');

update ga_general_state_house_20061107_fullnames
  set last_name = split_part(name, ' ', 2);

select name, last_name
from ga_general_state_house_20061107_fullnames
order by last_name;

-- Just used DataGrip to edit any records that didn't
-- get a clean split...

-- Check that we have good clean data...
select *
from ga_general_state_house_20061107_fullnames
order by district_number::int;

---------------------------------------------------------
---------------------------------------------------------

truncate table ga_general_state_house_20061107_county_votes;

create table ga_general_state_house_20061107_county_votes
  (
    last_name varchar(50),
    party varchar(50),
    total_votes varchar(50),
    district_number varchar(50),
    county_name varchar(50),
    county_votes varchar(50)
);

-- Run Python script here...
-- 20060718_ga_primary_state_house_county_votes.py

select *
from ga_general_state_house_20061107_county_votes
order by district_number::int desc;

select *
from ga_general_state_house_20061107_county_votes
order by last_name;


select district_number, count(*) as cnt
from ga_general_state_house_20061107_county_votes
group by district_number
order by district_number::int;

-- QC to make sure we are matching both sides...
select a.*
from ga_general_state_house_20061107_fullnames as a
  left join ga_general_state_house_20061107_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

select *
from ga_general_state_house_20061107_county_votes as a
  left join ga_general_state_house_20061107_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
select *
from ga_general_state_house_20061107_county_votes as a
  left join ga_general_state_house_20061107_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
      and a.total_votes = b.votes
where b.last_name is null;

select distinct last_name, district_number
from ga_general_state_house_20061107_county_votes;

drop table check_results;

-- Generate the final output .csv file...
select b.county_name as country, 'State House' as office,
  a.district_number as district,
  case
    when a.party = 'R'
      then 'Republican'
    when a.party = 'D'
      then 'Democrat'
  end as party,
  a.name as candidate, b.county_votes as votes
into check_results
from ga_general_state_house_20061107_fullnames as a
  inner join ga_general_state_house_20061107_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
order by a.district_number::int, a.party, b.county_name, a.name


select candidate, party, district, sum(votes::int) as votes
from check_results
group by candidate, party, district
order by district::int, candidate;