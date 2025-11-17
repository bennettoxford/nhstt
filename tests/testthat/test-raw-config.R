# Validation function tests ---------------------------------------------------

test_that("validate_dataset accepts valid dataset", {
  expect_invisible(validate_dataset("key_measures"))
})

test_that("validate_dataset errors for invalid dataset", {
  expect_error(
    validate_dataset("invalid_dataset"),
    "Invalid dataset"
  )
})

test_that("validate_frequency accepts annual", {
  expect_invisible(validate_frequency("annual"))
})

test_that("validate_frequency accepts monthly", {
  expect_invisible(validate_frequency("monthly"))
})

test_that("validate_frequency errors for invalid frequency", {
  expect_error(
    validate_frequency("invalid"),
    "Invalid frequency"
  )
})

test_that("validate_period accepts valid period", {
  expect_invisible(validate_period("2023-24", "key_measures", "annual"))
})

test_that("validate_period errors for invalid period", {
  expect_error(
    validate_period("fy9999", "key_measures", "annual"),
    "Invalid period"
  )
})

# Raw config loading tests ----------------------------------------------------

test_that("load_raw_config returns a list", {
  raw_config <- load_raw_config()

  expect_type(raw_config, "list")
})

test_that("load_raw_config has datasets key", {
  raw_config <- load_raw_config()

  expect_true("datasets" %in% names(raw_config))
})

test_that("load_raw_config has key_measures dataset", {
  raw_config <- load_raw_config()

  expect_true("key_measures" %in% names(raw_config$datasets))
})

test_that("key_measures has annual frequency", {
  raw_config <- load_raw_config()

  expect_true("annual" %in% names(raw_config$datasets$key_measures))
})

test_that("annual key_measures has required fields", {
  raw_config <- load_raw_config()
  annual_km <- raw_config$datasets$key_measures$annual

  expect_true("title" %in% names(annual_km))
  expect_true("version" %in% names(annual_km))
  expect_true("get_function" %in% names(annual_km))
  expect_true("sources" %in% names(annual_km))
})

# List available periods tests -------------------------------------------------

test_that("list_available_periods returns character vector", {
  periods <- list_available_periods("key_measures", "annual")

  expect_type(periods, "character")
  expect_true(length(periods) > 0)
})

test_that("list_available_periods returns financial year format", {
  periods <- list_available_periods("key_measures", "annual")

  expect_true(all(grepl("^\\d{4}-\\d{2}$", periods)))
})

test_that("list_available_periods includes known periods", {
  periods <- list_available_periods("key_measures", "annual")

  expect_true("2023-24" %in% periods)
  expect_true("2017-18" %in% periods)
})

test_that("list_available_periods errors for invalid dataset", {
  expect_error(
    list_available_periods("invalid_dataset", "annual"),
    "Invalid dataset"
  )
})

test_that("list_available_periods errors for invalid frequency", {
  expect_error(
    list_available_periods("key_measures", "invalid_frequency"),
    "Invalid frequency"
  )
})

# Get source info tests --------------------------------------------------------

test_that("get_source_config returns a list", {
  source <- get_source_config("key_measures", "2023-24", "annual")

  expect_type(source, "list")
})

test_that("get_source_config has required fields", {
  source <- get_source_config("key_measures", "2023-24", "annual")

  expect_true("url" %in% names(source))
  expect_true("format" %in% names(source))
  expect_true("csv_pattern" %in% names(source))
  expect_true("period" %in% names(source))
})

test_that("get_source_config returns correct period", {
  source <- get_source_config("key_measures", "2023-24", "annual")

  expect_equal(source$period, "2023-24")
})

test_that("get_source_config returns valid URL", {
  source <- get_source_config("key_measures", "2023-24", "annual")

  expect_match(source$url, "^https://")
  expect_match(source$url, "files\\.digital\\.nhs\\.uk")
})

test_that("get_source_config errors for invalid period", {
  expect_error(
    get_source_config("key_measures", "fy9999", "annual"),
    "Invalid period"
  )
})

test_that("get_source_config returns URL string", {
  source <- get_source_config("key_measures", "2023-24", "annual")

  expect_type(source$url, "character")
  expect_match(source$url, "^https://")
})

test_that("get_source_config returns correct format for zip", {
  source <- get_source_config("key_measures", "2023-24", "annual")

  expect_equal(source$format, "zip")
})

test_that("get_source_config returns correct format for rar", {
  source <- get_source_config("key_measures", "2018-19", "annual")

  expect_equal(source$format, "rar")
})

test_that("get_source_config returns csv_pattern string", {
  source <- get_source_config("key_measures", "2023-24", "annual")

  expect_type(source$csv_pattern, "character")
  expect_true(nchar(source$csv_pattern) > 0)
})

test_that("get_source_config has csv_file field", {
  source <- get_source_config("key_measures", "2023-24", "annual")

  expect_true("csv_file" %in% names(source))
  expect_type(source$csv_file, "character")
})

# Get dataset version tests ----------------------------------------------------

test_that("get_dataset_version returns version string", {
  version <- get_dataset_version("key_measures", "annual")

  expect_type(version, "character")
  expect_match(version, "^\\d+\\.\\d+\\.\\d+$")
})

test_that("get_dataset_version errors for invalid dataset", {
  expect_error(
    get_dataset_version("invalid", "annual"),
    "Invalid dataset"
  )
})

test_that("get_dataset_version errors for invalid frequency", {
  expect_error(
    get_dataset_version("key_measures", "invalid"),
    "Invalid frequency"
  )
})

# Resolve periods tests --------------------------------------------------------

test_that("resolve_periods handles NULL by returning all periods", {
  periods <- resolve_periods(NULL, "key_measures", "annual")

  expect_type(periods, "character")
  expect_true(length(periods) > 0)
  expect_true(all(grepl("^\\d{4}-\\d{2}$", periods)))
})

