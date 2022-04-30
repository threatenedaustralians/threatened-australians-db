# code for getting EPBC-listed species images out of ALA using {galah}

# load packages
install.packages("galah")
library(galah)
galah_config(
  email = "example@email.com", # add registered email here
  run_checks = FALSE # necessary to use the species lists functionality below
)

# how many images can I expect to download?
galah_call() |>
  # galah_identify("Mammalia") # optional: to restrict to a specific taxon
  galah_filter(
    # Optional stuff for example purposes
    basisOfRecord == "HumanObservation", # removes preserved specimens
    year >= 2018, # restrict to recent records
    # Useful stuff for your use case
    species_list_uid == dr656, # EPBC-listed species
    multimedia == Image, # choose only records with images
    profile = "re-usable" # data quality profile, see show_all_profiles()
      # this profile chooses images with permissive licences
  ) |>
  galah_group_by(species) |> # optional: groups counts by species
  atlas_counts() 
# this shows there are 1,655 occurrences that meet these criteria
# note that there might be >1 images per occurrence record

# how do I get these images?
# create somewhere in your working directory to store images
dir.create("temporary_folder")

# download (NOTE: not tested)
media_info <- galah_call() |>
  galah_filter(
    basisOfRecord == "HumanObservation", 
    year >= 2018,
    species_list_uid == dr656,
    multimedia == Image, 
    profile = "re-usable") |>
  atlas_media(download_dir = "temporary_folder")

# to see metadata on downloaded images
media_info

# useful links:
# quick-start guide to galah
https://atlasoflivingaustralia.github.io/galah/articles/quick_start_guide.html
# how to use lists in galah
https://github.com/AtlasOfLivingAustralia/galah/issues/127
# EPBC-listed species in ALA
https://lists.ala.org.au/speciesListItem/list/dr656
