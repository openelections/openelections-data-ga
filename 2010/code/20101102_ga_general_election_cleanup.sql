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
-- Governor
----------------------------------------------
select *
from ga_general_nov2010
where office = 'Governor';

update ga_general_nov2010
    set candidate = 'Nathan Deal',
        party = 'Republican'
where office = 'Governor'
    and candidate = 'Deal';

update ga_general_nov2010
    set candidate = 'Roy E. Barnes',
        party = 'Democrat'
where office = 'Governor'
    and candidate = 'Barnes';

update ga_general_nov2010
    set candidate = 'John H. Monds',
        party = 'Libertarian'
where office = 'Governor'
    and candidate = 'Monds';

update ga_general_nov2010
    set candidate = 'David C. Byrne',
        party = 'Write-In'
where office = 'Governor'
    and candidate = 'Byrne';

update ga_general_nov2010
    set candidate = 'Neal Horsley',
        party = 'Write-In'
where office = 'Governor'
    and candidate = 'Horsley';

-- Check the vote numbers...
select candidate, party, sum(votes) as votes
from ga_general_nov2010
where office = 'Governor'
group by candidate, party
order by votes desc;

-- Final Output...
select county, office, district, party, candidate, votes
from ga_general_nov2010
where office = 'Governor'
order by district, candidate, county;

----------------------------------------------
-- Lieutenant Governor
----------------------------------------------
select *
from ga_general_nov2010
where office = 'Lieutenant Governor';

update ga_general_nov2010
    set candidate = 'L.S. Casey Cagle',
        party = 'Republican'
where office = 'Lieutenant Governor'
    and candidate = 'Cagle';

update ga_general_nov2010
    set candidate = 'Carol Porter',
        party = 'Democrat'
where office = 'Lieutenant Governor'
    and candidate = 'Porter';

update ga_general_nov2010
    set candidate = 'Dan Barber',
        party = 'Libertarian'
where office = 'Lieutenant Governor'
    and candidate = 'Barber';

-- Check the vote numbers...
select candidate, party, sum(votes) as votes
from ga_general_nov2010
where office = 'Lieutenant Governor'
group by candidate, party
order by votes desc;

-- Final Output...
select county, office, district, party, candidate, votes
from ga_general_nov2010
where office = 'Lieutenant Governor'
order by district, candidate, county;

----------------------------------------------
-- Secretary of State
----------------------------------------------
select *
from ga_general_nov2010
where office = 'Secretary of State';

update ga_general_nov2010
    set candidate = 'Brian Kemp',
        party = 'Republican'
where office = 'Secretary of State'
    and candidate = 'Kemp';

update ga_general_nov2010
    set candidate = 'Georganna Sinkfield',
        party = 'Democrat'
where office = 'Secretary of State'
    and candidate = 'Sinkfield';

update ga_general_nov2010
    set candidate = 'David Chastain',
        party = 'Libertarian'
where office = 'Secretary of State'
    and candidate = 'Chastain';

-- Check the vote numbers...
select candidate, party, sum(votes) as votes
from ga_general_nov2010
where office = 'Secretary of State'
group by candidate, party
order by votes desc;

-- Final Output...
select county, office, district, party, candidate, votes
from ga_general_nov2010
where office = 'Secretary of State'
order by district, candidate, county;

----------------------------------------------
-- Attorney General
----------------------------------------------
select *
from ga_general_nov2010
where office = 'Attorney General';

update ga_general_nov2010
    set candidate = 'Sam Olens',
        party = 'Republican'
where office = 'Attorney General'
    and candidate = 'Olens';

update ga_general_nov2010
    set candidate = 'Ken Hodges',
        party = 'Democrat'
where office = 'Attorney General'
    and candidate = 'Hodges';

update ga_general_nov2010
    set candidate = 'Don Smart',
        party = 'Libertarian'
where office = 'Attorney General'
    and candidate = 'Smart';

-- Check the vote numbers...
select candidate, party, sum(votes) as votes
from ga_general_nov2010
where office = 'Attorney General'
group by candidate, party
order by votes desc;

-- Final Output...
select county, office, district, party, candidate, votes
from ga_general_nov2010
where office = 'Attorney General'
order by district, candidate, county;

----------------------------------------------
-- State School Superintendent
----------------------------------------------
select *
from ga_general_nov2010
where office = 'State School Superintendent';

update ga_general_nov2010
    set candidate = 'John D. Barge',
        party = 'Republican'
where office = 'State School Superintendent'
    and candidate = 'Barge';

update ga_general_nov2010
    set candidate = 'Joe Martin',
        party = 'Democrat'
where office = 'State School Superintendent'
    and candidate = 'Martin';

update ga_general_nov2010
    set candidate = 'Kira Griffiths Willis',
        party = 'Libertarian'
where office = 'State School Superintendent'
    and candidate = 'Willis';

update ga_general_nov2010
    set candidate = 'Howard Miller',
        party = 'Write-In'
where office = 'State School Superintendent'
    and candidate = 'Miller';

-- Check the vote numbers...
select candidate, party, sum(votes) as votes
from ga_general_nov2010
where office = 'State School Superintendent'
group by candidate, party
order by votes desc;

-- Final Output...
select county, office, district, party, candidate, votes
from ga_general_nov2010
where office = 'State School Superintendent'
order by district, candidate, county;

----------------------------------------------
-- Commissioner Of Insurance
----------------------------------------------
select *
from ga_general_nov2010
where office = 'Commissioner Of Insurance';

update ga_general_nov2010
    set candidate = 'Ralph T. Hudgens',
        party = 'Republican'
where office = 'Commissioner Of Insurance'
    and candidate = 'Hudgens';

update ga_general_nov2010
    set candidate = 'Mary Squires',
        party = 'Democrat'
where office = 'Commissioner Of Insurance'
    and candidate = 'Squires';

update ga_general_nov2010
    set candidate = 'Shane Bruce',
        party = 'Libertarian'
where office = 'Commissioner Of Insurance'
    and candidate = 'Bruce';

-- Check the vote numbers...
select candidate, party, sum(votes) as votes
from ga_general_nov2010
where office = 'Commissioner Of Insurance'
group by candidate, party
order by votes desc;

-- Final Output...
select county, office, district, party, candidate, votes
from ga_general_nov2010
where office = 'Commissioner Of Insurance'
order by district, candidate, county;

----------------------------------------------
-- Commissioner Of Agriculture
----------------------------------------------
select *
from ga_general_nov2010
where office = 'Commissioner Of Agriculture';

update ga_general_nov2010
    set candidate = 'Gary Black',
        party = 'Republican'
where office = 'Commissioner Of Agriculture'
    and candidate = 'Black';

update ga_general_nov2010
    set candidate = 'J. B. Powell',
        party = 'Democrat'
where office = 'Commissioner Of Agriculture'
    and candidate = 'Powell';

update ga_general_nov2010
    set candidate = 'Kevin Cherry',
        party = 'Libertarian'
where office = 'Commissioner Of Agriculture'
    and candidate = 'Cherry';

-- Check the vote numbers...
select candidate, party, sum(votes) as votes
from ga_general_nov2010
where office = 'Commissioner Of Agriculture'
group by candidate, party
order by votes desc;

-- Final Output...
select county, office, district, party, candidate, votes
from ga_general_nov2010
where office = 'Commissioner Of Agriculture'
order by district, candidate, county;

----------------------------------------------
-- Commissioner Of Labor
----------------------------------------------
select *
from ga_general_nov2010
where office = 'Commissioner Of Labor';
