select *
from ga_primary_state_representative_20100720_fullnames
order by district, party, candidate;

alter table ga_primary_state_representative_20100720_fullnames
    add column last_name text;

update ga_primary_state_representative_20100720_fullnames
  set last_name = split_part(candidate, ' ', 2);

select district, candidate, last_name
from ga_primary_state_representative_20100720_fullnames
order by last_name;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Welch'
where rtrim(candidate) = 'Andrew ''Andy'' J. Welch III'
    and district = 110;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Williams'
where rtrim(candidate) = 'Earnest ''Coach'' Williams'
    and district = 89;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Bridges'
where rtrim(candidate) = 'Marilyn ''MJ'' Bridges'
    and district = 30;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Marin'
where rtrim(candidate) = 'Pedro ''Pete'' Marin'
    and district = 96;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Garrett'
where rtrim(candidate) = 'Tawana ''T'' Garrett'
    and district = 159;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Howard'
where rtrim(candidate) = 'Henry ''Wayne'' Howard'
    and district = 121;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Epps'
where rtrim(candidate) = 'James A. ''Bubber'' Epps'
    and district = 140;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Royal'
where rtrim(candidate) = 'Keith A. Royal'
    and district = 102;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Kaylor'
where rtrim(candidate) = 'Keith A. Kaylor'
    and district = 79;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Carter'
where rtrim(candidate) = 'Mary Alice Carter'
    and district = 125;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Howard'
where rtrim(candidate) = 'Sharon B. Howard'
    and district = 136;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Lane'
where rtrim(candidate) = 'Roger B. Lane'
    and district = 167;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Quarterman'
where rtrim(candidate) = 'Kenneth Brett Quarterman'
    and district = 85;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Kaiser'
where rtrim(candidate) = 'Margaret D Kaiser'
    and district = 59;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Deal'
where rtrim(candidate) = 'Porter D. Deal'
    and district = 102;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Adams'
where rtrim(candidate) = 'Matthew D. Adams'
    and district = 35;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Greene'
where rtrim(candidate) = 'Gerald E. Greene'
    and district = 149;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Lucas'
where rtrim(candidate) = 'David E. Lucas'
    and district = 139;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Martin'
where rtrim(candidate) = 'Charles E. ''Chuck'' Martin, Jr.'
    and district = 47;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Hugley'
where rtrim(candidate) = 'Carolyn F. Hugley'
    and district = 133;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Scott'
where rtrim(candidate) = 'Sandra G. Scott'
    and district = 76;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Koch'
where rtrim(candidate) = 'Mark G. Koch'
    and district = 37;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Burns'
where rtrim(candidate) = 'Jon G. Burns'
    and district = 157;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Heard'
where rtrim(candidate) = 'Keith G. Heard'
    and district = 114;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Freeman'
where rtrim(candidate) = 'Allen G. Freeman'
    and district = 140;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Buckner'
where rtrim(candidate) = 'Debbie G. Buckner'
    and district = 130;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Hudson'
where rtrim(candidate) = 'Helen G. ''Sistie'' Hudson'
    and district = 124;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Webb'
where rtrim(candidate) = 'Gary H Webb'
    and district = 104;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Smith'
where rtrim(candidate) = 'Richard H. Smith'
    and district = 131;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Fullerton'
where rtrim(candidate) = 'Carol H. Fullerton'
    and district = 151;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Bearden'
where rtrim(candidate) = 'Timothy J. Bearden'
    and district = 68;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Irvin'
where rtrim(candidate) = 'Christopher James Irvin'
    and district = 28;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Taylor'
where rtrim(candidate) = 'Darlene K Taylor'
    and district = 173;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Talton'
where rtrim(candidate) = 'Willie L. Talton'
    and district = 145;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Washington'
where rtrim(candidate) = 'Sherri L. Washington'
    and district = 94;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Parsons'
where rtrim(candidate) = 'Don L. Parsons'
    and district = 42;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Dempsey'
where rtrim(candidate) = 'Katie M. Dempsey'
    and district = 13;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Spahos'
where rtrim(candidate) = 'Lee M. Spahos'
    and district = 110;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Kendrick'
where rtrim(candidate) = 'Dar''shun N. Kendrick'
    and district = 94;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Purcell'
where rtrim(candidate) = 'Ann R Purcell'
    and district = 159;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Golden'
where rtrim(candidate) = 'Steve R. Golden'
    and district = 19;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Nicholson'
where rtrim(candidate) = 'Tom R. Nicholson'
    and district = 110;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Battles'
where rtrim(candidate) = 'Paul R. Battles'
    and district = 15;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Maxwell'
where rtrim(candidate) = 'Howard R. Maxwell'
    and district = 17;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Smith'
where rtrim(candidate) = 'Lynn R. Smith'
    and district = 70;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Timmons'
