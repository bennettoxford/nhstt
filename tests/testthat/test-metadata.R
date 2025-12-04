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
