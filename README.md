
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nhstt

<!-- badges: start -->

[![R-CMD-check](https://github.com/bennettoxford/nhstt/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bennettoxford/nhstt/actions/workflows/R-CMD-check.yaml)
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

# Download and process data (run once)
nhstt_setup()

# See R package info and avialable datasets
nhstt_info()

# Load a dataset
key_measures
```

## Available NHS Talking Therapies reports

### Annual reports

All annual reports are available from April 2017 to March 2025 (8 annual
periods).

| Dataset | Description | Version |
|:---|:---|---:|
| `key_measures` | Key measures like referrals, finished treatments, and treatment outcomes | 0.1.0 |
| `medication_status` | Psychotropic medication status at start and end of treatment | 0.1.0 |
| `therapy_type` | Therapy type at start and end of treatment | 0.1.0 |
| `effect_size` | Effect sizes for PHQ9 and GAD7, with start and end of treatment scores | 0.1.0 |
