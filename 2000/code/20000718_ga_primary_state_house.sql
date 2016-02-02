--truncate table ga_primary_state_house_20000718_fullnames

CREATE TABLE ga_primary_state_house_20000718_fullnames
  (
    name varchar(50),
    last_name varchar(50),
    party varchar(50),
    district_number varchar(50),
    votes varchar(50),
    percent varchar(50)
  );

select *
from ga_primary_state_house_20000718_fullnames

-- Clean up some name issues and then split out the
-- last name. Finally we fix a few last names that
-- didn't parse out correctly...
update ga_primary_state_house_20000718_fullnames
  set name = replace(name, '  ', ' ');

update ga_primary_state_house_20000718_fullnames
  set last_name = split_part(name, ' ', 2)
where strpos(name, 'VON EPPS') = 0;

update ga_primary_state_house_20000718_fullnames
  set last_name = 'STANLEY'
where rtrim(name) = 'PAMELA A. STANLEY';

update ga_primary_state_house_20000718_fullnames
  set last_name = 'TURNQUEST'
where rtrim(name) = 'H. E TURNQUEST';

update ga_primary_state_house_20000718_fullnames
  set last_name = 'GREENE'
where rtrim(name) = 'GERALD E. GREENE';

update ga_primary_state_house_20000718_fullnames
  set last_name = 'BARBREE'
where rtrim(name) = 'CAROLYN B. BARBREE';

update ga_primary_state_house_20000718_fullnames
  set last_name = 'VON EPPS'
where rtrim(name) = 'CARL VON EPPS';

-- Check that we have good clean data...
select *
from ga_primary_state_house_20000718_fullnames
order by last_name;

---------------------------------------------------------
---------------------------------------------------------

-- truncate table ga_primary_state_house_20000718_county_votes

CREATE TABLE ga_primary_state_house_20000718_county_votes
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
from ga_primary_state_house_20000718_county_votes;

update ga_primary_state_house_20000718_county_votes
  set total_votes = replace(total_votes, ',', '');

update ga_primary_state_house_20000718_county_votes
  set county_votes = replace(county_votes, ',', '');

update ga_primary_state_house_20000718_county_votes
  set last_name = 'VON EPPS'
where last_name = 'VON_EPPS';

update ga_primary_state_house_20000718_county_votes
  set last_name = 'WESTMORELAND'
where last_name = 'WESTMORLND'
  and district_number = '104';

update ga_primary_state_house_20000718_county_votes
  set last_name = 'BILLINGSLEA'
where last_name = 'BILLNGSLEA'
  and district_number = '96';

-- This person got zero votes and is not in the fullname website...
delete from ga_primary_state_house_20000718_county_votes
where last_name = 'COOPER'
  and district_number = '86'
  and total_votes = '0';

-- QC to make sure we are matching both sides...
select *
from ga_primary_state_house_20000718_fullnames as a
  left join ga_primary_state_house_20000718_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

select *
from ga_primary_state_house_20000718_county_votes as a
  left join ga_primary_state_house_20000718_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
select *
from ga_primary_state_house_20000718_county_votes as a
  left join ga_primary_state_house_20000718_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
      and a.total_votes = b.votes
where b.last_name is null;

select distinct last_name, district_number
from ga_primary_state_house_20000718_county_votes;

-- Generate the final output .csv file...
select b.county_name as country, 'State House' as office,
  a.district_number as district, a.party as party,
  a.name as candidate, b.county_votes as votes
from ga_primary_state_house_20000718_fullnames as a
  inner join ga_primary_state_house_20000718_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
order by a.district_number::int, a.party, b.county_name, a.name

