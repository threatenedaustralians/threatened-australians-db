## ---- class.source = 'fold-hide'--------------------------------------------------
library(tidyverse)
library(sf)
library(jsonlite)
library(magrittr)
library(units)


## ---------------------------------------------------------------------------------
elects <- st_read(
    "/QRISdata/Q4107/threatened_australians/output/clean_data/elects_clean.gpkg"
)
elects_union <- st_read(
    "/QRISdata/Q4107/threatened_australians/output/clean_data/elects_union_clean.gpkg"
)
species <- st_read(
    "/QRISdata/Q4107/threatened_australians/output/clean_data/species_clean.gpkg"
)
species_union <- st_read(
    "/QRISdata/Q4107/threatened_australians/output/clean_data/species_union_clean.gpkg"
    )
postcodes <- st_read(
    "/QRISdata/Q4107/threatened_australians/data/POA_2021_AUST_GDA94_SHP/POA_2021_AUST_GDA94.shp"
)


## ---------------------------------------------------------------------------------
postcodes_elects_tbl <- postcodes %>%
    select(
        POA_CODE21, geometry
    ) %>%
    filter(
        !POA_CODE21 %in% c("9494", "9797", "ZZZZ")
    ) %>%
    rename(
        POA_code = POA_CODE21
    ) %>%
    mutate(
        POA_area_sqkm = units::set_units(st_area(.), km^2) %>%
            as.numeric()
    ) %>%
    st_intersection(elects) %>%
    st_make_valid() %>%
    mutate(
        POA_elect_int_area_sqkm = units::set_units(st_area(.), km^2) %>%
            as.numeric()
    ) %T>%
    st_write(
        dsn = "/QRISdata/Q4107/threatened_australians/output/analysed_data/final/postcodes_elects_tbl.gpkg",
        layer = "postcodes_elects_tbl", append = FALSE, delete_dsn = TRUE
    )


## ---------------------------------------------------------------------------------
species_elects_tbl <- species %>%
    st_intersection(elects) %>%
    st_make_valid() %>%
    mutate(
        species_intersect_area_sqkm = units::set_units(st_area(.), km^2) %>%
            as.numeric()
    ) %>%
    mutate(
        percent_range_within = species_intersect_area_sqkm / species_range_area_sqkm
    ) %T>%
    st_write(
        dsn = "/QRISdata/Q4107/threatened_australians/output/analysed_data/final/species_elects_tbl.gpkg",
        layer = "species_elects_tbl", append = FALSE, delete_dsn = TRUE
    )


## ---------------------------------------------------------------------------------
species_union_elects <- species_union %>%
    st_intersection(elects) %>%
    st_make_valid() %>%
    mutate(
        elects_intersect_area_sqkm = units::set_units(st_area(.), km^2) %>%
            as.numeric()
    ) %T>%
    st_write(
        dsn = "/QRISdata/Q4107/threatened_australians/output/analysed_data/final/species_union_elects.gpkg",
        layer = "species_union_elects", append = FALSE, delete_dsn = TRUE
    )

