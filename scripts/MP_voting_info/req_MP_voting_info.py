# Script to scrape the TVFY information for each elected rep (ER)

import requests
import urllib.request
import time
from bs4 import BeautifulSoup
import json
import os
import pandas as pd

# main requests

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
        return "Request failed"


def parse_policy(policy):
    policy_ppl = policy['people_comparisons']
    ER_policy_list = []
    for item in policy_ppl:
        # if item['person']['latest_member']['house'] == "representatives":
        ER_policy = {
            "ID": item['person']['id'],
            "house": item['person']['latest_member']['house'],
            "category": item['category']
        }

        ER_policy_list.append(ER_policy)
    return ER_policy_list


def parse_people(people):
    ER_people_list = []
    for item in people:
        # if item['latest_member']['house'] == "representatives":
        ER_people = {
            "ID": item['id'],
            "first": item['latest_member']['name']['first'],
            "last": item['latest_member']['name']['last'],
            "electorate": item['latest_member']['electorate'],
            "house": item['latest_member']['house'],
            "party": item['latest_member']['party']
        }

        ER_people_list.append(ER_people)
    return ER_people_list


policy = get_data(
    "https://theyvoteforyou.org.au/api/v1/policies/172.json?key=hoKyN27uXNGAW0kNPf19")
ER_policy_list = parse_policy(policy)
ER_policy_df = pd.DataFrame(ER_policy_list)
ER_policy = ER_policy_df[ER_policy_df['house'] == "representatives"]

people = get_data(
    "https://theyvoteforyou.org.au/api/v1/people.json?key=hoKyN27uXNGAW0kNPf19")
ER_people_list = parse_people(people)
ER_people_df = pd.DataFrame(ER_people_list)
ER_people = ER_people_df[ER_people_df['house'] == "representatives"]

# If we join by outer, we get two former members
# John McVeigh 10889 - https://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=125865
# David Feeney 10709 - https://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=I0O
ER_info = pd.merge(ER_policy, ER_people, "outer")
ER_info = ER_info[['ID', 'first', 'last', 'house',
                   'electorate', 'category', 'party']]

# exp_ER_info['url'] = ER_info.apply(
#     lambda row: "https://theyvoteforyou.org.au/people/representatives/" +
#     row.electorate + "/" + row.first + "_" + row.last + "/policies/172", axis=1
# )
ER_info['url'] = "https://theyvoteforyou.org.au/people/representatives/" + ER_info['electorate'].map(str) + "/" + ER_info['first'].map(str) + "_" + ER_info['last'].map(str) + "/policies/172"
ER_info['url'] = ER_info['url'].str.lower()

ER_info.to_json(
    "data/MP_voting_info.json",
    orient="records"
)
