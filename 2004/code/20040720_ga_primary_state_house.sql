truncate table ga_primary_state_house_20040720_fullnames;

CREATE TABLE ga_primary_state_house_20040720_fullnames
  (
    name varchar(50),
    last_name varchar(50),
    party varchar(50),
    district_number varchar(50),
    votes varchar(50),
    percent varchar(50)
  );

-- Run Python script here...
-- 20040720_ga_primary_state_house_fullnames.py

select *
from ga_primary_state_house_20040720_fullnames;

-- Clean up some name issues and then split out the
-- last name. Finally we fix a few last names that
-- didn't parse out correctly...
update ga_primary_state_house_20040720_fullnames
  set name = 'MICKEY CHANNELL'
where rtrim(name) = '''MICKEY'' CHANNELL';

update ga_primary_state_house_20040720_fullnames
  set name = replace(name, '  ', ' ');

update ga_primary_state_house_20040720_fullnames
  set last_name = split_part(name, ' ', 2);

select *
from ga_primary_state_house_20040720_fullnames
order by last_name;

update ga_primary_state_house_20040720_fullnames
  set last_name = 'SMITH'
where rtrim(name) = 'GERALD E. SMITH';

update ga_primary_state_house_20040720_fullnames
  set last_name = 'MUMFORD'
where rtrim(name) = 'ROBERT F. MUMFORD';

update ga_primary_state_house_20040720_fullnames
  set last_name = 'BUCKNER'
where rtrim(name) = 'JAMES H. BUCKNER';

update ga_primary_state_house_20040720_fullnames
  set last_name = 'JOHNSON'
where rtrim(name) = 'D. L. JOHNSON';

update ga_primary_state_house_20040720_fullnames
  set last_name = 'OLIVER'
where rtrim(name) = 'MARY M. OLIVER';

update ga_primary_state_house_20040720_fullnames
  set last_name = 'DAVIS'
where rtrim(name) = 'J. MAX DAVIS JR';

update ga_primary_state_house_20040720_fullnames
  set last_name = 'DOLLAR'
where rtrim(name) = 'ALVIN R. DOLLAR';

update ga_primary_state_house_20040720_fullnames
  set last_name = 'VON EPPS'
where rtrim(name) = 'CARL VON EPPS';

update ga_primary_state_house_20040720_fullnames
  set last_name = 'THOMAS'
where rtrim(name) = 'ABLE MABEL THOMAS';

update ga_primary_state_house_20040720_fullnames
  set last_name = 'BENNETT'
where rtrim(name) = 'G. NORMAN BENNETT';

-- Check that we have good clean data...
select *
from ga_primary_state_house_20040720_fullnames
order by last_name;

---------------------------------------------------------
---------------------------------------------------------
truncate table ga_primary_state_house_20040720_county_votes;

CREATE TABLE ga_primary_state_house_20040720_county_votes
  (
    last_name varchar(50),
    party varchar(50),
    total_votes varchar(50),
    percent_votes varchar(50),
    district_number varchar(50),
    county_name varchar(50),
    county_votes varchar(50)
);

-- Run Python script here...
-- 20040720_ga_primary_state_house_county_votes.py

select *
from ga_primary_state_house_20040720_county_votes;

update ga_primary_state_house_20040720_county_votes
  set total_votes = replace(total_votes, ',', '');

update ga_primary_state_house_20040720_county_votes
  set county_votes = replace(county_votes, ',', '');

update ga_primary_state_house_20040720_county_votes
  set last_name = 'VON EPPS'
where last_name = 'VON_EPPS';

select *
from ga_primary_state_house_20040720_county_votes
order by last_name;

update ga_primary_state_house_20040720_county_votes
  set last_name = 'SHACKELFORD'
where last_name = 'SHACKELFRD'
  and district_number = '143';

update ga_primary_state_house_20040720_county_votes
  set last_name = 'DOUBLESTEIN'
where last_name = 'DOUBLESTN'
  and district_number = '95';


-- QC to make sure we are matching both sides...
select *
from ga_primary_state_house_20040720_fullnames as a
  left join ga_primary_state_house_20040720_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

select *
from ga_primary_state_house_20040720_county_votes as a
  left join ga_primary_state_house_20040720_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
select *
from ga_primary_state_house_20040720_county_votes as a
  left join ga_primary_state_house_20040720_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
      and a.total_votes = b.votes
where b.last_name is null;

select distinct last_name, district_number
from ga_primary_state_house_20040720_county_votes;

-- Generate the final output .csv file...
select b.county_name as country, 'State House' as office,
  a.district_number as district, a.party as party,
  a.name as candidate, b.county_votes as votes
from ga_primary_state_house_20040720_fullnames as a
  inner join ga_primary_state_house_20040720_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
order by a.district_number::int, a.party, b.county_name, a.name

