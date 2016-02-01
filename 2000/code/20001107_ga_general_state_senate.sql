truncate table ga_general_state_senate_20001107_fullnames

CREATE TABLE ga_general_state_senate_20001107_fullnames
  (
    name varchar(50),
    last_name varchar(50),
    party varchar(50),
    district_number varchar(50),
    votes varchar(50),
    percent varchar(50)
  );

select *
from ga_general_state_senate_20001107_fullnames;

-- Clean up some name issues and then split out the
-- last name. Finally we fix a few last names that
-- didn't parse out correctly...
update ga_general_state_senate_20001107_fullnames
  set name = replace(name, '  ', ' ');

update ga_general_state_senate_20001107_fullnames
  set last_name = split_part(name, ' ', 2);

update ga_general_state_senate_20001107_fullnames
  set last_name = 'BRUSH'
where rtrim(name) = 'BEN ''JOEY'' BRUSH';

update ga_general_state_senate_20001107_fullnames
  set last_name = 'STARR'
where rtrim(name) = 'TERRELL A. STARR';

update ga_general_state_senate_20001107_fullnames
  set last_name = 'MORING'
where rtrim(name) = 'FELIX C. MORING';

update ga_general_state_senate_20001107_fullnames
  set last_name = 'JOHNSON'
where rtrim(name) = 'D. L. JOHNSON';

update ga_general_state_senate_20001107_fullnames
  set last_name = 'MARABLE'
where rtrim(name) = 'RICHARD O. MARABLE';

update ga_general_state_senate_20001107_fullnames
  set last_name = 'THOMAS'
where rtrim(name) = 'DON R. THOMAS';

update ga_general_state_senate_20001107_fullnames
  set last_name = 'WALKER'
where rtrim(name) = 'CHARLES W. WALKER';

update ga_general_state_senate_20001107_fullnames
  set last_name = 'VON BREMEN'
where rtrim(name) = 'MIKE VON BREMEN';

-- Check that we have good clean data...
select *
from ga_general_state_senate_20001107_fullnames
order by last_name;

select party, count(*) as cnt
from ga_general_state_senate_20001107_fullnames
group by party
order by party;


---------------------------------------------------------
---------------------------------------------------------

truncate table ga_general_state_senate_20001107_county_votes

CREATE TABLE ga_general_state_senate_20001107_county_votes
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
from ga_general_state_senate_20001107_county_votes;

update ga_general_state_senate_20001107_county_votes
  set total_votes = replace(total_votes, ',', '');

update ga_general_state_senate_20001107_county_votes
  set county_votes = replace(county_votes, ',', '');

update ga_general_state_senate_20001107_county_votes
  set party = 'Democrat'
where party = '(D)';

update ga_general_state_senate_20001107_county_votes
  set party = 'Republican'
where party = '(R)';

update ga_general_state_senate_20001107_county_votes
  set last_name = 'VON BREMEN'
where last_name = 'VON_BREMEN';


-- QC to make sure we are matching both sides...
select *
from ga_general_state_senate_20001107_fullnames as a
  left join ga_general_state_senate_20001107_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

select *
from ga_general_state_senate_20001107_county_votes as a
  left join ga_general_state_senate_20001107_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
select *
from ga_general_state_senate_20001107_county_votes as a
  left join ga_general_state_senate_20001107_fullnames as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
      and a.total_votes = b.votes
where b.last_name is null;

select distinct last_name, district_number
from ga_general_state_senate_20001107_county_votes;

select distinct last_name, district_number
from ga_general_state_senate_20001107_fullnames;


-- Generate the final output .csv file...
select b.county_name as country, 'State Senate' as office,
  a.district_number as district, a.party as party,
  a.name as candidate, b.county_votes as votes
from ga_general_state_senate_20001107_fullnames as a
  inner join ga_general_state_senate_20001107_county_votes as b
    on a.last_name = b.last_name
      and a.district_number = b.district_number
      and a.party = b.party
order by a.district_number::int, a.party, b.county_name, a.name

