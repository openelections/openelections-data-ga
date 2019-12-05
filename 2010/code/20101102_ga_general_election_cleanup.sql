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

update ga_general_nov2010
    set candidate = 'Mark Butler',
        party = 'Republican'
where office = 'Commissioner Of Labor'
    and candidate = 'Butler';

update ga_general_nov2010
    set candidate = 'Darryl Hicks',
        party = 'Democrat'
where office = 'Commissioner Of Labor'
    and candidate = 'Hicks';

update ga_general_nov2010
    set candidate = 'Will Costa',
        party = 'Libertarian'
where office = 'Commissioner Of Labor'
    and candidate = 'Costa';

-- Check the vote numbers...
select candidate, party, sum(votes) as votes
from ga_general_nov2010
where office = 'Commissioner Of Labor'
group by candidate, party
order by votes desc;

-- Final Output...
select county, office, district, party, candidate, votes
from ga_general_nov2010
where office = 'Commissioner Of Labor'
order by district, candidate, county;

----------------------------------------------
-- U.S. Representative
----------------------------------------------
select *
from ga_general_nov2010
where office = 'U.S. Representative';

update ga_general_nov2010
    set party = 'Republican'
where office = 'U.S. Representative'
    and party = 'R';

update ga_general_nov2010
    set party = 'Democrat'
where office = 'U.S. Representative'
    and party = 'D';

update ga_general_nov2010
    set candidate = 'Jack Kingston'
where office = 'U.S. Representative'
    and district = '1'
    and candidate = 'Kingston';

update ga_general_nov2010
    set candidate = 'Oscar L. Harris II'
where office = 'U.S. Representative'
    and district = '1'
    and candidate = 'Harris';

update ga_general_nov2010
    set candidate = 'Sanford Bishop'
where office = 'U.S. Representative'
    and district = '2'
    and candidate = 'Bishop';

update ga_general_nov2010
    set candidate = 'Mike Keown'
where office = 'U.S. Representative'
    and district = '2'
    and candidate = 'Keown';

update ga_general_nov2010
    set candidate = 'Lynn Westmoreland'
where office = 'U.S. Representative'
    and district = '3'
    and candidate = 'Westmoreland';

update ga_general_nov2010
    set candidate = 'Frank Saunders'
where office = 'U.S. Representative'
    and district = '3'
    and candidate = 'Saunders';

update ga_general_nov2010
    set candidate = 'Jagdish Agrawal'
where office = 'U.S. Representative'
    and district = '3'
    and candidate = 'Agrawal';

update ga_general_nov2010
    set candidate = 'Hank Johnson Jr.'
where office = 'U.S. Representative'
    and district = '4'
    and candidate = 'Johnson';

update ga_general_nov2010
    set candidate = 'Lisbeth (Liz) Carter'
where office = 'U.S. Representative'
    and district = '4'
    and candidate = 'Carter';

update ga_general_nov2010
    set candidate = 'John Lewis'
where office = 'U.S. Representative'
    and district = '5'
    and candidate = 'Lewis';

update ga_general_nov2010
    set candidate = 'Fenn Little'
where office = 'U.S. Representative'
    and district = '5'
    and candidate = 'Little';

update ga_general_nov2010
    set candidate = 'Tom Price'
where office = 'U.S. Representative'
    and district = '6'
    and candidate = 'Price';

update ga_general_nov2010
    set candidate = 'Sean Greenberg'
where office = 'U.S. Representative'
    and district = '6'
    and candidate = 'Greenberg';

update ga_general_nov2010
    set candidate = 'Rob Woodall'
where office = 'U.S. Representative'
    and district = '7'
    and candidate = 'Woodall';

update ga_general_nov2010
    set candidate = 'Doug Heckman'
where office = 'U.S. Representative'
    and district = '7'
    and candidate = 'Heckman';

update ga_general_nov2010
    set candidate = 'Austin Scott'
where office = 'U.S. Representative'
    and district = '8'
    and candidate = 'Scott';

update ga_general_nov2010
    set candidate = 'Jim Marshall'
where office = 'U.S. Representative'
    and district = '8'
    and candidate = 'Marshall';

