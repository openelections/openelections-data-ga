truncate table ga_primary_state_senate_20040720_fullnames;

CREATE TABLE ga_primary_state_senate_20040720_fullnames
  (
    name varchar(50),
    last_name varchar(50),
    party varchar(50),
    district_number varchar(50),
    votes varchar(50),
    percent varchar(50)
  );

select *
from ga_primary_state_senate_20040720_fullnames
order by district_number::int, party, last_name;

-- Clean up some name issues and then split out the
-- last name. Finally we fix a few last names that
-- didn't parse out correctly...
update ga_primary_state_senate_20040720_fullnames
  set name = replace(name, '  ', ' ');

update ga_primary_state_senate_20040720_fullnames
  set last_name = split_part(name, ' ', 2);

select name, last_name
from ga_primary_state_senate_20040720_fullnames
order by last_name;

update ga_primary_state_senate_20040720_fullnames
  set last_name = 'POWELL'
where rtrim(name) = 'J. B. POWELL';

update ga_primary_state_senate_20040720_fullnames
  set last_name = 'SHAFER'
where rtrim(name) = 'DAVID J. SHAFER';

update ga_primary_state_senate_20040720_fullnames
  set last_name = 'THOMAS'
where rtrim(name) = 'DON R. THOMAS';

update ga_primary_state_senate_20040720_fullnames
  set last_name = 'VON BREMEN'
where rtrim(name) = 'MIKE VON BREMEN';

-- Check that we have good clean data...
select *
from ga_primary_state_senate_20040720_fullnames
order by district_number::int;

---------------------------------------------------------
---------------------------------------------------------

truncate table ga_primary_state_senate_20040720_county_votes;

CREATE TABLE ga_primary_state_senate_20040720_county_votes
  (
    last_name varchar(50),
    party varchar(50),
    total_votes varchar(50),
    percent_votes varchar(50),
    district_number varchar(50),
    county_name varchar(50),
    county_votes varchar(50)
);

select *
from ga_primary_state_senate_20040720_county_votes
order by district_number::int desc;

select district_number, count(*) as cnt
from ga_primary_state_senate_20040720_county_votes
group by district_number
order by district_number::int;

select max(district_number::int)
from ga_primary_state_senate_20040720_county_votes;

update ga_primary_state_senate_20040720_county_votes
  set total_votes = replace(total_votes, ',', '');

update ga_primary_state_senate_20040720_county_votes
  set county_votes = replace(county_votes, ',', '');

select *
from ga_primary_state_senate_20040720_county_votes
where district_number = '12'
order by last_name;

update ga_primary_state_senate_20040720_county_votes
  set last_name = 'VON BREMEN'
where last_name = 'VON_BREMEN'
  and district_number = '12';

-- QC to make sure we are matching both sides...
select *
from ga_primary_state_senate_20040720_fullnames as a
  left join ga_primary_state_senate_20040720_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

select *
from ga_primary_state_senate_20040720_county_votes as a
  left join ga_primary_state_senate_20040720_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
select *
from ga_primary_state_senate_20040720_county_votes as a
  left join ga_primary_state_senate_20040720_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
      and a.total_votes = b.votes
where b.last_name is null;

select distinct last_name, district_number
from ga_primary_state_senate_20040720_county_votes;

-- Generate the final output .csv file...
select b.county_name as country, 'State Senate' as office,
  a.district_number as district, a.party as party,
  a.name as candidate, b.county_votes as votes
from ga_primary_state_senate_20040720_fullnames as a
  inner join ga_primary_state_senate_20040720_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
order by a.district_number::int, a.party, b.county_name, a.name

