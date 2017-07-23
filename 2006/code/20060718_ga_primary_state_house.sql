truncate table ga_primary_state_house_20060718_fullnames;

CREATE TABLE ga_primary_state_house_20060718_fullnames
  (
    name varchar(50),
    last_name varchar(50),
    party varchar(50),
    district_number varchar(50),
    votes varchar(50),
    percent varchar(50)
  );

-- Run Python script here...
-- 20060718_ga_primary_state_house_fullnames.py

select *
from ga_primary_state_house_20060718_fullnames;

-- Clean up some name issues and then split out the
-- last name. Finally we fix a few last names that
-- didn't parse out correctly...
update ga_primary_state_house_20060718_fullnames
  set name = replace(name, '  ', ' ');

update ga_primary_state_house_20060718_fullnames
  set last_name = split_part(name, ' ', 2);

select *
from ga_primary_state_house_20060718_fullnames
order by last_name;

update ga_primary_state_house_20060718_fullnames
  set last_name = 'CRIPPS'
where rtrim(name) = 'L. C. CRIPPS';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'MUMFORD'
where rtrim(name) = 'ROBERT F. MUMFORD';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'JOHNSON'
where rtrim(name) = 'D. L. JOHNSON';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'QUICK'
where rtrim(name) = 'REGINA M. QUICK';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'OLIVER'
where rtrim(name) = 'MARY M. OLIVER';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'HORGAN'
where rtrim(name) = 'MICHAEL O. HORGAN';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'VON EPPS'
where rtrim(name) = 'CARL VON EPPS';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'THOMAS'
where rtrim(name) = 'ABLE MABEL THOMAS';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'BREWSTER'
where rtrim(name) = 'EDDIE LEE BREWSTER';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'SINKFIELD',
    name = 'GEORGANNA SINKFIELD'
where rtrim(name) = 'GEORGANNA SINKFIEL';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'ABDUL-SALAAM',
    name = 'ROBERTA ABDUL-SALAAM'
where rtrim(name) = 'ROBERTA SALAAM';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'E.HOWARD'
where rtrim(name) = 'EARNESTINE HOWARD';

update ga_primary_state_house_20060718_fullnames
  set last_name = 'H.HOWARD'
where rtrim(name) = 'HENRY HOWARD';

-- Check that we have good clean data...
select *
from ga_primary_state_house_20060718_fullnames
order by last_name;

---------------------------------------------------------
---------------------------------------------------------
truncate table ga_primary_state_house_20060718_county_votes;

CREATE TABLE ga_primary_state_house_20060718_county_votes
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
-- 20060718_ga_primary_state_house_county_votes.py

select *
from ga_primary_state_house_20060718_county_votes;

update ga_primary_state_house_20060718_county_votes
  set total_votes = replace(total_votes, ',', '');

update ga_primary_state_house_20060718_county_votes
  set county_votes = replace(county_votes, ',', '');

update ga_primary_state_house_20060718_county_votes
  set last_name = 'VON EPPS'
where last_name = 'VON_EPPS';

update ga_primary_state_house_20060718_county_votes
  set last_name = 'ABDUL-SALAAM'
where last_name = 'ABDL-SALAM';

update ga_primary_state_house_20060718_county_votes
  set last_name = 'JONSON'
where last_name = 'R.JONSON';

update ga_primary_state_house_20060718_county_votes
  set last_name = 'JOHNSON'
where last_name = 'C.JONSON';

select *
from ga_primary_state_house_20060718_county_votes
order by last_name;


-- QC to make sure we are matching both sides...
select *
from ga_primary_state_house_20060718_fullnames as a
  left join ga_primary_state_house_20060718_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;


select *
from ga_primary_state_house_20060718_county_votes as a
  left join ga_primary_state_house_20060718_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
select *
from ga_primary_state_house_20060718_county_votes as a
  left join ga_primary_state_house_20060718_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
      and a.total_votes = b.votes
where b.last_name is null;

select distinct last_name, district_number
from ga_primary_state_house_20060718_county_votes;

-- Generate the final output .csv file...
select b.county_name as country, 'State House' as office,
  a.district_number as district, a.party as party,
  a.name as candidate, b.county_votes as votes
from ga_primary_state_house_20060718_fullnames as a
  inner join ga_primary_state_house_20060718_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
order by a.district_number::int, a.party, b.county_name, a.name

