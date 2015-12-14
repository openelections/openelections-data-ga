import string
import requests
from BeautifulSoup import BeautifulSoup
import unicodecsv

OFFICES = ['United States Senator, Isakson', 'Governor', 'Lieutenant Governor', 'Secretary Of State', 'Attorney General',
'State School Superintendent', 'Commissioner Of Insurance', 'Commissioner Of Agriculture', 'Commissioner Of Labor',
'U.S. Representative, District 1', 'U.S. Representative, District 2', 'U.S. Representative, District 3', 'U.S. Representative, District 4',
'U.S. Representative, District 5', 'U.S. Representative, District 6', 'U.S. Representative, District 7', 'U.S. Representative, District 8',
'U.S. Representative, District 9', 'U.S. Representative, District 10', 'U.S. Representative, District 11',
'U.S. Representative, District 12', 'U.S. Representative, District 13']

def parse_statewide_url(url):
    contests = []
    r = requests.get(url)
    soup = BeautifulSoup(r.text)
    offices = soup.findAll('strong')[1:]
    for office in offices:
        if office.text in OFFICES:
            o = office.text

def get_candidates(candidates_row):
    candidates = []
    for cell in candidates_row.findAll('td'):
        if cell.text == '&nbsp;':
            continue
        elif cell.findAll('br')[0].previous.strip() == 'Totals':
            continue
        else:
            candidates.append({'name': cell.findAll('br')[0].previous.strip(), 'party': cell.findAll('br')[1].next.strip().replace('(','').replace(')',''),
            'total_votes': cell.findAll('br')[3].previous.strip().replace(',',''), 'counties': []})
    return candidates

def parse_county_results(url):
    r = requests.get(url)
    soup = BeautifulSoup(r.text)
    table = soup.findAll('table')[2]
    rows = table.findAll('tr')
    candidates = get_candidates(rows[0].find('table').find('tr'))
    for row in rows[4:]:
        county_name = row.find('td').text.strip()
        for idx, r in enumerate(row.findAll('td')[2:-1]):
            candidate = candidates[idx]
            candidate['counties'].append({"county": county_name, 'votes': r.text.replace(',','')})
    return candidates

def get_county_results(url, file_name, office, district):
    results = parse_county_results(url)
    with open(file_name, 'wb') as csvfile:
        w = unicodecsv.writer(csvfile, encoding='utf-8')
        w.writerow(['county', 'office', 'district', 'party', 'candidate', 'votes'])
        for result in results:
            for county in result['counties']:
                w.writerow([county['county'], office, district, result['party'], result['name'], county['votes']])

def get_state_senate(base_url, districts):
    with open('state_senate.csv', 'wb') as csvfile:
        w = unicodecsv.writer(csvfile, encoding='utf-8')
        for district in range(1, districts):
            url = base_url + string.zfill(str(district), 2)+'.htm'
            print url
            results = parse_county_results(url)
            for result in results:
                for county in result['counties']:
                    w.writerow([county['county'], 'State Senate', district, result['party'], result['name'], county['votes']])

def get_state_house(base_url, districts):
    with open('state_house.csv', 'wb') as csvfile:
        w = unicodecsv.writer(csvfile, encoding='utf-8')
        for district in range(501, districts):
            url = base_url + str(district)+'.htm'
            print url
            d = district - 500
            results = parse_county_results(url)
            for result in results:
                for county in result['counties']:
                    w.writerow([county['county'], 'State House', d, result['party'], result['name'], county['votes']])
