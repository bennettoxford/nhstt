fixture_path_annual_legacy <- function(filename) {
  test_path("fixtures", "annual-legacy", filename)
}

# Zip fixture CSVs into a temporary archive, like the 2015-16 and 2016-17 packs
zip_fixture_annual_legacy <- function(csv_filenames, env = parent.frame()) {
  tmp_dir <- withr::local_tempdir(.local_envir = env)
  tmp_zip <- withr::local_tempfile(fileext = ".zip", .local_envir = env)

  file.copy(fixture_path_annual_legacy(csv_filenames), tmp_dir)
  zip(tmp_zip, files = file.path(tmp_dir, csv_filenames), flags = "-jq")

  tmp_zip
}

tables_2016_17 <- list(
  "table-1a" = list(count_referrals_received = "ReferralsReceived"),
  "table-7a" = list(
    count_finished_course_treatment = "FinishedCourseTreatment",
    count_at_caseness = "StartedCaseness",
    count_not_at_caseness = "StartedNotCaseness",
    count_improvement = "Improvement",
    percentage_improvement = "ImprovementRate",
    count_no_reliable_change = "NoReliableChange",
    percentage_no_reliable_change = "NoReliableChangeRate",
    count_deterioration = "Deterioration",
    percentage_deterioration = "DeteriorationRate",
    count_recovery = "Recovery",
    percentage_recovery = "RecoveryRate",
    count_reliable_recovery = "ReliableRecovery",
    percentage_reliable_recovery = "ReliableRecoveryRate"
  )
)

# Point the legacy archive at local fixture files instead of the NHS England site
local_annual_legacy_archive <- function(sources, env = parent.frame()) {
  config <- load_raw_config()
  config$archives$annual_legacy <- sources
  local_mocked_bindings(
    load_raw_config = function() config,
    download_with_retry = function(url, file) {
      file.copy(url, file, overwrite = TRUE)
    },
    .env = env
  )
}

totals_2016_17 <- function() {
  zip <- zip_fixture_annual_legacy(c(
    "table-1a_2016-17.csv",
    "table-7a_2016-17.csv"
  ))
  extract_annual_legacy_totals(zip, tables_2016_17)
}

test_that("read_annual_legacy_england_row reads the England row of a CSV by header", {
  zip <- zip_fixture_annual_legacy("table-1a_2016-17.csv")
  row <- read_annual_legacy_england_row(zip, "table-1a")

  expect_equal(row$ReferralsReceived, 1385664)
  expect_equal(row$FinishedCourseTreatment, 567106)
})

test_that("read_annual_legacy_england_row reads the England total row of an XLSX by column number", {
  row <- read_annual_legacy_england_row(
    fixture_path_annual_legacy("table-12b_2014-15.xlsx"),
    "Sheet1"
  )

  expect_equal(row[[1]], "England total")
  expect_equal(row[[5]], 265833)
})

test_that("read_annual_legacy_england_row errors when the table is missing", {
  zip <- zip_fixture_annual_legacy("table-1a_2016-17.csv")

  expect_error(
    read_annual_legacy_england_row(zip, "no-such-table"),
    "No file matching"
  )
})

test_that("read_annual_legacy_england_row errors when there is no England row", {
  csv <- withr::local_tempfile(fileext = ".csv")
  writeLines(
    readLines(fixture_path_annual_legacy("table-1a_2016-17.csv"))[-2],
    csv
  )
  zip_no_england <- withr::local_tempfile(fileext = ".zip")
  zip(zip_no_england, files = csv, flags = "-jq")

  expect_error(
    read_annual_legacy_england_row(zip_no_england, "\\.csv"),
    "Expected 1 England row"
  )
})

test_that("extract_annual_legacy_totals maps each configured column to its measure", {
  result <- totals_2016_17()

  expect_equal(nrow(result), 1)
  expect_equal(result$org_type, "England")
  expect_equal(result$variable_type, "Total")
  expect_equal(result$variable_a, "NULL")
  expect_equal(result$variable_b, "NULL")
  expect_equal(result$count_referrals_received, 1385664)
  expect_equal(result$count_finished_course_treatment, 567106)
  expect_equal(result$count_not_at_caseness, 42376)
  expect_equal(result$percentage_recovery, 49.3)
  expect_equal(result$count_reliable_recovery, 246460)
})

test_that("extract_annual_legacy_totals errors when a configured column is missing", {
  zip <- zip_fixture_annual_legacy("table-1a_2016-17.csv")

  expect_error(
    extract_annual_legacy_totals(
      zip,
      list("table-1a" = list(count_referrals_received = "RECEIVED"))
    ),
    "not found"
  )
  expect_error(
    extract_annual_legacy_totals(
      fixture_path_annual_legacy("table-12b_2014-15.xlsx"),
      list(Sheet1 = list(count_referrals_received = 99))
    ),
    "not found"
  )
})

