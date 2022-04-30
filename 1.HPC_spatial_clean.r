# Clean data

#### Libraries ####

library(tidyverse)
library(sf)
library(magrittr)
library(jsonlite)
library(units)
library(readxl)
library(stringr)

#### Import ####

elects <- st_read(
    # "/QRISdata/Q4107/digital_platform/data/2021-Cwlth_electoral_boundaries_ESRI/2021_ELB_region.shp"
    "/QRISdata/Q4107/digital_platform/data/AEC_electoral_boundaries_2019/COM_ELB_region.shp"
)
species <- st_read(
    "/QRISdata/Q4107/digital_platform/data/SNES_public_1july2021.gdb"
)

#### Clean: Electorates ####

elects$Elect_div <- gsub("Eden-monaro", "Eden-Monaro", elects$Elect_div)
elects$Elect_div <- gsub("Mcewen", "McEwen", elects$Elect_div)
elects$Elect_div <- gsub("Mcmahon", "McMahon", elects$Elect_div)
elects$Elect_div <- gsub("Mcpherson", "McPherson", elects$Elect_div)
elects$Elect_div <- gsub("O'connor", "O'Connor", elects$Elect_div)

elects_clean <- elects %>%
    st_make_valid() %>%
    select(
        Elect_div, geometry
    ) %>%
    rename(
        electorate = Elect_div
    ) %>%
    mutate(
        electorate_area_sqkm = units::set_units(st_area(.), km^2) %>%
            as.numeric()
    ) %T>%
    st_write(
        "/QRISdata/Q4107/digital_platform/output/clean_data/elects_clean.gpkg",
        layer = "elects_clean", append = FALSE, delete_dsn = TRUE
    )

elects_union_clean <- elects_clean %>%
    st_union(by_feature = FALSE) %>%
    st_sf() %>%
    st_make_valid() %T>%
    st_write(
        "/QRISdata/Q4107/digital_platform/output/clean_data/elects_union_clean.gpkg",
        layer = "elects_union_clean", append = FALSE, delete_dsn = TRUE
    )

#### Clean: Species ####

species_clean <- species %>%
    filter(
        PRESENCE_RANK == 2
    ) %>%
    filter(
        !is.na(THREATENED_STATUS)
    ) %>%
    select(c(
        "LISTED_TAXON_ID", "SCIENTIFIC_NAME", "VERNACULAR_NAME",
        "THREATENED_STATUS", "MIGRATORY_STATUS", "MARINE",
        "CETACEAN", "TAXON_GROUP", "SPRAT_PROFILE",
        "TAXON_KINGDOM", "Shape"
    )) %>%
    rename(
        taxon_ID = LISTED_TAXON_ID,
        scientific_name = SCIENTIFIC_NAME,
        vernacular_name = VERNACULAR_NAME,
        threatened_status = THREATENED_STATUS,
        migratory_status = MIGRATORY_STATUS,
        marine = MARINE,
        cetacean = CETACEAN,
        taxon_group = TAXON_GROUP,
        taxon_kingdom = TAXON_KINGDOM,
        SPRAT_profile = SPRAT_PROFILE,
        geometry = Shape
    ) %>%
    st_make_valid() %>%
    group_by(
        taxon_ID,
        scientific_name,
        vernacular_name,
        threatened_status,
        migratory_status,
        marine,
        cetacean,
        taxon_group,
        taxon_kingdom,
        SPRAT_profile
    ) %>%
    summarise() %>%
    ungroup() %>%
    st_make_valid() %>%
    relocate(
        taxon_ID, scientific_name,
        vernacular_name, threatened_status,
        migratory_status, marine,
        cetacean, taxon_group,
        taxon_kingdom, SPRAT_profile,
        geometry
    ) %>%
    # Check MW species name adjustment script
    mutate(
        scientific_name = replace(
            scientific_name,
            scientific_name == "Rutidosis leptorhynchoides",
            "Rutidosis leptorrhynchoides"
        )
    ) %>%
    mutate(
        scientific_name_clean = word(
            scientific_name, 1, 1,
            sep = fixed("(")
        )
    ) %>%
    mutate(
        vernacular_name_other = word(
            vernacular_name, 2, -1,
            sep = fixed(", ")
        )
    ) %>%
    mutate(
        vernacular_name_first = word(
            vernacular_name, 1, 1,
            sep = fixed(", ")
        )
    ) %>%
    mutate(
        vernacular_name_first_clean = word(
            vernacular_name_first, 1, 1,
            sep = fixed("(")
        )
    ) %>%
    mutate(
        species_range_area_sqkm = units::set_units(st_area(.), km^2) %>%
            as.numeric()
    ) %T>%
    st_write(
        "/QRISdata/Q4107/digital_platform/output/clean_data/species_clean.gpkg",
        layer = "species_clean", append = FALSE, delete_dsn = TRUE
    )

species_clean_no_geom <- species_clean %>%
    st_set_geometry(NULL) %T>%
    write_json(
        "/QRISdata/Q4107/digital_platform/output/clean_data/species_clean_no_geom.json"
    )

species_union_clean <- species_clean %>%
    st_union(by_feature = FALSE) %>%
    st_sf() %>%
    st_make_valid() %T>%
    st_write(
        "/QRISdata/Q4107/digital_platform/output/clean_data/species_union_clean.gpkg",
        layer = "species_union_clean", append = FALSE, delete_dsn = TRUE
    )
