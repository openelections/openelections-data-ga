# python 3.5

from urllib.request import urlopen

from bs4 import BeautifulSoup
import psycopg2


conn = psycopg2.connect(
    database='dev',
    user='jreed',
    host='127.0.0.1',
    port='5432'
)

cur = conn.cursor()

html = urlopen("http://sos.ga.gov/elections/election_results/2002_1105/senate.htm")
bs = BeautifulSoup(html.read(), "lxml")

SQL = """
INSERT INTO ga_general_state_senate_20021105_fullnames
    (name, party, district_number, votes, percent)
    VALUES (%(name)s, %(party)s, %(district_number)s, %(votes)s, %(percent)s);
"""

districts = bs.findAll('h4')[1:]
names = bs.findAll('pre')

for counter, name in enumerate(names):

    district_info = districts[counter].get_text().replace("STATE SENATOR - DISTRICT", "")
    district_number = district_info.replace(' ', '')

    n = name.get_text()
    name_parts = n.split('\n')[3:-1]

    for line in name_parts:
        name = line[:21]
        party = line[21:25].replace(' ', '')
        votes = line[30:40].replace(',', '').replace(' ', '')
        percent = line[41:].replace(' ', '')

        if party == '(D)':
            party = 'Democrat'
        
        if party == '(R)':
            party = 'Republican'

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
