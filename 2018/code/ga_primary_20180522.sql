select *
from ga_primary_20180522
limit 500;

select distinct race
from ga_primary_20180522
order by race;

delete from ga_primary_20180522
where race like 'Democratic Party Question %';
-- 5088

select distinct candidate_party, candidate
from ga_primary_20180522
where candidate_party like '%(I)%'
order by candidate_party;

alter table ga_primary_20180522
    add column candidate varchar(100),
    add column party varchar(50),
    add column office varchar(200),
    add column district varchar(100);

update ga_primary_20180522
  set party = 'Republican'
where candidate_party like '%(REP)%';

update ga_primary_20180522
  set party = 'Democrat'
where candidate_party like '%(DEM)%';

select distinct candidate_party, race
from ga_primary_20180522
where party is null;

update ga_primary_20180522
  set candidate = candidate_party;

update ga_primary_20180522
  set candidate = replace(candidate, '"', '''');
where candidate like '%"%';

select distinct candidate_party, candidate
from ga_primary_20180522
where candidate_party like '%"%';

update ga_primary_20180522
  set candidate = replace(candidate, '(DEM)', '')
where candidate like '%(DEM)%';

update ga_primary_20180522
  set candidate = replace(candidate, '(REP)', '')
where candidate like '%(REP)%';

update ga_primary_20180522
  set candidate = replace(candidate, '(I)', '')
where candidate like '%(I)%';

select distinct candidate_party, candidate
from ga_primary_20180522
order by candidate_party;

select *
from ga_primary_20180522;

select distinct race
from ga_primary_20180522
where position(',' in race) > 0
order by race;

select
  race,
  split_part(race, ',', 1) as office,
  split_part(race, ',', 2) as district
from ga_primary_20180522;

update ga_primary_20180522
  set office = race
where position(',' in race) = 0;

update ga_primary_20180522
  set office = replace(office, '- DEM', '')
where office is not null;

update ga_primary_20180522
  set office = replace(office, '- REP', '')
where office is not null;

select distinct office
from ga_primary_20180522
where office is not null;

update ga_primary_20180522
  set office = split_part(race, ',', 1),
      district = split_part(race, ',', 2)
where position(',' in race) > 0;

update ga_primary_20180522
  set district = replace(district, '- DEM', '')
where position('- DEM' in district) > 0;

update ga_primary_20180522
  set district = replace(district, '- REP', '')
where position('- REP' in district) > 0;

update ga_primary_20180522
  set district = replace(district, 'District', '')
where position('District' in district) > 0;

update ga_primary_20180522
  set district = trim(district);

update ga_primary_20180522
  set district = left(district, 1)
where office = 'Public Service Commission';

select distinct race, office, district
from ga_primary_20180522
where position(',' in race) > 0
order by race;

update ga_primary_20180522
  set county = upper(county);


select county, office, district, party, candidate, sum(votes) as votes
from ga_primary_20180522
group by county, office, district, party, candidate
order by office, district, county, candidate;
