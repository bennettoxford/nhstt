# Synthetic measures table with two services and one measure
make_test_plot_measures <- function() {
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

  data <- dplyr::bind_rows(
    org(
      "ORG1",
      "Service One",
      "M000",
      "finished_course_treatment",
      c(100, 100, 100)
    ),
    org("ORG1", "Service One", "M001", "ended_completed", c(50, 60, 70)),
    org(
      "ORG2",
      "Service Two",
      "M000",
      "finished_course_treatment",
      c(80, 80, 80)
    ),
    org("ORG2", "Service Two", "M001", "ended_completed", c(20, 30, 40))
  )

  create_measures(data, numerators = "M001", denominator = "M000")
}

test_that("theme_nhstt returns a ggplot2 theme", {
  skip_if_not_installed("ggplot2")
  expect_s3_class(theme_nhstt(), "theme")
})

test_that("measure_name_to_sentence cleans raw measure names", {
  expect_equal(
    measure_name_to_sentence("ended_completed_treatment"),
    "Completed treatment"
  )
  expect_equal(
    measure_name_to_sentence("finished_course_treatment"),
    "Finished course treatment"
  )
})

test_that("measure_panel_labels builds ordered labels with optional tags", {
  measures <- make_test_plot_measures()

  labelled <- measure_panel_labels(measures)
  expect_equal(levels(labelled$measure_name_id), "Completed (M001)")

  tagged <- measure_panel_labels(measures, panel_tags = TRUE)
  expect_equal(levels(tagged$measure_name_id), "A: Completed (M001)")
})

test_that("nhstt_year_breaks returns January of each year", {
  dates <- as.Date(c("2021-03-31", "2023-06-30"))
  expect_equal(
    nhstt_year_breaks(dates),
    as.Date(c("2021-01-01", "2022-01-01", "2023-01-01"))
  )
})

test_that("nhstt_year_breaks anchors to break_start", {
  dates <- as.Date(c("2021-03-31", "2023-06-30"))
  expect_equal(
    nhstt_year_breaks(dates, break_start = "%Y-04-01"),
    as.Date(c("2021-04-01", "2022-04-01", "2023-04-01"))
  )
})

test_that("nhstt_year_breaks falls back to pretty breaks for sub-year data", {
  # April to June: no 1 January in range, so yearly breaks would all fall
  # outside the axis and leave it unlabelled
  dates <- as.Date(c("2024-04-30", "2024-06-30"))
  breaks <- nhstt_year_breaks(dates)
  expect_true(any(breaks >= min(dates) & breaks <= max(dates)))
})

test_that("measure_panel_labels orders panels by measure_order", {
  measures <- dplyr::bind_rows(
    make_test_plot_measures(),
    make_test_plot_measures() |>
      dplyr::mutate(measure_id = "M002", measure_name = "ended_dropped_out")
  )

  labelled <- measure_panel_labels(measures, measure_order = c("M002", "M001"))
  expect_equal(
    levels(labelled$measure_name_id),
    c("Dropped out (M002)", "Completed (M001)")
  )
})

test_that("measure_panel_labels errors when panel tags run out of letters", {
  measures <- purrr::map(1:27, function(i) {
    make_test_plot_measures() |>
      dplyr::mutate(measure_id = sprintf("M%03d", i))
  }) |>
    dplyr::bind_rows()

  expect_error(
    measure_panel_labels(measures, panel_tags = TRUE),
    "at most 26"
  )
})

test_that("plot_measures returns a ggplot for ratio and numerator", {
  skip_if_not_installed("ggplot2")
  measures <- make_test_plot_measures()

  expect_s3_class(plot_measures(measures), "ggplot")
  expect_s3_class(plot_measures(measures, y = "numerator"), "ggplot")
  expect_error(plot_measures(measures, y = "nope"))
})

test_that("plot_measures_deciles returns a ggplot with and without highlights", {
  skip_if_not_installed("ggplot2")
  measures <- make_test_plot_measures()

  expect_s3_class(plot_measures_deciles(measures), "ggplot")
  expect_s3_class(
    plot_measures_deciles(measures, highlight_services = "ORG1"),
    "ggplot"
  )
  expect_error(
    plot_measures_deciles(measures, highlight_services = "NOPE"),
    "not found"
  )
})

test_that("plot_measures_deciles handles duplicate codes and names", {
  skip_if_not_installed("ggplot2")
  measures <- make_test_plot_measures()

  # duplicated org codes are deduplicated rather than erroring
  expect_s3_class(
    plot_measures_deciles(measures, highlight_services = c("ORG1", "ORG1")),
    "ggplot"
  )

  # two org codes sharing a service name get disambiguated labels
  measures_same_name <- measures |> dplyr::mutate(org_name2 = "Same Name")
  p <- plot_measures_deciles(
    measures_same_name,
    highlight_services = c("ORG1", "ORG2")
  )
  labels <- ggplot2::ggplot_build(p)$plot$scales$get_scales(
    "colour"
  )$get_labels()
  expect_equal(labels, c("Same Name (ORG1)", "Same Name (ORG2)"))
})

test_that("plot_measures_deciles errors on too many highlighted services", {
  skip_if_not_installed("ggplot2")
  measures <- make_test_plot_measures()

  expect_error(
    plot_measures_deciles(
      measures,
      highlight_services = paste0("ORG", 1:9)
    ),
    "at most 8"
  )
})

test_that("plot_measures keeps ratios above 1 instead of censoring them", {
  skip_if_not_installed("ggplot2")
  measures <- make_test_plot_measures() |>
    dplyr::mutate(
      ratio = dplyr::if_else(
        org_code2 == "ORG1" & interval_end == as.Date("2024-03-31"),
        1.3,
        ratio
      )
    )

  built <- ggplot2::ggplot_build(plot_measures(measures, y = "ratio"))
  point_layer <- built$data[[2]]
  expect_false(anyNA(point_layer$y))
  expect_true(any(point_layer$y > 1))
})

test_that("plot_measures_deciles labels services by name or generic label", {
  skip_if_not_installed("ggplot2")
  measures <- make_test_plot_measures()

  p_named <- plot_measures_deciles(
    measures,
    highlight_services = c("ORG1", "ORG2")
  )
  p_anon <- plot_measures_deciles(
    measures,
    highlight_services = c("ORG1", "ORG2"),
    hide_service_names = TRUE
  )

  named_labels <- ggplot2::ggplot_build(p_named)$plot$scales$get_scales(
    "colour"
  )$get_labels()
  anon_labels <- ggplot2::ggplot_build(p_anon)$plot$scales$get_scales(
    "colour"
  )$get_labels()

  expect_equal(named_labels, c("Service One", "Service Two"))
  expect_equal(anon_labels, c("Service A", "Service B"))
})
