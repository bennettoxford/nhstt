# How to use the monthly activity performance data

> **Note:** This vignette is for illustration purposes only and may
> contain errors. It demonstrates example usage of the dataset and
> functions, but results should not be interpreted as validated
> analyses.

This example demonstrates how to explore monthly NHS Talking Therapies
reports using the `nhstt` package. We’ll look at changes in monthly
measures related to different treatment end codes broken down by
individual NHS Talking Therapies providers.

## Setup

We start by loading the necessary packages and downloading the monthly
activity performance dataset with
[`get_activity_performance_monthly()`](https://bennettoxford.github.io/nhstt/reference/get_activity_performance_monthly.md).
This report contains monthly performance indicators for NHS Talking
Therapies services across England.

``` r
# Load packages
library(nhstt)
library(ggplot2)
library(dplyr)
library(scales)
library(stringr)

# Get all monthly activity performance reports
activity_performance <- get_activity_performance_monthly()
```

## Select data for analysis

We want to explore changes in the following measures related to
referrals that ended:

- **M057**: Count of referrals that ended in the reporting period with
  an end code of ‘Not suitable for IAPT service - no action taken or
  directed back to referrer’ (End code: 10)
- **M058**: Count of referrals that ended in the reporting period with
  an end code of ‘Not suitable for IAPT service - signposted elsewhere
  with mutual agreement of patient’ (End code: 11)
- **M059**: Count of referrals that ended in the reporting period with
  an end code of ‘Discharged by mutual agreement following advice and
  support’ (End code: 12)
- **M060**: Count of referrals that ended in the reporting period with
  an end code of ‘Referred to another therapy service by mutual
  agreement’ (End code: 13)
- **M061**: Count of referrals that ended in the reporting period with
  an end code of ‘Suitable for IAPT service, but patient declined
  treatment that was offered’ (End code: 14)
- **M066**: Count of referrals with an end date in the reporting
  period - Improving Access to Psychological Therapies care spell end
  code is ‘Mutually agreed completion of treatment’ (End code: 46)
- **M062**: Count of referrals that ended in the reporting period with
  an end code of ‘Deceased (Seen but not taken on for a course of
  treatment)’ (End code: 17)
- **M063**: Count of referrals that ended in the reporting period with
  an end code of ‘Not known (Seen but not taken on for a course of
  treatment)’ (End code: 95)
- **M066**: Count of referrals with an end date in the reporting
  period - Improving Access to Psychological Therapies care spell end
  code is ‘Mutually agreed completion of treatment’ (End code: 46)
- **M069**: Count of referrals that ended in the reporting period with
  an end code of ‘Deceased (Seen and taken on for a course of
  treatment)’ (End code: 49)
- **M070**: Count of referrals that ended in the reporting period with
  an end code of ‘Not Known (Seen and taken on for a course of
  treatment)’ (End code: 96)
- **M071**: Count of referrals that ended in the reporting period with
  an invalid end code (Invalid: not in 10, 11, 12, 13, 14, 16, 17, 95,
  46, 47, 48, 49, 50, 96)
- **M340**: Count of referrals that ended in the reporting period with
  an end code of ‘Incomplete Assessment (Patient dropped out)’ (End
  code: 16)
- **M341**: Count of referrals that ended in the reporting period with
  an end code of ‘Termination of treatment earlier than patient
  requested’ (End code: 48)
- **M342**: Count of referrals that ended in the reporting period with
  an end code of ‘Not assessed’ (End code: 50)
- **M344**: Count of referrals that ended in the reporting period with
  an end code of ‘Termination of treatment earlier than Care
  Professional planned’ (End code: 47)

``` r
referral_ended_measures <- c(
  "M057", "M058", "M059", "M060", "M061", "M066", "M340", "M062",
  "M063", "M066", "M344", "M341", "M069", "M342", "M070", "M071"
)

selected_activity_performance <- activity_performance |>
  filter(measure_id %in% c(referral_ended_measures)) |>
  filter(group_type == "Provider")
```

## Create figure

Finally, we visualise the trends over time broken down by codes for
referrals that ended for each service provider.

![Trends for counts of different referrals that ended
measures.](how-to-activity-performance-monthly_files/figure-html/fig-example-1.png)

Trends for counts of different referrals that ended measures.