update ga_general_nov2010
    set candidate = 'Tom Graves'
where office = 'U.S. Representative'
    and district = '9'
    and candidate = 'Graves';

update ga_general_nov2010
    set candidate = 'Paul Broun'
where office = 'U.S. Representative'
    and district = '10'
    and candidate = 'Broun';

update ga_general_nov2010
    set candidate = 'Russell Edwards'
where office = 'U.S. Representative'
    and district = '10'
    and candidate = 'Edwards';

update ga_general_nov2010
    set candidate = 'Phil Gingrey'
where office = 'U.S. Representative'
    and district = '11'
    and candidate = 'Gingrey';

update ga_general_nov2010
    set candidate = 'John Barrow'
where office = 'U.S. Representative'
    and district = '12'
    and candidate = 'Barrow';

update ga_general_nov2010
    set candidate = 'Raymond Mckinney'
where office = 'U.S. Representative'
    and district = '12'
    and candidate = 'Mckinney';

update ga_general_nov2010
    set candidate = 'David Scott'
where office = 'U.S. Representative'
    and district = '13'
    and candidate = 'Scott';

update ga_general_nov2010
    set candidate = 'Mike Crane'
where office = 'U.S. Representative'
    and district = '13'
    and candidate = 'Crane';

-- Check the vote numbers...
select candidate, district, party, sum(votes) as votes
from ga_general_nov2010
where office = 'U.S. Representative'
group by candidate, district, party
order by district::int, votes desc;

-- Final Output...
select county, office, district, party, candidate, votes
from ga_general_nov2010
where office = 'U.S. Representative'
order by district::int, candidate, county;

----------------------------------------------
-- State Senate
----------------------------------------------
select *
from ga_general_nov2010
where office = 'State Senate';

select *
from state_senate_full_names;

alter table state_senate_full_names
    add column last_name text;

update state_senate_full_names
  set last_name = split_part(candidate, ' ', 2);

select district, candidate, last_name, party
from state_senate_full_names
order by last_name;

update state_senate_full_names
  set last_name = 'Johnson'
where rtrim(candidate) = 'Jordan ''Alex'' Johnson'
    and district = 41;

update state_senate_full_names
  set last_name = 'Pollard'
where rtrim(candidate) = 'Frances ''Beth'' Pollard'
    and district = 6;

update state_senate_full_names
  set last_name = 'Carter'
where rtrim(candidate) = 'Earl ''Buddy'' Carter'
    and district = 1;

update state_senate_full_names
  set last_name = 'Billingslea'
where rtrim(candidate) = 'Zannie (Tiger) Billingslea'
    and district = 34;

update state_senate_full_names
  set last_name = 'Ramsey'
where rtrim(candidate) = 'Ronald B. Ramsey, Sr.'
    and district = 43;

update state_senate_full_names
  set last_name = 'Jackson'
where rtrim(candidate) = 'Lester G. Jackson'
    and district = 2;

update state_senate_full_names
  set last_name = 'Bennett'
where rtrim(candidate) = 'Tracy Gene Bennett'
    and district = 31;

update state_senate_full_names
  set last_name = 'Griffin'
where rtrim(candidate) = 'Floyd L. Griffin'
    and district = 25;

update state_senate_full_names
  set last_name = 'Sims'
where rtrim(candidate) = 'Freddie Powell Sims'
    and district = 12;

update state_senate_full_names
  set last_name = 'Unterman'
where rtrim(candidate) = 'Renee S. Unterman'
    and district = 45;

update state_senate_full_names
  set last_name = 'Jackson'
where rtrim(candidate) = 'William S.(Bill) Jackson'
    and district = 24;

update state_senate_full_names
  set last_name = 'Ligon'
where rtrim(candidate) = 'William T. Ligon Jr.'
    and district = 3;

update state_senate_full_names
  set last_name = 'Crosby'
where rtrim(candidate) = 'John Dickey Crosby'
    and district = 13;

update state_senate_full_names
  set last_name = 'Anderson'
where rtrim(candidate) = 'Evelyn Thompson Anderson'
    and district = 29;

update ga_general_nov2010
    set party = 'Republican'
where office = 'State Senate'
    and party = 'R';

