
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

## Available NHS Talking Therapies reports

### Annual reports

| Function                    | First period | Last period | Count periods | Version |
|:----------------------------|:-------------|:------------|--------------:|--------:|
| `get_key_measures_annual()` | 2017-18      | 2024-25     |             8 |   0.2.0 |

### Monthly reports

| Function | First period | Last period | Count periods | Version |
|:---|:---|:---|---:|---:|
| `get_activity_performance_monthly()` | 2023-05 | 2025-09 | 29 | 0.2.0 |
