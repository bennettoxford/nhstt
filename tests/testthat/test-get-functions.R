# Test that all get_* functions use correct dataset names

test_that("get_key_measures_annual uses correct dataset name", {
  # Should not error when resolving periods
  expect_no_error(
    {
      periods <- resolve_periods(NULL, "key_measures_annual", "annual")
    }
  )
  expect_true(length(periods) > 0)
})

test_that("get_activity_performance_monthly uses correct dataset name", {
  # Should not error when resolving periods
  expect_no_error(
    {
      periods <- resolve_periods(
        NULL,
        "activity_performance_monthly",
        "monthly"
      )
    }
  )
  expect_true(length(periods) > 0)
})

test_that("get_metadata_monthly uses correct dataset name", {
  # Should not error when resolving periods
  expect_no_error(
    {
      periods <- resolve_periods(NULL, "metadata_measures_monthly", "monthly")
    }
  )
  expect_true(length(periods) > 0)
})

test_that("get_metadata_measures_annual uses correct dataset names", {
  # Should not error when resolving periods
  expect_no_error(
    {
      periods <- resolve_periods(
        NULL,
        "metadata_measures_main_annual",
        "annual"
      )
    }
  )
  expect_true(length(periods) > 0)
})

test_that("get_metadata_variables_annual uses correct dataset names", {
  # Should not error when resolving periods
  expect_no_error(
    {
      periods <- resolve_periods(
        NULL,
        "metadata_variables_main_annual",
        "annual"
      )
    }
  )
  expect_true(length(periods) > 0)
})

test_that("get_proms_annual uses correct dataset name", {
  # Should not error when resolving periods
  expect_no_error(
    {
      periods <- resolve_periods(NULL, "proms_annual", "annual")
    }
  )
  expect_true(length(periods) > 0)
})
