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

## Available NHS Talking Therapies reports

### Annual reports

| Function                                                                                                  | First period | Last period | Count periods | Version |
|:----------------------------------------------------------------------------------------------------------|:-------------|:------------|--------------:|--------:|
| [`get_key_measures_annual()`](https://bennettoxford.github.io/nhstt/reference/get_key_measures_annual.md) | 2017-18      | 2024-25     |             8 |   0.2.0 |

### Monthly reports

| Function                                                                                                                    | First period | Last period | Count periods | Version |
|:----------------------------------------------------------------------------------------------------------------------------|:-------------|:------------|--------------:|--------:|
| [`get_activity_performance_monthly()`](https://bennettoxford.github.io/nhstt/reference/get_activity_performance_monthly.md) | 2023-05      | 2025-09     |            29 |   0.2.0 |