update ga_general_nov2010
    set party = 'Democrat'
where office = 'State Senate'
    and party = 'D';

update state_senate_full_names
    set party = 'Democrat'
where party = 'Democratic'

select *
from state_senate_full_names
where district = 29;

update ga_general_nov2010
    set candidate = 'Sims'
where candidate = 'Powell Sims'
    and district::int = 12
    and office = 'State Senate';

alter table ga_general_nov2010
    add column last_name text;

update ga_general_nov2010
    set last_name = candidate
where office = 'State Senate';

-- QC to make sure we are matching both sides...
with state_senate as
(
    select *
    from ga_general_nov2010
    where office = 'State Senate'
)
select *
from state_senate as a
  left join state_senate_full_names as b
    on a.last_name = b.last_name
      and a.district::int = b.district
      and a.party = b.party
where b.last_name is null;

with state_senate as
(
    select *
    from ga_general_nov2010
    where office = 'State Senate'
)
select *
from state_senate_full_names as a
  left join state_senate as b
    on a.last_name = b.last_name
      and a.district = b.district::int
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
with state_senate as
(
    select last_name, district, party, sum(votes) as total_votes
    from ga_general_nov2010
    where office = 'State Senate'
    group by last_name, district, party
)
select *
from state_senate as a
  left join state_senate_full_names as b
    on a.last_name = b.last_name
      and a.district::int = b.district
      and a.party = b.party
      and a.total_votes = b.total_votes
where b.last_name is null;

-- Generate the final output .csv file...
with state_senate as
(
    select *
    from ga_general_nov2010
    where office = 'State Senate'
)
select b.county, 'State Senate' as office,
  a.district, a.party as party, a.candidate, b.votes
from state_senate_full_names as a
  inner join state_senate as b
    on a.last_name = b.last_name
      and a.district = b.district::int
      and a.party = b.party
order by a.district, a.party, b.county, a.candidate

----------------------------------------------
-- State House
----------------------------------------------
set search_path to dev;

update ga_general_nov2010
    set last_name = candidate
where office = 'State House';

select *
from ga_general_nov2010
where office = 'State House';

select *
from state_house_full_names;

alter table state_house_full_names
    add column last_name text;

update state_house_full_names
  set last_name = split_part(candidate, ' ', 2);

select district, candidate, last_name, party
from state_house_full_names
order by last_name;

update state_house_full_names
  set last_name = 'Welch'
where rtrim(candidate) = 'Andrew ''Andy'' J. Welch III'
    and district = 110;

update state_house_full_names
  set last_name = 'Williams'
where rtrim(candidate) = 'Earnest ''Coach'' Williams'
    and district = 89;

update state_house_full_names
  set last_name = 'Bridges'
where rtrim(candidate) = 'Marilyn ''MJ'' Bridges'
    and district = 30;

update state_house_full_names
  set last_name = 'Marin'
where rtrim(candidate) = 'Pedro ''Pete'' Marin'
    and district = 96;

update state_house_full_names
  set last_name = 'Garrett'
where rtrim(candidate) = 'Tawana ''T'' Garrett'
    and district = 159;

update state_house_full_names
  set last_name = 'Howard'
where rtrim(candidate) = 'Henry ''Wayne'' Howard'
    and district = 121;

update state_house_full_names
  set last_name = 'Kaylor'
where rtrim(candidate) = 'Keith A. Kaylor'
    and district = 79;

update state_house_full_names
  set last_name = 'Epps'
where rtrim(candidate) = 'James A. ''Bubber'' Epps'
    and district = 140;

update state_house_full_names
  set last_name = 'Howard'
where rtrim(candidate) = 'Sharon B. Howard'
    and district = 136;

update state_house_full_names
  set last_name = 'Lane'
where rtrim(candidate) = 'Roger B. Lane'
    and district = 167;

update state_house_full_names
  set last_name = 'Kaiser'
where rtrim(candidate) = 'Margaret D Kaiser'
    and district = 59;

update state_house_full_names
  set last_name = 'Adams'
where rtrim(candidate) = 'Matthew D. Adams'
    and district = 35;

update state_house_full_names
  set last_name = 'Deal'
