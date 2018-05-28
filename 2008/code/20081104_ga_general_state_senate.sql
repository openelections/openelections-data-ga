create table ga_general_state_senate_20081104_fullnames
  (
    name varchar(50),
    last_name varchar(50),
    party varchar(50),
    district_number varchar(50),
    votes varchar(50),
    percent varchar(50)
  );

-- Run Python script here...
-- 20081104_ga_primary_state_senate_fullnames.py

truncate table ga_general_state_senate_20081104_fullnames;

select *
from ga_general_state_senate_20081104_fullnames
order by district_number::int, party, last_name;


-- Clean up some name issues and then split out the
-- last name. Finally we fix a few last names that
-- didn't parse out correctly...
update ga_general_state_senate_20081104_fullnames
  set name = replace(name, '  ', ' ');

update ga_general_state_senate_20081104_fullnames
  set last_name = split_part(name, ' ', 2);

select name, last_name
from ga_general_state_senate_20081104_fullnames
order by last_name;

update ga_general_state_senate_20081104_fullnames
  set party = 'Democrat'
where party = 'Democratic';

-- Manual fix last_name...

-- Check that we have good clean data...
select *
from ga_general_state_senate_20081104_fullnames
order by district_number::int;

---------------------------------------------------------
---------------------------------------------------------
-- Extract county votes from original data extract...

select count(*) as cnt
from votes_20081104;

select *
from votes_20080715
limit 200;

delete from votes_20081104
where candidate = 'Totals';

select office, count(*) as cnt
from votes_20081104
group by office;

select *
into state_senate_20081104
from votes_20081104
where office = 'State Senator';

select *
from state_senate_20081104
order by district::int;

update state_senate_20081104
  set district = replace(district, 'District ', '');

update state_senate_20081104
  set office = 'State Senate';

update state_senate_20081104
  set party =
    case
        when party = 'R' then 'Republican'
        when party = 'D' then 'Democrat'
        else party
    end;


alter table state_senate_20081104
    rename column candidate to last_name;

alter table state_senate_20081104
    rename column district to district_number;

alter table state_senate_20081104
    add column candidate varchar(50);

select *
from state_senate_20081104
order by district_number::int;

-- QC to make sure we are matching both sides...
select *
from ga_general_state_senate_20081104_fullnames as a
  left join state_senate_20081104 as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

-- These were missing from the original data extract...
insert into state_senate_20081104 (office, last_name, party, county, votes, district_number)
    values ('State Senate', 'Parmar', 'Write-In', 'Cherokee', 3, '21')

insert into state_senate_20081104 (office, last_name, party, county, votes, district_number)
    values ('State Senate', 'Parmar', 'Write-In', 'Cobb', 2, '21')

select *
from state_senate_20081104 as a
  left join ga_general_state_senate_20081104_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
select *
from state_senate_20081104 as a
  left join ga_general_state_senate_20081104_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
      and a.votes = b.votes::int
where b.last_name is null;

select distinct last_name, district_number
from ga_general_state_senate_20081104_county_votes;

-- Generate the final output .csv file...
select b.county as country, 'State Senate' as office,
  a.district_number as district,
  a.party,
  a.name as candidate, b.votes
--into check_results
from ga_general_state_senate_20081104_fullnames as a
  inner join state_senate_20081104 as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
order by a.district_number::int, a.party, b.county, a.name


select candidate, party, district, sum(votes::int) as votes
from check_results
group by candidate, party, district
order by district::int, candidate;