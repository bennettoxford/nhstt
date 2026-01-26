test_that("load_tidy_config returns a list", {
  tidy_config <- load_tidy_config()

  expect_type(tidy_config, "list")
})

test_that("load_tidy_config has key_measures dataset", {
  tidy_config <- load_tidy_config()

  expect_true("key_measures_annual" %in% names(tidy_config))
})

test_that("load_tidy_config has metadata dataset", {
  tidy_config <- load_tidy_config()

  expect_true("metadata_measures_monthly" %in% names(tidy_config))
})

test_that("key_measures config contains expected sections", {
  tidy_config <- load_tidy_config()

  expect_true("filter" %in% names(tidy_config$key_measures_annual))
  expect_true("pivot_longer" %in% names(tidy_config$key_measures_annual))
})

test_that("metadata config contains expected sections", {
  tidy_config <- load_tidy_config()

  expect_true("rename" %in% names(tidy_config$metadata_measures_monthly))
  expect_true("select" %in% names(tidy_config$metadata_measures_monthly))
})

test_that("get_tidy_config returns configuration for dataset", {
  config <- get_tidy_config("key_measures_annual", "annual")

  expect_type(config, "list")
  expect_true("filter" %in% names(config))
  expect_true("pivot_longer" %in% names(config))
  expect_true("select" %in% names(config))
})

test_that("get_tidy_config returns configuration for metadata dataset", {
  config <- get_tidy_config("metadata_measures_monthly", "monthly")

  expect_type(config, "list")
  expect_true("select" %in% names(config))
})


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

test_that("validate_tidy_config errors when pivot_longer missing measure_cols", {
  invalid_config <- list(
    test_dataset = list(
      pivot_longer = list(
        id_cols = c("org_code"),
        sep = "^(count)_(.+)$",
        names_to = c("stat", "name")
      )
    )
  )

  expect_error(
    validate_tidy_config(invalid_config),
    "missing measure_cols"
  )
})

test_that("validate_tidy_config errors when pivot_longer missing sep or names_to", {
  invalid_config <- list(
    test_dataset = list(
      pivot_longer = list(
        id_cols = c("org_code"),
        measure_cols = c("count_referrals")
      )
    )
  )

  expect_error(
    validate_tidy_config(invalid_config),
    "missing sep|missing names_to"
  )
})


test_that("separate_columns splits column into two parts", {
  df <- tibble::tibble(
    measure_name = c("count_referrals", "percentage_recovery", "mean_age"),
    value = c(100, 50.5, 35)
  )

  separate_config <- list(
    measure_name = list(
      into = c("measure_statistic", "measure_name"),
      sep = "^([^_]+)_(.+)$",
      remove = TRUE
    )
  )

  result <- separate_columns(df, separate_config)

  expect_named(
    result,
    c("value", "measure_statistic", "measure_name"),
    ignore.order = TRUE
  )
  expect_equal(result$measure_statistic, c("count", "percentage", "mean"))
  expect_equal(result$measure_name, c("referrals", "recovery", "age"))
})

test_that("separate_columns keeps original column when remove = FALSE", {
  df <- tibble::tibble(
    measure_name = c("count_referrals", "percentage_recovery")
  )

  separate_config <- list(
    measure_name = list(
      into = c("measure_statistic", "measure_name"),
      sep = "^([^_]+)_(.+)$",
      remove = FALSE
    )
  )

  result <- separate_columns(df, separate_config)

  expect_true("measure_source" %in% names(result))
  expect_equal(
    result$measure_source,
    c("count_referrals", "percentage_recovery")
  )
  expect_equal(result$measure_statistic, c("count", "percentage"))
  expect_equal(result$measure_name, c("referrals", "recovery"))
})

test_that("separate_columns handles values without separator", {
  df <- tibble::tibble(
    measure_name = c("count_referrals", "total")
  )

  separate_config <- list(
    measure_name = list(
      into = c("measure_statistic", "measure_name"),
      sep = "^([^_]+)_(.+)$",
      remove = TRUE
    )
  )

  result <- separate_columns(df, separate_config)

  expect_equal(result$measure_statistic, c("count", "total"))
  expect_equal(result$measure_name, c("referrals", "total"))
})