where rtrim(candidate) = 'Porter D. Deal'
    and district = 102;

update state_house_full_names
  set last_name = 'Martin'
where rtrim(candidate) = 'Charles E. ''Chuck'' Martin, Jr.'
    and district = 47;

update state_house_full_names
  set last_name = 'Greene'
where rtrim(candidate) = 'Gerald E. Greene'
    and district = 149;

update state_house_full_names
  set last_name = 'Lucas'
where rtrim(candidate) = 'David E. Lucas'
    and district = 139;

update state_house_full_names
  set last_name = 'Hugley'
where rtrim(candidate) = 'Carolyn F. Hugley'
    and district = 133;

update state_house_full_names
  set last_name = 'Buckner'
where rtrim(candidate) = 'Debbie G. Buckner'
    and district = 130;

update state_house_full_names
  set last_name = 'Freeman'
where rtrim(candidate) = 'Allen G. Freeman'
    and district = 140;

update state_house_full_names
  set last_name = 'Scott'
where rtrim(candidate) = 'Sandra G. Scott'
    and district = 76;

update state_house_full_names
  set last_name = 'Burns'
where rtrim(candidate) = 'Jon G. Burns'
    and district = 157;

update state_house_full_names
  set last_name = 'Heard'
where rtrim(candidate) = 'Keith G. Heard'
    and district = 114;

update state_house_full_names
  set last_name = 'Hudson'
where rtrim(candidate) = 'Helen G. ''Sistie'' Hudson'
    and district = 124;

update state_house_full_names
  set last_name = 'Fullerton'
where rtrim(candidate) = 'Carol H. Fullerton'
    and district = 151;

update state_house_full_names
  set last_name = 'Smith'
where rtrim(candidate) = 'Richard H. Smith'
    and district = 131;

update state_house_full_names
  set last_name = 'Bearden'
where rtrim(candidate) = 'Timothy J. Bearden'
    and district = 68;

update state_house_full_names
  set last_name = 'Taylor'
where rtrim(candidate) = 'Darlene K Taylor'
    and district = 173;

update state_house_full_names
  set last_name = 'Parsons'
where rtrim(candidate) = 'Don L. Parsons'
    and district = 42;

update state_house_full_names
  set last_name = 'Talton'
where rtrim(candidate) = 'Willie L. Talton'
    and district = 145;

update state_house_full_names
  set last_name = 'Dempsey'
where rtrim(candidate) = 'Katie M. Dempsey'
    and district = 13;

update state_house_full_names
  set last_name = 'Kendrick'
where rtrim(candidate) = 'Dar''shun N. Kendrick'
    and district = 94;

update state_house_full_names
  set last_name = 'Purcell'
where rtrim(candidate) = 'Ann R Purcell'
    and district = 159;

update state_house_full_names
  set last_name = 'Battles'
where rtrim(candidate) = 'Paul R. Battles'
    and district = 15;

update state_house_full_names
  set last_name = ''
where rtrim(candidate) = ''
    and district = ;

update state_house_full_names
  set last_name = 'Timmons'
where rtrim(candidate) = 'James R. C. Timmons'
    and district = 171;

update state_house_full_names
  set last_name = 'Smith'
where rtrim(candidate) = 'Lynn R. Smith'
    and district = 70;

update state_house_full_names
  set last_name = 'Maxwell'
where rtrim(candidate) = 'Howard R. Maxwell'
    and district = 17;

update state_house_full_names
  set last_name = 'Stephenson'
where rtrim(candidate) = 'Pam S. Stephenson'
    and district = 92;

update state_house_full_names
  set last_name = 'Howell'
where rtrim(candidate) = 'Quentin T. Howell'
    and district = 141;

update state_house_full_names
  set last_name = 'Randall'
where rtrim(candidate) = 'Nikki T. Randall'
    and district = 138;

update state_house_full_names
  set last_name = 'Epps'
where rtrim(candidate) = 'Carl Von Epps'
    and district = 128;

update state_house_full_names
  set last_name = 'Smith'
where rtrim(candidate) = 'Lynn R. Smith'
    and district = 70;

update state_house_full_names
  set last_name = 'Timmons'
