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

url = "http://sos.ga.gov/elections/election_results/2000_1107/senate.htm"

html = urlopen(url)
bsObj = BeautifulSoup(html.read(), "lxml")

SQL = """
INSERT INTO ga_general_state_senate_20001107_fullnames
    (name, party, district_number, votes, percent)
    VALUES (%(name)s, %(party)s, %(district_number)s, %(votes)s, %(percent)s);
"""

districts = bsObj.findAll('h4')[1:]
names = bsObj.findAll('pre')

for counter, name in enumerate(names):

    district_info = districts[counter].get_text().replace(
        "STATE SENATOR - ", ""
    )

    district_number = district_info.replace('DISTRICT', '')
    district_number = district_number.replace(' ', '')

    n = name.get_text()
    name_parts = n.split('\n')[3:-1]

    for line in name_parts:
        name = line[:21]
        party = line[21:24].replace(' ', '')
        if party == '(D)':
            party = 'Democrat'
        elif party == '(R)':
            party = 'Republican'
        elif party == '(Lib)':
            party = 'Libertarian'
        elif party == '(Ind)':
            party = 'Independent'
        votes = line[30:41].replace(',', '').replace(' ', '')
        percent = line[42:].replace(' ', '')

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
