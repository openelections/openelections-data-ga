select *
from ga_general_nov2010;

select office, count(*) as cnt
from ga_general_nov2010
group by office;

----------------------------------------------
-- US Senate
----------------------------------------------
select *
from ga_general_nov2010
where office = 'U.S. Senate';

update ga_general_nov2010
    set candidate = 'Johnny Isakson',
        party = 'Republican',
        office = 'US Senate'
where office = 'U.S. Senate'
    and candidate = 'Isakson';

update ga_general_nov2010
    set candidate = 'Michael (Mike) Thurmond',
        party = 'Democrat',
        office = 'US Senate'
where office = 'U.S. Senate'
    and candidate = 'Thurmond';

update ga_general_nov2010
    set candidate = 'Chuck Donovan',
        party = 'Libertarian',
        office = 'US Senate'
where office = 'U.S. Senate'
    and candidate = 'Donovan';

update ga_general_nov2010
    set candidate = 'Steve Davis',
        party = 'Write-In',
        office = 'US Senate'
where office = 'U.S. Senate'
    and candidate = 'Davis';

update ga_general_nov2010
    set candidate = 'Raymond Beckworth',
        party = 'Write-In',
        office = 'US Senate'
where office = 'U.S. Senate'
    and candidate = 'Beckworth';

update ga_general_nov2010
    set candidate = 'Brian Russell Brown',
        party = 'Write-In',
        office = 'US Senate'
where office = 'U.S. Senate'
    and candidate = 'Brown';

-- Check the vote numbers...
select candidate, party, sum(votes) as votes
from ga_general_nov2010
where office = 'US Senate'
group by candidate, party
order by votes desc;

-- Final Output...
select county, office, district, party, candidate, votes
from ga_general_nov2010
where office = 'US Senate'
order by district, candidate, county;

----------------------------------------------
--
----------------------------------------------
