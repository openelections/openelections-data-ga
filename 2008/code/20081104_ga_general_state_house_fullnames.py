from bs4 import BeautifulSoup
import psycopg2
import requests


URL = 'http://sos.ga.gov/elections/election_results/2008_1104/swgahouse.htm' # noqa

INSERT_SQL = """
    INSERT INTO ga_general_state_house_20081104_fullnames
        (name, party, district_number, votes, percent)
    VALUES (%(name)s, %(party)s, %(district_number)s,
        %(votes)s, %(percent)s);
"""


def create_connection(database_name):
    conn = psycopg2.connect(
        database=database_name,
        user='jreed',
        host='127.0.0.1',
        port='5432'
    )
    return conn


def extract_data(url):
    results = []
    record = {}
    district_number = None
    r = requests.get(url)
    bs = BeautifulSoup(r.text, 'lxml')
    rows = tag_getter(bs, 'tr')
    for row in rows:
        data = []
        cells = tag_getter(row, 'td')
        for cell in cells:
            content = cell.text.strip()
            if content:
                data.append(content)
        if len(data) == 1:
            district_number = \
                data[0].replace('State Representative, District', '').strip()
            district_number = district_number.splitlines()[0]
        elif len(data) == 4:
            record['name'] = data[0]
            record['party'] = data[1].replace('(', '').replace(')', '')
            record['votes'] = data[2].replace(',', '')
            record['percent'] = data[3]
            record['district_number'] = district_number
            if data[0] != 'Candidates':
                results.append(record)
            record = {}
    return results


def tag_getter(soup, tag):
    return soup.find_all(tag)


def write_results(results):
    for result in results:
        data = {
            'name': result.get('name', ''),
            'party': result.get('party', ''),
            'district_number': result.get('district_number', ''),
            'votes': result.get('votes', ''),
            'percent': result.get('percent', '')
        }
        cur.execute(INSERT_SQL, data)


conn = create_connection('dev')
cur = conn.cursor()
results = extract_data(URL)
write_results(results)
conn.commit()

conn.close()
