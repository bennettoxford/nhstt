test_that("str_extract_snomed returns string with all matches", {
  string <- c("Code one: 123456, Code two: 1234567", "No code")
  match <- str_extract_snomed(string)

  expect_equal(
    match,
    c(
      "123456, 1234567",
      NA_character_
    )
  )
})

test_that("str_extract_snomed returns NA_character for empty string", {
  string <- ""
  match <- str_extract_snomed(string)

  expect_equal(
    match,
    NA_character_
  )
})

test_that("str_extract_snomed returns NA_character for 19+ digit", {
  string <- c(
    "Code too long: 218954566244485696558",
    "SNOMED code: 6597962, another code: 5468696"
  )
  match <- str_extract_snomed(string)

  expect_equal(
    match,
    c(NA_character_, "6597962, 5468696")
  )
})

test_that("str_extract_snomed works with mutate", {
  df <- tibble::tribble(
    ~measure_id , ~technical_construction                                    ,
    "M1"        , "Good SNOMED code 123456789"                               ,
    "M2"        , "Almost SNOMED code 012345678 but leading zero"            ,
    "M3"        , "No SNOMED code"                                           ,
    "M4"        , "SNOMED code one: 123456789101112, SNOMED code two 123456"
  )
  df_output <- df |>
    dplyr::mutate(
      snomed_codes = str_extract_snomed(technical_construction)
    )

  expect_equal(
    df_output$snomed_codes,
    c(
      "123456789",
      NA_character_,
      NA_character_,
      "123456789101112, 123456"
    )
  )
})


test_that("str_extract_icd10 returns string with all matches", {
  string <- c("Diagnosis: F32.1, History of: Z865", "No code")
  match <- str_extract_icd10(string)

  expect_equal(
    match,
    c(
      "F321, Z865",
      NA_character_
    )
  )
})

test_that("str_extract_icd10 returns NA_character for empty string", {
  string <- ""
  match <- str_extract_icd10(string)

  expect_equal(
    match,
    NA_character_
  )
})

test_that("str_extract_icd10 handles codes with and without decimals", {
  string <- c(
    "Code with decimal: F32.1",
    "Code without decimal: F32",
    "Both: F32 and F32.1"
  )
  match <- str_extract_icd10(string)

  expect_equal(
    match,
    c(
      "F321",
      "F32",
      "F32, F321"
    )
  )
})

test_that("str_extract_icd10 returns NA_character for invalid codes", {
  string <- c("Too short: A1", "Lowercase: f32.1", "Too many decimals: A00.123")
  match <- str_extract_icd10(string)

  expect_equal(
    match,
    c(
      NA_character_,
      NA_character_,
      NA_character_
    )
  )
})

test_that("str_extract_icd10 works with mutate", {
  df <- tibble::tribble(
    ~measure_id , ~technical_construction             ,
    "M1"        , "Valid ICD-10 code F321"            ,
    "M2"        , "Invalid code A1"                   ,
    "M3"        , "No ICD-10 code"                    ,
    "M4"        , "Multiple codes: F32, F32.1, Z86.5"
  )
  df_output <- df |>
    dplyr::mutate(
      icd10_codes = str_extract_icd10(technical_construction)
    )

  expect_equal(
    df_output$icd10_codes,
    c(
      "F321",
      NA_character_,
      NA_character_,
      "F32, F321, Z865"
    )
  )
})