test_that("check_annual_legacy_totals passes published England totals", {
  expect_no_error(check_annual_legacy_totals(totals_2016_17(), "2016-17"))
})

test_that("check_annual_legacy_totals catches a column read from the wrong position", {
  swapped <- totals_2016_17()
  swapped$percentage_recovery <- swapped$percentage_reliable_recovery

  expect_error(
    check_annual_legacy_totals(swapped, "2016-17"),
    "percentage_recovery"
  )
})

test_that("check_annual_legacy_totals catches impossible values", {
  df <- totals_2016_17()

  negative <- df
  negative$count_deterioration <- -1
  expect_error(check_annual_legacy_totals(negative, "2016-17"), "negative")

  too_high <- df
  too_high$count_reliable_recovery <- df$count_recovery + 1
  expect_error(
    check_annual_legacy_totals(too_high, "2016-17"),
    "reliable recovery"
  )
})

test_that("check_annual_legacy_totals reports a missing value instead of crashing", {
  df <- totals_2016_17()
  df$percentage_recovery <- NA_real_

  expect_error(check_annual_legacy_totals(df, "2016-17"), "missing")
})

test_that("check_annual_legacy_totals uses at caseness when not at caseness is missing", {
  # 2013-14 published England totals
  df <- tibble::tibble(
    count_finished_course_treatment = 364343,
    count_at_caseness = 319904,
    count_recovery = 143833,
    percentage_recovery = 45,
    count_reliable_recovery = 136928,
    percentage_reliable_recovery = 42.8
  )

  expect_no_error(check_annual_legacy_totals(df, "2013-14"))
})

test_that("check_annual_legacy_totals passes counts without percentages", {
  # 2012-13 published England totals
  df <- tibble::tibble(
    count_referrals_received = 883968,
    count_finished_course_treatment = 144210,
    count_at_caseness = 127060,
    count_recovery = 54430,
    count_reliable_recovery = 51900
  )

  expect_no_error(check_annual_legacy_totals(df, "2012-13"))
})

test_that("tidy_annual_legacy_totals tidies every period in the legacy archive", {
  zip <- zip_fixture_annual_legacy(c(
    "table-1a_2016-17.csv",
    "table-7a_2016-17.csv"
  ))
  # The second source has one measure only, like 2012-13 has fewer measures
  local_annual_legacy_archive(list(
    list(
      period = "2016-17",
      url = zip,
      format = "zip",
      tables = tables_2016_17
    ),
    list(
      period = "2012-13",
      url = zip,
      format = "zip",
      tables = tables_2016_17["table-1a"]
    )
  ))

  result <- tidy_annual_legacy_totals("measures_annual")

  expect_equal(
    names(result),
    get_tidy_config("measures_annual", "annual")$select
  )
  expect_equal(sum(result$reporting_period == "2016-17"), 14)
  expect_equal(sum(result$reporting_period == "2012-13"), 1)
  expect_false(anyNA(result$value))
  expect_equal(
    unique(result$start_date[result$reporting_period == "2012-13"]),
    as.Date("2012-04-01")
  )
  expect_equal(
    result$value[
      result$measure_statistic == "percentage" &
        result$measure_name == "recovery"
    ],
    49.3
  )
})

test_that("tidy_annual_legacy_totals stops when a period fails the checks", {
  zip <- zip_fixture_annual_legacy(c(
    "table-1a_2016-17.csv",
    "table-7a_2016-17.csv"
  ))
  wrong_column <- tables_2016_17
  wrong_column$`table-7a`$percentage_recovery <- "ReliableRecoveryRate"
  local_annual_legacy_archive(list(
    list(period = "2016-17", url = zip, format = "zip", tables = wrong_column)
  ))

  expect_error(
    tidy_annual_legacy_totals("measures_annual"),
    "percentage_recovery"
  )
})

test_that("legacy config covers 2012-13 to 2016-17 with known measures only", {
  raw_config <- load_raw_config()
  expect_equal(
    raw_config$datasets$measures_annual$legacy_archive,
    "annual_legacy"
  )

  sources <- raw_config$archives$annual_legacy
  measure_cols <- get_tidy_config(
    "measures_annual",
    "annual"
  )$pivot_longer$measure_cols

  expect_equal(
    purrr::map_chr(sources, "period"),
    c("2016-17", "2015-16", "2014-15", "2013-14", "2012-13")
  )

  for (source in sources) {
    measures <- unlist(lapply(source$tables, names))
    expect_true(all(measures %in% measure_cols), info = source$period)
    expect_false(anyDuplicated(measures) > 0, info = source$period)
    expect_true("count_referrals_received" %in% measures, info = source$period)
  }
})
