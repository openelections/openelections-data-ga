#!/usr/bin/python3.7
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
import requests
from selenium import webdriver
from selenium.webdriver.chrome.options import Options


def download_detail_xml_file(url, county, logger):
    logger.info(f'Downloading {url}')
    r = requests.get(url, stream=True)
    z = zipfile.ZipFile(BytesIO(r.content))
    z.extractall()
    os.rename('detail.xml', f'detail_{county}.xml')
    logger.info(f'Renaming detail.xml to detail_{county}.xml')


def get_county_detail_xml_urls(url, sleep_seconds, logger):
    html = get_rendered_html(url, sleep_seconds)
    soup = BeautifulSoup(html, 'lxml')
    links = []
    for link in soup.find_all(attrs={'href': re.compile("http")}):
        links.append(link.get('href'))
    for l in links:
        if l.endswith('detailxml.zip'):
            logger.info('Detail XML URL found')
            return l


def get_georgia_counties(logger):
    with open('georgia_counties.json') as f:
        ga_counties = json.load(f)
    counties = []
    for c in ga_counties:
        counties.append(c.get('county'))
    logger.info(f'Loaded {len(counties)} counties')
    return counties


def get_participating_counties(url, sleep_seconds, logger):
    counties = get_georgia_counties(logger)
    html = get_rendered_html(url, sleep_seconds)
    soup = BeautifulSoup(html, 'lxml')
    links = []
    for link in soup.find_all(attrs={'href': re.compile("http")}):
        links.append(link.get('href'))
    county_urls = []
    for l in links:
        if [c for c in counties if(c in l)]:
            county_urls.append(l)
    logger.info(f'Found {len(county_urls)} counties to process')
    return county_urls


def get_rendered_html(url, sleep_seconds):
    chrome_options = Options()
    chrome_options.add_argument('--headless')
    browser = webdriver.Chrome(
        executable_path="/Users/skunkworks/Development/chromedriver",
        options=chrome_options
    )
    browser.get(url)
    time.sleep(sleep_seconds)
    html = browser.page_source
    browser.close()
    return html


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