test_that("clean_str converts CamelCase to snake_case", {
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
    clean_str(raw_names),
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

test_that("replace_suppression_with_na converts suppression markers to NA", {
  suppression_values <- c("*", "-", "", "N/A", "NA", "NULL", "Null", "null")

  result <- replace_suppression_with_na(suppression_values)

  expect_type(result, "double")
  expect_true(all(is.na(result)))
})

test_that("replace_suppression_with_na coerces numeric strings", {
  result <- replace_suppression_with_na(c("10", "45.6"))

  expect_equal(result, c(10, 45.6))
})

test_that("convert_to_numeric only cleans configured measure columns", {
  df <- tibble::tribble(
    ~org_code , ~count_gp_referrals , ~count_other ,
    "A"       , "10"                , "200"        ,
    "B"       , "*"                 , "300"
  )

  result <- convert_to_numeric(df, c("count_gp_referrals"))

  expect_equal(result$count_gp_referrals, c(10, NA))
  expect_equal(result$count_other, c("200", "300"))
})

test_that("rename_columns renames present columns only", {
  df <- tibble::tibble(org_code = "A123", sites = 2)
  mapping <- c(org_code = "org_code", site_count = "sites", ignored = "missing")

  result <- rename_columns(df, mapping)

  expect_named(result, c("org_code", "site_count"))
  expect_equal(result$site_count, 2)
})

test_that("rename_columns handles different measures across periods", {
  df_2023 <- tibble::tibble(
    count_referrals = 100,
    count_recovery = 50,
    percentage_recovery = 25.0
  )
  df_2024 <- tibble::tibble(count_referrals = 200)

  config <- list(
    count_referrals = "count_referrals",
    count_recovery = "count_recovery",
    percentage_recovery = "percentage_recovery"
  )

  result_2023 <- rename_columns(df_2023, config)
  result_2024 <- rename_columns(df_2024, config)

  expect_named(
    result_2023,
    c("count_referrals", "count_recovery", "percentage_recovery")
  )
  expect_equal(result_2023$count_referrals, 100)
  expect_equal(result_2023$count_recovery, 50)
  expect_equal(result_2023$percentage_recovery, 25.0)
  expect_named(result_2024, "count_referrals")
  expect_equal(result_2024$count_referrals, 200)
})

test_that("rename_columns applies period-specific overrides", {
  df_old <- tibble::tibble(count_referrals_old = 100)
  df_new <- tibble::tibble(count_referrals = 200)

  config <- list(
    count_referrals = "count_referrals",
    "2023-24" = list(count_referrals = "count_referrals_old")
  )

  result_old <- rename_columns(df_old, config, period = "2023-24")
  result_new <- rename_columns(df_new, config, period = "2024-25")

  expect_equal(result_old$count_referrals, 100)
  expect_equal(result_new$count_referrals, 200)
})

test_that("rename_columns works without period parameter", {
  df <- tibble::tibble(reporting_period_start = "2023-04-01")

  config <- list(
    start_date = "reporting_period_start",
    "2023-24" = list(start_date = "period_start")
  )

  result <- rename_columns(df, config, period = NULL)

  expect_named(result, "start_date")
  expect_equal(result$start_date, "2023-04-01")
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
  result <- parse_annual_period_bounds("FY2021-22")

  expect_equal(result$start, as.Date("2021-04-01"))
  expect_equal(result$end, as.Date("2022-03-31"))
})

test_that("parse_monthly_period_bounds returns month start/end", {
  result <- parse_monthly_period_bounds("2024-02")

  expect_equal(result$start, as.Date("2024-02-01"))
  expect_equal(result$end, as.Date("2024-02-29"))
})

test_that("clean_column_values applies clean_str to requested columns", {
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

test_that("filter_rows filters based on single column", {
  df <- tibble::tibble(
    org_type = c("England", "Provider", "CCG", "England"),
    value = 1:4
  )
  filter_config <- list(org_type = c("England", "Provider"))

  result <- filter_rows(df, filter_config)

  expect_equal(nrow(result), 3)
  expect_true(all(result$org_type %in% c("England", "Provider")))
})

test_that("filter_rows filters based on multiple columns", {
  df <- tibble::tibble(
    org_type = c("England", "Provider", "CCG", "Provider"),
    variable_type = c("Total", "Age Group", "Total", "Total"),
    value = 1:4
  )
  filter_config <- list(
    org_type = c("England", "Provider"),
    variable_type = "Total"
  )

  result <- filter_rows(df, filter_config)

  expect_equal(nrow(result), 2)
  expect_equal(result$org_type, c("England", "Provider"))
  expect_true(all(result$variable_type == "Total"))
})

test_that("filter_rows ignores missing columns", {
  df <- tibble::tibble(org_type = c("England", "Provider"), value = 1:2)
  filter_config <- list(org_type = "England", missing_col = "value")

  result <- filter_rows(df, filter_config)

  expect_equal(nrow(result), 1)
  expect_equal(result$org_type, "England")
})

test_that("filter_rows returns unchanged data with empty config", {
  df <- tibble::tibble(org_type = c("England", "Provider"), value = 1:2)

  result <- filter_rows(df, list())

  expect_identical(result, df)
})

test_that("pivot_longer_measures converts wide to long format", {
  data_list <- list(
    "2023-24" = tibble::tibble(
      org_code = c("A", "B"),
      count_referrals = c(100, 200),
      count_recovery = c(50, 100),
      percentage_recovery = c(50.0, 50.0)
    )
  )
  pivot_config <- list(
    measure_cols = c(
      "count_referrals",
      "count_recovery",
      "percentage_recovery"
    ),
    sep = "^(count|percentage)_(.+)$",
    names_to = c("measure_statistic", "measure_name")
  )

  result <- pivot_longer_measures(data_list, pivot_config)

  expect_s3_class(result, "tbl_df")
  expect_true("reporting_period" %in% names(result))
  expect_true("measure_statistic" %in% names(result))
  expect_true("measure_name" %in% names(result))
  expect_true("value" %in% names(result))
  expect_equal(nrow(result), 6)
  expect_equal(unique(result$measure_name), c("referrals", "recovery"))
  expect_setequal(unique(result$measure_statistic), c("count", "percentage"))
})

test_that("pivot_longer_measures combines multiple periods", {
  data_list <- list(
    "2023-24" = tibble::tibble(org_code = "A", count_referrals = 100),
    "2024-25" = tibble::tibble(org_code = "B", count_referrals = 200)
  )
  pivot_config <- list(
    measure_cols = "count_referrals",
    sep = "^(count)_(.+)$",
    names_to = c("measure_statistic", "measure_name")
  )

  result <- pivot_longer_measures(data_list, pivot_config)

  expect_equal(nrow(result), 2)
  expect_setequal(result$reporting_period, c("2023-24", "2024-25"))
  expect_equal(result$org_code, c("A", "B"))
  expect_equal(result$value, c(100, 200))
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

  result <- clean_org_names(providers)

  expect_equal(
    result,
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
