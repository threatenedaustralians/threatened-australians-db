# Scrape webpages or html files for image urls for each species profile on the ALA

# Helpful websites:
# https://towardsdatascience.com/how-to-web-scrape-with-python-in-4-minutes-bc49186a8460
# https://www.crummy.com/software/BeautifulSoup/bs4/doc/
# https://api.ala.org.au/
# https://support.ala.org.au/support/solutions/articles/6000196777-ala-api-how-to-access-ala-web-services
# http://www.compjour.org/warmups/govt-text-releases/intro-to-bs4-lxml-parsing-wh-press-briefings/
# https://www.youtube.com/watch?v=LC9yE7T93cs
# https://medium.com/ymedialabs-innovation/web-scraping-using-beautiful-soup-and-selenium-for-dynamic-page-2f8ad15efe25

# Workflow:
# (1) Get a list of all URLs for images for all of our animal threatened species (ATS) from ALA taking just the first image that comes up
# (2) Scrape the first image for each ATS from ALA as a JPG (or whatever) and save them to a folder with a sensible name
# (3) Go through that folder of images together someday (together then perhaps split) and note down any that don't make the cut. Note that down by deleting the URL from the list in (1)
# (4) Once we finish (3) then see how many blank URLs we have
# Repeat steps (2) and (3) for this now much smaller subset of species needing an image but on the second JPG on ALA
# (5) Hopefully after (4) there are now few enough left that are blank that we can manually figure them out

# Extract each first url from API
# Then do the others manually?

# "Erythrotriorchis radiatus",
# "Pezoporus occidentalis",
# "Macroderma gigas",
# "Isoodon auratus auratus",
# "Calyptorhynchus banksii naso"

import requests
import urllib.request
import time
from bs4 import BeautifulSoup
import json
import os
import pandas as pd

pd.options.mode.chained_assignment = None  # default='warn'


animals = pd.read_json("output/clean_data/species_clean_FT_animals.json")

# main requests

headers = {'user-agent': 'my-app/0.0.1'}


def get_data(url):
    time.sleep(0.1)
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        return response
    elif response.status_code == 429:
        time.sleep(int(response.headers["Retry-After"]))
        response = requests.get(url, headers=headers)
        return response
    else:
        print(response.text)
        print(response.status_code)
        print(response.headers)
        return "Request failed"


def get_ALA_URL(scientific_name_query):
    species_request = get_data(
        "http://bie.ala.org.au/ws/search.json?q=" +
        str(scientific_name_query)
    )
    if species_request == "Request failed":
        return "Request failed"
    else:
        species_response = species_request.json()
        first_response = species_response['searchResults']['results'][0]
        guid = first_response['guid']
        if guid:
            return "https://bie.ala.org.au/species/" + str(guid)
        else:
            return "No guid value was found in the first record"


animals['ALA_URL'] = animals.apply(
    lambda row: get_ALA_URL(row['scientific_name']), axis=1)


def get_API_image_URL(scientific_name_query):
    species_request = get_data(
        "http://bie.ala.org.au/ws/search.json?q=" +
        str(scientific_name_query)
    )
    if species_request == "Request failed":
        return "Request failed"
    else:
        species_response = species_request.json()
        first_response = species_response['searchResults']['results'][0]
        try:
            large_image_url = first_response['largeImageUrl']
        # except KeyError:
        except:
            large_image_url = "No image URL was found in first record"
    return large_image_url


animals['ALA_API_image_URL'] = animals.apply(
    lambda row: get_API_image_URL(row['scientific_name']), axis=1)

animals = pd.DataFrame(animals)
animals.to_json(
    "data/image_vetting/animals_API_image_URLs.json",
    orient="records"
)
