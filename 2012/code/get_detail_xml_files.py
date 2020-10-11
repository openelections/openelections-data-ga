#!/usr/bin/python3.7
# -*- coding: utf-8 -*-
import os

import clarify

import helpers


def get_detail_xml_files(county_url, logger):
    j = clarify.Jurisdiction(url=county_url, level='state')
    subs = j.get_subjurisdictions()
    for s in subs:
        county = s.name
        url = s.report_url('xml')
        if county in ['Coweta', 'Dooly', 'Lowndes', 'McIntosh', 'Oglethorpe']:
            if not url:
                logger.error(f'No detail XML URL found for {county} country')
            else:
                helpers.download_detail_xml_file(url, county, logger)


if __name__ == '__main__':
    # move to working directory...
    abspath = os.path.abspath(__file__)
    dname = os.path.dirname(abspath)
    os.chdir(dname)

    logger = helpers.setup_logger_stdout('get_detail_xml_files')

    county_url = 'https://results.enr.clarityelections.com/GA/40378/95366/en/summary.html' # noqa

    get_detail_xml_files(county_url, logger)