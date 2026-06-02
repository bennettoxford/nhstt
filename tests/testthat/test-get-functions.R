make_test_parquet <- function(dataset, periods, extra_cols = list()) {
  cache_path <- get_tidy_source_cache_path(dataset)
  sidecar_path <- get_tidy_source_sidecar_path(dataset)
  version <- get_tidy_source_config(dataset)$version

  data <- tibble::tibble(
    reporting_period = periods,
    !!!extra_cols
  )
  arrow::write_parquet(data, cache_path)
  jsonlite::write_json(
    list(dataset = dataset, version = version),
    sidecar_path,
    auto_unbox = TRUE
  )
  list(cache_path = cache_path, sidecar_path = sidecar_path)
}

# Period resolution -------------------------------------------------------

test_that("get_key_measures_annual rejects invalid periods before downloading", {
  local_mocked_bindings(
    download_tidy_source = function(...) stop("download should not be called"),
    .package = "nhstt"
  )
  expect_error(
    get_key_measures_annual(periods = "9999-00"),
    regexp = "9999-00"
  )
})

test_that("get_activity_performance_monthly rejects invalid periods before downloading", {
  local_mocked_bindings(
    download_tidy_source = function(...) stop("download should not be called"),
    .package = "nhstt"
  )
  expect_error(
    get_activity_performance_monthly(periods = "9999-00"),
    regexp = "9999-00"
  )
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

# Dataset name correctness ------------------------------------------------

test_that("all datasets are registered in raw config", {
  for (dataset in c("key_measures_annual", "proms_annual", "therapy_position_annual")) {
    expect_true(length(resolve_periods(NULL, dataset, "annual")) > 0)
  }
  expect_true(
    length(resolve_periods(NULL, "activity_performance_monthly", "monthly")) > 0
  )
})
