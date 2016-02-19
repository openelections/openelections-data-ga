# python 3.5

import sqlite3
from urllib.request import urlopen

from bs4 import BeautifulSoup


conn = sqlite3.connect('openelections2002.db')

cur = conn.cursor()

#cur.execute('create table ga_primary_state_house_20020820_fullnames (name text, last_name text, party text, district_number text, votes text, percent text);')

html = urlopen("http://sos.ga.gov/elections/election_results/2000_0718/house.htm")
bs = BeautifulSoup(html.read(), "lxml")

SQL = """
INSERT INTO ga_primary_state_house_20020820_fullnames
    (name, party, district_number, votes, percent)
    VALUES (:name, :party, :district_number, :votes, :percent)
"""

districts = bs.findAll('h4')[1:]
names = bs.findAll('pre')

for counter, name in enumerate(names):

    district_info = districts[counter].get_text().replace("STATE REPRESENTATIVE - ", "")

    if 'Republican' in district_info:
        party = 'Republican'
        district_info = district_info.replace('Republican', '')
    else:
        party = 'Democrat'
        district_info = district_info.replace('Democrat', '')
    district_number = district_info.replace('DISTRICT', '')
    district_number = district_number.replace(' ', '')

    n = name.get_text()
    name_parts = n.split('\n')[3:-1]

    for line in name_parts:
        name = line[:25]
        votes = line[25:30].replace(',', '').replace(' ', '')
        percent = line[30:].replace(' ', '')

        data = {
            'name': name,
            'party': party,
            'district_number': district_number,
            'votes': votes,
            'percent': percent
        }

        #print(data)
        cur.execute(SQL, data)

conn.commit()
cur.close()
conn.close()
