select *
into ga_primary_runoff_20080805
from "20080805__ga__primary__runoff__county";

delete
--select *
from ga_primary_runoff_20080805
where candidate = 'Totals';

select *
from ga_primary_runoff_20080805;

update ga_primary_runoff_20080805
  set candidate = 'Jim Martin'
where candidate = 'Martin'
  and office = 'U.S. Senate';

update ga_primary_runoff_20080805
  set candidate = 'Vernon Jones'
where candidate = 'Jones'
  and office = 'U.S. Senate';

update ga_primary_runoff_20080805
  set district = ''
where office = 'U.S. Senate';

select distinct party
from ga_primary_runoff_20080805;

update ga_primary_runoff_20080805
  set party = 'Republian'
where party = 'R';

update ga_primary_runoff_20080805
  set party = 'Democrat'
where party = 'D';

update ga_primary_runoff_20080805
  set office = 'US Senate'
where office = 'U.S. Senate';

select candidate, party, sum(votes) as votes
from ga_primary_runoff_20080805
where office = 'US Senate'
group by candidate, party;

select *
from ga_primary_runoff_20080805
where office = 'State Senator'
  and district = '44';

update ga_primary_runoff_20080805
  set district = replace(district, 'District ', '')

update ga_primary_runoff_20080805
  set candidate = 'Gail Buckner'
where candidate = 'Buckner'
  and office = 'State Senator'
  and district = '44';

update ga_primary_runoff_20080805
  set candidate = 'Gail Davenport'
where candidate = 'Davenport'
  and office = 'State Senator'
  and district = '44';

select candidate, party, sum(votes) as votes
from ga_primary_runoff_20080805
where office = 'State Senator'
  and district = '44'
group by candidate, party;

select *
from ga_primary_runoff_20080805
where office = 'State Senator'
  and district = '50';

update ga_primary_runoff_20080805
  set candidate = 'Jim Butterworth'
where candidate = 'Butterworth'
  and office = 'State Senator'
  and district = '50';

update ga_primary_runoff_20080805
  set candidate = 'Nancy Schaefer'
where candidate = 'Schaefer'
  and office = 'State Senator'
  and district = '50';

select candidate, party, sum(votes) as votes
from ga_primary_runoff_20080805
where office = 'State Senator'
  and district = '50'
group by candidate, party;

select *
from ga_primary_runoff_20080805
where office = 'State Representative'
  and district = '61';

update ga_primary_runoff_20080805
  set candidate = 'Ralph Long III'
where candidate = 'Long'
  and office = 'State Representative'
  and district = '61';

update ga_primary_runoff_20080805
  set candidate = 'Keisha Waites'
where candidate = 'Waites'
  and office = 'State Representative'
  and district = '61';

select candidate, party, sum(votes) as votes
from ga_primary_runoff_20080805
where office = 'State Representative'
  and district = '61'
group by candidate, party;

select *
from ga_primary_runoff_20080805
where office = 'State Representative'
  and district = '91';

update ga_primary_runoff_20080805
  set candidate = 'Rahn Mayo'
where candidate = 'Mayo'
  and office = 'State Representative'
  and district = '91';

update ga_primary_runoff_20080805
  set candidate = 'Rita Robinzine'
where candidate = 'Robinzine'
  and office = 'State Representative'
  and district = '91';

select candidate, party, sum(votes) as votes
from ga_primary_runoff_20080805
where office = 'State Representative'
  and district = '91'
group by candidate, party;

select *
from ga_primary_runoff_20080805
where office = 'State Representative'
  and district = '93';

update ga_primary_runoff_20080805
  set candidate = 'Dee Dawkins-Haigler'
where candidate = 'Dawkins-Haigler'
  and office = 'State Representative'
  and district = '93';

update ga_primary_runoff_20080805
  set candidate = 'Malik Douglas'
where candidate = 'Douglas'
  and office = 'State Representative'
  and district = '93';

select candidate, party, sum(votes) as votes
from ga_primary_runoff_20080805
where office = 'State Representative'
  and district = '93'
group by candidate, party;

select *
from ga_primary_runoff_20080805
where office = 'District Attorney'
  and district = 'Clayton Circuit';

update ga_primary_runoff_20080805
  set candidate = 'Tracy Graham-Lawson'
where candidate = 'Lawson'
  and office = 'District Attorney'
  and district = 'Clayton Circuit';

update ga_primary_runoff_20080805
  set candidate = 'Jewel Scott'
where candidate = 'Scott'
  and office = 'District Attorney'
  and district = 'Clayton Circuit';

select candidate, party, sum(votes) as votes
from ga_primary_runoff_20080805
where office = 'District Attorney'
  and district = 'Clayton Circuit'
group by candidate, party;

select *
from ga_primary_runoff_20080805
where office = 'District Attorney'
  and district = 'Eastern Circuit';

update ga_primary_runoff_20080805
  set candidate = 'Larry Chisolm'
where candidate = 'Chisolm'
  and office = 'District Attorney'
  and district = 'Eastern Circuit';

update ga_primary_runoff_20080805
  set candidate = 'Jerry Rothschild'
where candidate = 'Rothschild'
  and office = 'District Attorney'
  and district = 'Eastern Circuit';

select candidate, party, sum(votes) as votes
from ga_primary_runoff_20080805
where office = 'District Attorney'
  and district = 'Eastern Circuit'
group by candidate, party;

select *
from ga_primary_runoff_20080805
where office = 'District Attorney'
  and district = 'Piedmont Circuit';

update ga_primary_runoff_20080805
  set candidate = 'Brad Smith'
where candidate = 'Smith'
  and office = 'District Attorney'
  and district = 'Piedmont Circuit';

update ga_primary_runoff_20080805
  set candidate = 'Donna Sikes'
where candidate = 'Sikes'
  and office = 'District Attorney'
  and district = 'Piedmont Circuit';

select candidate, party, sum(votes) as votes
from ga_primary_runoff_20080805
where office = 'District Attorney'
  and district = 'Piedmont Circuit'
group by candidate, party;

select office, candidate, district, party, sum(votes) as votes
from ga_primary_runoff_20080805
group by office, candidate, district, party
order by office, district, party desc;

-- Generate the final output .csv file...
select county, office, district, party, candidate, votes
from ga_primary_runoff_20080805
order by office, district, county, party desc;

-----------------------------------------------------------------
-- Reworking State Senate District 13
-----------------------------------------------------------------
select *
into ga_special_state_senate_13
from "20080805__ga__special__primary__county";

delete
-- select *
from ga_special_state_senate_13
where candidate = 'Totals';

update ga_special_state_senate_13
  set district = replace(district, 'District ', '');

update ga_special_state_senate_13
  set party = 'Republican';

select *
from ga_special_state_senate_13;

select office, candidate, district, party, sum(votes) as votes
from ga_special_state_senate_13
group by office, candidate, district, party
order by office, district, party desc;

update ga_special_state_senate_13
  set candidate = 'John Dickey Crosby'
where candidate = 'Crosby';

update ga_special_state_senate_13
  set candidate = 'Wally Roberts'
where candidate = 'Roberts';

update ga_special_state_senate_13
  set candidate = 'Rusty Simpson'
where candidate = 'Simpson';

update ga_special_state_senate_13
  set candidate = 'Horace Hudgins'
where candidate = 'Hudgins';

update ga_special_state_senate_13
  set candidate = 'Bob Usry'
where candidate = 'Usry';

select county, office, district, party, candidate, votes
from ga_special_state_senate_13
order by office, district, county, party desc;
