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

#### Imports ####

threats <- readxl::read_excel("data/Ward_2019_national_dataset_imperiled_appendix_S1.xlsx", "Species-Threat-Impact")
species <- st_read("output/clean_data/species_clean.gpkg")

#### Clean: threats ####

names(threats) <- make.names(names(threats), unique = TRUE)

threats_clean <- threats %>%
    rename(species_name_adjusted = Species.name.adjusted, scientific_name = Species.name, vernacular_name = Common.name,
        broad_level_threat = Broad.level.threat, taxon_group = Group) %>%
    select(species_name_adjusted, scientific_name, vernacular_name, broad_level_threat, taxon_group) %>%
    group_by(species_name_adjusted, broad_level_threat) %>%
    summarise() %>%
    ungroup() %>%
    rename(scientific_name = species_name_adjusted) %>%
    inner_join(species) %>%
    select(taxon_ID, broad_level_threat) %>%
    mutate(threat_ID = case_when(broad_level_threat == "Adverse fire regimes" ~ "T01", broad_level_threat == "Changed surface and groundwater regimes" ~
        "T02", broad_level_threat == "Climate change and severe weather" ~ "T03", broad_level_threat == "Disrupted ecosystem and population processes" ~
        "T04", broad_level_threat == "Habitat loss, fragmentation and degradation" ~ "T05", broad_level_threat == "Invasive species and diseases" ~
        "T06", broad_level_threat == "Overexploitation and other direct harm from human activities" ~ "T07", broad_level_threat ==
        "Pollution" ~ "T08")) %T>%
    # mutate( broad_level_threat_alt = case_when( broad_level_threat == 'Adverse fire regimes' ~ 'Adverse fire
    # regimes', broad_level_threat == 'Changed surface and groundwater regimes' ~ 'Changed surface and groundwater
    # regimes', broad_level_threat == 'Climate change and severe weather' ~ 'Climate change and severe weather',
    # broad_level_threat == 'Disrupted ecosystem and population processes' ~ 'Disrupted ecosystem and population
    # processes', broad_level_threat == 'Habitat destruction, fragmentation and degradation' ~ 'Habitat loss,
    # fragmentation and degradation', broad_level_threat == 'Invasive species and diseases' ~ 'Invasive species and
    # diseases', broad_level_threat == 'Overexploitation and other direct harm from human activities' ~
    # 'Overexploitation and other direct harm from human activities', broad_level_threat == 'Pollution' ~
    # 'Pollution' )
write_json("output/clean_data/threats_clean.json")

#### Collapse: threats ####

threats_collapsed_clean <- threats_clean %>%
    group_by(taxon_ID) %>%
    summarise(threat_ID_collapsed = paste(threat_ID, collapse = ", ")) %>%
    ungroup() %T>%
    write_json("output/clean_data/threats_collapsed_clean.json")
