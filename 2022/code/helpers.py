#!/usr/bin/python3.9
# -*- coding: utf-8 -*-
from io import BytesIO
import json
import logging
import os
import re
import sys
import time
import zipfile

from bs4 import BeautifulSoup
from selenium import webdriver


def build_county_detail_xml_url(county_name, eid, v, logger):
    url = f'https://results.enr.clarityelections.com//GA/{county_name}/{eid}/{v}/reports/detailxml.zip' # noqa
    logger.info(f'URL: {url}')
    return url


def download_detail_xml_file(url, county, scraper, logger):
    logger.info(f'Downloading {url}')
    r = scraper.get(url)
    z = zipfile.ZipFile(BytesIO(r.content))
    z.extractall()
    os.rename('detail.xml', f'detail_{county}.xml')
    logger.info(f'Renaming detail.xml to detail_{county}.xml')


def get_county_detail_xml_urls(url, sleep_seconds, logger):
    # TODO: This is where I need to wait for the detail.xml to show up...
    html = get_rendered_html(url, sleep_seconds)
    soup = BeautifulSoup(html, 'lxml')
    links = []
    for link in soup.find_all(attrs={'href': re.compile("http")}):
        links.append(link.get('href'))
    for link in links:
        if link.endswith('detailxml.zip'):
            logger.info('Detail XML URL found')
            return link


def get_georgia_counties(logger):
    with open('georgia_counties_all.json') as f:
        ga_counties = json.load(f)
    counties = []
    for c in ga_counties:
        counties.append(c.get('county'))
    logger.info(f'Loaded {len(counties)} counties')
    return counties


def get_participating_counties(url, logger):
    counties = get_georgia_counties(logger)
    html = get_rendered_html(url)
    soup = BeautifulSoup(html, 'lxml')
    links = []
    for link in soup.find_all(attrs={'href': re.compile("https")}):
        links.append(link.get('href'))
    county_urls = []
    for link in links:
        if [c for c in counties if (c in link)]:
            county_urls.append(link)
    logger.info(f'Found {len(county_urls)} counties to process')
    return county_urls


def get_rendered_html(url, sleep_seconds=3):
    browser = webdriver.Chrome()
    browser.get(url)
    time.sleep(sleep_seconds)
    scroll_to_bottom(browser)
    html = browser.page_source
    print(html)
    browser.close()
    return html


def scroll_to_bottom(driver):

    old_position = 0
    new_position = None

    while new_position != old_position:
        # Get old scroll position
        old_position = driver.execute_script(
                ("return (window.pageYOffset !== undefined) ?"
                 " window.pageYOffset : (document.documentElement ||"
                 " document.body.parentNode || document.body);"))
        # Sleep and Scroll
        time.sleep(1)
        driver.execute_script((
                "var scrollingElement = (document.scrollingElement ||"
                " document.body);scrollingElement.scrollTop ="
                " scrollingElement.scrollHeight;"))
        # Get new position
        new_position = driver.execute_script(
                ("return (window.pageYOffset !== undefined) ?"
                 " window.pageYOffset : (document.documentElement ||"
                 " document.body.parentNode || document.body);"))


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
