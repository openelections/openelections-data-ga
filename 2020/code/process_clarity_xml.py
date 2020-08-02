#!/usr/bin/python3.7
# -*- coding: utf-8 -*-
import logging
import os
import sys
import xml.etree.ElementTree as ET

import psycopg2


INSERT_SQL = """
    INSERT INTO dev.ga_special_state_house_20200128
        (county, precinct, office, candidate, party,
        total_votes, vote_type, votes)
    VALUES (%(county)s, %(precinct)s, %(office)s, %(candidate)s, %(party)s,
        %(total_votes)s, %(vote_type)s, %(votes)s);
"""


def create_connection():
    conn = psycopg2.connect(
        database='openelections',
        user='jreed',
        host='127.0.0.1',
        port='5432'
    )
    return conn


def process_detail_xml_file(file, logger):

    results = []

    tree = ET.parse(file)
    root = tree.getroot()

    logger.info(f"Processing {root.find('ElectionName').text} results")
    county = root.find('Region').text
    logger.info(f'Processing county: {county}')

    contests = root.findall('Contest')
    for contest in contests:
        office = contest.get('text')
        candidates = contest.findall('Choice')
        for c in candidates:
            candidate = c.get('text')
            party = c.get('party')
            total_votes = c.get('totalVotes')
            vote_types = c.findall('VoteType')
            for v in vote_types:
                vote_type = v.get('name')
                votes = v.get('votes')
                precincts = v.findall('Precinct')
                for p in precincts:
                    precinct = p.get('name')
                    votes = p.get('votes')
                    results.append(
                        {
                            'county': county,
                            'precinct': precinct,
                            'office': office,
                            'candidate': candidate,
                            'party': party,
                            'total_votes': total_votes,
                            'vote_type': vote_type,
                            'votes': votes
                        }
                    )
    write_results(results)


def setup_logger_stdout(logger_name):
    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.DEBUG)
    ch = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    return logger


def write_results(results):
    conn = create_connection()
    conn.cursor().executemany(INSERT_SQL, results)
    conn.commit()
    conn.close()


if __name__ == '__main__':
    # move to working directory...
    abspath = os.path.abspath(__file__)
    dname = os.path.dirname(abspath)
    os.chdir(dname)

    logger = setup_logger_stdout('process_detail_xml_file')

    process_detail_xml_file('Detail.xml', logger)
