# python 3.5

from urllib.request import urlopen

from bs4 import BeautifulSoup
import psycopg2


def build_list(input_string):
    return_list = []
    for line in input_string:
        for item in line.split(' '):
            if len(item) > 0 and item != '\r':
                return_list.append(item.strip())
    return return_list


def create_connection(database_name):
    conn = psycopg2.connect(
        database=database_name,
        user='jreed',
        host='127.0.0.1',
        port='5432'
    )
    return conn


def extract_data(input_url):
    html = urlopen(input_url)
    bs = BeautifulSoup(html.read(), 'lxml')

    district_info = bs.findAll('h4')
    district_info = district_info[1].get_text()
    district_info = district_info.replace(
        "STATE SENATOR - DISTRICT", ""
    )

    if 'Republican' in district_info:
        party = 'Republican'
        district_info = district_info.replace('Republican', '')
    else:
        party = 'Democrat'
        district_info = district_info.replace('Democrat', '')
    district_number = district_info.replace('DISTRICT', '')

    district_number = district_number.replace(' ', '')

    county_vote_info = bs.find('pre')
    county_vote_info = county_vote_info.get_text()

    county_vote_info = county_vote_info.replace('VON BREMEN', 'VON_BREMEN')

    names = county_vote_info.split('\n')[5:6]
    totals = county_vote_info.split('\n')[6:7]
    percents = county_vote_info.split('\n')[7:8]
    counties = county_vote_info.split('\n')[9:-1]

    last_names = build_list(names)
    total_votes = build_list(totals)
    percent_votes = build_list(percents)

    county_votes = {}

    for line in counties:
        county_name = line[:14]
        votes = line[22:]
        split_votes = build_list([votes])
        county_votes[county_name.strip()] = split_votes

    for counter, name in enumerate(last_names):
        data = {
            'last_name': name,
            'party': party,
            'district_number': district_number,
            'total_votes': total_votes[counter],
            'percent_votes': percent_votes[counter],

        }
        for key, value in county_votes.items():
            data['county_name'] = key
            data['county_votes'] = value[counter]

            cur.execute(SQL, data)


SQL = """
INSERT INTO ga_primary_state_senate_20020820_county_votes
    (last_name, party, total_votes,
        percent_votes, district_number,
        county_name, county_votes)
    VALUES (%(last_name)s, %(party)s, %(total_votes)s,
        %(percent_votes)s, %(district_number)s,
        %(county_name)s, %(county_votes)s);
"""

conn = create_connection('dev')
cur = conn.cursor()

base_url = "http://sos.ga.gov/elections/election_results/2002_0820/"

url = "http://sos.ga.gov/elections/election_results/2002_0820/senatemenu.htm"

html = urlopen(url)
bs_links = BeautifulSoup(html.read(), 'lxml')

links = bs_links.findAll('a')
for link in links:
    if 'href' in link.attrs:
        extract_data(base_url + link.attrs['href'])
        conn.commit()

conn.close()
