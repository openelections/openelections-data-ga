import os
import glob
import csv

year = '2022'
election = '20221108'
path = election+'*precinct.csv'
output_file = election+'__ga__general__precinct.csv'

def generate_headers(year, path):
    os.chdir(year)
    os.chdir('counties')
    vote_headers = []
    for fname in glob.glob(path):
        print(fname)
        with open(fname, "r") as csvfile:
            reader = csv.reader(csvfile)
            headers = next(reader)
            print(set(list(h for h in headers if h not in ['county','precinct', 'office', 'district', 'candidate', 'party'])))
            #vote_headers.append(h for h in headers if h not in ['county','precinct', 'office', 'district', 'candidate', 'party'])
#    with open('vote_headers.csv', "w") as csv_outfile:
#        outfile = csv.writer(csv_outfile)
#        outfile.writerows(vote_headers)

def generate_offices(year, path):
    os.chdir(year)
    os.chdir('counties')
    offices = []
    for fname in glob.glob(path):
        with open(fname, "r") as csvfile:
            print(fname)
            reader = csv.DictReader(csvfile)
            for row in reader:
                if not row['office'] in offices:
                    offices.append(row['office'])
    with open('offices.csv', "w") as csv_outfile:
        outfile = csv.writer(csv_outfile)
        outfile.writerows(offices)

def generate_consolidated_file(year, path, output_file):
    results = []
    os.chdir(year)
    os.chdir('counties')
    for fname in glob.glob(path):
        with open(fname, "r") as csvfile:
            print(fname)
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row['office'].strip() in ['US House of Representatives', 'Straight Party', 'President', 'Governor', 'Secretary of State', 'State Mine Inspector', 'Corporation Commissioner', 'State Auditor', 'State Treasurer', 'Commissioner of Agriculture & Commerce', 'Commissioner of Insurance', 'Commissioner of Labor', 'Attorney General', 'U.S. House', 'State Senate', 'U.S. Senate', 'State Representative', 'Registered Voters', 'Ballots Cast', 'US Senate', 'Lieutenant Governor', 'Commissioner of Agriculture', 'State House']:
                    if all(k in set(row) for k in ['absentee_by_mail_votes','election_day_votes','advance_voting_votes','provisional_votes']):
                        results.append([row['county'], row['precinct'], row['office'], row['district'], row['candidate'], row['party'], row['votes'], row['absentee_by_mail_votes'], row['election_day_votes'], row['advance_voting_votes'], row['provisional_votes']])
                    else:
                        results.append([row['county'], row['precinct'], row['office'], row['district'], row['candidate'], row['party'], row['votes'], None, None, None, None])
    os.chdir('..')
#    os.chdir('..')
    with open(output_file, "w") as csv_outfile:
        outfile = csv.writer(csv_outfile)
        outfile.writerow(['county','precinct', 'office', 'district', 'candidate', 'party', 'votes', 'absentee_by_mail','election_day','advance_in_person','provisional'])
        outfile.writerows(results)
