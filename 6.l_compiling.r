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
    "output/clean_data/elects_clean.gpkg"
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
    "output/clean_data/species_clean.gpkg"
)
threats <- fromJSON(
    "output/clean_data/threats_clean.json"
)
threats_collapsed <- fromJSON(
    "output/clean_data/threats_collapsed_clean.json"
)
animals_ft <- fromJSON(
    "output/clean_data/species_animals_clean.json"
) %>%
    select(taxon_ID)
plants_ft <- fromJSON(
    "output/clean_data/species_plants_clean.json"
) %>%
    select(taxon_ID)
animals_images <- fromJSON(
    "output/clean_data/animals_images_clean.json"
)
animals_info <- fromJSON(
    "output/clean_data/animals_info_clean.json"
)

#### Import: other ####

action_groups <- fromJSON(
    "data/action_groups.json"
)

#### Species_elects_tbl: with range calcs ####

species_elects_tbl <- species_elects %>%
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
    mutate(
        taxon_ID = as.integer(
            taxon_ID
        )
    ) %>%
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
    mutate(
        vernacular_name_first_clean = replace(
            vernacular_name_first_clean,
            vernacular_name_first_clean == "bluegrass",
            "Bluegrass"
        )
    )

animals_elects_tbl <- species_elects_tbl %>%
    inner_join(animals_ft) %>%
    select(
        taxon_ID, scientific_name_clean,
        species_range_intersects_with_n_electorates,
        species_range_area_sqkm, species_electorate_coverage, electorate,
        species_intersect_area_sqkm, percent_range_within, geom
    ) %T>%
    st_write(
        "output/analysed_data/final/imports/animals_elects_tbl.geojson",
        layer = "animals_elects_tbl", append = FALSE, delete_dsn = TRUE
    )

plants_elects_tbl <- species_elects_tbl %>%
    st_set_geometry(NULL) %>%
    inner_join(plants_ft) %>%
    select(
        taxon_ID,
        scientific_name_clean,
        vernacular_name_first_clean,
        threatened_status,
        SPRAT_profile,
        electorate
    ) %T>%
    write_json(
        "output/analysed_data/final/imports/plants_elects_tbl.json"
    )

#### Reference table and individual tables for users to download ####

species_ft <- animals_ft %>%
    bind_rows(plants_ft)

species_elects_ref_tbl <- species_elects_tbl %>%
    st_set_geometry(NULL) %>%
    inner_join(species_ft) %>%
    mutate(
        across(
            percent_range_within,
            signif,
            digits = 3
        )
    ) %>%
    full_join(demo) %>%
    select(
        electorate, state_territory, electorate_area_sqkm,
        taxon_ID, scientific_name,
        # scientific_name_clean,
        vernacular_name,
        # vernacular_name_other, vernacular_name_first,
        # vernacular_name_first_clean,
        threatened_status,
        migratory_status, marine, taxon_group, taxon_kingdom,
        SPRAT_profile, species_range_area_sqkm,
        species_intersect_area_sqkm, percent_range_within
    ) %T>%
    write_csv(
        "output/analysed_data/ref_tables/species_elects_ref_tbl.csv"
    )

write_elects_csv = function(data) {
    write_csv(
        data, paste0("/home/gareth/science/eSpace/threatened_australians/electorate_species_lists/",
        unique(data$electorate), "_species_list.csv"
        )
    )
    return(data)
}

species_elects_ref_tbl %>%
    group_by(electorate) %>%
    do(write_elects_csv(.))

#### Species_tbl ####

animals_tbl <- species %>%
    inner_join(animals_ft) %>%
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
    mutate(
        taxon_ID = as.integer(
            taxon_ID
        )
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

animals_elects_counts <- species_elects %>%
    st_set_geometry(NULL) %>%
    inner_join(animals_ft) %>%
    group_by(electorate) %>%
    summarise(no_animal_species = n_distinct(taxon_ID)) %>%
    ungroup()

plants_elects_counts <- species_elects %>%
    st_set_geometry(NULL) %>%
    inner_join(plants_ft) %>%
    group_by(electorate) %>%
    summarise(no_plant_species = n_distinct(taxon_ID)) %>%
    ungroup()

elects_tbl <- elects %>%
    inner_join(demo) %>%
    inner_join(MP_info) %>%
    inner_join(MP_voting_info) %>%
    inner_join(animals_elects_counts) %>%
    full_join(plants_elects_counts) %>% # Not all elects have plants
    mutate(
        no_plant_species = replace_na(
            no_plant_species, 0
        )
    ) %>%
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

#### Copy to eSpace directory ####

file.copy(
    "/home/gareth/science/projects/electoral/threatened_australians/output/",
    "/home/gareth/science/eSpace/threatened_australians/",
    recursive = TRUE
)
