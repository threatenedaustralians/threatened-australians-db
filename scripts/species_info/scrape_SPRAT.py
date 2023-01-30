# Scrape the SPRAT website for description and habitat info

import requests
import urllib.request
import time
from bs4 import BeautifulSoup
from lxml import html
import csv
import pandas as pd
import json
import re
# import geopandas as gpd
pd.options.mode.chained_assignment = None

# animals = pd.read_json("output/clean_data/species_FT_animals_clean.json")
# plants = pd.read_json("output/clean_data/species_plants_clean.json")
species = pd.read_json("output/clean_data/species_clean_no_geom.json")

species = species[['taxon_ID', 'scientific_name',
    'vernacular_name', 'SPRAT_profile']]

# species = species.sample(n=10)

headers = {'user-agent': 'my-app/0.0.1'}


def get_data(url):
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        return response
    elif response.status_code == 429:
        time.sleep(45)
        # website doesn't even have a response.header so I can't use the next line of code
        # time.sleep(int(response.headers["Retry-After"]))
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response
        else:
            print(response.text)
            print(response.status_code)
            print(response.headers)
            return "Request failed"
    else:
        print(response.text)
        print(response.status_code)
        print(response.headers)
        return "Request failed"


def get_descrip(species_ID):
    species_url = "http://www.environment.gov.au/cgi-bin/sprat/public/publicspecies.pl?taxon_id=" + \
        str(species_ID)
    print(species_ID)
    species_html = get_data(species_url)
    if species_html == "Request failed":
        return "Request failed"
    else:
        species_html_text = BeautifulSoup(species_html.text, 'html.parser')
        descrip_find = species_html_text.find("a", string="Description")
        about_find = species_html_text.find(string=re.compile("About the"))
        if descrip_find:
            descrip_text = descrip_find.find_next("p")
            descrip_text = str(descrip_text)
            # remove all html tags in one line of code
            descrip_text = descrip_text.replace("<p>", "")
            descrip_text = descrip_text.replace("</p>", "")
            return descrip_text
        elif about_find:
            about_text = about_find.find_next("p")
            about_text = str(about_text)
            about_text = about_text.replace("<p>", "")
            about_text = about_text.replace("</p>", "")
            return about_text
        else:
            return "NA"


species['description'] = species.apply(
    lambda row: get_descrip(row['taxon_ID']), axis=1)


species_df = pd.DataFrame(species)

species.to_json(
    "data/EJA_species_info_SPRAT.json",
    orient="records"
)
species.to_csv(
    "data/EJA_species_info_SPRAT.csv",
    index=False
)

######################################

# request html text from species url
# extract description and habitat text
# return description and habitat text into separate columns in dataframe
# return dataframe


def get_info(species_ID):
    species_url = "http://www.environment.gov.au/cgi-bin/sprat/public/publicspecies.pl?taxon_id=" + \
        str(species_ID)
    print(species_ID)
    return_dicts = {"descrip": "", "habitat": ""}
    species_html = get_data(species_url)
    if species_html == "Request failed":
        return_dicts["descrip"] = "Request failed"
        return_dicts["habitat"] = "Request failed"
    else:
        species_html_text = BeautifulSoup(species_html.text, 'html.parser')
        return_dicts["descrip"] = get_descrip(species_html_text)
        return_dicts["habitat"] = get_habitat(species_html_text)
    return return_dicts


def get_descrip(species_html_text):
    descrip_find = species_html_text.find("a", string="Description")
    about_find = species_html_text.find(string=re.compile("About the"))
    if descrip_find:
        descrip_text = descrip_find.find_next("p")
        descrip_text = str(descrip_text)
        # optimise the next two lines
        descrip_text = descrip_text.replace("<p>", "")
        descrip_text = descrip_text.replace("</p>", "")
        return_dicts["descrip"] = descrip_text
    elif about_find:
        about_text = about_find.find_next("p")
        about_text = str(about_text)
        about_text = about_text.replace("<p>", "")
        about_text = about_text.replace("</p>", "")
        return_dicts["descrip"] = about_text
    else:
        return_dicts["descrip"] = "NA"


def get_habitat(species_html_text):
    habitat_find = species_html_text.find("a", string="Habitat")
    if habitat_find:
        habitat_text = habitat_find.find_next("p")
        habitat_text = str(habitat_text)
        habitat_text = habitat_text.replace("<p>", "")
        habitat_text = habitat_text.replace("</p>", "")
        return_dicts["habitat"] = habitat_text
    else:
        return_dicts["habitat"] = "NA"


animals_slice['descrip_habitat'] = animals_slice.apply(
    lambda row: [get_info(row['taxon_ID'])], axis=1)

animals_slice['description'] = animals_slice.apply(
    lambda row: row['descrip_habitat'][0]['descrip'], axis=1)

animals_slice['habitat'] = animals_slice.apply(
    lambda row: row['descrip_habitat'][0]['habitat'], axis=1)

animals_slice.iloc[0]['description']
animals_slice.iloc[0]['habitat']
