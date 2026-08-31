create schema raw;
create schema stage;
create schema prod;

-----------------------------------------------------------------------------------------------
-- Load JSON data...
-----------------------------------------------------------------------------------------------
create or replace table raw.ga__special__state__house__129
as
select *
from read_json('/home/skunkworks/development/openelections-data-ga/2022/source_data/data.json');

select *
from raw.ga__special__state__house__129;

-----------------------------------------------------------------------------------------------
-- Rename vote_types before pivoting the data...
-----------------------------------------------------------------------------------------------
select distinct vote_type
from raw.ga__special__state__house__129;

update raw.ga__special__state__house__129
    set vote_type =
        case
            when vote_type = 'Election Day Votes' then 'election_day_votes'
            when vote_type = 'Absentee by Mail Votes' then 'absentee_by_mail_votes'
            when vote_type = 'Advance Voting Votes' then 'advance_votes'
            when vote_type = 'Provisional Votes' then 'provisional_votes'
        end;

-----------------------------------------------------------------------------------------------
-- Pivot data and copy to STAGE, begin the cleanup and QC...
-----------------------------------------------------------------------------------------------
create or replace table stage.ga__special__state__house__129
as
pivot raw.ga__special__state__house__129
on vote_type
using sum(votes);

select *
from stage.ga__special__state__house__129;

alter table stage.ga__special__state__house__129
    add column precint varchar;

alter table stage.ga__special__state__house__129
    add column district varchar;

select *
from stage.ga__special__state__house__129;

update stage.ga__special__state__house__129
    set precint = 'not available';

update stage.ga__special__state__house__129
    set district = '129'
where office = 'State House of Representatives - District 129 - Dem';

update stage.ga__special__state__house__129
    set office = 'State House'
where office = 'State House of Representatives - District 129 - Dem';

update stage.ga__special__state__house__129
    set party = 'Democrat'
where party = 'DEM';

update stage.ga__special__state__house__129
    set county = replace(county, ' County', '');

-----------------------------------------------------------------------------------------------
-- QC the data...
-----------------------------------------------------------------------------------------------
select *
from stage.ga__special__state__house__129;

select
    candidate,
    total_votes,
    (absentee_by_mail_votes + advance_votes + election_day_votes + provisional_votes) as qc_total_votes
from stage.ga__special__state__house__129;

where total_votes <> qc_total_votes;

-----------------------------------------------------------------------------------------------
-- Copy data to PROD...
-----------------------------------------------------------------------------------------------
create or replace table prod.ga__special__state__house__129
as
select
    county,
    precint,
    office,
    district,
    party,
    candidate,
    election_day_votes,
    advance_votes,
    absentee_by_mail_votes,
    provisional_votes
from stage.ga__special__state__house__129;

-----------------------------------------------------------------------------------------------
-- Write out CSV file...
-----------------------------------------------------------------------------------------------
select *
from prod.ga__special__state__house__129;
