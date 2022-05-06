# Simplified data to experiment on before mounting on the HPC with the real data

#### Libraries ####

library(tidyverse)
library(sf)
library(rmapshaper) # For installing use 'library(remotes)'
library(jsonlite)
library(magrittr)
library(units)
library(httpgd)

#### Import: electoral ####

elects <- st_read(
    "output/analysed_data/final/elects_tbl.gpkg"
)
postcodes_elects <- st_read(
    "output/analysed_data/final/postcodes_elects_tbl.gpkg"
)
MP_info <- fromJSON(
    "output/clean_data/MP_info_clean.json"
)
MP_voting_info <- fromJSON(
    "output/clean_data/MP_voting_info_clean.json"
)
demo <- fromJSON(
    "output/clean_data/demo_clean.json"
)

#### Import: species ####

species_elects <- st_read(
    "output/analysed_data/final/species_elects_tbl.gpkg"
)
species <- st_read(
    "output/analysed_data/final/species_tbl.gpkg"
)
threats <- fromJSON(
    "output/clean_data/threats_clean.json"
)
threats_collapsed <- fromJSON(
    "output/clean_data/threats_collapsed_clean.json"
)
animals <- fromJSON(
    "output/clean_data/species_animals_ft_clean.json"
) %>%
    select(taxon_ID)
plants <- fromJSON(
    "output/clean_data/species_plants_ft_clean.json"
) %>%
    select(taxon_ID)
animals_images <- fromJSON(
    "output/clean_data/animals_images_clean.json"
) %>%
    mutate(
        taxon_ID = as.character(taxon_ID)
    )
animals_info <- fromJSON(
    "output/clean_data/animals_info_clean.json"
) %>%
    mutate(
        taxon_ID = as.character(taxon_ID)
    )

#### Import: other ####

action_groups <- fromJSON(
    "data/action_groups.json"
)

#### Animals_filter ####

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

#### Species_elects_tbl: with range calcs ####

animals_elects_tbl <- species_elects %>%
    mutate(
        across(
            c(
                species_range_area_sqkm,
                species_intersect_area_sqkm,
                percent_range_within
            ),
            signif,
            digits = 3
        )
    ) %>%
    group_by(
        taxon_ID
    ) %>%
    mutate(species_range_intersects_with_n_electorates = n_distinct(electorate)) %>%
    ungroup() %>%
    mutate(
        scientific_name_clean = word(
            scientific_name, 1, 1,
            sep = fixed("(")
        )
    ) %>%
    # filter(
    #     percent_range_within >= 0.05 # TODO: gotta solve this among others
    # )
    # This introduces various errors, but for most species it's going to be good
    mutate(
        species_electorate_coverage = case_when(
            percent_range_within == 1 ~ paste0(
                scientific_name_clean,
                " is only found within ",
                electorate
            ),
            percent_range_within >= 0.8 &
            percent_range_within < 1
            # species_range_intersects_with_n_electorates != 1
             ~ paste0(
                scientific_name_clean,
                " has greater than 80% of it's range within ",
                electorate
            ),
            TRUE ~ paste0(
                scientific_name_clean,
                " is found across ",
                species_range_intersects_with_n_electorates,
                " electorates."
            )
        )
    ) %>%
    select(
        taxon_ID, scientific_name_clean,
        species_range_intersects_with_n_electorates,
        species_range_area_sqkm, species_electorate_coverage, electorate,
        species_intersect_area_sqkm, percent_range_within, geom
    ) %>%
    inner_join(species_ft) %>%
    inner_join(animals) %T>%
    st_write(
        "output/analysed_data/final/imports/animals_elects_tbl.geojson",
        layer = "animals_elects_tbl", append = FALSE, delete_dsn = TRUE
    )

animals_elects_ref_tbl <- species_elects %>%
    mutate(
        across(
            c(
                species_range_area_sqkm,
                species_intersect_area_sqkm,
                percent_range_within
            ),
            signif,
            digits = 3
        )
    ) %>%
    group_by(
        taxon_ID
    ) %>%
    mutate(species_range_intersects_with_n_electorates = n_distinct(electorate)) %>%
    ungroup() %>%
    select(
        taxon_ID, electorate, scientific_name,
        vernacular_name, threatened_status, species_range_intersects_with_n_electorates,
        species_range_area_sqkm, species_intersect_area_sqkm, percent_range_within, geom
    ) %>%
    inner_join(species_ft) %>%
    inner_join(animals) %>%
    st_set_geometry(NULL) %T>%
    write_csv(
        "output/analysed_data/ref_tables/animals_elects_ref_tbl.csv"
    )

plants_elects_tbl <- species_elects %>%
    st_set_geometry(NULL) %>%
    inner_join(plants) %>%
    mutate(
        vernacular_name_first_clean = replace(
            vernacular_name_first_clean,
            vernacular_name_first_clean == "cycad",
            "a cycad "
        )
    ) %>%
    mutate(
        vernacular_name_first_clean = replace(
            vernacular_name_first_clean,
            vernacular_name_first_clean == "fern",
            "a fern"
        )
    ) %>%
    select(
        taxon_ID, # scientific_name_clean,
        electorate,
        scientific_name, vernacular_name, # vernacular_name_first_clean,
        threatened_status,
        SPRAT_profile
    ) %>%
    relocate(electorate, .after = SPRAT_profile) %T>%
    write_json(
        "output/analysed_data/final/imports/plants_elects_tbl.json"
    )