where rtrim(candidate) = 'James R. C. Timmons'
    and district = 171;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Stephenson'
where rtrim(candidate) = 'Pam S. Stephenson'
    and district = 92;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'James'
where rtrim(candidate) = 'H. Shawn James'
    and district = 75;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Benfield'
where rtrim(candidate) = 'Stephanie Stuckey Benfield'
    and district = 85;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Welch'
where rtrim(candidate) = 'Joe T. Welch'
    and district = 163;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Randall'
where rtrim(candidate) = 'Nikki T. Randall'
    and district = 138;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Howell'
where rtrim(candidate) = 'Quentin T. Howell'
    and district = 141;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Von Epps'
where rtrim(candidate) = 'Carl Von Epps'
    and district = 128;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Tinubu'
where rtrim(candidate) = 'Gloria Bromell Tinubu'
    and district = 60;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Kaiser'
where rtrim(candidate) = 'Margaret D Kaiser'
    and district = 59;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Oliver'
where rtrim(candidate) = 'Mary Margaret Oliver'
    and district = 83;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Reece'
where rtrim(candidate) = 'Barbara Massey Reece'
    and district = 11;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Boatright'
where rtrim(candidate) = 'W. Neal Boatright'
    and district = 167;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Braddock'
where rtrim(candidate) = 'Paulette Rakestraw Braddock'
    and district = 19;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Morgan'
where rtrim(candidate) = 'Alisha Thomas Morgan'
    and district = 39;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'McDearman'
where rtrim(candidate) = 'D. Scott McDearman'
    and district = 40;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Epps'
where rtrim(candidate) = 'Carl Von Epps'
    and district = 128;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'Gordon'
where rtrim(candidate) = 'J. Craig Gordon'
    and district = 162;

update ga_primary_state_representative_20100720_fullnames
  set last_name = 'McClain',
      candidate = 'Zena McClain'
where rtrim(candidate) = 'Zena Mcclain'
    and district = 164;

select district, candidate, last_name
from ga_primary_state_representative_20100720_fullnames
order by last_name;

-- Check that we have good clean data...
select *
from ga_primary_state_representative_20100720_fullnames
order by district, party;

insert into ga_primary_state_representative_20100720_fullnames
    (district, party, candidate, total_votes, last_name)
values(55, 'Democratic', 'Able Mable Thomas', 1265, 'Thomas');


---------------------------------------------------------
---------------------------------------------------------
-- drop table ga_primary_state_representative_20100720_county_votes;
-- truncate table ga_primary_state_representative_20100720_county_votes;

create table ga_primary_state_representative_20100720_county_votes
  (
    district int,
    party text,
    last_name text,
    total_votes int,
    county_name text,
    county_votes int
);

-- Run Python script here...
-- 20060718_ga_primary_state_representative_county_votes.py

select *
from ga_primary_state_representative_20100720_county_votes
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
    from ga_primary_state_representative_20100720_county_votes
    group by district, party, last_name
)
select *
from votes
where total_votes <> agg_total_votes;

update ga_primary_state_representative_20100720_county_votes
  set last_name = 'Weaver-Stoll'
where last_name = 'Stoll'
  and district = 14;

update ga_primary_state_representative_20100720_county_votes
  set last_name = 'McManus'
where last_name = 'Mcmanus'
  and district = 24;

update ga_primary_state_representative_20100720_county_votes
  set last_name = 'Anderson-Woods'
where last_name = 'Woods'
  and district = 78;

update ga_primary_state_representative_20100720_county_votes
  set last_name = 'McClain'
where last_name = 'Mcclain-Haymon'
  and district = 164;

-- QC to make sure we are matching both sides...
select *
from ga_primary_state_representative_20100720_county_votes as a
  left join ga_primary_state_representative_20100720_fullnames as b
    on a.last_name = b.last_name
      and a.district = b.district
      and a.party = b.party
where b.last_name is null;

select *
from ga_primary_state_representative_20100720_fullnames as a
  left join ga_primary_state_representative_20100720_county_votes as b
    on a.last_name = b.last_name
      and a.district = b.district
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
select *
from ga_primary_state_representative_20100720_county_votes as a
  left join ga_primary_state_representative_20100720_fullnames as b
    on a.last_name = b.last_name
      and a.district = b.district
      and a.party = b.party
      and a.total_votes = b.total_votes
where b.last_name is null;

-- Generate the final output .csv file...
select b.county_name as country, 'State Representative' as office,
  a.district, a.party as party, a.candidate, b.county_votes as votes
from ga_primary_state_representative_20100720_fullnames as a
  inner join ga_primary_state_representative_20100720_county_votes as b
    on a.last_name = b.last_name
      and a.district = b.district
      and a.party = b.party
order by a.district, a.party, b.county_name, a.candidate