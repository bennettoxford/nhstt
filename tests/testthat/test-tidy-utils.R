test_that("make_clean_str normalises NHS source column names", {
  raw_names <- c(
    "ORG_CODE1",
    "MEASURE_NAME",
    "Count_SelfReferrals",
    "Count_GPReferrals",
    "Count_AccessingServices28days",
    "Count_IPTAppts",
    "Mean_LastWSASHM",
    "Count_AccessingServices57to90days",
    "Count_MHDropInReferrals"
  )

  expect_equal(
    make_clean_str(raw_names),
    c(
      "org_code1",
      "measure_name",
      "count_self_referrals",
      "count_gp_referrals",
      "count_accessing_services28days",
      "count_ipt_appts",
      "mean_last_wsashm",
      "count_accessing_services57to90days",
      "count_mh_drop_in_referrals"
    )
  )
})

test_that("tidy_numeric_values converts suppression markers to NA", {
  suppression_values <- c("*", "-", "", "N/A", "NA", "NULL", "Null", "null")
  numeric_values <- tidy_numeric_values(suppression_values)

  expect_type(numeric_values, "double")
  expect_true(all(is.na(numeric_values)))
})

test_that("tidy_numeric_values coerces numeric strings", {
  result <- tidy_numeric_values(c("10", "45.6"))

  expect_equal(result, c(10, 45.6))
})

test_that("convert_to_numeric only cleans configured measure columns", {
  df <- tibble::tribble(
    ~org_code , ~count_gp_referrals , ~count_other ,
    "A"       , "10"                , "200"        ,
    "B"       , "*"                 , "300"
  )

  tidied <- convert_to_numeric(df, c("count_gp_referrals"))

  expect_equal(tidied$count_gp_referrals, c(10, NA))
  expect_equal(tidied$count_other, c("200", "300"))
})

test_that("rename_columns renames present columns only", {
  df <- tibble::tibble(
    org_code = "A123",
    sites = 2
  )

  mapping <- c(org_code = "org_code", sites = "site_count", missing = "ignored")

  result <- rename_columns(df, mapping)

  expect_named(result, c("org_code", "site_count"))
  expect_equal(result$site_count, 2)
})

test_that("add_period_columns handles annual periods", {
  df <- tibble::tibble(reporting_period = c("2023-24", "2024-25"))
  result <- add_period_columns(df)

  expect_equal(
    result$start_date,
    as.Date(c("2023-04-01", "2024-04-01"))
  )
  expect_equal(
    result$end_date,
    as.Date(c("2024-03-31", "2025-03-31"))
  )
})

test_that("add_period_columns handles monthly periods", {
  df <- tibble::tibble(reporting_period = c("2025-09", "2025-10"))
  result <- add_period_columns(df)

  expect_equal(
    result$start_date,
    as.Date(c("2025-09-01", "2025-10-01"))
  )
  expect_equal(
    result$end_date,
    as.Date(c("2025-09-30", "2025-10-31"))
  )
})

test_that("is_financial_year_period recognises valid formats", {
  expect_true(is_financial_year_period("2023-24"))
  expect_true(is_financial_year_period("FY2022-23"))
  expect_false(is_financial_year_period("2025-09"))
})

test_that("parse_annual_period_bounds expands FY codes", {
  bounds <- parse_annual_period_bounds("FY2021-22")

  expect_equal(bounds$start, as.Date("2021-04-01"))
  expect_equal(bounds$end, as.Date("2022-03-31"))
})

test_that("parse_monthly_period_bounds returns month start/end", {
  bounds <- parse_monthly_period_bounds("2024-02")

  expect_equal(bounds$start, as.Date("2024-02-01"))
  expect_equal(bounds$end, as.Date("2024-02-29"))
})

test_that("clean_column_values applies make_clean_str to requested columns", {
  df <- tibble::tibble(
    measure = c("Count_GPReferrals", "Count_IPTAppts"),
    statistic = c("Mean_LastWSASHM", "Total")
  )

  result <- clean_column_values(df, c("measure", "statistic"))

  expect_equal(
    result$measure,
    c("count_gp_referrals", "count_ipt_appts")
  )
  expect_equal(
    result$statistic,
    c("mean_last_wsashm", "total")
  )
})

test_that("clean_org_names formats NHS TT provider names", {
  providers <- c(
    "NHS BATH AND NORTH EAST SOMERSET CIC",
    "TALKINGSPACE PLUS:OXFORD HEALTH NHS FOUNDATION TRUST",
    "VITAMINDS (BRISTOL) UK",
    "WEST LONDON:NHS TRUST(ADULTS)",
    "TEST(SPACE BEFORE BRACKETS)",
    "TEST:SPACE AFTER COLON",
    "THE  "
  )

  expect_equal(
    clean_org_names(providers),
    c(
      "NHS Bath and North East Somerset CIC",
      "TalkingSpace Plus: Oxford Health NHS Foundation Trust",
      "VitaMinds (Bristol) UK",
      "West London: NHS Trust (Adults)",
      "Test (Space Before Brackets)",
      "Test: Space After Colon",
      "The"
    )
  )
})
