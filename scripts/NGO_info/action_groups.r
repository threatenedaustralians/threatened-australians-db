# action group dataset gathering

#### Libraries ####

library(tidyverse)
library(sf)
library(magrittr)
library(jsonlite)
library(units)
library(readxl)
library(stringr)

#### Create ####

group_name <- c(
    "BirdLife Australia",
    "Australia Conservation Foundation"
)
group_name_abbrev <- c(
    "BLA",
    "ACF"
)
# logo_URL <- c(
#     "https://cdn.pixabay.com/photo/2017/09/06/15/05/logo-2721837_960_720.png",
#     "https://cdn.pixabay.com/photo/2017/09/06/15/05/logo-2721837_960_720.png",
#     "https://cdn.pixabay.com/photo/2017/09/06/15/05/logo-2721837_960_720.png"
# )
website_URL <- c(
    "https://birdlife.org.au/",
    "https://www.acf.org.au/"
)
website_get_inv_link <- c(
    "https://birdlife.org.au/get-involved",
    "https://www.acf.org.au/community"
)

action_groups <- data.frame(
    group_name,
    group_name_abbrev,
    # logo_URL,
    website_URL,
    website_get_inv_link
    # disclaimer
) %T>%
    write_json(
        "data/action_groups.json"
    )
