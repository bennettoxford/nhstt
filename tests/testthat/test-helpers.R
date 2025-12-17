test_that("summarise_percentiles returns correct structure", {
  test_data <- tibble::tibble(
    end_date = as.Date(c(
      rep("2024-01-31", 10),
      rep("2024-02-29", 10)
    )),
    value = c(1:10, 11:20)
  )

  result <- summarise_percentiles(
    test_data,
    period_col = end_date,
    value_col = value
  )

  # Check structure
  expect_s3_class(result, "tbl_df")
  expect_named(result, c("end_date", "percentile", "value"))

  # Check number of rows: 9 percentiles × 2 periods = 18
  expect_equal(nrow(result), 18)

  # Check percentile column contains expected values
  expect_equal(unique(result$percentile), seq(10, 90, 10))

  # Check percentile column is integer
  expect_type(result$percentile, "integer")

  # Check ordering: descending by period, ascending by percentile
  expect_true(all(result$end_date[1:9] == as.Date("2024-02-29")))
  expect_true(all(result$end_date[10:18] == as.Date("2024-01-31")))
  expect_equal(result$percentile[1:9], seq(10, 90, 10))
})

test_that("summarise_percentiles works with custom percentiles", {
  test_data <- tibble::tibble(
    end_date = as.Date(rep("2024-01-31", 100)),
    value = 1:100
  )

  result <- summarise_percentiles(
    test_data,
    period_col = end_date,
    value_col = value,
    percentiles = c(0.25, 0.5, 0.75)
  )

  expect_equal(nrow(result), 3)
  expect_equal(result$percentile, c(25, 50, 75))
})

test_that("summarise_percentiles works with grouping", {
  test_data <- tibble::tibble(
    end_date = as.Date(rep("2024-01-31", 20)),
    measure_id = rep(c("M1", "M2"), each = 10),
    value = c(1:10, 11:20)
  )

  result <- summarise_percentiles(
    test_data,
    period_col = end_date,
    value_col = value,
    percentiles = c(0.5),
    group_by = measure_id
  )

  expect_equal(nrow(result), 2)
  expect_named(result, c("end_date", "measure_id", "percentile", "value"))
  expect_true(all(c("M1", "M2") %in% result$measure_id))
})

test_that("summarise_percentiles works with multiple grouping variables", {
  test_data <- tibble::tibble(
    end_date = as.Date(rep("2024-01-31", 40)),
    measure_id = rep(c("M1", "M2"), each = 20),
    region = rep(c("North", "South"), times = 20),
    value = 1:40
  )

  result <- summarise_percentiles(
    test_data,
    period_col = end_date,
    value_col = value,
    percentiles = c(0.5),
    group_by = c(measure_id, region)
  )

  # 2 measures × 2 regions = 4 rows
  expect_equal(nrow(result), 4)
  expect_named(
    result,
    c("end_date", "measure_id", "region", "percentile", "value")
  )
})

test_that("summarise_percentiles handles NA values", {
  test_data <- tibble::tibble(
    end_date = as.Date(rep("2024-01-31", 8)),
    value = c(1:6, NA, NA)
  )

  result <- summarise_percentiles(
    test_data,
    period_col = end_date,
    value_col = value,
    percentiles = c(0.5)
  )

  # Should return one row with median calculated ignoring NAs
  expect_equal(nrow(result), 1)
  expect_false(is.na(result$value))
})

test_that("summarise_percentiles maintains correct ordering with multiple periods", {
  test_data <- tibble::tibble(
    end_date = as.Date(c(
      rep("2024-01-31", 10),
      rep("2024-02-29", 10),
      rep("2024-03-31", 10)
    )),
    value = c(1:10, 11:20, 21:30)
  )

  result <- summarise_percentiles(
    test_data,
    period_col = end_date,
    value_col = value,
    percentiles = c(0.5)
  )

  expect_equal(nrow(result), 3)

  # Check descending period order
  expect_equal(
    result$end_date,
    as.Date(c("2024-03-31", "2024-02-29", "2024-01-31"))
  )
})