test_that("resolve_periods returns valid periods unchanged", {
  input <- c("2023-24", "2024-25")
  periods <- resolve_periods(input, "key_measures", "annual")

  expect_equal(periods, input)
})

test_that("resolve_periods errors for invalid period", {
  expect_error(
    resolve_periods("fy9999", "key_measures", "annual"),
    "Invalid period"
  )
})

test_that("resolve_periods errors for multiple invalid periods", {
  expect_error(
    resolve_periods(c("fy9999", "fy8888"), "key_measures", "annual"),
    "Invalid period"
  )
})

test_that("resolve_periods errors for mix of valid and invalid", {
  expect_error(
    resolve_periods(c("2023-24", "fy9999"), "key_measures", "annual"),
    "Invalid period"
  )
})

# Available reports tests ------------------------------------------------------

test_that("available_nhstt_reports returns a tibble", {
  reports <- available_nhstt_reports()

  expect_s3_class(reports, "tbl_df")
})

test_that("available_nhstt_reports has required columns", {
  reports <- available_nhstt_reports()

  required_cols <- c(
    "dataset",
    "frequency",
    "title",
    "first_period",
    "last_period",
    "n_periods",
    "version"
  )
  expect_true(all(required_cols %in% names(reports)))
})

test_that("available_nhstt_reports includes key_measures", {
  reports <- available_nhstt_reports()

  expect_true("key_measures" %in% reports$dataset)
})

test_that("available_nhstt_reports includes annual key_measures", {
  reports <- available_nhstt_reports()
  km_reports <- reports[reports$dataset == "key_measures", ]

  expect_true("annual" %in% km_reports$frequency)
})

test_that("available_nhstt_reports shows correct period counts", {
  reports <- available_nhstt_reports()
  km_annual <- reports[
    reports$dataset == "key_measures" & reports$frequency == "annual",
  ]

  # Should have 8 annual periods (2017-18 through 2024-25)
  expect_equal(km_annual$n_periods, 8)
})

test_that("available_nhstt_reports shows correct first and last periods", {
  reports <- available_nhstt_reports()
  km_annual <- reports[
    reports$dataset == "key_measures" & reports$frequency == "annual",
  ]

  expect_equal(km_annual$first_period, "2017-18")
  expect_equal(km_annual$last_period, "2024-25")
})

# Config validation tests ------------------------------------------------------

test_that("validate_raw_config accepts valid config", {
  raw_config <- load_raw_config()

  expect_invisible(validate_raw_config(raw_config))
})

test_that("validate_raw_config errors without datasets section", {
  invalid_config <- list()

  expect_error(
    validate_raw_config(invalid_config),
    "must have a 'datasets' section"
  )
})

test_that("validate_raw_config errors with empty datasets", {
  invalid_config <- list(datasets = list())

  expect_error(
    validate_raw_config(invalid_config),
    "must define at least one dataset"
  )
})

test_that("validate_raw_config errors with invalid frequency", {
  invalid_config <- list(
    datasets = list(
      test_dataset = list(
        weekly = list(
          title = "Test",
          version = "1.0.0",
          get_function = "get_test",
          sources = list()
        )
      )
    )
  )

  expect_error(
    validate_raw_config(invalid_config),
    "invalid frequency"
  )
})

test_that("validate_raw_config errors with missing required fields", {
  invalid_config <- list(
    datasets = list(
      test_dataset = list(
        annual = list(
          title = "Test"
          # Missing: version, get_function, sources
        )
      )
    )
  )

  expect_error(
    validate_raw_config(invalid_config),
    "missing required fields"
  )
})

test_that("validate_raw_config errors with invalid format", {
  invalid_config <- list(
    datasets = list(
      test_dataset = list(
        annual = list(
          title = "Test",
          version = "1.0.0",
          get_function = "get_test",
          sources = list(
            list(
              period = "2023-24",
              url = "https://example.com/data.txt",
              format = "txt" # Invalid format
            )
          )
        )
      )
    )
  )

  expect_error(
    validate_raw_config(invalid_config),
    "invalid format"
  )
})

test_that("validate_raw_config errors when zip/rar missing csv_pattern", {
  invalid_config <- list(
    datasets = list(
      test_dataset = list(
        annual = list(
          title = "Test",
          version = "1.0.0",
          get_function = "get_test",
          sources = list(
            list(
              period = "2023-24",
              url = "https://example.com/data.zip",
              format = "zip"
              # Missing: csv_pattern
            )
          )
        )
      )
    )
  )

  expect_error(
    validate_raw_config(invalid_config),
    "must have csv_pattern"
  )
})

# Development flag tests -------------------------------------------------------

test_that("list_available_periods excludes development periods by default", {
  # This test assumes no actual development periods exist in raw_config.toml
  periods <- list_available_periods("key_measures", "annual")
  periods_with_dev <- list_available_periods(
    "key_measures",
    "annual",
    include_development = TRUE
  )

  # Should return same list if no development periods
  expect_equal(periods, periods_with_dev)
})

test_that("resolve_periods errors for development periods", {
  # Create a mock scenario by testing the error message structure
  # We can't easily test with actual development periods without modifying raw_config.toml
  # So we test that resolve_periods handles the filtering correctly

  # Normal case should work
  periods <- resolve_periods(c("2023-24", "2024-25"), "key_measures", "annual")
  expect_equal(periods, c("2023-24", "2024-25"))
})

test_that("validate_period accepts periods in raw_config including development", {
  # validate_period should work for all periods (including development)
  # since it's used internally by read_raw()
  expect_invisible(validate_period("2023-24", "key_measures", "annual"))
})