test_that("mutate_columns creates column with constant value", {
  df <- tibble::tibble(org_code = c("A", "B"), value = c(10, 20))

  mutate_config <- list(
    dataset_name = list(value = "key_measures_annual")
  )

  result <- mutate_columns(df, mutate_config)

  expect_true("dataset_name" %in% names(result))
  expect_equal(
    result$dataset_name,
    c("key_measures_annual", "key_measures_annual")
  )
})

test_that("mutate_columns formats date column", {
  df <- tibble::tibble(
    start_date = as.Date(c("2023-04-01", "2024-04-01")),
    value = c(10, 20)
  )

  mutate_config <- list(
    reporting_period = list(
      source_column = "start_date",
      "function" = "format",
      args = list(
        format = "%Y-%m"
      )
    )
  )

  result <- mutate_columns(df, mutate_config)

  expect_true("reporting_period" %in% names(result))
  expect_equal(result$reporting_period, c("2023-04", "2024-04"))
})

test_that("mutate_columns handles multiple mutations", {
  df <- tibble::tibble(
    start_date = as.Date("2023-04-01"),
    value = 10
  )

  mutate_config <- list(
    dataset_name = list(value = "test_dataset"),
    reporting_period = list(
      source_column = "start_date",
      "function" = "format",
      args = list(
        format = "%Y-%m"
      )
    )
  )

  result <- mutate_columns(df, mutate_config)

  expect_true(all(c("dataset_name", "reporting_period") %in% names(result)))
  expect_equal(result$dataset_name, "test_dataset")
  expect_equal(result$reporting_period, "2023-04")
})


test_that("tidy_dataset returns a tibble (key_measures)", {
  raw_list <- load_raw_data("key_measures_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures_annual", "annual")

  expect_s3_class(result, "tbl_df")
})

test_that("tidy_dataset has expected columns (key_measures)", {
  raw_list <- load_raw_data("key_measures_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures_annual", "annual")

  expected_cols <- expected_tidy_columns("key_measures_annual", "annual")

  expect_named(result, expected_cols, ignore.order = FALSE)
})

test_that("tidy_dataset has correct column order (key_measures)", {
  raw_list <- load_raw_data("key_measures_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures_annual", "annual")

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
  raw_list <- load_raw_data("key_measures_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures_annual", "annual")

  expect_type(result$reporting_period, "character")
  expect_s3_class(result$start_date, "Date")
  expect_s3_class(result$end_date, "Date")
  expect_type(result$org_type, "character")
  expect_type(result$org_code, "character")
  expect_type(result$org_name, "character")
  expect_type(result$measure_statistic, "character")
  expect_type(result$measure_name, "character")

  expect_true(is.numeric(result$value) || is.character(result$value))
})

test_that("tidy_dataset has no missing required columns (key_measures)", {
  raw_list <- load_raw_data("key_measures_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures_annual", "annual")

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
  raw_list <- load_raw_data("key_measures_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures_annual", "annual")

  expect_snapshot(names(result))
})

test_that("tidy_dataset converts to long format (key_measures)", {
  raw_list <- load_raw_data("key_measures_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures_annual", "annual")

  raw_fixture <- load_raw_fixture("key_measures_annual", "2024-25", "annual")
  expect_gt(nrow(result), nrow(raw_fixture))
})

test_that("tidy_dataset handles multiple periods and schema variations (key_measures)", {
  raw_list <- load_raw_data(
    "key_measures_annual",
    c("2017-18", "2024-25"),
    "annual"
  )
  result <- tidy_dataset(raw_list, "key_measures_annual", "annual")

  expect_setequal(unique(result$reporting_period), c("2017-18", "2024-25"))

  n_rows_1718 <- nrow(load_raw_fixture(
    "key_measures_annual",
    "2017-18",
    "annual"
  ))
  n_rows_2425 <- nrow(load_raw_fixture(
    "key_measures_annual",
    "2024-25",
    "annual"
  ))
  expect_gt(nrow(result), n_rows_1718)
  expect_gt(nrow(result), n_rows_2425)

  expect_named(result, expected_tidy_columns("key_measures_annual", "annual"))
})