where rtrim(candidate) = 'James R. C. Timmons'
    and district = 171;

update state_house_full_names
  set last_name = 'Maxwell'
where rtrim(candidate) = 'Howard R. Maxwell'
    and district = 17;

update state_house_full_names
  set last_name = 'Braddock'
where rtrim(candidate) = 'Paulette Rakestraw Braddock'
    and district = 19;

update state_house_full_names
  set last_name = 'Stephenson'
where rtrim(candidate) = 'Pam S. Stephenson'
    and district = 92;

update state_house_full_names
  set last_name = 'Quarterman'
where rtrim(candidate) = 'Kenneth Brett Quarterman'
    and district = 85;

update state_house_full_names
  set last_name = 'Tinubu'
where rtrim(candidate) = 'Gloria Bromell Tinubu'
    and district = 60;

update state_house_full_names
  set last_name = 'Kidd'
where rtrim(candidate) = 'E Culver ''Rusty'' Kidd'
    and district = 141;

update state_house_full_names
  set last_name = 'Irvin'
where rtrim(candidate) = 'Christopher James Irvin'
    and district = 28;

update state_house_full_names
  set last_name = 'Oliver'
where rtrim(candidate) = 'Mary Margaret Oliver'
    and district = 83;

update state_house_full_names
  set last_name = 'Morgan'
where rtrim(candidate) = 'Alisha Thomas Morgan'
    and district = 39;

update state_house_full_names
  set last_name = 'Benfield'
where rtrim(candidate) = 'Stephanie Stuckey Benfield'
    and district = 85;

update state_house_full_names
  set last_name = 'McDearman'
where rtrim(candidate) = 'D. Scott McDearman'
    and district = 40;

select district, candidate, last_name, party
from state_house_full_names
order by last_name;

select *
from state_house_full_names;

update ga_general_nov2010
    set party = 'Republican'
where office = 'State House'
    and party = 'R';

update ga_general_nov2010
    set party = 'Democrat'
where office = 'State House'
    and party = 'D';

update ga_general_nov2010
    set party = 'Independent'
where office = 'State House'
    and party = 'Ind';

update state_house_full_names
    set party = 'Democrat'
where party = 'Democratic';

select *
from state_house_full_names
where district = 164

update state_house_full_names
  set last_name = 'Reece'
where rtrim(candidate) = 'Barbara Massey Reece'
    and district = 11;

update state_house_full_names
  set last_name = 'Gordon'
where rtrim(candidate) = 'J. Craig Gordon'
    and district = 162;

update state_house_full_names
  set last_name = 'Mcclain-Haymon',
      candidate = 'Zena McClain-Haymon'
where rtrim(candidate) = 'Zena Mcclain'
    and district = 164;

Mcclain-Haymon


-- QC to make sure we are matching both sides...
with state_house as
(
    select *
    from ga_general_nov2010
    where office = 'State House'
)
select *
from state_house as a
  left join state_house_full_names as b
    on a.last_name = b.last_name
      and a.district::int = b.district
      and a.party = b.party
where b.last_name is null;

with state_house as
(
    select *
    from ga_general_nov2010
    where office = 'State House'
)
select *
from state_house_full_names as a
  left join state_house as b
    on a.last_name = b.last_name
      and a.district = b.district::int
      and a.party = b.party
where b.last_name is null;

-- QC make sure total votes match from each side...
with state_house as
(
    select last_name, district, party, sum(votes) as total_votes
    from ga_general_nov2010
    where office = 'State House'
    group by last_name, district, party
)
select *
from state_house as a
  left join state_house_full_names as b
    on a.last_name = b.last_name
      and a.district::int = b.district
      and a.party = b.party
      and a.total_votes = b.total_votes
where b.last_name is null;

-- Generate the final output .csv file...
with state_house as
(
    select *
    from ga_general_nov2010
    where office = 'State House'
)
select b.county, 'State House' as office,
  a.district, a.party as party, a.candidate, b.votes
from state_house_full_names as a
  inner join state_house as b
    on a.last_name = b.last_name
      and a.district = b.district::int
      and a.party = b.party
order by a.district, a.party, b.county, a.candidate
