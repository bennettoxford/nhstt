# nhstt

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

| Function                                                                                                          | First period | Last period | Count periods | Version |
|:------------------------------------------------------------------------------------------------------------------|:-------------|:------------|--------------:|--------:|
| [`get_key_measures_annual()`](https://bennettoxford.github.io/nhstt/reference/get_key_measures_annual.md)         | 2017-18      | 2024-25     |             8 |   0.2.0 |
| [`get_proms_annual()`](https://bennettoxford.github.io/nhstt/reference/get_proms_annual.md)                       | 2022-23      | 2024-25     |             3 |   0.1.0 |
| [`get_therapy_position_annual()`](https://bennettoxford.github.io/nhstt/reference/get_therapy_position_annual.md) | 2022-23      | 2024-25     |             3 |   0.1.0 |

### Monthly data

| Function                                                                                                                    | First period | Last period | Count periods | Version |
|:----------------------------------------------------------------------------------------------------------------------------|:-------------|:------------|--------------:|--------:|
| [`get_activity_performance_monthly()`](https://bennettoxford.github.io/nhstt/reference/get_activity_performance_monthly.md) | 2023-05      | 2025-09     |            29 |   0.2.0 |

### Metadata

| Function                                                                                                              | First period | Last period | Count periods | Version |
|:----------------------------------------------------------------------------------------------------------------------|:-------------|:------------|--------------:|--------:|
| [`get_metadata_measures_annual()`](https://bennettoxford.github.io/nhstt/reference/get_metadata_measures_annual.md)   | 2024-25      | 2024-25     |             1 |   0.1.0 |
| [`get_metadata_variables_annual()`](https://bennettoxford.github.io/nhstt/reference/get_metadata_variables_annual.md) | 2024-25      | 2024-25     |             1 |   0.1.0 |
| [`get_metadata_monthly()`](https://bennettoxford.github.io/nhstt/reference/get_metadata_monthly.md)                   | 2025-07      | 2025-07     |             1 |   0.1.0 |
| [`get_metadata_providers()`](https://bennettoxford.github.io/nhstt/reference/get_metadata_providers.md)               | current      | current     |             1 |   0.1.0 |

## Time to download and tidy the data

Approximate download and processing times per period. Your times might
be a bit faster or slower depending on your internet speed and computer
setup.

| Function                                                                                                                    | Download per period | Tidy per period | Total (all periods) |
|:----------------------------------------------------------------------------------------------------------------------------|--------------------:|----------------:|--------------------:|
| [`get_key_measures_annual()`](https://bennettoxford.github.io/nhstt/reference/get_key_measures_annual.md)                   |             1.2 sec |          16 sec |             2.3 min |
| [`get_proms_annual()`](https://bennettoxford.github.io/nhstt/reference/get_proms_annual.md)                                 |            0.52 sec |        31.2 sec |             1.6 min |
| [`get_therapy_position_annual()`](https://bennettoxford.github.io/nhstt/reference/get_therapy_position_annual.md)           |            0.26 sec |        0.07 sec |               1 sec |
| [`get_activity_performance_monthly()`](https://bennettoxford.github.io/nhstt/reference/get_activity_performance_monthly.md) |             4.3 sec |        0.52 sec |             2.4 min |

## For developers

See
[DEVELOPERS.md](https://bennettoxford.github.io/nhstt/DEVELOPERS.md).

## Licence

### R package

The `nhstt` package is licensed under the [MIT
License](https://bennettoxford.github.io/nhstt/LICENSE.md).

### NHS Talking Therapies data

All NHS Talking Therapies data is Copyright NHS England and licensed
under the [Open Government Licence
v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
Contains public sector information licensed under the Open Government
Licence v3.0.
