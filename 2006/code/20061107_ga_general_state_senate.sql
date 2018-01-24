create table ga_general_state_senate_20061107_fullnames
  (
    name varchar(50),
    last_name varchar(50),
    party varchar(50),
    district_number varchar(50),
    votes varchar(50),
    percent varchar(50)
  );

-- Run Python script here...
-- 20061107_ga_primary_state_senate_fullnames.py

truncate table ga_general_state_senate_20061107_fullnames;

select *
from ga_general_state_senate_20061107_fullnames
order by district_number::int, party, last_name;


-- Clean up some name issues and then split out the
-- last name. Finally we fix a few last names that
-- didn't parse out correctly...
update ga_general_state_senate_20061107_fullnames
  set name = replace(name, '  ', ' ');

update ga_general_state_senate_20061107_fullnames
  set last_name = split_part(name, ' ', 2);

select name, last_name
from ga_general_state_senate_20061107_fullnames
order by last_name;

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Powell'
where rtrim(name) = 'J. B. Powell';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Ramsey'
where rtrim(name) = 'Ronald B. Ramsey, Sr.';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Thomas'
where rtrim(name) = 'Regina D. Thomas';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Fort'
where rtrim(name) = 'Vincent D. Fort';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Gilbert'
where rtrim(name) = 'Bruce E. Gilbert';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Wiles'
where rtrim(name) = 'John J. Wiles';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'DeLoach'
where rtrim(name) = 'George L DeLoach';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Thomas'
where rtrim(name) = 'Don R. Thomas';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Thomas'
where rtrim(name) = 'Joe R. Thomas';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Meyer von Bremen'
where rtrim(name) = 'Michael S. Meyer von Bremen';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Unterman'
where rtrim(name) = 'Renee S. Unterman';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Hudgens'
where rtrim(name) = 'Ralph T. Hudgens';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Grant'
where rtrim(name) = 'Mark T. Grant';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Kidd'
where rtrim(name) = 'Jane V. Kidd';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Smith'
where rtrim(name) = 'Preston W. Smith';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Whitehead'
where rtrim(name) = 'Jim Whitehead, Sr.';

update ga_general_state_senate_20061107_fullnames
  set last_name = 'Anderson'
where rtrim(name) = 'Evelyn Thompson Anderson';


-- Check that we have good clean data...
select *
from ga_general_state_senate_20061107_fullnames
order by district_number::int;

---------------------------------------------------------
---------------------------------------------------------

truncate table ga_general_state_senate_20061107_county_votes;

create table ga_general_state_senate_20061107_county_votes
  (
    last_name varchar(50),
    party varchar(50),
    total_votes varchar(50),
    district_number varchar(50),
    county_name varchar(50),
    county_votes varchar(50)
);

-- Run Python script here...
-- 20060718_ga_primary_state_senate_county_votes.py

select *
from ga_general_state_senate_20061107_county_votes
order by district_number::int desc;

select district_number, count(*) as cnt
from ga_general_state_senate_20061107_county_votes
group by district_number
order by district_number::int;

-- QC to make sure we are matching both sides...
select *
from ga_general_state_senate_20061107_fullnames as a
  left join ga_general_state_senate_20061107_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

select *
from ga_general_state_senate_20061107_county_votes as a
  left join ga_general_state_senate_20061107_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
select *
from ga_general_state_senate_20061107_county_votes as a
  left join ga_general_state_senate_20061107_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
      and a.total_votes = b.votes
where b.last_name is null;

select distinct last_name, district_number
from ga_general_state_senate_20061107_county_votes;

-- Generate the final output .csv file...
select b.county_name as country, 'State Senate' as office,
  a.district_number as district,
  CASE
    when a.party = 'R'
      then 'Republican'
    when a.party = 'D'
      then 'Democrat'
  end as party,
  a.name as candidate, b.county_votes as votes
--into check_results
from ga_general_state_senate_20061107_fullnames as a
  inner join ga_general_state_senate_20061107_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
order by a.district_number::int, a.party, b.county_name, a.name


select candidate, party, district, sum(votes::int) as votes
from check_results
group by candidate, party, district
order by district::int, candidate;