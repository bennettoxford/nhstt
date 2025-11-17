# Tidy config loading tests ---------------------------------------------------

test_that("load_tidy_config returns a list", {
  tidy_config <- load_tidy_config()

  expect_type(tidy_config, "list")
})

test_that("load_tidy_config has key_measures dataset", {
  tidy_config <- load_tidy_config()

  expect_true("key_measures" %in% names(tidy_config))
})

test_that("key_measures has annual frequency in tidy config", {
  tidy_config <- load_tidy_config()

  expect_true("annual" %in% names(tidy_config$key_measures))
})

test_that("get_tidy_config returns configuration for dataset", {
  config <- get_tidy_config("key_measures", "annual")

  expect_type(config, "list")
  expect_true("filter" %in% names(config))
  expect_true("pivot_longer" %in% names(config))
  expect_true("select" %in% names(config))
})

# Config validation tests ------------------------------------------------------

test_that("validate_tidy_config accepts valid config", {
  tidy_config <- load_tidy_config()

  expect_invisible(validate_tidy_config(tidy_config))
})

test_that("validate_tidy_config errors with empty config", {
  invalid_config <- list()

  expect_error(
    validate_tidy_config(invalid_config),
    "must define at least one dataset"
  )
})

test_that("validate_tidy_config errors with invalid frequency", {
  invalid_config <- list(
    test_dataset = list(
      quarterly = list(
        id_cols = c("org_code")
      )
    )
  )

  expect_error(
    validate_tidy_config(invalid_config),
    "invalid frequency"
  )
})

test_that("validate_tidy_config errors when pivot_longer missing required fields", {
  invalid_config <- list(
    test_dataset = list(
      annual = list(
        pivot_longer = list(
          id_cols = c("org_code"),
          measure_cols = c("count_referrals")
          # Missing: sep and into
        )
      )
    )
  )

  expect_error(
    validate_tidy_config(invalid_config),
    "missing sep|missing into"
  )
})

# Key measures dataset tests ---------------------------------------------------
# Note: Tests use 2024-25 (newest format) and 2017-18 (oldest format) to ensure
# backwards compatibility across the full historical range

