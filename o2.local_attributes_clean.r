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

#### Import: species ####

species <- st_read(
    "output/clean_data/species_clean.gpkg"
)
animals_images <- read_csv(
    "data/animals_image_vetting/animals_image_vetting - ft_combined.csv"
)
animals_info <- fromJSON(
    "data/animals_info_vetting/animals_info_SPRAT.json"
)
threats <- readxl::read_excel(
    "data/Ward_2019_national_dataset_imperiled_appendix_S1.xlsx",
    "Species-Threat-Impact"
)
animals_images <- read_csv(
    "data/animals_image_vetting/animals_image_vetting - ft_combined.csv"
)
species_ft <- fromJSON(
    "output/clean_data/species_ft.json"
)

#### Clean: electoral ####

postcodes_clean <- postcodes %>%
    select(
        POA_CODE21, AREASQKM21, geometry
    ) %>%
    filter(
        !POA_CODE21 %in% c("9494", "9797", "ZZZZ")
    ) %>%
    rename(
        POA_code = POA_CODE21,
        POA_area_sqkm = AREASQKM21
    ) %T>%
    st_write(
        "output/clean_data/postcodes_clean.gpkg",
        layer = "postcodes_clean", append = FALSE, delete_dsn = TRUE
    )

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
            "Diomedea antipodensis gibsoni" # Gibson's Albatross, whack geom
        )
    ) %T>%
    write_json(
        "output/clean_data/species_animals_clean.json"
    ) %T>%
    write_csv(
        "output/clean_data/species_animals_clean.csv"
    )

animals_ft <- species_animals_clean %>%
    select(taxon_ID)

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

plants_ft <- species_plants_clean %>%
    select(taxon_ID)

species_marine_clean <- species %>%
    st_set_geometry(NULL) %>%
    # inner_join(species_ft) %>% # no filter as this is not necessary info
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

#### Clean: threats ####

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
        species_name_adjusted, scientific_name,
        vernacular_name, broad_level_threat,
        taxon_group
    ) %>%
    group_by(
        species_name_adjusted, broad_level_threat
    ) %>%
    summarise() %>%
    ungroup() %>%
    rename(
        scientific_name = species_name_adjusted
    ) %>%
    inner_join(species) %>%
    select(
        taxon_ID, broad_level_threat
    ) %>%
    mutate(
        threat_ID =
            case_when(
                broad_level_threat == "Adverse fire regimes" ~ "T01",
                broad_level_threat == "Changed surface and groundwater regimes" ~ "T02",
                broad_level_threat == "Climate change and severe weather" ~ "T03",
                broad_level_threat == "Disrupted ecosystem and population processes" ~ "T04",
                broad_level_threat == "Habitat loss, fragmentation and degradation" ~ "T05",
                broad_level_threat == "Invasive species and diseases" ~ "T06",
                broad_level_threat == "Overexploitation and other direct harm from human activities" ~ "T07",
                broad_level_threat == "Pollution" ~ "T08"
            )
    ) %T>%
    # mutate(
    #     broad_level_threat_alt =
    #         case_when(
    #             broad_level_threat == "Adverse fire regimes" ~ "Adverse fire regimes",
    #             broad_level_threat == "Changed surface and groundwater regimes" ~ "Changed surface and groundwater regimes",
    #             broad_level_threat == "Climate change and severe weather" ~ "Climate change and severe weather",
    #             broad_level_threat == "Disrupted ecosystem and population processes" ~ "Disrupted ecosystem and population processes",
    #             broad_level_threat == "Habitat destruction, fragmentation and degradation" ~ "Habitat loss, fragmentation and degradation",
    #             broad_level_threat == "Invasive species and diseases" ~ "Invasive species and diseases",
    #             broad_level_threat == "Overexploitation and other direct harm from human activities" ~ "Overexploitation and other direct harm from human activities",
    #             broad_level_threat == "Pollution" ~ "Pollution"
    #         )
    write_json(
        "output/clean_data/threats_clean.json"
    )

