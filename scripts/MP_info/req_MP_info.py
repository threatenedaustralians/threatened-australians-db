# Script to scrape the APH for member info

# Helpful websites:
# https://www.aph.gov.au/api/parliamentarian/?page=1&q=&mem=1&par=-1&gen=0&st=1'
# https://github.com/openaustralia/openaustralia/issues/648
# https://github.com/openaustralia/openaustralia-parser/tree/master/data
# https://github.com/openaustralia/openaustralia-parser/blob/3bbb1908600e2f39151b2979aeccc67415fe967e/README.md

# By using James Polley's intel on the APH API found here - https://github.com/openaustralia/openaustralia/issues/648

# https://www.aph.gov.au/api/parliamentarian/?q=&mem=1&page=0

import requests
import urllib.request
import time
from bs4 import BeautifulSoup
from lxml import html
import csv
import pandas as pd
import json
import re
pd.options.mode.chained_assignment = None

# requests function

headers = {'user-agent': 'my-app/0.0.1'}


def get_data(url):
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        return response.json()
    elif response.status_code == 429:
        time.sleep(int(response.headers["Retry-After"]))
        response = requests.get(url, headers=headers)
        return response.json()
    else:
        print(response.text)
        print(response.status_code)
        print(response.headers)
        return "Response failed"


def parse_json(response):
    MP_list = []
    for item in response:
        MP = {
            "MP_ID": item["MPID"],
            "full_name": item["FullName"],
            "titles": item["Titles"],
            "representing": item["Representing"],
            "email_address": item["EmailAddress"],
            "Twitter_address": item["TwitterAddress"],
            "Facebook_address": item["FacebookAddress"],
            "image_URL": item["ImageUrl"],
            "former_member": item["FormerMember"],
            "date_elected": item["DateElected"]
        }

        MP_list.append(MP)
    return MP_list


main_MP_list = []
for x in range(14):
    aph_response = get_data(
        "https://www.aph.gov.au/api/parliamentarian/?q=&mem=1" + f"&page={x}")
    main_MP_list.extend(parse_json(aph_response))
    print(len(main_MP_list))

MP_info = pd.DataFrame(main_MP_list)

MP_info.to_json(
    "data/22-12-13_MP_info.json",
    orient="records"
)