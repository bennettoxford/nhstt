# nhstt

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
files from the GitHub Releases page. Metadata datasets link to the raw
Excel files published by NHS England. The *Periods* column shows the
number of reporting periods covered by each dataset.

### Annual data

| Function | First period | Last period | Periods | Tidy data | Version |
|:---|:---|:---|---:|:---|---:|
| [`get_key_measures_annual()`](https://bennettoxford.github.io/nhstt/reference/get_key_measures_annual.md) | 2017-18 | 2024-25 | 8 | [Download](https://github.com/bennettoxford/nhstt/releases/download/key-measures-annual-v0.2.0/key_measures_annual.parquet) | 0.2.0 |
| [`get_proms_annual()`](https://bennettoxford.github.io/nhstt/reference/get_proms_annual.md) | 2019-20 | 2024-25 | 6 | [Download](https://github.com/bennettoxford/nhstt/releases/download/proms-annual-v0.1.0/proms_annual.parquet) | 0.1.0 |
| [`get_therapy_position_annual()`](https://bennettoxford.github.io/nhstt/reference/get_therapy_position_annual.md) | 2019-20 | 2024-25 | 6 | [Download](https://github.com/bennettoxford/nhstt/releases/download/therapy-position-annual-v0.1.0/therapy_position_annual.parquet) | 0.1.0 |

### Monthly data

| Function | First period | Last period | Periods | Tidy data | Version |
|:---|:---|:---|---:|:---|---:|
| [`get_activity_performance_monthly()`](https://bennettoxford.github.io/nhstt/reference/get_activity_performance_monthly.md) | 2023-05 | 2026-03 | 35 | [Download](https://github.com/bennettoxford/nhstt/releases/download/activity-performance-monthly-v0.3.0/activity_performance_monthly.parquet) | 0.3.0 |

### Metadata

| Function | First period | Last period | Periods | Raw data | Version |
|:---|:---|:---|---:|:---|---:|
| [`get_metadata_measures_annual()`](https://bennettoxford.github.io/nhstt/reference/get_metadata_measures_annual.md) | 2024-25 | 2024-25 | 1 | [Download](https://files.digital.nhs.uk/BE/AAF6D0/psych-ther-ann-2024-25-meta.xlsx) | 0.1.0 |
| [`get_metadata_variables_annual()`](https://bennettoxford.github.io/nhstt/reference/get_metadata_variables_annual.md) | 2024-25 | 2024-25 | 1 | [Download](https://files.digital.nhs.uk/BE/AAF6D0/psych-ther-ann-2024-25-meta.xlsx) | 0.1.0 |
| [`get_metadata_monthly()`](https://bennettoxford.github.io/nhstt/reference/get_metadata_monthly.md) | 2025-07 | 2025-07 | 1 | [Download](https://digital.nhs.uk/binaries/content/assets/website-assets/data-and-information/datasets/nhs-talking-therapies/reports/nhstalkingtherapies-monthly-metadata-20250710.xlsx) | 0.1.0 |
| [`get_metadata_providers()`](https://bennettoxford.github.io/nhstt/reference/get_metadata_providers.md) | current | current | 1 | [Download](https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations) | 0.1.0 |

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