test_that("tidy_dataset returns a tibble (key_measures)", {
  raw_list <- load_raw_data("key_measures", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures", "annual")

  expect_s3_class(result, "tbl_df")
})

test_that("tidy_dataset has expected columns (key_measures)", {
  raw_list <- load_raw_data("key_measures", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures", "annual")

  # Get expected columns from schema
  expected_cols <- expected_tidy_columns("key_measures", "annual")

  expect_named(result, expected_cols, ignore.order = FALSE)
})

test_that("tidy_dataset has correct column order (key_measures)", {
  raw_list <- load_raw_data("key_measures", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures", "annual")

  # First 3 columns should always be date/period columns
  expect_equal(
    names(result)[1:3],
    c(
      "reporting_period",
      "start_date",
      "end_date"
    )
  )
})

test_that("tidy_dataset column types are correct (key_measures)", {
  raw_list <- load_raw_data("key_measures", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures", "annual")

  # Check key column types
  expect_type(result$reporting_period, "character")
  expect_s3_class(result$start_date, "Date")
  expect_s3_class(result$end_date, "Date")
  expect_type(result$org_type, "character")
  expect_type(result$org_code, "character")
  expect_type(result$org_name, "character")
  expect_type(result$measure_statistic, "character")
  expect_type(result$measure_name, "character")
  # Value could be numeric or character depending on measure
  expect_true(is.numeric(result$value) || is.character(result$value))
})

test_that("tidy_dataset has no missing required columns (key_measures)", {
  raw_list <- load_raw_data("key_measures", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures", "annual")

  # These columns should never be all NA
  required_cols <- c(
    "reporting_period",
    "start_date",
    "end_date",
    "measure_name",
    "measure_statistic",
    "value"
  )

  for (col in required_cols) {
    expect_true(
      !all(is.na(result[[col]])),
      info = paste0(col, " should not be all NA")
    )
  }
})

test_that("tidy_dataset snapshot test for column names (key_measures)", {
  raw_list <- load_raw_data("key_measures", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures", "annual")

  # Snapshot test - will alert if column names change unexpectedly
  expect_snapshot(names(result))
})

test_that("tidy_dataset converts to long format (key_measures)", {
  raw_list <- load_raw_data("key_measures", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures", "annual")

  # Long format means more rows than original (each measure becomes a row)
  # With our 5-row fixture and multiple measures, should have many more rows
  raw_fixture <- load_raw_fixture("key_measures", "2024-25", "annual")
  expect_gt(nrow(result), nrow(raw_fixture))
})

test_that("tidy_dataset handles multiple periods and schema variations (key_measures)", {
  # Test oldest (no underscores) and newest (with underscores) to ensure
  # backwards compatibility across full historical range
  raw_list <- load_raw_data("key_measures", c("2017-18", "2024-25"), "annual")
  result <- tidy_dataset(raw_list, "key_measures", "annual")

  # Should have data from both periods
  expect_setequal(unique(result$reporting_period), c("2017-18", "2024-25"))

  # Should have combined rows from both periods
  n_rows_1718 <- nrow(load_raw_fixture("key_measures", "2017-18", "annual"))
  n_rows_2425 <- nrow(load_raw_fixture("key_measures", "2024-25", "annual"))
  expect_gt(nrow(result), n_rows_1718)
  expect_gt(nrow(result), n_rows_2425)

  # Both periods should have same tidy schema despite different raw formats
  expect_named(result, expected_tidy_columns("key_measures", "annual"))
})

test_that("tidy_dataset cleans column names (key_measures)", {
  raw_list <- load_raw_data("key_measures", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures", "annual")

  # All column names should be lowercase snake_case
  expect_true(all(grepl("^[a-z][a-z0-9_]*$", names(result))))

  # No spaces or special characters
  expect_false(any(grepl("\\s", names(result))))
  expect_false(any(grepl("[A-Z]", names(result))))
})

test_that("tidy_dataset applies org_type filter from config (key_measures)", {
  raw_list <- load_raw_data("key_measures", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures", "annual")

  # Get expected filter values from config
  config <- get_tidy_config("key_measures", "annual")

  # If org_type filter is defined in config, verify it's applied
  if (!is.null(config$filters$org_type)) {
    expect_true(all(result$org_type %in% config$filters$org_type))
  } else {
    # If no filter defined, just check column exists
    expect_true("org_type" %in% names(result))
  }
})

test_that("tidy_dataset applies variable_type filter from config (key_measures)", {
  raw_list <- load_raw_data("key_measures", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures", "annual")

  # Get expected filter values from config
  config <- get_tidy_config("key_measures", "annual")

  # If variable_type filter is defined in config, verify it's applied
  if (!is.null(config$filters$variable_type)) {
    expect_true(all(result$variable_type %in% config$filters$variable_type))
  } else {
    # If no filter defined, just check column exists
    expect_true("variable_type" %in% names(result))
  }
})

# Activity performance dataset tests -------------------------------------------
# Note: Tests use 2025-09 (newest) and 2025-06 (oldest) monthly periods

test_that("tidy_dataset returns a tibble (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  expect_s3_class(result, "tbl_df")
})

test_that("tidy_dataset has expected columns (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  # Get expected columns from schema
  expected_cols <- expected_tidy_columns("activity_performance", "monthly")

  expect_named(result, expected_cols, ignore.order = FALSE)
})

test_that("tidy_dataset has correct column order (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  # First 3 columns should always be date/period columns
  expect_equal(
    names(result)[1:3],
    c(
      "reporting_period",
      "start_date",
      "end_date"
    )
  )
})

test_that("tidy_dataset column types are correct (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  # Check key column types
  expect_type(result$reporting_period, "character")
  expect_s3_class(result$start_date, "Date")
  expect_s3_class(result$end_date, "Date")
  expect_type(result$group_type, "character")
  expect_type(result$org_code1, "character")
  expect_type(result$org_name1, "character")
  expect_type(result$org_code2, "character")
  expect_type(result$org_name2, "character")
  expect_type(result$measure_id, "character")
  expect_type(result$measure_name, "character")
  expect_type(result$measure_statistic, "character")
})

test_that("tidy_dataset converts suppressed values to NA (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  suppressed_rows <- result[result$measure_id %in% c("M005", "ABC"), ]
  expect_true(all(is.na(suppressed_rows$value)))
})

test_that("tidy_dataset has no missing required columns (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  # These columns should never be all NA
  required_cols <- c(
    "reporting_period",
    "start_date",
    "end_date",
    "measure_name",
    "measure_statistic",
    "value"
  )

  for (col in required_cols) {
    expect_true(
      !all(is.na(result[[col]])),
      info = paste0(col, " should not be all NA")
    )
  }
})

test_that("tidy_dataset snapshot test for column names (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  # Snapshot test - will alert if column names change unexpectedly
  expect_snapshot(names(result))
})

test_that("tidy_dataset data remains in long format (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  # In long format, each measure is in its own row (not pivoted to wide)
  # Check we have measure columns with multiple unique values
  expect_true("measure_name" %in% names(result))
  expect_true("measure_statistic" %in% names(result))
  expect_gt(length(unique(result$measure_name)), 1)

  # Should have single value column (not multiple measure-specific columns)
  expect_true("value" %in% names(result))
  expect_false(any(grepl("^count_", names(result))))
})

test_that("tidy_dataset splits measure_statistic and measure_name (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  sample <- result[result$measure_id == "M001", ]
  expect_equal(unique(sample$measure_statistic), "count")
  expect_equal(unique(sample$measure_name), "referrals_received")
})

test_that("tidy_dataset handles multiple periods (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", c("2025-06", "2025-09"), "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  # Should have data from both periods (ISO format: "2025-06", "2025-09")
  expect_setequal(
    unique(result$reporting_period),
    c("2025-06", "2025-09")
  )

  # Both periods should have data (at least 1 row each)
  expect_gt(sum(result$reporting_period == "2025-06"), 0)
  expect_gt(sum(result$reporting_period == "2025-09"), 0)

  # All data should still respect filters from config
  config <- get_tidy_config("activity_performance", "monthly")
  if (!is.null(config$filters$group_type)) {
    expect_true(all(result$group_type %in% config$filters$group_type))
  }
})