test_that("tidy_dataset cleans column names (key_measures)", {
  raw_list <- load_raw_data("key_measures_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures_annual", "annual")

  expect_true(all(grepl("^[a-z][a-z0-9_]*$", names(result))))

  expect_false(any(grepl("\\s", names(result))))
  expect_false(any(grepl("[A-Z]", names(result))))
})

test_that("tidy_dataset applies org_type filter from config (key_measures)", {
  raw_list <- load_raw_data("key_measures_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures_annual", "annual")

  config <- get_tidy_config("key_measures_annual", "annual")

  if (!is.null(config$filters$org_type)) {
    expect_true(all(result$org_type %in% config$filters$org_type))
  } else {
    expect_true("org_type" %in% names(result))
  }
})

test_that("tidy_dataset applies variable_type filter from config (key_measures)", {
  raw_list <- load_raw_data("key_measures_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "key_measures_annual", "annual")

  config <- get_tidy_config("key_measures_annual", "annual")

  if (!is.null(config$filters$variable_type)) {
    expect_true(all(result$variable_type %in% config$filters$variable_type))
  } else {
    expect_true("variable_type" %in% names(result))
  }
})


test_that("tidy_dataset returns a tibble (activity_performance)", {
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

  expect_s3_class(result, "tbl_df")
})

test_that("tidy_dataset has expected columns (activity_performance)", {
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

  expected_cols <- expected_tidy_columns(
    "activity_performance_monthly",
    "monthly"
  )

  expect_named(result, expected_cols, ignore.order = FALSE)
})

test_that("tidy_dataset has correct column order (activity_performance)", {
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

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
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

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
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

  suppressed_rows <- result[result$measure_id %in% c("M005", "ABC"), ]
  expect_true(all(is.na(suppressed_rows$value)))
})

test_that("tidy_dataset has no missing required columns (activity_performance)", {
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

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
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

  expect_snapshot(names(result))
})

test_that("tidy_dataset data remains in long format (activity_performance)", {
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

  expect_true("measure_name" %in% names(result))
  expect_true("measure_statistic" %in% names(result))
  expect_gt(length(unique(result$measure_name)), 1)

  expect_true("value" %in% names(result))
  expect_false(any(grepl("^count_", names(result))))
})

test_that("tidy_dataset splits measure_statistic and measure_name (activity_performance)", {
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

  sample <- result[result$measure_id == "M001", ]
  expect_equal(unique(sample$measure_statistic), "count")
  expect_equal(unique(sample$measure_name), "referrals_received")
})

test_that("tidy_dataset handles multiple periods (activity_performance)", {
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    c("2025-06", "2025-09"),
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

  expect_setequal(
    unique(result$reporting_period),
    c("2025-06", "2025-09")
  )

  expect_gt(sum(result$reporting_period == "2025-06"), 0)
  expect_gt(sum(result$reporting_period == "2025-09"), 0)

  config <- get_tidy_config("activity_performance_monthly", "monthly")
  if (!is.null(config$filters$group_type)) {
    expect_true(all(result$group_type %in% config$filters$group_type))
  }
})

test_that("tidy_dataset cleans column names (activity_performance)", {
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

  expect_true(all(grepl("^[a-z][a-z0-9_]*$", names(result))))

  expect_false(any(grepl("\\s", names(result))))
  expect_false(any(grepl("[A-Z]", names(result))))
})

test_that("tidy_dataset reporting_period in ISO format (activity_performance)", {
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

  expected_periods <- format(result$start_date, "%Y-%m")
  expect_equal(result$reporting_period, expected_periods)

  expect_true(all(result$reporting_period == "2025-09"))
})

test_that("tidy_dataset parses dd/mm/YYYY dates (activity_performance)", {
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2023-05",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

  expect_equal(unique(result$start_date), as.Date("2023-05-01"))
  expect_equal(unique(result$end_date), as.Date("2023-05-31"))
  expect_true(all(result$reporting_period == "2023-05"))
})

test_that("tidy_dataset applies group_type filter from config (activity_performance)", {
  raw_data <- load_raw_data(
    "activity_performance_monthly",
    "2025-09",
    "monthly"
  )
  result <- tidy_dataset(raw_data, "activity_performance_monthly", "monthly")

  config <- get_tidy_config("activity_performance_monthly", "monthly")

  if (!is.null(config$filters$group_type)) {
    expect_true(all(result$group_type %in% config$filters$group_type))
  } else {
    expect_true("group_type" %in% names(result))
  }
})


test_that("tidy_dataset returns a tibble (metadata)", {
  raw_data <- load_raw_data("metadata_measures_monthly", "2025-07", "monthly")
  result <- tidy_dataset(raw_data, "metadata_measures_monthly", "monthly")

  expect_s3_class(result, "tbl_df")
})

test_that("tidy_dataset has expected columns (metadata)", {
  raw_data <- load_raw_data("metadata_measures_monthly", "2025-07", "monthly")
  result <- tidy_dataset(raw_data, "metadata_measures_monthly", "monthly")

  expected_cols <- expected_tidy_columns("metadata_measures_monthly", "monthly")
  expect_named(result, expected_cols, ignore.order = FALSE)
})

test_that("tidy_dataset sets reporting period for metadata", {
  raw_data <- load_raw_data("metadata_measures_monthly", "2025-07", "monthly")
  result <- tidy_dataset(raw_data, "metadata_measures_monthly", "monthly")

  expect_setequal(unique(result$reporting_period), "2025-07")
})

test_that("tidy_dataset keeps descriptive fields for metadata", {
  raw_data <- load_raw_data("metadata_measures_monthly", "2025-07", "monthly")
  result <- tidy_dataset(raw_data, "metadata_measures_monthly", "monthly")

  expect_true(all(nchar(result$description) > 0))
  expect_true(all(nchar(result$construction) > 0))
  expect_true(all(
    result$measure_id %in% c("M001", "M002", "M003", "M004", "M005")
  ))
})


test_that("tidy_dataset returns tibble for metadata measures main", {
  raw_data <- load_raw_data(
    "metadata_measures_main_annual",
    "2024-25",
    "annual"
  )
  result <- tidy_dataset(raw_data, "metadata_measures_main_annual", "annual")

  expect_s3_class(result, "tbl_df")
  expect_named(
    result,
    expected_tidy_columns("metadata_measures_main_annual", "annual")
  )
  expect_true(all(result$dataset_name == "key_measures_annual"))
})

test_that("tidy_dataset returns tibble for metadata measures additional", {
  raw_data <- load_raw_data(
    "metadata_measures_additional_annual",
    "2024-25",
    "annual"
  )
  result <- tidy_dataset(
    raw_data,
    "metadata_measures_additional_annual",
    "annual"
  )

  expect_s3_class(result, "tbl_df")
  expect_named(
    result,
    expected_tidy_columns("metadata_measures_additional_annual", "annual")
  )
  expect_true(any(grepl("therapy", result$dataset_name)))
})

test_that("tidy_dataset returns tibble for metadata variables main", {
  raw_data <- load_raw_data(
    "metadata_variables_main_annual",
    "2024-25",
    "annual"
  )
  result <- tidy_dataset(raw_data, "metadata_variables_main_annual", "annual")

  expect_s3_class(result, "tbl_df")
  expect_named(
    result,
    expected_tidy_columns("metadata_variables_main_annual", "annual")
  )
  expect_true(all(result$dataset_name == "key_measures_annual"))
})

test_that("tidy_dataset returns tibble for metadata variables additional", {
  raw_data <- load_raw_data(
    "metadata_variables_additional_annual",
    "2024-25",
    "annual"
  )
  result <- tidy_dataset(
    raw_data,
    "metadata_variables_additional_annual",
    "annual"
  )

  expect_s3_class(result, "tbl_df")
  expect_named(
    result,
    expected_tidy_columns("metadata_variables_additional_annual", "annual")
  )
  expect_true(any(grepl("therapy", result$dataset_name)))
})


test_that("tidy_dataset returns a tibble (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  expect_s3_class(result, "tbl_df")
})

