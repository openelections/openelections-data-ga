import requests, csv, re
from bs4 import BeautifulSoup

def get_candidates(candidates_row):
    candidates = []

    for cell in candidates_row.findAll('td'):
        # print(cell.text)
        if cell.text == '\xa0':
            continue
        else:
            print(cell.findAll('br'))
            candidates.append({'name': cell.findAll('br')[0].previous.strip(), 'party': cell.findAll('br')[1].next.strip().replace('(','').replace(')',''),
            'total_votes': cell.findAll('br')[3].previous.strip().replace(',',''), 'counties': []})
    return candidates

def county_parse(rows, candidates):
    for r in rows:
        county_name = r.find('td').text.strip()
        cells = r.findAll('td')[3:]
        for idx, td in enumerate(cells):
            # print(idx)
            candidates[idx]['counties'].append({"county": county_name, 'votes': td.text.replace(',','').strip()})
    return candidates

api_endpoint = 'http://openelections.net/api/v1/election/?format=json&limit=0&state__postal=GA&start_date__year=2007'

r = requests.get(api_endpoint).json()

data = r['objects']
headers = ['county', 'office', 'district', 'party', 'candidate', 'votes']

for i, d in enumerate(data):
    print('Now in object', i)
    for l in d['direct_links']:
        
        temp1 = []
        temp2 = []
        el = requests.get(l)
        soup = BeautifulSoup(el.text, 'lxml')
        
        # This one URL has a different kind of table
        if 'swall' in l:
            table = soup.findAll('table')
            rows = table[1].findAll('tr')
            table1 = rows[4:14]
            table2 = rows[18:]

            office1 = rows[1].find('h4').text.strip().split(',')[0]
            office2 = rows[15].find('h4').text.strip().split(',')[0]
            district1 = re.findall('\d+', rows[1].find('h4').text.strip())[0]
            district2 = re.findall('\d+', rows[15].find('h4').text.strip())[0]
            fname1 = l.split('/')[-2] + 'swall-rep.csv'
            fname2 = l.split('/')[-2] + 'swall-sen.csv'
            
            with open(fname1, 'w') as f1:
                w1 = csv.writer(f1)

                for trow in table1:
                    tcells = trow.findAll('td')
                    p = tcells[1].text.strip().replace('(','').replace(')','')
                    v = tcells[2].text.strip().replace(',','')
                    n = tcells[0].text.strip()
                    w1.writerow([office1, district1, p, n, v])

            with open(fname2, 'w') as f2:
                w2 = csv.writer(f2)

                for trow2 in table2:
                    tcells2 = trow.findAll('td')
                    temp2 = [office2, district2, tcells2[1].text.replace('(','').replace(')',''),tcells2[0].text.strip(), tcells2[2].text.strip().replace(',','') ]
                    w2.writerow(temp2)

        else:
            fname = l.split('/')[-2] + '.csv'
            table = soup.findAll('table')
            rows = table[len(table) - 1].findAll('tr')

            office = soup.find('h4').text.strip().split(',')[0]
            district = re.findall('\d+', soup.find('h4').text.strip())[0]

            candidates = get_candidates(rows[0])
            w_data = county_parse(rows[3:], candidates)

            with open(fname, 'w') as out:
                w = csv.writer(out)
                w.writerow(['county','office','district','party','candidate','votes'])
                for item in w_data:
                    for j in item['counties']:
                        temp = [j['county'].capitalize(), office, district, item['party'], item['name'].capitalize(), j['votes'] ]
                        w.writerow(temp)