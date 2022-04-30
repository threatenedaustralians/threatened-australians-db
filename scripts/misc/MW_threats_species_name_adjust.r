# Understanding MW's species name adjustment thing

#### Libraries ####

library(tidyverse)
library(sf)
library(rmapshaper) # For installing use 'library(remotes)'
library(jsonlite)
library(magrittr)
library(units)
library(httpgd)

#### Import: species, threats ####

threats <- readxl::read_excel(
    "raw_data/Ward_2019_national_dataset_imperiled_appendix_S1.xlsx",
    "Species-Threat-Impact"
)
species <- st_read(
    "raw_data/SNES_public_1july2021.gdb"
)

#### Clean: Species ####

species_clean <- species %>%
    filter(PRESENCE_RANK == 2) %>%
    filter(!is.na(THREATENED_STATUS)) %>%
    st_set_geometry(NULL) %>%
    select(c(
        "LISTED_TAXON_ID", "SCIENTIFIC_NAME", "VERNACULAR_NAME",
        "THREATENED_STATUS", "MIGRATORY_STATUS",
        "TAXON_GROUP", "SPRAT_PROFILE",
        "TAXON_KINGDOM"
    )) %>%
    rename(
        taxon_ID = LISTED_TAXON_ID,
        scientific_name = SCIENTIFIC_NAME,
        vernacular_name = VERNACULAR_NAME,
        threatened_status = THREATENED_STATUS,
        migratory_status = MIGRATORY_STATUS,
        taxon_group = TAXON_GROUP,
        taxon_kingdom = TAXON_KINGDOM,
        SPRAT_profile = SPRAT_PROFILE,
    ) %>%
    group_by(
        taxon_ID,
        scientific_name,
        vernacular_name,
        threatened_status,
        migratory_status,
        taxon_group,
        taxon_kingdom,
        SPRAT_profile
    ) %>%
    summarise() %>%
    ungroup() %>%
    relocate(
        taxon_ID, scientific_name,
        vernacular_name, threatened_status,
        migratory_status, taxon_group,
        taxon_kingdom, SPRAT_profile,
    )

#### Threats: clean ####

names(threats) <- make.names(names(threats), unique = TRUE)

threats_clean <- threats %>%
    rename(
        species_name_adjusted = Species.name.adjusted,
        scientific_name = Species.name,
        vernacular_name = Common.name,
        broad_level_threat = Broad.level.threat,
        taxon_group = Group
    ) %>%
    select(
        species_name_adjusted, scientific_name
    ) %>%
    group_by(
        species_name_adjusted, scientific_name
    ) %>%
    summarise() %>%
    ungroup()

#### Getting to the bottom of this ####

table(duplicated(threats_clean$species_name_adjusted))
table(duplicated(threats_clean$scientific_name))

threats_clean$scientific_name[duplicated(threats_clean$scientific_name)]

[1] "Rutidosis leptorrhynchoides"

Rutidosis leptorhynchoides
Rutidosis leptorrhynchoides

# Looks like there are these two different spellings out there of this species

species_duplicates <- species_clean %>%
    filter(
        scientific_name == "Rutidosis leptorhynchoides" |
        scientific_name == "Rutidosis leptorrhynchoides"
    )

# SPRAT database title of the name of the species is one 'r'
# Then everywhere else, including on the document it is two 'r's