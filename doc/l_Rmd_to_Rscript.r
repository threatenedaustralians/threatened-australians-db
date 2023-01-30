# Converting R markdown files to R scripts

library(rmarkdown)

knitr::purl("doc/1.H_spatial_clean.Rmd", "1.H_spatial_clean.r")

knitr::purl("doc/2.H_spatial_ops.Rmd", "2.H_spatial_ops.r")
