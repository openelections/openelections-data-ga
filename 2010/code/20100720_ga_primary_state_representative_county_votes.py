#!/usr/bin/python3.6
# -*- coding: utf-8 -*-
from bs4 import BeautifulSoup
import psycopg2
import requests


url = "http://sos.ga.gov/elections/election_results/2010_0720/HouseMenu.htm"
base_url = "http://sos.ga.gov/elections/election_results/2010_0720/"

SQL = """
INSERT INTO ga_primary_state_representative_20100720_county_votes
    (district, party, last_name, total_votes, county_name, county_votes)
    VALUES (%(district)s, %(party)s, %(last_name)s,  %(total_votes)s,
        %(county_name)s, %(county_votes)s);
"""


def create_connection(database_name):
    conn = psycopg2.connect(
        database=database_name,
        user='jreed',
        host='127.0.0.1',
        port='5432'
    )
    return conn


def get_number_candidates(input):
    check = input.pop(0)
    if check:
        print(f'Wrong data: {check}')
    check = input.pop(0)
    if check:
        print(f'Wrong data: {check}')
    check = input.pop(-1)
    if 'Totals|' not in check:
        print(f'Wrong data: {check}')
    return len(input)


def extract_data(input_url):
    data = []
    district = party = last_name = county_name = county_votes = None
    candidates_data = county_data = []
    num_candidates = 0
    try:
        page = requests.get(input_url)
    except Exception as e:
        print(e, input_url)
        return

    soup = BeautifulSoup(page.text, 'html.parser')
    table = soup.find_all("table")[2]
    rows = [
        [td.get_text("|", strip=True) for td in tr.find_all('td')]
        for tr in table.find_all('tr')
    ]

    for r in rows:
        if r[0].startswith('State Representative'):
            district = r[0].split('|')[0].replace('State Representative, District ', '').strip() # noqa
            party = r[0].split('|')[1].strip()
        if r[0] == '' and r[1] == '' and 'Totals|' in r[-1]:
            candidates_data = r.copy()
            num_candidates = get_number_candidates(r)
        if len(r) == 4 and r[0] == '' and r[1] == '' and '%' in r[2] and '%' in r[3]: # noqa
            continue
        if len(r) == 3 and r[1] == 'County' and r[2] == 'PPR' and r[3]:
            continue
        if len(r) >= 3 and r[0] and '%' in r[1]:
            county_data = r.copy()

        if district and party and num_candidates > 0 and candidates_data and county_data: # noqa
            for i in range(2, num_candidates + 2):
                last_name = candidates_data[i].split('|')[0].strip()
                total_votes = candidates_data[i].split('|')[1].replace(',', '').strip() # noqa
                county_name = county_data[0].strip()
                county_votes = county_data[i].replace(',', '').strip()
                extracted_data = {
                    'district': district,
                    'party': party,
                    'last_name': last_name,
                    'total_votes': total_votes,
                    'county_name': county_name,
                    'county_votes': county_votes
                }
                data.append(extracted_data)
            county_data = None

    for d in data:
        cur.execute(SQL, d)


conn = create_connection('openelections')
cur = conn.cursor()

page = requests.get(url)
bs_links = BeautifulSoup(page.text, 'html.parser')

links = bs_links.findAll('a')
for link in links:
    if 'href' in link.attrs:
        print(link.attrs['href'])
        extract_data(base_url + link.attrs['href'])
        conn.commit()

conn.close()
