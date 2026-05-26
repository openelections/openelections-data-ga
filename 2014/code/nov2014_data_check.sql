WITH precinct_agg AS (
    SELECT 
        county,
        office,
        district,
        party,
        candidate,
        SUM(election_day_votes) AS p_election_day,
        SUM(advanced_votes) AS p_advanced,
        SUM(absentee_by_mail_votes) AS p_absentee,
        SUM(provisional_votes) AS p_provisional
    FROM read_csv_auto('/Users/skunkworks/Development/openelections-data-ga/2014/20141104__ga__general__precinct-level_UNOFFICIAL.csv')
    GROUP BY county, office, district, party, candidate
),
county_level AS (
    SELECT 
        county,
        office,
        district,
        party,
        candidate,
        election_day_votes AS c_election_day,
        advanced_votes AS c_advanced,
        absentee_by_mail_votes AS c_absentee,
        provisional_votes AS c_provisional
    FROM read_csv_auto('/Users/skunkworks/Development/openelections-data-ga/2014/20141104__ga__general__county-level.csv')
)
SELECT 
    c.county,
    c.office,
    c.district,
    c.candidate,
    c.c_election_day, p.p_election_day,
    c.c_advanced, p.p_advanced,
    c.c_absentee, p.p_absentee,
    c.c_provisional, p.p_provisional
FROM county_level c
inner JOIN precinct_agg p
    ON c.county = p.county 
    AND c.office = p.office 
    AND c.district = p.district 
    AND c.party = p.party 
    AND c.candidate = p.candidate
WHERE 
    COALESCE(c.c_election_day, 0) <> COALESCE(p.p_election_day, 0) OR
    COALESCE(c.c_advanced, 0) <> COALESCE(p.p_advanced, 0) OR
    COALESCE(c.c_absentee, 0) <> COALESCE(p.p_absentee, 0) OR
    COALESCE(c.c_provisional, 0) <> COALESCE(p.p_provisional, 0) OR
    c.candidate IS NULL OR 
    p.candidate IS NULL;
