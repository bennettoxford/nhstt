
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nhstt

<!-- badges: start -->

[![R-CMD-check](https://github.com/bennettoxford/nhstt/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bennettoxford/nhstt/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/bennettoxford/nhstt/graph/badge.svg)](https://app.codecov.io/gh/bennettoxford/nhstt)
<!-- badges: end -->

> **This package is under active development. Breaking changes are
> likely.**

`nhstt` provides access to publicly available NHS Talking Therapies
reports in a tidy data format.

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
# Note, this will take a few minutes
ap_monthly <- get_activity_performance_monthly()
```

## Available NHS Talking Therapies data

### Annual data

| Function                    | First period | Last period | Count periods | Version |
|:----------------------------|:-------------|:------------|--------------:|--------:|
| `get_key_measures_annual()` | 2017-18      | 2024-25     |             8 |   0.2.0 |

### Monthly data

| Function | First period | Last period | Count periods | Version |
|:---|:---|:---|---:|---:|
| `get_activity_performance_monthly()` | 2023-05 | 2025-09 | 29 | 0.2.0 |

### Metadata

| Function | First period | Last period | Count periods | Version |
|:---|:---|:---|---:|---:|
| `get_metadata_monthly()` | 2025-07 | 2025-07 | 1 | 0.1.0 |
| `get_metadata_measures_annual()` | 2024-25 | 2024-25 | 1 | 0.1.0 |
| `get_metadata_variables_annual()` | 2024-25 | 2024-25 | 1 | 0.1.0 |

## Time to download and tidy the data

Approximate download and processing times per period. Your times might
be a bit faster or slower depending on your internet and computer.

| Function | Download per period | Tidy per period | Total (all periods) |
|:---|---:|---:|---:|
| `get_key_measures_annual()` | 1.2 sec | 15.5 sec | 2.2 min |
| `get_activity_performance_monthly()` | 4.3 sec | 0.44 sec | 2.3 min |

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
