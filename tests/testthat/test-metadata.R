test_that("get_metadata_measures_annual loads the pre-built parquet", {
  paths <- make_test_parquet(
    "metadata_measures_annual",
    periods = c("2023-24", "2024-25"),
    extra_cols = list(
      dataset_name = c("key_measures_annual", "key_measures_annual"),
      field_name = c("a", "b")
    )
  )
  on.exit({
    unlink(paths$cache_path)
    unlink(paths$sidecar_path)
  })

  result <- get_metadata_measures_annual()

  expect_s3_class(result, "tbl_df")
  expect_setequal(result$reporting_period, c("2023-24", "2024-25"))
  expect_contains(names(result), c("dataset_name", "field_name"))
})

test_that("get_metadata_variables_annual filters to requested periods", {
  paths <- make_test_parquet(
    "metadata_variables_annual",
    periods = c("2023-24", "2024-25"),
    extra_cols = list(variable_type = c("x", "y"))
  )
  on.exit({
    unlink(paths$cache_path)
    unlink(paths$sidecar_path)
  })

  result <- get_metadata_variables_annual(periods = "2024-25")

  expect_equal(result$reporting_period, "2024-25")
  expect_equal(result$variable_type, "y")
})

test_that("get_metadata_monthly loads the pre-built parquet without downloading", {
  paths <- make_test_parquet(
    "metadata_measures_monthly",
    periods = c("2025-07", "2025-08")
  )
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

  result <- get_metadata_monthly()

  expect_false(downloaded)
  expect_equal(result$reporting_period[1], "2025-08")
})
