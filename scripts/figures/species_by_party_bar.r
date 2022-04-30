# Creating bar charts for convo piece

#### Libraries ####

library(tidyverse)
library(sf)
library(jsonlite)
library(httpgd)
library(plotly)
library(shiny)
library(svglite)

#### Import ####

species_elects_tbl <- st_read(
    "output/analysed_data/final/species_elects_tbl.gpkg"
) %>%
    st_set_geometry(NULL)
species_union_elects <- st_read(
    "output/analysed_data/final/species_union_elects.gpkg"
) %>%
    st_set_geometry(NULL)
MP_voting_info <- fromJSON(
    "output/analysed_data/MP_voting_info_clean.json"
)
species <- st_read(
  "output/analysed_data/species_clean.gpkg"
)

#### create base dfs ####

species_elects_collapsed <- species_elects_tbl %>%
    group_by(electorate) %>%
    summarise()

species_elects_counts <- species_elects_tbl %>%
    group_by(taxon_ID) %>%
    summarise()

species_counts <- species %>%
  st_set_geometry(NULL) %>%
  group_by(taxon_ID) %>%
  summarise()

MP_voting_info_collapsed <- MP_voting_info %>%
    group_by(party) %>%
    summarise()

#### analysis dfs ####

range_by_party <- species_elects_tbl %>%
    inner_join(MP_voting_info) %>%
    select(electorate, species_intersect_area_sqkm, party) %>%
    group_by(party) %>%
    summarise(
        range_sum_area_sqkm = sum(
            species_intersect_area_sqkm
        )
    )

range_union_by_party <- species_union_elects %>%
    inner_join(MP_voting_info) %>%
    select(electorate, elects_intersect_area_sqkm, party) %>%
    group_by(party) %>%
    summarise(
        range_union_sum_area_sqkm = sum(
            elects_intersect_area_sqkm
        )
    )

distinct_by_party <- species_elects_tbl %>%
    select(electorate, taxon_ID) %>%
    inner_join(MP_voting_info) %>%
    group_by(party) %>%
    summarise(n_distinct_species = n_distinct(taxon_ID))

endemic_by_party <- species_elects_tbl %>%
    filter(percent_range_within == 1) %>%
    select(electorate, taxon_ID) %>%
    inner_join(MP_voting_info) %>%
    group_by(party) %>%
    summarise(n_distinct_endemic_species = n_distinct(taxon_ID)) %>%
    full_join(MP_voting_info_collapsed)

species_by_party <- range_by_party %>%
    full_join(range_union_by_party) %>%
    full_join(distinct_by_party) %>%
    full_join(endemic_by_party) %>%
    mutate(
        across(
            c(range_sum_area_sqkm, range_union_sum_area_sqkm),
            signif,
            digits = 3
        )
    ) %>%
    replace_na(
        list(
            n_distinct_endemic_species = 0
        )
    )

#### ggplotly - species by party ####

p <-
ggplotly(
  ggplot(
    species_by_party
) +
    aes(
        x = party,
        y = n_distinct_species,
        fill = party,
        text = paste(
          party, "MP(s) currently \nhave", n_distinct_species,
          "of the ~1800 listed threatened species", "\nacross their electorates."
        )
    ) +
    geom_bar(
        stat = "identity",
        colour = "black"
    ) +
    guides(
        fill = "none"
    ) +
    labs(
        y = "Number of threatened species"
    ) +
    scale_y_continuous(
        labels = scales::comma
    ) +
    # colours from https://www.flagcolorcodes.com/
    scale_fill_manual(
        values = c(
            "#009C3D",
            "#E13940",
            "#FF5800",
            "#dbdbdb",
            "#05428C",
            "#2f85e9",
            "#1C4F9C",
            "#006946",
            "yellow"
        )
    ) +
    theme_classic() +
    theme(
        axis.title.x = element_blank(),
        axis.text.x = element_text(
            angle = 30,
            hjust = 1
        ),
        legend.position='none'
    ), tooltip = "text"
    # ), tooltip = c("x", "y")
)

htmlwidgets::saveWidget(p, "figs/species_by_party_n_int.html")

#### ggplot ####

# p <-
    ggplot(
      species_by_party
    ) +
      aes(
        x = party,
        y = n_distinct_species,
        fill = party
      ) +
      geom_bar(
        stat = "identity",
        colour = "black"
      ) +
      guides(
        fill = "none"
      ) +
      labs(
        y = "Number of threatened species"
      ) +
      scale_y_continuous(
        labels = scales::comma
      ) +
      # colours from https://www.flagcolorcodes.com/
      scale_fill_manual(
        values = c(
          "#009C3D",
          "#E13940",
          "#FF5800",
          "#dbdbdb",
          "#05428C",
          "#2f85e9",
          "#1C4F9C",
          "#006946",
          "yellow"
        )
      ) +
      theme_classic() +
      theme(
        axis.title.x = element_blank(),
        axis.text.x = element_text(
          angle = 30,
          hjust = 1
        ),
        legend.position='none'
      )

ggsave("figs/species_by_party_n.png",
       # species_by_party_area,
       width = 20, height = 15, units = "cm"
)