#### Collapse: threats ####

threats_collapsed_clean <- threats_clean %>%
    group_by(
        taxon_ID
    ) %>%
    summarise(
        threat_ID_collapsed = paste(threat_ID, collapse = ", ")
    ) %>%
    ungroup() %>%
    mutate(
        taxon_ID = as.double(taxon_ID)
    ) %T>%
    write_json(
        "output/clean_data/threats_collapsed_clean.json"
    )

#### Clean: animals info ####

animals_info_for_vetting <- animals_info %>%
    mutate(
        taxon_ID = as.character(taxon_ID)
    ) %>%
    inner_join(animals_ft) %>%
    # mutate(
    #     habitat = str_remove_all(
    #             habitat,
    #             "<.*?>"
    #         )
    #     ) %>%
    mutate(
        description = str_remove_all(
                description,
                "<.*?>"
            )
        ) %>%
    mutate(
        description = str_remove_all(
                description,
                " \\(.*?\\)"
            )
        ) %>%
    mutate(
        description = str_remove_all(
                description,
                "\\(.*?\\)"
            )
        ) %>%
    mutate(
        description = trimws(
                description
            )
        ) %>%
    mutate(
        description = str_replace(
                description,
                "NA",
                "No information was found for this species on the Species Profile and Threats Database (SPRAT) website, which is the database designed to provide information on species listed as threatened under the Environment Protection and Biodiversity Conservation (EPBC) Act 1999. This does not mean there is no information out there. We encourage you to do a web search using the scientific latin name."
            )
        ) %>%
    # mutate(
    #     description = trimws(
    #         str_remove_all(
    #             description,
    #             "[^a-zA-Z0-9 -,'.]"
    #         )
    #     )
    # ) %>%
    # mutate(
    #     habitat = trimws(
    #         str_remove_all(
    #             habitat,
    #             "[^a-zA-Z0-9 -,'.]"
    #         )
    #     )
    # ) %>%
    select(
        taxon_ID, scientific_name, vernacular_name,
        SPRAT_profile, description
    ) %T>%
    write_csv(
        "data/animals_info_vetting/animals_info_for_vetting.csv"
    )

# Need to do some manual cleaning here
# Save it then re-import

animals_info_vetted <- read_csv(
    "data/animals_info_vetting/animals_info_vettting - animals_info_vetted.csv"
)

animals_info_clean <- animals_info_vetted %>%
    select(taxon_ID, description) %T>%
    write_json(
        "output/clean_data/animals_info_clean.json"
    )

#### Clean: images ####

animals_images_clean <- animals_images %>%
    inner_join(animals_ft) %>% # this is because of removing albo
    select(
        taxon_ID, ALA_URL,
        ALA_API_image_URL, alt_URL
        ) %>%
    mutate(
        image_URL =
            case_when(
                grepl("http", alt_URL) ~ paste0(alt_URL),
                grepl("http", ALA_API_image_URL) ~ paste0(ALA_API_image_URL),
                TRUE ~ "http://nickkellyresearch.com/wp-content/uploads/2022/03/Yellow-Footed-Rock-Wallaby.jpeg"
            )
        ) %>%
    mutate(
        image_URL =
            case_when(
                grepl(
                    "https://images.ala.org.au", image_URL
                ) ~ str_remove_all(
                    .$image_URL,
                    "ThumbnailLarge"
                ),
                TRUE ~ paste0(
                    image_URL
                )
            )
        ) %>%
    mutate(
        image_URL =
            case_when(
                grepl(
                    "https://images.ala.org.au", image_URL
                ) ~ str_remove_all(
                    .$image_URL,
                    "Thumbnail"
                ),
                TRUE ~ paste0(
                    image_URL
                )
            )
        ) %>%
    select(
        !c(
            alt_URL, ALA_API_image_URL,
        )
    ) %T>%
    write_csv(
        "output/clean_data/animals_images_clean.csv"
    )
    write_json(
        "output/clean_data/animals_images_clean.json"
    )
