create schema raw;

create or replace table raw.ga__special__state__house__129
as
select *
from read_json('20221220__ga__special__state__house__129.json');

select *
from raw.ga__special__state__house__129;

select
    results.name as state,
--    localResults[1].name as country,
--    localResults[1].ballotItems[1].name as race,
    unnest(localResults, recursive := true) as local_results,
    unnest(localResults[1].ballotItems, recursive := true) as ballot_items,
    unnest(localResults[1].ballotItems[1].ballotOptions, recursive := true) as ballot_options
--    unnest(unnest(localResults, recursive := true).ballotItems, recursive := true)
--    unnest(local_results, recursive := true) as word
from raw.ga__special__state__house__129

select
    b.*
from raw.ga__special__state__house__129 as a
    cross join unnest(a.localResults, recursive := true) as b