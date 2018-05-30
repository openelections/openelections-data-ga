select *
from ga_general_runoff_20081202;

delete
--select *
from ga_general_runoff_20081202
where candidate = 'Totals';

select *
from ga_general_runoff_20081202;

update ga_general_runoff_20081202
  set district = ''
where district = 'N/A';

update ga_general_runoff_20081202
  set candidate = 'Jim Martin'
where candidate = 'Martin'
  and office = 'U.S. Senate';

update ga_general_runoff_20081202
  set candidate = 'Saxby Chambliss'
where candidate = 'Chambliss'
  and office = 'U.S. Senate';

update ga_general_runoff_20081202
  set party = 'Republian'
where party = 'R';

update ga_general_runoff_20081202
  set party = 'Democrat'
where party = 'D';

update ga_general_runoff_20081202
  set party = 'Non-Partisan'
where party = 'NP';


select party, count(*) as cnt
from ga_general_runoff_20081202
group by party;

select *
from ga_general_runoff_20081202
where party = 'Adams';

select *
from ga_general_runoff_20081202
where office = 'U.S. Senate';

update ga_general_runoff_20081202
  set district = '4'
where office = 'Public Service Commission'
  and district = 'District 4 - Northern';

update ga_general_runoff_20081202
  set candidate = 'Lauren W. McDonald Jr.'
where candidate = 'McDonald'
  and office = 'Public Service Commission';

update ga_general_runoff_20081202
  set candidate = 'Jim Powell'
where candidate = 'Powell'
  and office = 'Public Service Commission';

select *
from ga_general_runoff_20081202
where office = 'Public Service Commission';


select office, count(*) as cnt
from ga_general_runoff_20081202
group by office
order by office;


update ga_general_runoff_20081202
  set candidate = 'Sara Doyle'
where candidate = 'Doyle'
  and office = 'Appeals Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Mike Sheffield'
where candidate = 'Sheffield'
  and office = 'Appeals Court Judge';

select *
from ga_general_runoff_20081202
where office = 'Appeals Court Judge';


update ga_general_runoff_20081202
  set candidate = 'Kimberly Esmond Adams'
where candidate = 'Esmond Adams'
  and office = 'Superior Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Mike Wallace'
where candidate = 'Wallace'
  and office = 'Superior Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Beau McClain'
where candidate = 'McClain'
  and office = 'Superior Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Sandra Dawson'
where candidate = 'Dawson'
  and office = 'Superior Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Brian House'
where candidate = 'House'
  and office = 'Superior Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Lawrence (Larry) A. Stagg'
where candidate = 'Stagg'
  and office = 'Superior Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Sarah Wall'
where candidate = 'Wall'
  and office = 'Superior Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Mike Johnson'
where candidate = 'Johnson'
  and office = 'Superior Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Tangela Barrie'
where candidate = 'Barrie'
  and office = 'Superior Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Johnny Mason'
where candidate = 'Mason'
  and office = 'Superior Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Melanie Barbee Cross'
where candidate = 'Cross'
  and office = 'Superior Court Judge';

update ga_general_runoff_20081202
  set candidate = 'Joseph Carter'
where candidate = 'Carter'
  and office = 'Superior Court Judge';

select *
from ga_general_runoff_20081202
where office = 'Superior Court Judge';

select office, candidate, party, district, sum(votes) as votes
from ga_general_runoff_20081202
group by office, candidate, party, district
order by office, district, party;

select county, count(*) as cnt
from ga_general_runoff_20081202
group by county
order by county;

update ga_general_runoff_20081202
  set county = upper(county);

-- Generate the final output .csv file...
select county, office, district, party, candidate, votes
from ga_general_runoff_20081202
order by office, district, county, party, candidate;

