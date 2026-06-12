# Synthetic tidy monthly data: three periods, three providers, one England row.
# ORG1 is a large service with one implausible ratio (> 1) in M002.
# ORG2 has a low denominator (median 10). ORG3 has a high ratio (0.99).
make_test_tidy_data <- function() {
  end_dates <- as.Date(c("2024-01-31", "2024-02-29", "2024-03-31"))
  start_dates <- as.Date(c("2024-01-01", "2024-02-01", "2024-03-01"))

  org <- function(code, name, measure_id, measure_name, values) {
    tibble::tibble(
      measure_id = measure_id,
      measure_name = measure_name,
      group_type = "Provider",
      start_date = start_dates,
      end_date = end_dates,
      org_code2 = code,
      org_name2 = name,
      value = values
    )
  }

  dplyr::bind_rows(
    org(
      "ORG1",
      "Service One",
      "M000",
      "finished_course_treatment",
      c(100, 100, 100)
    ),
    org("ORG1", "Service One", "M001", "ended_completed", c(50, 60, 70)),
    org("ORG1", "Service One", "M002", "ended_unknown_treated", c(10, 20, 120)),
    org(
      "ORG2",
      "Service Two",
      "M000",
      "finished_course_treatment",
      c(10, 10, 12)
    ),
    org("ORG2", "Service Two", "M001", "ended_completed", c(5, 5, 6)),
    org("ORG2", "Service Two", "M002", "ended_unknown_treated", c(1, 1, 1)),
    org(
      "ORG3",
      "Service Three",
      "M000",
      "finished_course_treatment",
      c(100, 100, 100)
    ),
    org("ORG3", "Service Three", "M001", "ended_completed", c(99, 50, 50)),
    org(
      "ORG3",
      "Service Three",
      "M002",
      "ended_unknown_treated",
      c(10, 10, 10)
    ),
    tibble::tibble(
      measure_id = "M001",
      measure_name = "ended_completed",
      group_type = "England",
      start_date = start_dates[1],
      end_date = end_dates[1],
      org_code2 = "ENG",
      org_name2 = "England",
      value = 1000
    )
  )
}

make_test_measures <- function() {
  create_measures(
    make_test_tidy_data(),
    numerators = c("M001", "M002"),
    denominator = "M000"
  )
}

test_that("create_measures builds the expected table", {
  measures <- make_test_measures()

  expect_named(
    measures,
    c(
      "measure_id",
      "measure_name",
      "interval_start",
      "interval_end",
      "numerator",
      "org_code2",
      "org_name2",
      "denominator",
      "denominator_measure_id",
      "ratio"
    )
  )
  # 2 numerator measures x 3 orgs x 3 periods, England rows dropped
  expect_equal(nrow(measures), 18)
  expect_false("ENG" %in% measures$org_code2)
  expect_true(all(measures$denominator_measure_id == "M000"))

  org1_m001 <- measures |>
    dplyr::filter(org_code2 == "ORG1", measure_id == "M001") |>
    dplyr::arrange(interval_end)
  expect_equal(org1_m001$ratio, c(0.5, 0.6, 0.7))
})

test_that("create_measures errors on unknown measures and missing columns", {
  data <- make_test_tidy_data()

  expect_error(
    create_measures(data, numerators = "M999", denominator = "M000"),
    "not found"
  )
  expect_error(
    create_measures(data, numerators = "M001", denominator = c("M000", "M002")),
    "single measure"
  )
  expect_error(
    create_measures(
      data |> dplyr::select(-org_name2),
      numerators = "M001",
      denominator = "M000"
    ),
    "missing column"
  )
})

test_that("summarise_measures gives one row per service", {
  summary <- summarise_measures(make_test_measures())

  expect_equal(nrow(summary), 3)
  expect_true(all(c("ratio_m001", "ratio_m002") %in% names(summary)))

  org2 <- summary[summary$org_code2 == "ORG2", ]
  expect_equal(org2$n_periods, 3)
  expect_equal(org2$median_denominator, 10)
  expect_equal(org2$min_denominator, 10)

  # ratios above 1 are ignored in the median (ORG1 M002: 0.1, 0.2, then 1.2 -> NA)
  org1 <- summary[summary$org_code2 == "ORG1", ]
  expect_equal(org1$ratio_m002, 0.15)
})

test_that("explore_services groups low denominator and high ratio services", {
  explored <- explore_services(make_test_measures())

  expect_equal(sort(explored$org_code2), c("ORG2", "ORG3"))
  expect_equal(
    explored$group[explored$org_code2 == "ORG2"],
    "low_denominator"
  )
  expect_equal(
    explored$group[explored$org_code2 == "ORG3"],
    "high_ratio"
  )
})

test_that("explore_services groups services matching both criteria as both", {
  explored <- explore_services(make_test_measures(), median_threshold = 200)

  expect_equal(explored$group[explored$org_code2 == "ORG3"], "both")
  expect_equal(explored$group[explored$org_code2 == "ORG1"], "low_denominator")
})

test_that("ratios above 1 do not count towards the high ratio group", {
  # ORG1 has a ratio of 1.2 but should not be grouped
  explored <- explore_services(make_test_measures())
  expect_false("ORG1" %in% explored$org_code2)
})

test_that("explore_services output supports excluding services with dplyr", {
  # the documented workflow: review the explored services, then filter
  # them out and treat ratios above 1 as missing in your own code
  measures <- make_test_measures()
  explored <- explore_services(measures)

  clean <- measures |>
    dplyr::filter(!org_code2 %in% explored$org_code2) |>
    dplyr::mutate(ratio = dplyr::if_else(ratio > 1, NA_real_, ratio))

  expect_false(any(c("ORG2", "ORG3") %in% clean$org_code2))
  # ORG1 M002 March ratio 1.2 set to NA
  expect_true(all(clean$ratio <= 1, na.rm = TRUE))
  expect_equal(sum(is.na(clean$ratio)), 1)
})

test_that("summarise_measures counts renamed services once with the latest name", {
  data <- make_test_tidy_data() |>
    dplyr::mutate(
      org_name2 = dplyr::if_else(
        org_code2 == "ORG1" & end_date == as.Date("2024-03-31"),
        "Service One Renamed",
        org_name2
      )
    )
  measures <- create_measures(
    data,
    numerators = c("M001", "M002"),
    denominator = "M000"
  )

  summary <- summarise_measures(measures)

  expect_equal(nrow(summary), 3)
  expect_equal(
    summary$org_name2[summary$org_code2 == "ORG1"],
    "Service One Renamed"
  )
})
