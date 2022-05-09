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

animals_images <- read_csv(
    "data/animals_image_vetting/animals_image_vetting - ft_combined.csv"
)
animals_info <- fromJSON(
    "data/animals_info_vetting/animals_info_SPRAT.json"
)
animals_ft <- fromJSON(
    "output/clean_data/species_animals_clean.json"
) %>%
select(taxon_ID)

#### Clean: animals info ####

animals_info_for_vetting <- animals_info %>%
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
    inner_join(animals_ft) %>%
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
    # write_csv(
    #     "output/clean_data/animals_images_clean.csv"
    # ) %T>%
    write_json(
        "output/clean_data/animals_images_clean.json"
    )
