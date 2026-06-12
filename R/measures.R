# Measures analysis pipeline: create a numerator/denominator measures table
# from a tidy dataset, then summarise and explore services. Exclusions are
# left to the user with plain dplyr so analysis decisions stay visible in
# their code. These functions are experimental and may change as we learn
# more about analysing this data.

#' Check that a data frame has the required columns
#'
#' @param data Data frame to check
#' @param required_cols Character vector of column names that must be present
#' @param arg Character, name of the user-facing argument for the error message
#' @param hint Optional named character vector appended to the error message
#' @param call Environment reported as the source of the error
#'
#' @return Invisible TRUE, aborts if any required column is missing
#'
#' @importFrom cli cli_abort
#' @importFrom rlang caller_env
#'
#' @keywords internal
check_required_columns <- function(
  data,
  required_cols,
  arg,
  hint = NULL,
  call = caller_env()
) {
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    cli_abort(
      c("{.arg {arg}} is missing column{?s}: {.val {missing_cols}}", hint),
      call = call
    )
  }
  invisible(TRUE)
}

#' Set ratios above `max_ratio` to NA
#'
#' Single place for the rule that ratios above `max_ratio` cannot be
#' interpreted and are treated as missing, used by [summarise_measures()]
#' and [explore_services()].
#'
#' @param ratio Numeric vector of ratios
#' @param max_ratio Numeric, ratios above this are set to NA. Default 1
#'
#' @return Numeric vector with ratios above `max_ratio` set to NA
#'
#' @importFrom dplyr if_else
#'
#' @keywords internal
clean_ratios <- function(ratio, max_ratio = 1) {
  if_else(ratio > max_ratio, NA_real_, ratio)
}

#' Create a measures table from a tidy monthly dataset
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Builds an analysis-ready measures table by pairing one or more numerator
#' measures with a denominator measure, following the structure used in
#' OpenSAFELY measures: one row per measure, organisation, and reporting
#' interval, with a `ratio` column giving numerator / denominator.
#'
#' @param data Tibble, a tidy dataset as returned by
#'   [get_activity_performance_monthly()]
#' @param numerators Character vector of measure IDs to use as numerators
#'   (e.g., `c("M066", "M344")`)
#' @param denominator Character, single measure ID to use as the denominator
#'   (e.g., `"M076"`)
#' @param group_type Character, organisation level to keep. Default "Provider"
#'
#' @return Tibble with columns: measure_id, measure_name, interval_start,
#'   interval_end, numerator, org_code2, org_name2, denominator,
#'   denominator_measure_id, ratio
#'
#' @importFrom dplyr filter select left_join mutate
#' @importFrom cli cli_abort
#'
#' @export
#'
#' @examples
#' \dontrun{
#' df <- get_activity_performance_monthly()
#' df_measures <- create_measures(
#'   df,
#'   numerators = c("M066", "M344", "M341", "M070", "M069"),
#'   denominator = "M076"
#' )
#' }
create_measures <- function(
  data,
  numerators,
  denominator,
  group_type = "Provider"
) {
  check_required_columns(
    data,
    required_cols = c(
      "measure_id",
      "measure_name",
      "group_type",
      "start_date",
      "end_date",
      "org_code2",
      "org_name2",
      "value"
    ),
    arg = "data"
  )

  if (length(denominator) != 1) {
    cli_abort("{.arg denominator} must be a single measure ID")
  }

  available <- unique(data$measure_id)
  unknown <- setdiff(c(numerators, denominator), available)
  if (length(unknown) > 0) {
    cli_abort("Measure{?s} not found in {.arg data}: {.val {unknown}}")
  }

  df_denominator <- data |>
    filter(measure_id == denominator, group_type == !!group_type) |>
    select(interval_end = end_date, org_code2, denominator = value)

  data |>
    filter(measure_id %in% numerators, group_type == !!group_type) |>
    select(
      measure_id,
      measure_name,
      interval_start = start_date,
      interval_end = end_date,
      numerator = value,
      org_code2,
      org_name2
    ) |>
    left_join(df_denominator, by = c("interval_end", "org_code2")) |>
    mutate(
      denominator_measure_id = !!denominator,
      ratio = numerator / denominator
    )
}

#' Validate a measures table
#'
#' @param measures Tibble, as returned by [create_measures()]
#'
#' @return Invisible TRUE, aborts if required columns are missing
#'
#' @importFrom cli cli_abort
#'
#' @keywords internal
validate_measures <- function(measures) {
  check_required_columns(
    measures,
    required_cols = c(
      "measure_id",
      "measure_name",
      "interval_end",
      "numerator",
      "denominator",
      "ratio",
      "org_code2",
      "org_name2"
    ),
    arg = "measures",
    hint = c("i" = "Create a measures table with {.fun create_measures}")
  )
}

