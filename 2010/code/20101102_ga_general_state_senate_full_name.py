#!/usr/bin/python3.6
# -*- coding: utf-8 -*-
import csv

from bs4 import BeautifulSoup
import requests


page = requests.get('https://sos.ga.gov/elections/election_results/2010_1102/swgasenate.htm') # noqa
soup = BeautifulSoup(page.text, 'html.parser')

table = soup.find_all("table")[2]
rows = [
    [td.get_text("|", strip=True) for td in tr.find_all('td')]
    for tr in table.find_all('tr')
]

district = party = candidate = votes = None
results = [['district', 'party', 'candidate', 'total_votes']]

for r in rows:
    if r[0].startswith('State Senator'):
        district = r[0].split('|')[0].replace('State Senator, District ', '').strip() # noqa
    if len(r) == 6 and r[0] == '' and r[5] == ''and '%' in r[4]:
        candidate = r[1].replace('"', "'").strip().replace('  ', ' ')
        party = r[2].replace(',', '').strip()
        votes = r[3].replace(',', '').strip()
    if district and party and candidate and votes and 'Candidates' not in candidate: # noqa
        extracted_data = [district, party, candidate, votes]
        results.append(extracted_data)
        candidate = None

with open('full_names.csv', 'w') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerows(results)
csv_file.close()