plants_elects_ref_tbl <- species_elects %>%
    mutate(
        across(
            percent_range_within
            ,
            signif,
            digits = 3
        )
    ) %>%
    st_set_geometry(NULL) %>%
    inner_join(plants) %>%
    select(
        taxon_ID, # scientific_name_clean,
        electorate,
        scientific_name, vernacular_name, # vernacular_name_first_clean,
        threatened_status,
        percent_range_within,
        SPRAT_profile
    ) %T>%
    write_csv(
        "output/analysed_data/ref_tables/plants_elects_ref_tbl.csv"
    )

#### Species_tbl ####

animals_tbl <- species %>%
    inner_join(animals) %>%
    inner_join(species_ft) %>%
    inner_join(animals_info) %>%
    inner_join(animals_images) %>%
    inner_join(threats_collapsed) %>%
    mutate(
        vernacular_name_first_clean = replace(
            vernacular_name_first_clean,
            vernacular_name_first_clean == "freshwater crayfish",
            "a freshwater crayfish"
        )
    ) %>%
    mutate(
        vernacular_name_first_clean = replace(
            vernacular_name_first_clean,
            vernacular_name_first_clean == "A native bee",
            "a native bee"
        )
    ) %>%
    relocate(
        vernacular_name_first,
        .after = vernacular_name
    ) %>%
    relocate(
        vernacular_name_other,
        .after = vernacular_name_first
    ) %>%
    relocate(
        vernacular_name_first_clean,
        .after = vernacular_name_first
    ) %>%
    select(
         taxon_ID, scientific_name_clean, vernacular_name_first_clean,
         threatened_status, migratory_status, taxon_group,
         taxon_kingdom, SPRAT_profile,
         species_range_area_sqkm, description, ALA_URL, image_URL,
         threat_ID_collapsed, geom
    ) %>%
    mutate(
        across(
            species_range_area_sqkm,
            signif,
            digits = 3
        )
    ) %T>%
    st_write(
        "output/analysed_data/final/imports/animals_tbl.geojson",
        layer = "animals_tbl", append = FALSE, delete_dsn = TRUE
    )

#### Elects_tbl ####

species_elects_counts <- species_elects %>%
    st_set_geometry(NULL) %>%
    inner_join(species_ft) %>%
    group_by(electorate) %>%
    summarise(no_species = n_distinct(taxon_ID))

animals_elects_counts <- species_elects %>%
    st_set_geometry(NULL) %>%
    inner_join(animals) %>%
    inner_join(species_ft) %>%
    group_by(electorate) %>%
    summarise(no_animal_species = n_distinct(taxon_ID))

plants_elects_counts <- species_elects %>%
    st_set_geometry(NULL) %>%
    inner_join(plants) %>%
    inner_join(species_ft) %>%
    group_by(electorate) %>%
    summarise(no_plant_species = n_distinct(taxon_ID))

elects_tbl <- elects %>%
    inner_join(demo) %>%
    inner_join(MP_info) %>%
    inner_join(MP_voting_info) %>%
    full_join(species_elects_counts) %>%
    inner_join(animals_elects_counts) %>%
    full_join(plants_elects_counts) %>% # Not all elects have plants
    mutate(
        across(
            electorate_area_sqkm,
            signif,
            digits = 3
        )
    ) %T>%
    st_write(
        "output/analysed_data/final/imports/elects_tbl.geojson",
        layer = "elects_tbl", append = FALSE, delete_dsn = TRUE
    ) %>%
    st_set_geometry(NULL) %T>%
    write_csv(
        "output/analysed_data/ref_tables/elects_tbl.csv"
    )

#### Postcodes ####

postcodes_elects_tbl <- postcodes_elects %>%
    st_set_geometry(NULL) %>%
    mutate(
        across(
            c(
                POA_area_sqkm, POA_elect_int_area_sqkm
            ),
            signif,
            digits = 3
        )
    ) %>%
    mutate(
        proportion_POA_within_elect = POA_elect_int_area_sqkm / POA_area_sqkm
    ) %>%
    filter(
        !proportion_POA_within_elect <= 0.001
    ) %T>%
    write_json(
        "output/analysed_data/final/imports/postcodes_elects_tbl.json"
    ) %T>%
    write_csv(
        "output/analysed_data/ref_tables/postcodes_elects_ref_tbl.csv"
    )

#### Action_groups_tbl ####

action_groups_tbl <- action_groups %T>%
    write_json(
        "output/analysed_data/final/imports/action_groups_tbl.json"
    )

#### Threats_tbl ####

threats_tbl <- threats %>%
    group_by(
        broad_level_threat, threat_ID
    ) %>%
    summarise() %>%
    relocate(
        threat_ID,
        .before = broad_level_threat
    ) %T>%
    write_json(
        "output/analysed_data/final/imports/threats_tbl.json"
    )
