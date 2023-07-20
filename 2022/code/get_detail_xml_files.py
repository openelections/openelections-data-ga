#!/usr/bin/python3.9
# -*- coding: utf-8 -*-
import os
from urllib.parse import urlparse

import cloudscraper

import helpers


def get_detail_xml_files(url, logger):
    logger.info(f'Starting to process URL: {url}')
    scraper = cloudscraper.create_scraper()
    participating_county_urls = helpers.get_participating_counties(url, logger) # noqa
    for c in participating_county_urls:
        logger.info(c)
        o = urlparse(c)
        county_name = o.path.split('/')[3]
        eid = o.path.split('/')[4]
        v = o.query.replace('v=', '')
        logger.info(f'Building for detail xml url for {county_name} country')
        url = helpers.build_county_detail_xml_url(county_name, eid, v, logger)
        helpers.download_detail_xml_file(url, county_name, scraper, logger)


if __name__ == '__main__':
    # move to working directory...
    abspath = os.path.abspath(__file__)
    dname = os.path.dirname(abspath)
    os.chdir(dname)

    logger = helpers.setup_logger_stdout('get_detail_xml_files')

    url = 'https://results.enr.clarityelections.com/GA/112811/web.285569/#/access-to-races' # noqa

    get_detail_xml_files(url, logger)
