from bs4 import BeautifulSoup
import psycopg2
import requests


BASE_URL = 'http://sos.ga.gov/elections/election_results/2006_1107/'
MENU_URL = BASE_URL + 'SenateMenu.htm'

INSERT_SQL = """
    INSERT INTO ga_general_state_senate_20061107_county_votes
        (last_name, party, total_votes, district_number,
            county_name, county_votes)
    VALUES (%(last_name)s, %(party)s, %(total_votes)s,
        %(district_number)s, %(county_name)s,
        %(county_votes)s);
"""


def tag_getter(soup, tag):
    return soup.find_all(tag)


def candidate_extractor(cells, district):
    results = []
    for cell in cells:
        content = cell.text.strip()
        content = content.split('\n')
        if len(content) > 1:
            candidate = {}
            candidate['last_name'] = content[0].strip()
            candidate['party'] = content[1].strip() \
                .replace('(', '').replace(')', '')
            candidate['district_number'] = district
            candidate['total_votes'] = content[4].strip().replace(',', '')
            candidate['county_votes'] = {}
            results.append(candidate)
    return results


def county_vote_extractor(cells, results):
    for counter, cell in enumerate(cells):
        if counter == 0:
            county = cell.text.strip()
        if counter >= 3:
            votes = results[counter - 3]['county_votes']
            votes[county] = cell.text.strip().replace(',', '')
            results[counter - 3]['county_votes'] = votes
    return results


def create_connection(database_name):
    conn = psycopg2.connect(
        database=database_name,
        user='jreed',
        host='127.0.0.1',
        port='5432'
    )
    return conn


def extract_data(html_page, district):
    district = district.replace('District ', '')
    r = requests.get(BASE_URL + html_page)
    bs = BeautifulSoup(r.text, 'lxml')
    rows = tag_getter(bs, 'tr')
    for counter, row in enumerate(rows):
        cells = tag_getter(row, 'td')
        if len(cells) >= 4:
            if counter == 1:
                results = candidate_extractor(cells, district)
            if counter > 3:
                results = county_vote_extractor(cells, results)
    return results


def write_results(results):
    for result in results:
        data = {
            'last_name': result.get('last_name', ''),
            'party': result.get('party', ''),
            'district_number': result.get('district_number', ''),
            'total_votes': result.get('total_votes', ''),
        }
        county_votes = result.get('county_votes', None)
        for key, value in county_votes.items():
            data['county_name'] = key
            data['county_votes'] = value
            cur.execute(INSERT_SQL, data)


conn = create_connection('dev')
cur = conn.cursor()
r = requests.get(MENU_URL)
bs = BeautifulSoup(r.text, 'html.parser')
links = bs.findAll('a')
for link in links:
    results = extract_data(link['href'], link.string)
    write_results(results)
    conn.commit()

conn.close()