test_that("tidy_dataset cleans column names (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  # All column names should be lowercase snake_case
  expect_true(all(grepl("^[a-z][a-z0-9_]*$", names(result))))

  # No spaces or special characters
  expect_false(any(grepl("\\s", names(result))))
  expect_false(any(grepl("[A-Z]", names(result))))
})

test_that("tidy_dataset reporting_period in ISO format (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  # reporting_period should be ISO format (YYYY-MM) derived from start_date
  expected_periods <- format(result$start_date, "%Y-%m")
  expect_equal(result$reporting_period, expected_periods)

  # For Sep 2025 fixture, should be "2025-09"
  expect_true(all(result$reporting_period == "2025-09"))
})

test_that("tidy_dataset parses dd/mm/YYYY dates (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2023-05", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  expect_equal(unique(result$start_date), as.Date("2023-05-01"))
  expect_equal(unique(result$end_date), as.Date("2023-05-31"))
  expect_true(all(result$reporting_period == "2023-05"))
})

test_that("tidy_dataset applies group_type filter from config (activity_performance)", {
  raw_data <- load_raw_data("activity_performance", "2025-09", "monthly")
  result <- tidy_dataset(raw_data, "activity_performance", "monthly")

  # Get expected filter values from config
  config <- get_tidy_config("activity_performance", "monthly")

  # If group_type filter is defined in config, verify it's applied
  if (!is.null(config$filters$group_type)) {
    expect_true(all(result$group_type %in% config$filters$group_type))
  } else {
    # If no filter defined, just check column exists
    expect_true("group_type" %in% names(result))
  }
})
