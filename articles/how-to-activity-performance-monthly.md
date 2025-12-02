# How to use the monthly activity and performance data

> **Note:** This guide is for illustration purposes only and may contain
> errors. It demonstrates example usage of the dataset and functions,
> but results should not be interpreted as validated analyses.

This example demonstrates how to explore monthly NHS Talking Therapies
reports using the `nhstt` package. To illustrate the basic workflow for
accessing and visualising this publicly available data we’ll look at
three examples:

1.  Measures describing different treatment end codes
2.  Measures describing wait times from referral to first treatment
3.  Comparing a measure across different providers

## Setup

``` r
# Load nhstt package for data
library(nhstt)

# Load other packages for analysis
library(ggplot2)
library(lubridate)
library(dplyr)
library(scales)
library(stringr)
library(gt)

# Get 5 monthly activity performance reports
activity_performance <- get_activity_performance_monthly(
  periods = c("2024-01", "2024-02", "2024-03", "2024-04", "2024-05")
)
```

We start by loading R packages and downloading the monthly activity and
performance dataset with
[`get_activity_performance_monthly()`](https://bennettoxford.github.io/nhstt/reference/get_activity_performance_monthly.md).
This report contains monthly performance indicators for NHS Talking
Therapies services across England.

The `activity_performance` dataset defined above contains a total of 204
different activity and performance measures, available from January 2024
to May 2024 (5 reporting periods).

### Example 1: Explore changes in referrals that ended

#### Define measures related to referrals that ended

Using the
[`get_metadata_monthly()`](https://bennettoxford.github.io/nhstt/reference/get_metadata_monthly.md)
function, we can look up the descriptions for these measures:

``` r
# Define measure ids for analysis
referral_ended_measures <- c(
  "M057",
  "M058",
  "M059",
  "M060",
  "M061",
  "M066",
  "M340",
  "M062",
  "M063",
  "M066",
  "M344",
  "M341",
  "M069",
  "M342",
  "M070",
  "M071"
)
```

    #> ℹ Downloading metadata (monthly) for 2025-07
    #> ! Download failed (attempt 1/3), retrying...
    #> ℹ Downloading metadata (monthly) for 2025-07! Download failed (attempt 2/3), retrying...
    #> ℹ Downloading metadata (monthly) for 2025-07✖ Downloading metadata (monthly) for 2025-07 ... failed
    #> 
    #> ! Download failed, using package metadata for 2025-07

| ID   | Description                                                                                                                                                                |
|:-----|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| M057 | Count of referrals that ended in the reporting period with an end code of 'Not suitable for IAPT service - no action taken or directed back to referrer’                   |
| M058 | Count of referrals that ended in the reporting period with an end code of ‘Not suitable for IAPT service - signposted elsewhere with mutual agreement of patient’          |
| M059 | Count of referrals that ended in the reporting period with an end code of 'Discharged by mutual agreement following advice and support'                                    |
| M060 | Count of referrals that ended in the reporting period with an end code of 'Referred to another therapy service by mutual agreement'                                        |
| M061 | Count of referrals that ended in the reporting period with an end code of 'Suitable for IAPT service, but patient declined treatment that was offered'                     |
| M062 | Count of referrals that ended in the reporting period with an end code of ‘Deceased (Seen but not taken on for a course of treatment)’                                     |
| M063 | Count of referrals that ended in the reporting period with an end code of 'Not known (Seen but not taken on for a course of treatment)'                                    |
| M066 | Count of referrals with an end date in the reporting period - Improving Access to Psychological Therapies care spell end code is 'Mutually agreed completion of treatment’ |
| M069 | Count of referrals that ended in the reporting period with an end code of ‘Deceased (Seen and taken on for a course of treatment)’                                         |
| M070 | Count of referrals that ended in the reporting period with an end code of ‘Not Known (Seen and taken on for a course of treatment)’                                        |
| M340 | Count of referrals that ended in the reporting period with an end code of ‘Incomplete Assessment (Patient dropped out)’                                                    |
| M341 | Count of referrals that ended in the reporting period with an end code of ‘Termination of treatment earlier than patient requested’                                        |
| M342 | Count of referrals that ended in the reporting period with an end code of ‘Not assessed’                                                                                   |
| M344 | Count of referrals that ended in the reporting period with an end code of ‘Termination of treatment earlier than Care Professional planned’                                |
| M071 | Count of referrals that ended in the reporting period with an invalid end code                                                                                             |

#### Analysis

Here we filter the data to include all measures defined above in
`referral_ended_measures` and select all service providers:

``` r
# Select data for analysis
selected_activity_performance <- activity_performance |>
  filter(measure_id %in% c(referral_ended_measures)) |>
  filter(group_type == "Provider")
```

Now we can visualise the trends over time broken down by codes for
referrals that ended for each service provider. Note that the y-axis
scales are not fixed to allow better visualisation of trends for
measures with different count ranges.

![Trends for counts of different referrals that ended
measures.](how-to-activity-performance-monthly_files/figure-html/fig-example-1.png)

Trends for counts of different referrals that ended measures.

### Example 2: Explore wait times from referrral to first treatment

#### Define measures

Here we will explore changes in the following measures related to wait
times from referrral to first treatment. Note that there are other
measures related to wait times available in the dataset.

``` r
# Define measure ids for analysis
first_tx_waited_measures <- c(
  "M039",
  "M040",
  "M041",
  "M042",
  "M043",
  "M044",
  "M045"
)
```

| ID   | Description                                                                                                             |
|:-----|:------------------------------------------------------------------------------------------------------------------------|
| M039 | Count of referrals yet to have a first treatment who have been waiting 0 to 2 weeks at the end of the reporting period  |
| M040 | Count of referrals yet to have a first treatment who have been waiting 0 to 4 weeks at the end of the reporting period  |
| M041 | Count of referrals yet to have a first treatment who have been waiting 0 to 6 weeks at the end of the reporting period  |
| M042 | Count of referrals yet to have a first treatment who have been waiting 0 to 12 weeks at the end of the reporting period |
| M043 | Count of referrals yet to have a first treatment who have been waiting 0 to 18 weeks at the end of the reporting period |
| M044 | Count of referrals yet to have a first treatment who have been waiting over 18 weeks at the end of the reporting period |
| M045 | Count of referrals yet to have a first treatment who have been waiting over 90 days at the end of the reporting period  |

#### Analysis

Here we filter the data to include all measures defined above in
`first_tx_waited_measures` and select all service providers:

``` r
# Select data for analysis
selected_activity_performance <- activity_performance |>
  filter(measure_id %in% first_tx_waited_measures) |>
  filter(group_type == "Provider")
```

Now we can visualise the trends over time broken down by different
waiting time periods from referral to first treatment, with one line for
each service provider.

![Trends for counts of different waiting time periods from referral to
first treatment for each
service.](how-to-activity-performance-monthly_files/figure-html/fig-example2-1.png)

Trends for counts of different waiting time periods from referral to
first treatment for each service.

### Example 3: Compare a measure across different providers

We can also focus on a single measure and compare counts across
different services. In this example we look at measure `M344` (*Count of
referrals that ended in the reporting period with an end code of
‘Termination of treatment earlier than Care Professional planned’*) and
visualise trends over time for the four providers with the highest
overall counts.

Here we identify the 4 providers with the most recorded activity in
`M344` across the whole time period:

``` r
top4_m344_providers <- activity_performance |>
  filter(measure_id == "M344") |>
  filter(group_type == "Provider") |>
  select(org_name2, value) |>
  group_by(org_name2) |>
  summarise(total = sum(value, na.rm = TRUE)) |>
  slice_max(total, n = 4) |>
  pull(org_name2)
```

We can use this list (`top4_m344_providers`) to filter the data and plot
trends for these four providers:

![Counts of referrals with measure M344 for the four providers with the
highest
totals.](how-to-activity-performance-monthly_files/figure-html/fig-example3-1.png)

Counts of referrals with measure M344 for the four providers with the
highest totals.
