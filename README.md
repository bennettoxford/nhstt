
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

# Load annual key measures dataset for financial year 2024-25
km_annual <- get_key_measures_annual(periods = "2024-25")

# Load all monthly activity performance datasets
ap_monthly <- get_activity_performance_monthly()
```

## Available NHS Talking Therapies data

Data can be accessed from R using the `get_*()` functions or downloaded
directly using the links in the tables below. Annual and monthly
datasets are also available as [Parquet](https://parquet.apache.org/)
files from the GitHub Releases page. The *Periods* column shows the
number of reporting periods covered by each dataset.

### Annual data

| Function | First period | Last period | Periods | Tidy data | Version |
|:---|:---|:---|---:|:---|---:|
| `get_key_measures_annual()` | 2017-18 | 2024-25 | 8 | [Download](https://github.com/bennettoxford/nhstt/releases/download/key-measures-annual-v0.2.0/key_measures_annual.parquet) | 0.2.0 |
| `get_proms_annual()` | 2019-20 | 2024-25 | 6 | [Download](https://github.com/bennettoxford/nhstt/releases/download/proms-annual-v0.1.0/proms_annual.parquet) | 0.1.0 |
| `get_therapy_position_annual()` | 2019-20 | 2024-25 | 6 | [Download](https://github.com/bennettoxford/nhstt/releases/download/therapy-position-annual-v0.1.0/therapy_position_annual.parquet) | 0.1.0 |

### Monthly data

| Function | First period | Last period | Periods | Tidy data | Version |
|:---|:---|:---|---:|:---|---:|
| `get_activity_performance_monthly()` | 2021-01 | 2026-03 | 63 | [Download](https://github.com/bennettoxford/nhstt/releases/download/activity-performance-monthly-v0.4.0/activity_performance_monthly.parquet) | 0.4.0 |

### Metadata

| Function | First period | Last period | Periods | Tidy data | Version |
|:---|:---|:---|---:|:---|---:|
| `get_metadata_measures_annual()` | 2024-25 | 2024-25 | 1 | [Download](https://github.com/bennettoxford/nhstt/releases/download/metadata-measures-annual-v0.1.0/metadata_measures_annual.parquet) | 0.1.0 |
| `get_metadata_variables_annual()` | 2024-25 | 2024-25 | 1 | [Download](https://github.com/bennettoxford/nhstt/releases/download/metadata-variables-annual-v0.1.0/metadata_variables_annual.parquet) | 0.1.0 |
| `get_metadata_monthly()` | 2026-05 | 2026-05 | 1 | [Download](https://github.com/bennettoxford/nhstt/releases/download/metadata-measures-monthly-v0.1.0/metadata_measures_monthly.parquet) | 0.1.0 |
| `get_metadata_providers()` | current | current | 1 | [Download](https://github.com/bennettoxford/nhstt/releases/download/metadata-providers-v0.1.0/metadata_providers.parquet) | 0.1.0 |

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
