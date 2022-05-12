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

#### Import: species ####

species <- st_read(
    "output/clean_data/species_clean.gpkg"
)
species_elects <- st_read(
    "output/analysed_data/final/species_elects_tbl.gpkg"
)
threats_collapsed <- fromJSON(
    "output/clean_data/threats_collapsed_clean.json"
)

#### Filter: species ####

species_ft <- species_elects %>%
    st_set_geometry(NULL) %>%
    group_by(taxon_ID) %>%
    summarise() %>%
    ungroup() %>%
    inner_join(threats_collapsed) %>%
    select(taxon_ID) %T>%
    write_json(
        "output/clean_data/species_ft.json"
    )

#### Filter: species - freshwater and terrestrial ####

species_animals_clean <- species %>%
    st_set_geometry(NULL) %>%
    inner_join(species_ft) %>%
    filter(
        taxon_kingdom %in% "Animalia"
    ) %>%
    filter(
        !marine %in% c(
            "Listed", "Listed - overfly marine area"
        )
    ) %>%
    filter(
        !cetacean %in% "Cetacean"
    ) %>%
    filter(
        !scientific_name %in% c(
            "Brachionichthys hirsutus", # Spotted Handfish
            "Brachiopsilus ziebelli", # Ziebell's Handfish, Waterfall Bay Handfish
            "Carcharias taurus (east coast population)", # Grey Nurse Shark (east coast population)
            "Carcharias taurus (west coast population)", # Grey Nurse Shark (west coast population)
            "Carcharodon carcharias", # White Shark, Great White Shark
            "Epinephelus daemelii", # Black Rockcod, Black Cod, Saddled Rockcod
            "Glyphis garricki", # Northern River Shark, New Guinea River Shark
            "Glyphis glyphis", # Speartooth Shark
            "Pristis clavata", # Dwarf Sawfish, Queensland Sawfish
            "Rhincodon typus", # Whale Shark
            "Thymichthys politus", # Red Handfish
            "Zearaja maugeana", # Maugean Skate, Port Davey Skate
            "Thunnus maccoyii", # Southern Bluefin Tuna
            "Diomedea antipodensis gibsoni", # Gibson's Albatross, whack geom
            "Diomedea antipodensis", # Antipodean Albatross
            "Pachyptila turtur subantarctica", # Fairy Prion (southern)
            "Thalassarche salvini", # Salvin's Ablatross
            "Thalassarche steadi", # White-capped Albatross
            "Thalassarche eremita", # Chatham Albatross
            "Diomedea sanfordi", # Northern Royal Albatross
            "Diomedea epomophora" # Southern Royal Albatross
        )
    ) %T>%
    write_json(
        "output/clean_data/species_animals_clean.json"
    )

species_plants_clean <- species %>%
    st_set_geometry(NULL) %>%
    inner_join(species_ft) %>%
    filter(
        taxon_kingdom %in% "Plantae"
    ) %T>%
    # filter(
    #     !marine %in% c(
    #         "Listed", "Listed - overfly marine area"
    #     )
    # ) %T>%
    write_json(
        "output/clean_data/species_plants_clean.json"
    )

species_marine_clean <- species %>%
    st_set_geometry(NULL) %>%
    inner_join(species_ft) %>%
    filter(
        marine %in% c(
            "Listed", "Listed - overfly marine area"
        ) |
            cetacean %in% "Cetacean" |
            scientific_name %in% c(
                "Brachionichthys hirsutus", # Spotted Handfish
                "Brachiopsilus ziebelli", # Ziebell's Handfish, Waterfall Bay Handfish
                "Carcharias taurus (east coast population)", # Grey Nurse Shark (east coast population)
                "Carcharias taurus (west coast population)", # Grey Nurse Shark (west coast population)
                "Carcharodon carcharias", # White Shark, Great White Shark
                "Epinephelus daemelii", # Black Rockcod, Black Cod, Saddled Rockcod
                "Glyphis garricki", # Northern River Shark, New Guinea River Shark
                "Glyphis glyphis", # Speartooth Shark
                "Pristis clavata", # Dwarf Sawfish, Queensland Sawfish
                "Rhincodon typus", # Whale Shark
                "Thymichthys politus", # Red Handfish
                "Zearaja maugeana", # Maugean Skate, Port Davey Skate
                "Thunnus maccoyii" # Southern Bluefin Tuna
            )
    ) %T>%
    write_json(
        "output/clean_data/species_marine_clean.json"
    )
