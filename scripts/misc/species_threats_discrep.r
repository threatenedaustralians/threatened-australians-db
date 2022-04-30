# Diagnosing the discrepancies between species and threats

#### Libraries ####

library(tidyverse)
library(sf)
library(rmapshaper) # For installing use 'library(remotes)'
library(jsonlite)
library(magrittr)
library(units)
library(httpgd)

#### Import: Australia, electorates, species, demography ####

elect <- st_read("clean_data/elect_clean.gpkg")
species <- st_read("clean_data/species_clean.gpkg")
species <- read.csv("clean_data/species_clean.csv")
threats <- read.csv("clean_data/threats_clean.csv")

#### Species and threats in common ####

species_threats_common <- threats %>%
    inner_join(species) %>%
    group_by(broad_level_threat) %>%
    slice_sample(n = 100) %>%
    ungroup() %>%
    group_by(scientific_name, vernacular_name) %>%
    summarise(no_threats = n_distinct(broad_level_threat)) %>%
    ungroup()

#### filter species based on common threats/species sample ####

species <- species %>%
    inner_join(species_threats_common)

#### Simplify geometry ####

species <- species %>%
    # slice_sample(n = 200) %>%
    st_simplify(
        dTolerance = 10000
    ) %>%
    filter(!is.na(st_dimension(geom))) %>%
    st_make_valid() %>%
    slice_sample(n = 10)
elect <- elect %>%
    ms_simplify(
        keep = 0.001,
        keep_shape = TRUE
    ) %>%
    st_make_valid()

#### species-elect table with intersecting range ####

species_elect_intersect <- species %>%
    st_intersection(elect)
# %T>%
st_write(
    "analysed_data/prototype/species_elect_intersect.geoJSON",
    layer = "species_elect_intersect", append = FALSE
)

#### species table with all range ####

species_range <- species
# %T>%
st_write(
    "analysed_data/prototype/species_range.geoJSON",
    layer = "species_range", append = FALSE
)

#### threat table ####

species_threats <- species_range %>%
    st_set_geometry(NULL) %>%
    inner_join(threats)
#  %T>%
write.csv(
    "analysed_data/prototype/species_threats.csv",
    row.names = FALSE
)