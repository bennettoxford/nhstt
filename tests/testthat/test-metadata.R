test_that("get_metadata_measures_annual returns combined main and additional data", {
  result <- get_metadata_measures_annual(
    periods = "2024-25",
    use_cache = FALSE
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_contains(
    names(result),
    c(
      "reporting_period",
      "dataset_name",
      "field_name",
      "description",
      "technical_construction",
      "additional_notes"
    )
  )

  # Should have both key_measures and additional datasets
  expect_true("key_measures_annual" %in% result$dataset_name)
})


test_that("get_metadata_variables_annual returns combined main and additional data", {
  result <- get_metadata_variables_annual(
    periods = "2024-25",
    use_cache = FALSE
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_contains(
    names(result),
    c(
      "reporting_period",
      "dataset_name",
      "variable_type",
      "variable_a",
      "variable_b",
      "fields_for_variable_type",
      "values_for_variable_a",
      "values_for_variable_b",
      "notes"
    )
  )

  # Should have both key_measures and additional datasets
  expect_true("key_measures_annual" %in% result$dataset_name)
})


test_that("get_package_data_path returns paths for bundled metadata", {
  # Test that package data paths exist for metadata files
  # These are bundled as fallback when downloads fail in GitHub actions
  # Ideally this will be solved when we start using Zenodo

  # Annual metadata files
  measures_main_path <- get_package_data_path(
    "metadata_measures_main_annual",
    "2024-25",
    "annual"
  )
  measures_additional_path <- get_package_data_path(
    "metadata_measures_additional_annual",
    "2024-25",
    "annual"
  )
  variables_main_path <- get_package_data_path(
    "metadata_variables_main_annual",
    "2024-25",
    "annual"
  )
  variables_additional_path <- get_package_data_path(
    "metadata_variables_additional_annual",
    "2024-25",
    "annual"
  )

  # All paths should exist
  expect_true(!is.null(measures_main_path))
  expect_true(!is.null(measures_additional_path))
  expect_true(!is.null(variables_main_path))
  expect_true(!is.null(variables_additional_path))

  # Files should exist and be readable
  expect_true(file.exists(measures_main_path))
  expect_true(file.exists(measures_additional_path))
  expect_true(file.exists(variables_main_path))
  expect_true(file.exists(variables_additional_path))

  # Should be able to read the data
  measures_main <- arrow::read_parquet(measures_main_path)
  expect_s3_class(measures_main, "tbl_df")
  expect_true(nrow(measures_main) > 0)

  variables_main <- arrow::read_parquet(variables_main_path)
  expect_s3_class(variables_main, "tbl_df")
  expect_true(nrow(variables_main) > 0)
})


test_that("metadata functions fall back to package data when download fails", {
  # This test verifies the fallback mechanism works by mocking download_and_tidy
  # to fail, then checking that package data is used instead

  # Mock download_and_tidy to always fail
  local_mocked_bindings(
    download_and_tidy = function(...) {
      stop("Simulated download failure for testing")
    }
  )

  # Clear cache to force download attempt
  temp_cache <- tempfile("test_metadata_fallback")
  dir.create(temp_cache, recursive = TRUE)
  withr::local_envvar(NHSTT_TEST_CACHE_DIR = temp_cache)

  # Despite download failure, should succeed with package data
  # Multiple warnings are expected (one for each main/additional dataset)
  result_measures <- suppressWarnings(
    get_metadata_measures_annual(periods = "2024-25", use_cache = FALSE)
  )

  result_variables <- suppressWarnings(
    get_metadata_variables_annual(periods = "2024-25", use_cache = FALSE)
  )

  # Should return valid data from package
  expect_s3_class(result_measures, "tbl_df")
  expect_true(nrow(result_measures) > 0)
  expect_contains(names(result_measures), c("reporting_period", "field_name"))

  expect_s3_class(result_variables, "tbl_df")
  expect_true(nrow(result_variables) > 0)
  expect_contains(
    names(result_variables),
    c("reporting_period", "variable_type")
  )
})
