# Period validation -------------------------------------------------------

test_that("get_key_measures_annual errors for periods missing from the data", {
  paths <- make_test_parquet(
    "key_measures_annual",
    periods = c("2023-24", "2024-25")
  )
  on.exit({
    unlink(paths$cache_path)
    unlink(paths$sidecar_path)
  })

  local_mocked_bindings(
    download_tidy_source = function(...) stop("download should not be called"),
    .package = "nhstt"
  )
  expect_error(
    get_key_measures_annual(periods = "9999-00"),
    regexp = "9999-00"
  )
})

test_that("get_activity_performance_monthly errors for periods missing from the data", {
  paths <- make_test_parquet(
    "activity_performance_monthly",
    periods = c("2025-08", "2025-09")
  )
  on.exit({
    unlink(paths$cache_path)
    unlink(paths$sidecar_path)
  })

  local_mocked_bindings(
    download_tidy_source = function(...) stop("download should not be called"),
    .package = "nhstt"
  )
  expect_error(
    get_activity_performance_monthly(periods = "9999-00"),
    regexp = "9999-00"
  )
})

test_that("period errors list the periods available in the data", {
  paths <- make_test_parquet(
    "key_measures_annual",
    periods = c("2023-24", "2024-25")
  )
  on.exit({
    unlink(paths$cache_path)
    unlink(paths$sidecar_path)
  })

  expect_error(
    get_key_measures_annual(periods = c("2024-25", "2025-26")),
    regexp = "2023-24"
  )
})

# Period filtering ---------------------------------------------------------

test_that("get_key_measures_annual filters to requested periods", {
  paths <- make_test_parquet(
    "key_measures_annual",
    periods = c("2022-23", "2023-24", "2024-25")
  )
  on.exit({
    unlink(paths$cache_path)
    unlink(paths$sidecar_path)
  })

  result <- get_key_measures_annual(periods = c("2023-24", "2024-25"))
  expect_setequal(result$reporting_period, c("2023-24", "2024-25"))
})

# Output order ------------------------------------------------------------

test_that("get_key_measures_annual returns rows most-recent-first", {
  paths <- make_test_parquet(
    "key_measures_annual",
    periods = c("2022-23", "2024-25", "2023-24")
  )
  on.exit({
    unlink(paths$cache_path)
    unlink(paths$sidecar_path)
  })

  result <- get_key_measures_annual()
  expect_equal(result$reporting_period[1], "2024-25")
})

test_that("get_activity_performance_monthly returns rows most-recent-first", {
  paths <- make_test_parquet(
    "activity_performance_monthly",
    periods = c("2024-01", "2025-03", "2024-06")
  )
  on.exit({
    unlink(paths$cache_path)
    unlink(paths$sidecar_path)
  })

  result <- get_activity_performance_monthly()
  expect_equal(result$reporting_period[1], "2025-03")
})

# Cache behaviour ---------------------------------------------------------

test_that("get_key_measures_annual skips download when cache is current", {
  paths <- make_test_parquet("key_measures_annual", periods = c("2024-25"))
  on.exit({
    unlink(paths$cache_path)
    unlink(paths$sidecar_path)
  })

  downloaded <- FALSE
  local_mocked_bindings(
    download_tidy_source = function(...) {
      downloaded <<- TRUE
    },
    .package = "nhstt"
  )

  get_key_measures_annual()
  expect_false(downloaded)
})

test_that("get_key_measures_annual downloads when use_cache = FALSE", {
  paths <- make_test_parquet("key_measures_annual", periods = c("2024-25"))
  on.exit({
    unlink(paths$cache_path)
    unlink(paths$sidecar_path)
  })

  downloaded <- FALSE
  local_mocked_bindings(
    download_tidy_source = function(...) {
      downloaded <<- TRUE
    },
    .package = "nhstt"
  )

  suppressMessages(get_key_measures_annual(use_cache = FALSE))
  expect_true(downloaded)
})

# Dataset registration ------------------------------------------------------

test_that("every exported getter has a dataset in tidy_data_sources.yml", {
  sources <- load_tidy_sources_config()
  expected <- c(
    "key_measures_annual",
    "proms_annual",
    "therapy_position_annual",
    "activity_performance_monthly",
    "metadata_measures_annual",
    "metadata_variables_annual",
    "metadata_measures_monthly",
    "metadata_providers"
  )
  expect_contains(names(sources), expected)
})
