import clarify
import unicodecsv


def statewide_results():
    p = clarify.Parser()
    p.parse("/Users/DW-Admin/Downloads/detail.xml")
    results = []
    for result in p.results:
        candidate = result.choice.text
        office, district = parse_office(result.contest.text)
        party = parse_party(result.contest.text)
        if party is None and '(' in candidate:
            candidate, party = candidate.split(' (')
            candidate = candidate.strip()
            party = party.replace(')','').strip()
        if result.jurisdiction:
            county = result.jurisdiction.name
        else:
            county = None
        r = [x for x in results if x['county'] == county and x['office'] == office and x['district'] == district and x['party'] == party and x['candidate'] == candidate]
        if r:
             r[0][result.vote_type] = result.votes
        else:
            results.append({ 'county': county, 'office': office, 'district': district, 'party': party, 'candidate': candidate, result.vote_type: result.votes})

    with open("20160216__ga__special__general__runoff.csv", "wb") as csvfile:
        w = unicodecsv.writer(csvfile, encoding='utf-8')
        w.writerow(['county', 'office', 'district', 'party', 'candidate', 'votes', 'election_day', 'absentee', 'early_voting', 'provisional'])
        for row in results:
            total_votes = row['Election Day'] + row['Absentee by Mail'] + row['Advance in Person'] + row['Provisional']
            w.writerow([row['county'], row['office'], row['district'], row['party'], row['candidate'], total_votes, row['Election Day'], row['Absentee by Mail'], row['Advance in Person'], row['Provisional']])


def precinct_results():
    p = clarify.Parser()
    p.parse("/Users/DW-Admin/Downloads/detail.xml")
    results = []
    for result in [x for x in p.results if not 'Number of Precincts' in x.vote_type]:
        candidate = result.choice.text
        office, district = parse_office(result.contest.text)
        party = parse_party(result.contest.text)
        if party is None and '(' in candidate:
            candidate, party = candidate.split(' (')
            candidate = candidate.strip()
            party = party.replace(')','').strip()
        county = p.region
        if result.jurisdiction:
            precinct = result.jurisdiction.name
        else:
            precinct = None
        r = [x for x in results if x['county'] == county and x['precinct'] == precinct and x['office'] == office and x['district'] == district and x['party'] == party and x['candidate'] == candidate]
        if r:
             r[0][result.vote_type] = result.votes
        else:
            results.append({ 'county': county, 'precinct': precinct, 'office': office, 'district': district, 'party': party, 'candidate': candidate, result.vote_type: result.votes})

    with open("20160216__ga__special__general__runoff__precinct.csv", "wb") as csvfile:
        w = unicodecsv.writer(csvfile, encoding='utf-8')
        w.writerow(['county', 'precinct', 'office', 'district', 'party', 'candidate', 'votes', 'election_day', 'absentee', 'early_voting1', 'early_voting2', 'provisional'])
        for row in results:
            total_votes = row['Election Day'] + row['Absentee by Mail'] + row['Advance in Person 1'] + row['Advance in Person 2'] + row['Provisional']
            w.writerow([row['county'], row['precinct'], row['office'], row['district'], row['party'], row['candidate'], total_votes, row['Election Day'], row['Absentee by Mail'], row['Advance in Person 1'], row['Advance in Person 2'], row['Provisional']])


def parse_office(office_text):
    office = office_text.split(',')[0]
    if ', District' in office_text:
        district = office_text.split(', District')[1].split(' - ')[0].strip()
    elif office == 'United States Senator':
        district = None
    elif ',' in office_text:
        district = office_text.split(', ')[1]
    else:
        district = None
    return [office, district]

def parse_party(office_text):
    if ' REP' in office_text:
        party = 'REP'
    elif ' DEM' in office_text:
        party = 'DEM'
    else:
        party = None
    return party