#' Most recent service name for each org code
#'
#' Service names can change across reporting periods (e.g. after the NHS TT
#' rebrand), so summaries and plot labels use the most recent name.
#'
#' @param measures Tibble, as returned by [create_measures()]
#'
#' @return Tibble with one row per org_code2 and its most recent org_name2
#'
#' @importFrom dplyr arrange desc distinct select
#'
#' @keywords internal
latest_org_names <- function(measures) {
  measures |>
    arrange(desc(interval_end)) |>
    distinct(org_code2, .keep_all = TRUE) |>
    select(org_code2, org_name2)
}

#' Summarise a measures table by service
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Gives one row per service with the number of reporting periods, the median
#' and minimum monthly denominator count, and the median ratio for each
#' measure. Useful for getting an overview of which services contribute data
#' and how they compare.
#'
#' @param measures Tibble, as returned by [create_measures()]
#'
#' @return Tibble with one row per service: org_code2, org_name2, n_periods,
#'   median_denominator, min_denominator, and one `ratio_*` column per measure
#'   (median ratio across periods, with ratios above 1 ignored)
#'
#' @importFrom dplyr distinct group_by summarise arrange left_join n_distinct mutate if_else
#' @importFrom tidyr pivot_wider
#' @importFrom stats median
#'
#' @export
#'
#' @examples
#' \dontrun{
#' df_measures |> summarise_measures()
#' }
summarise_measures <- function(measures) {
  validate_measures(measures)

  # group by org code only: service names can change across reporting periods
  # (e.g. after the NHS TT rebrand), which would otherwise duplicate services
  df_denominator_summary <- measures |>
    distinct(interval_end, org_code2, denominator) |>
    group_by(org_code2) |>
    summarise(
      n_periods = n_distinct(interval_end),
      median_denominator = if (all(is.na(denominator))) {
        NA_real_
      } else {
        median(denominator, na.rm = TRUE)
      },
      min_denominator = if (all(is.na(denominator))) {
        NA_real_
      } else {
        min(denominator, na.rm = TRUE)
      },
      .groups = "drop"
    ) |>
    left_join(latest_org_names(measures), by = "org_code2") |>
    select(org_code2, org_name2, everything())

  df_median_ratios <- measures |>
    mutate(ratio = clean_ratios(ratio)) |>
    group_by(org_code2, measure_id = tolower(measure_id)) |>
    summarise(
      ratio = if (all(is.na(ratio))) NA_real_ else median(ratio, na.rm = TRUE),
      .groups = "drop"
    ) |>
    pivot_wider(
      names_from = measure_id,
      values_from = ratio,
      names_prefix = "ratio_"
    )

  df_denominator_summary |>
    left_join(df_median_ratios, by = "org_code2") |>
    arrange(median_denominator)
}

#' Explore services that cross chosen thresholds
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Shows which services cross the thresholds you choose: a median monthly
#' denominator count below `median_threshold`, or any single ratio at or
#' above `ratio_threshold` in at least one reporting period (ratios above 1
#' are ignored). Returns these services with their summary statistics so you
#' can look at them more closely and make an informed decision about what to
#' do with them — for example keep them, investigate them further, or
#' exclude them with a [dplyr::filter()] call in your own code (see Examples).
#'
#' @param measures Tibble, as returned by [create_measures()]
#' @param median_threshold Numeric, services with a median monthly denominator
#'   below this are grouped as "low_denominator". Default 20
#' @param ratio_threshold Numeric, services with any ratio at or above this in
#'   at least one period are grouped as "high_ratio". Default 0.99
#'
#' @return Tibble of services crossing a threshold: group ("low_denominator",
#'   "high_ratio", or "both"), followed by the columns from
#'   [summarise_measures()]
#'
#' @importFrom dplyr filter pull mutate case_when arrange select left_join if_else everything
#'
#' @export
#'
#' @examples
#' \dontrun{
#' df_explored <- df_measures |>
#'   explore_services(median_threshold = 20, ratio_threshold = 0.99)
#'
#' # after reviewing df_explored, exclude these services and treat
#' # ratios above 1 as missing
#' df_clean <- df_measures |>
#'   dplyr::filter(!org_code2 %in% df_explored$org_code2) |>
#'   dplyr::mutate(ratio = dplyr::if_else(ratio > 1, NA_real_, ratio))
#' }
explore_services <- function(
  measures,
  median_threshold = 20,
  ratio_threshold = 0.99
) {
  validate_measures(measures)

  df_summary <- summarise_measures(measures)

  low <- df_summary |>
    filter(median_denominator < median_threshold) |>
    pull(org_code2)

  high <- measures |>
    mutate(ratio = clean_ratios(ratio)) |>
    filter(!is.na(ratio), ratio >= ratio_threshold) |>
    pull(org_code2) |>
    unique()

  df_summary |>
    filter(org_code2 %in% c(low, high)) |>
    mutate(
      group = case_when(
        org_code2 %in% low & org_code2 %in% high ~ "both",
        org_code2 %in% low ~ "low_denominator",
        org_code2 %in% high ~ "high_ratio"
      )
    ) |>
    select(group, everything()) |>
    arrange(group, median_denominator)
}
