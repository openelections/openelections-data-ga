#!/usr/bin/python3.9
# -*- coding: utf-8 -*-
import os
from urllib.parse import urlparse

import helpers


def get_detail_xml_files(url, logger):
    logger.info(f'Starting to process URL: {url}')
    participating_county_urls = helpers.get_participating_counties(url, 10, logger) # noqa
    for c in participating_county_urls:
        logger.info(c)
        o = urlparse(c)
        county = o.path.split('/')[3]
        logger.info(f'Looking for detail xml for {county} country')
        url = helpers.get_county_detail_xml_urls(c, 10, logger)
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

    url = 'https://results.enr.clarityelections.com/GA/109978/web.276935/#/access-to-races' # noqa

    get_detail_xml_files(url, logger)
