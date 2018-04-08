select *
from votes_20080715;

select office, count(*) as cnt
from votes_20080715
group by office
order by office;

select *
into district_attorney_20080715
from votes_20080715
where office = 'District Attorney';

select *
from district_attorney_20080715;

select candidate, district
from district_attorney_20080715
group by candidate, district;

select distinct party
from district_attorney_20080715;

update district_attorney_20080715
  set party =
    case
        when party = 'R' then 'Republican'
        else 'Democrat'
    end;

alter table district_attorney_20080715
    rename column candidate to last_name;

select *
from district_attorney_20080715;

-- Setup fullname table...
select *
into district_attorney_fullname_20080715
from "20080715_district_attorney_fullname";

select *
from district_attorney_fullname_20080715;

select *
-- delete
from district_attorney_fullname_20080715
where coalesce(district, '') = ''
  and coalesce(percent, '') = '';

select *
-- delete
from district_attorney_fullname_20080715
where trim(candidate) = 'No Candidates';

select *
-- delete
from district_attorney_fullname_20080715
where trim(votes) = 'Votes';

select *
from district_attorney_fullname_20080715;

update district_attorney_fullname_20080715
  set district = replace(replace(district, 'District Attorney, ', ''), '100% of precincts reporting', '');

alter table district_attorney_fullname_20080715
    add column ukey serial primary key;

;with previous_district as (
  select ukey, lag(district) over(order by ukey) as district
  from district_attorney_fullname_20080715
)
update district_attorney_fullname_20080715 as a
  set district = b.district
from previous_district as b
where a.ukey = b.ukey
  and coalesce(a.district, '') = ''
  and coalesce(b.district, '') <> '';

delete from district_attorney_fullname_20080715
where coalesce(candidate, '') = '';

select *
from district_attorney_fullname_20080715
order by ukey;

alter table district_attorney_fullname_20080715
  add column last_name varchar(50);

update district_attorney_fullname_20080715
  set candidate = replace(candidate, '  ', ' ');

update district_attorney_fullname_20080715
  set last_name = split_part(candidate, ' ', 2);

select candidate, last_name, district
from district_attorney_fullname_20080715
order by last_name;

-- QC to make sure we are matching both sides...
select a.district, a.candidate, a.last_name
from district_attorney_fullname_20080715 as a
  left join district_attorney_20080715 as b
    on a.last_name = b.last_name
      and trim(a.district) = trim(b.district)
where b.last_name is null;

select *
from district_attorney_20080715 as a
  left join district_attorney_fullname_20080715 as b
    on a.last_name = b.last_name
      and trim(a.district) = trim(b.district)
where b.last_name is null;

-- QC make sure total votes match from each side...
;with total_votes as (
  select last_name, district, sum(votes::int) as votes
  from district_attorney_20080715
  group by last_name, district
)
select *
from total_votes as a
  left join district_attorney_fullname_20080715 as b
    on a.last_name = b.last_name
      and trim(a.district) = trim(b.district)
      and a.votes::int = b.votes::int
where b.last_name is null;


drop table if exists results;


-- Generate the final output .csv file...
select b.county, b.office,
  a.district, b.party, a.candidate,
  b.votes as votes
--into results
from district_attorney_fullname_20080715 as a
  inner join district_attorney_20080715 as b
    on a.last_name = b.last_name
      and trim(a.district) = trim(b.district)
order by a.district, b.party, b.county, a.candidate;



select district, party, candidate, sum(votes) as votes
from results
group by district, party, candidate
order by district, party, votes desc;


