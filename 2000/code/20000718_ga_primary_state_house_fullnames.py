# python 3.5

from urllib.request import urlopen

from bs4 import BeautifulSoup
import psycopg2


conn = psycopg2.connect(
    database='openelections',
    user='jreed',
    host='127.0.0.1',
    port='5432'
)

cur = conn.cursor()

html = urlopen("http://sos.ga.gov/elections/election_results/2000_0718/house.htm")
bs = BeautifulSoup(html.read(), "lxml")

SQL = """
INSERT INTO ga_primary_state_house_20000718_fullnames
    (name, party, district_number, votes, percent)
    VALUES (%(name)s, %(party)s, %(district_number)s, %(votes)s, %(percent)s);
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

        cur.execute(SQL, data)

conn.commit()
conn.close()
