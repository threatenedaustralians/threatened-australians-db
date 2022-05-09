# Clean attribute data

#### Libraries ####

library(tidyverse)
library(sf)
library(magrittr)
library(jsonlite)
library(units)
library(readxl)
library(stringr)
library(rmapshaper)
library(httpgd)

#### Import: electoral ####

MP_info <- fromJSON(
    "data/MP_info.json"
)
MP_voting_info <- fromJSON(
    "data/MP_voting_info.json"
)
elects <- st_read(
    "output/clean_data/elects_clean.gpkg"
)
postcodes <- st_read(
    "data/POA_2021_AUST_GDA94_SHP/POA_2021_AUST_GDA94.shp"
)
demo <- readxl::read_xlsx(
    "data/AEC_demographic-classification-1-january-2019/01-demographic-classification-as-at-1-january-2019.xlsx"
)

#### Clean: electoral ####

MP_info_clean <- MP_info %>%
    mutate(
        electorate = word(
            .$representing, 1,
            sep = ","
        )
    ) %>%
    distinct() %>%
    relocate(
        electorate,
        .after = representing
    ) %>%
    add_row(
        MP_ID = "HW9",
        full_name = "Nicholas David Champion",
        titles = "NA",
        representing = "Spence, South Australia",
        electorate = "Spence", # can link to TVFY on electorate attribute
        email_address = "NA",
        Twitter_address = "NA",
        Facebook_address = "NA",
        image_URL = "https://www.aph.gov.au/api/parliamentarian/HW9/image",
        former_member = as.logical("TRUE"),
        date_elected = "2019-05-18T00:000:00"
    ) %T>%
    write_json(
        "output/clean_data/MP_info_clean.json"
    )

MP_voting_info_clean <- MP_voting_info %>%
    # since we did an outer join in the py req script, we got two extra mems and the retired member for Spence
    # we have to remove manually and replace
    # we couldn't do an inner otherwise we lose the member for Spence
    # John McVeigh 10889 - https://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=125865
    # David Feeney 10709 - https://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=I0O
    filter(
        !ID %in% c(10111, 10889, 10709)
    ) %>%
    mutate(
        party = replace(
            party, party == "SPK", "Liberal Party"
        )
    ) %>%
    mutate(
        party = replace(
            party, party == "CWM", "National Party"
        )
    ) %>%
    add_row(
        ID = NA,
        first = "NA",
        last = "NA",
        house = "representatives",
        electorate = "Spence", # can link to TVFY on electorate attribute
        category = "NA",
        party = "Australian Labor Party",
        url = "NA"
    ) %T>%
    write_json(
        "output/clean_data/MP_voting_info_clean.json"
    )

demo_clean <- demo %>%
    rename(
        state_territory = "State or territory",
        demographic_class = "Demographic classification",
        electorate = "Electoral division"
    ) %>%
    mutate(
        state_territory = replace(
            state_territory, state_territory == "ACT", "Australian Capital Territory"
        )
    ) %>%
    mutate(
        state_territory = replace(
            state_territory, state_territory == "NT", "Northern Territory"
        )
    ) %>%
    mutate(
        state_territory_abbrev = case_when(
            state_territory == "Australian Capital Territory" ~ "ACT",
            state_territory == "New South Wales" ~ "NSW",
            state_territory == "Northern Territory" ~ "NT",
            state_territory == "Queensland" ~ "QLD",
            state_territory == "South Australia" ~ "SA",
            state_territory == "Tasmania" ~ "TAS",
            state_territory == "Victoria" ~ "VIC",
            state_territory == "Western Australia" ~ "WA"
        )
    ) %T>%
    write_json(
        "output/clean_data/demo_clean.json"
    )