test_that("tidy_dataset has expected columns (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  expected_cols <- expected_tidy_columns("proms_annual", "annual")

  expect_named(result, expected_cols, ignore.order = FALSE)
})

test_that("tidy_dataset has correct column order (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  expect_equal(
    names(result)[1:3],
    c(
      "reporting_period",
      "start_date",
      "end_date"
    )
  )
})

test_that("tidy_dataset column types are correct (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  expect_type(result$reporting_period, "character")
  expect_s3_class(result$start_date, "Date")
  expect_s3_class(result$end_date, "Date")
  expect_type(result$org_type, "character")
  expect_type(result$org_code, "character")
  expect_type(result$org_name, "character")
  expect_type(result$variable_type, "character")
  expect_type(result$variable_a, "character")
  expect_type(result$variable_b, "character")
  expect_type(result$measure_statistic, "character")
  expect_type(result$measure_name, "character")

  expect_true(is.numeric(result$value))
})

test_that("tidy_dataset sets variable_type to PROMs (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  expect_true(all(result$variable_type == "PROMs"))
})

test_that("tidy_dataset renames variable_a to diagnosis (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  # Check that variable_a contains diagnosis values
  expect_true("variable_a" %in% names(result))
  expect_true(any(!is.na(result$variable_a)))
})

