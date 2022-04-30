# Calculate the LPI index/tsx's

#### Libraries ####

library(tidyverse)
library(sf)
library(jsonlite)
library(magrittr)
library(rlpi)
library(httpgd)

#### Imports ####

NSW_ACT_tsx <- read.csv(
    "data/raw_data/TSX/NSW_ACT_tsxdata/tsxdata.csv",
    na.strings = "", quote = "\"", sep = ","
)
NT_tsx <- read.csv(
    "data/raw_data/TSX/NT_tsxdata/tsxdata.csv",
    na.strings = "", quote = "\"", sep = ","
)
QLD_tsx <- read.csv(
    "data/raw_data/TSX/QLD_tsxdata/tsxdata.csv",
    na.strings = "", quote = "\"", sep = ","
)
SA_tsx <- read.csv(
    "data/raw_data/TSX/SA_tsxdata/tsxdata.csv",
    na.strings = "", quote = "\"", sep = ","
)
TAS_tsx <- read.csv(
    "data/raw_data/TSX/TAS_tsxdata/tsxdata.csv",
    na.strings = "", quote = "\"", sep = ","
)
VIC_tsx <- read.csv(
    "data/raw_data/TSX/VIC_tsxdata/tsxdata.csv",
    na.strings = "", quote = "\"", sep = ","
)
WA_tsx <- read.csv(
    "data/raw_data/TSX/WA_tsxdata/tsxdata.csv",
    na.strings = "", quote = "\"", sep = ","
)

#### Prepare data for LPI ####

# Use 'here' package to set_wd to location you want files produced at

infile_NSW_ACT <- create_infile(
    NSW_ACT_tsx,
    name = "infile",
    start_col_name = "X1985",
    end_col_name = "X2017"
)
tsx_NSW_ACT <- LPIMain(
    infile_NSW_ACT,
    REF_YEAR = 1985,
    PLOT_MAX = 2017,
    BOOT_STRAP_SIZE = 1000,
    VERBOSE = TRUE,
    goParallel = TRUE,
    title = "tsx_NSW_ACT",
    plot_lpi = 0,
    save_plots = 0
) %>%
na.omit() %>%
tibble::rownames_to_column("ref_year") %T>%
    write_json(
        "output/analysed_data/final/imports/tsx_NSW_ACT_tbl.json"
    )
plot(tsx_NSW_ACT$ref_year, tsx_NSW_ACT$LPI_final, "l")

infile_NT <- create_infile(
    NT_tsx,
    name = "infile",
    start_col_name = "X1985",
    end_col_name = "X2017"
)
tsx_NT <- LPIMain(
    infile_NT,
    REF_YEAR = 1985,
    PLOT_MAX = 2017,
    BOOT_STRAP_SIZE = 1000,
    VERBOSE = TRUE,
    goParallel = TRUE,
    title = "tsx_NT",
    plot_lpi = 0,
    save_plots = 0
) %>%
na.omit() %>%
tibble::rownames_to_column("ref_year") %T>%
    write_json(
        "output/analysed_data/final/imports/tsx_NT_tbl.json"
    )
plot(tsx_NT$ref_year, tsx_NT$LPI_final, "l")

infile_QLD <- create_infile(
    QLD_tsx,
    name = "infile",
    start_col_name = "X1985",
    end_col_name = "X2017"
)
tsx_QLD <- LPIMain(
    infile_QLD,
    REF_YEAR = 1985,
    PLOT_MAX = 2017,
    BOOT_STRAP_SIZE = 1000,
    VERBOSE = TRUE,
    goParallel = TRUE,
    title = "tsx_QLD",
    plot_lpi = 0,
    save_plots = 0
) %>%
na.omit() %>%
tibble::rownames_to_column("ref_year") %T>%
    write_json(
        "output/analysed_data/final/imports/tsx_QLD_tbl.json"
    )
plot(tsx_QLD$ref_year, tsx_QLD$LPI_final, "l")

infile_SA <- create_infile(
    SA_tsx,
    name = "infile",
    start_col_name = "X1985",
    end_col_name = "X2017"
)
tsx_SA <- LPIMain(
    infile_SA,
    REF_YEAR = 1985,
    PLOT_MAX = 2017,
    BOOT_STRAP_SIZE = 1000,
    VERBOSE = TRUE,
    goParallel = TRUE,
    title = "tsx_SA",
    plot_lpi = 0,
    save_plots = 0
) %>%
na.omit() %>%
tibble::rownames_to_column("ref_year") %T>%
    write_json(
        "output/analysed_data/final/imports/tsx_SA_tbl.json"
    )
plot(tsx_SA$ref_year, tsx_SA$LPI_final, "l")

infile_TAS <- create_infile(
    TAS_tsx,
    name = "infile",
    start_col_name = "X1985",
    end_col_name = "X2017"
)
tsx_TAS <- LPIMain(
    infile_TAS,
    REF_YEAR = 1985,
    PLOT_MAX = 2017,
    BOOT_STRAP_SIZE = 1000,
    VERBOSE = TRUE,
    goParallel = TRUE,
    title = "tsx_TAS",
    plot_lpi = 0,
    save_plots = 0
) %>%
na.omit() %>%
tibble::rownames_to_column("ref_year") %T>%
    write_json(
        "output/analysed_data/final/imports/tsx_TAS_tbl.json"
    )
plot(tsx_TAS$ref_year, tsx_TAS$LPI_final, "l")

infile_VIC <- create_infile(
    VIC_tsx,
    name = "infile",
    start_col_name = "X1985",
    end_col_name = "X2017"
)
tsx_VIC <- LPIMain(
    infile_VIC,
    REF_YEAR = 1985,
    PLOT_MAX = 2017,
    BOOT_STRAP_SIZE = 1000,
    VERBOSE = TRUE,
    goParallel = TRUE,
    title = "tsx_VIC",
    plot_lpi = 0,
    save_plots = 0
) %>%
na.omit() %>%
tibble::rownames_to_column("ref_year") %T>%
    write_json(
        "output/analysed_data/final/imports/tsx_VIC_tbl.json"
    )
plot(tsx_VIC$ref_year, tsx_VIC$LPI_final, "l")

infile_WA <- create_infile(
    WA_tsx,
    name = "infile",
    start_col_name = "X1985",
    end_col_name = "X2017"
)
tsx_WA <- LPIMain(
    infile_WA,
    REF_YEAR = 1985,
    PLOT_MAX = 2017,
    BOOT_STRAP_SIZE = 1000,
    VERBOSE = TRUE,
    goParallel = TRUE,
    title = "tsx_WA",
    plot_lpi = 0,
    save_plots = 0
) %>%
na.omit() %>%
tibble::rownames_to_column("ref_year") %T>%
    write_json(
        "output/analysed_data/final/imports/tsx_WA_tbl.json"
    )
plot(tsx_WA$ref_year, tsx_WA$LPI_final, "l")
