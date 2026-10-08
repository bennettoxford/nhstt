
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nhstt

<!-- badges: start -->

[![R-CMD-check](https://github.com/bennettoxford/nhstt/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bennettoxford/nhstt/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/bennettoxford/nhstt/graph/badge.svg)](https://app.codecov.io/gh/bennettoxford/nhstt)
<!-- badges: end -->

`nhstt` provides access to publicly available NHS Talking Therapies
reports in a tidy, analysis-ready format.

## Installation

Install the development version from GitHub:

``` r
# install.packages("pak")
pak::pak("bennettoxford/nhstt")
```

## Usage

``` r
library(nhstt)

# Load the latest release of monthly measures
df_monthly <- get_measures_monthly()

# Load specific version of monthly measures
df_monthly <- get_measures_monthly(version = "0.3.0")
```

## Available NHS Talking Therapies data

Data can be accessed from R using the `get_*()` functions or downloaded
directly using the links in the tables below. Annual, quarterly and
monthly datasets are also available as
[Parquet](https://parquet.apache.org/) files from the GitHub Releases
page. The *Periods* column shows the number of reporting periods covered
by each dataset.

### Monthly data

| Function | First period | Last period | Periods | Version |
|:---|:---|:---|---:|---:|
| `get_measures_monthly()` | 2021-01 | 2026-07 | 67 | [0.6.0](https://github.com/bennettoxford/nhstt/releases/download/measures-monthly-v0.6.0/measures_monthly.parquet) |

### Quarterly data

| Function | First period | Last period | Periods | Version |
|:---|:---|:---|---:|---:|
| `get_measures_quarterly()` | 2023-24-q1 | 2026-27-q1 | 13 | [0.1.0](https://github.com/bennettoxford/nhstt/releases/download/measures-quarterly-v0.1.0/measures_quarterly.parquet) |

### Annual data

| Function | First period | Last period | Periods | Version |
|:---|:---|:---|---:|---:|
| `get_measures_annual()` | 2017-18 | 2024-25 | 8 | [0.3.0](https://github.com/bennettoxford/nhstt/releases/download/measures-annual-v0.3.0/measures_annual.parquet) |
| `get_proms_annual()` | 2019-20 | 2024-25 | 6 | [0.2.0](https://github.com/bennettoxford/nhstt/releases/download/proms-annual-v0.2.0/proms_annual.parquet) |
| `get_therapy_position_annual()` | 2019-20 | 2024-25 | 6 | [0.1.0](https://github.com/bennettoxford/nhstt/releases/download/therapy-position-annual-v0.1.0/therapy_position_annual.parquet) |

### Metadata

| Function | First period | Last period | Periods | Version |
|:---|:---|:---|---:|---:|
| `get_metadata_measures_annual()` | 2024-25 | 2024-25 | 1 | [0.1.0](https://github.com/bennettoxford/nhstt/releases/download/metadata-measures-annual-v0.1.0/metadata_measures_annual.parquet) |
| `get_metadata_variables_annual()` | 2024-25 | 2024-25 | 1 | [0.1.0](https://github.com/bennettoxford/nhstt/releases/download/metadata-variables-annual-v0.1.0/metadata_variables_annual.parquet) |
| `get_metadata_monthly()` | 2026-07 | 2026-07 | 1 | [0.2.0](https://github.com/bennettoxford/nhstt/releases/download/metadata-measures-monthly-v0.2.0/metadata_measures_monthly.parquet) |
| `get_metadata_providers()` | current | current | 1 | [0.1.0](https://github.com/bennettoxford/nhstt/releases/download/metadata-providers-v0.1.0/metadata_providers.parquet) |

## For developers

See [DEVELOPERS.md](DEVELOPERS.md).

## Licence

### R package

The `nhstt` package is licensed under the [MIT License](LICENSE.md).

### NHS Talking Therapies data

All NHS Talking Therapies data is Copyright NHS England and licensed
under the [Open Government Licence
v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
Contains public sector information licensed under the Open Government
Licence v3.0.