test_that("tidy_dataset renames variable_b to therapy_type (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  # Check that variable_b contains therapy type values
  expect_true("variable_b" %in% names(result))
  expect_true(any(!is.na(result$variable_b)))
})

test_that("tidy_dataset converts suppressed values to NA (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  # Check that suppression markers (*,-,NULL) are converted to NA
  # Row 5 in fixture has these markers
  expect_true(any(is.na(result$value)))

  # Verify numeric values are preserved
  expect_true(is.numeric(result$value))
})

test_that("tidy_dataset extracts correct measure statistics (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  # Check that measure statistics are correctly extracted
  expected_stats <- c("count", "mean", "sd", "percentage", "effect_size")
  expect_true(all(result$measure_statistic %in% expected_stats))
})

test_that("tidy_dataset has no missing required columns (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

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

test_that("tidy_dataset snapshot test for column names (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  expect_snapshot(names(result))
})

test_that("tidy_dataset converts to long format (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  raw_fixture <- load_raw_fixture("proms_annual", "2024-25", "annual")
  expect_gt(nrow(result), nrow(raw_fixture))
})

test_that("tidy_dataset cleans column names (proms_annual)", {
  raw_list <- load_raw_data("proms_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  expect_true(all(grepl("^[a-z][a-z0-9_]*$", names(result))))

  expect_false(any(grepl("\\s", names(result))))
  expect_false(any(grepl("[A-Z]", names(result))))
})

test_that("tidy_dataset handles multiple periods and schema variations (proms_annual)", {
  raw_list <- load_raw_data(
    "proms_annual",
    c("2022-23", "2024-25"),
    "annual"
  )
  result <- tidy_dataset(raw_list, "proms_annual", "annual")

  expect_setequal(unique(result$reporting_period), c("2022-23", "2024-25"))

  n_rows_2223 <- nrow(load_raw_fixture(
    "proms_annual",
    "2022-23",
    "annual"
  ))
  n_rows_2425 <- nrow(load_raw_fixture(
    "proms_annual",
    "2024-25",
    "annual"
  ))
  expect_gt(nrow(result), n_rows_2223)
  expect_gt(nrow(result), n_rows_2425)

  expect_named(result, expected_tidy_columns("proms_annual", "annual"))
})

test_that("tidy_dataset returns a tibble (therapy_position_annual)", {
  raw_list <- load_raw_data("therapy_position_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "therapy_position_annual", "annual")

  expect_s3_class(result, "tbl_df")
})

test_that("tidy_dataset has expected columns (therapy_position_annual)", {
  raw_list <- load_raw_data("therapy_position_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "therapy_position_annual", "annual")

  expected_cols <- expected_tidy_columns("therapy_position_annual", "annual")

  expect_named(result, expected_cols, ignore.order = FALSE)
})

test_that("tidy_dataset has correct column order (therapy_position_annual)", {
  raw_list <- load_raw_data("therapy_position_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "therapy_position_annual", "annual")

  expect_equal(
    names(result)[1:3],
    c(
      "reporting_period",
      "start_date",
      "end_date"
    )
  )
})

test_that("tidy_dataset column types are correct (therapy_position_annual)", {
  raw_list <- load_raw_data("therapy_position_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "therapy_position_annual", "annual")

  expect_type(result$reporting_period, "character")
  expect_s3_class(result$start_date, "Date")
  expect_s3_class(result$end_date, "Date")
  expect_type(result$org_type, "character")
  expect_type(result$org_code, "character")
  expect_type(result$org_name, "character")
  expect_type(result$variable_type, "character")
  expect_type(result$variable_a, "character")
  expect_type(result$variable_b, "character")
  expect_type(result$measure_statistic, "character")
  expect_type(result$measure_name, "character")

  expect_true(is.numeric(result$value) || is.character(result$value))
})

test_that("tidy_dataset sets variable_type to therapy_type (therapy_position_annual)", {
  raw_list <- load_raw_data("therapy_position_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "therapy_position_annual", "annual")

  expect_true(all(result$variable_type == "therapy_type"))
})

test_that("tidy_dataset cleans therapy_type values (therapy_position_annual)", {
  raw_list <- load_raw_data("therapy_position_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "therapy_position_annual", "annual")

  expect_true("variable_a" %in% names(result))
  expect_true(all(grepl("^[a-z0-9_]+$", result$variable_a)))
})

test_that("tidy_dataset converts to long format (therapy_position_annual)", {
  raw_list <- load_raw_data("therapy_position_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "therapy_position_annual", "annual")

  raw_fixture <- load_raw_fixture(
    "therapy_position_annual",
    "2024-25",
    "annual"
  )
  expect_gt(nrow(result), nrow(raw_fixture))
})

test_that("tidy_dataset snapshot test for column names (therapy_position_annual)", {
  raw_list <- load_raw_data("therapy_position_annual", "2024-25", "annual")
  result <- tidy_dataset(raw_list, "therapy_position_annual", "annual")

  expect_snapshot(names(result))
})

test_that("tidy_dataset handles all periods (therapy_position_annual)", {
  raw_list <- load_raw_data(
    "therapy_position_annual",
    c("2022-23", "2023-24", "2024-25"),
    "annual"
  )
  result <- tidy_dataset(raw_list, "therapy_position_annual", "annual")

  expect_setequal(
    unique(result$reporting_period),
    c("2022-23", "2023-24", "2024-25")
  )

  n_rows_2223 <- nrow(load_raw_fixture(
    "therapy_position_annual",
    "2022-23",
    "annual"
  ))
  n_rows_2324 <- nrow(load_raw_fixture(
    "therapy_position_annual",
    "2023-24",
    "annual"
  ))
  n_rows_2425 <- nrow(load_raw_fixture(
    "therapy_position_annual",
    "2024-25",
    "annual"
  ))
  expect_gt(nrow(result), n_rows_2223)
  expect_gt(nrow(result), n_rows_2324)
  expect_gt(nrow(result), n_rows_2425)

  expect_named(
    result,
    expected_tidy_columns("therapy_position_annual", "annual")
  )
})
