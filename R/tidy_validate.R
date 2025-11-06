#' Parse period bounds for supported frequencies
#'
#' Currently supports "annual" frequency. "quarterly" and "monthly" will be
#' added in future versions.
#'
#' @param periods Character vector of period identifiers
#' @param frequency Data frequency: "annual", "quarterly", or "monthly"
#' @return List with start_date and end_date vectors
#' @keywords internal
parse_period_bounds <- function(periods, frequency = "annual") {
  switch(frequency,
    "annual" = parse_annual_period_bounds(periods),
    cli::cli_abort(c(
      "Unsupported frequency: {.val {frequency}}",
      "i" = "Currently only {.val annual} is supported",
      "i" = "To add support, implement {.code parse_{frequency}_period_bounds()}"
    ))
  )
}

#' Parse annual (financial year) period bounds
#'
#' @param periods Character vector like "fy2324"
#' @return List with start_date and end_date
#' @keywords internal
parse_annual_period_bounds <- function(periods) {
  if (anyNA(periods)) {
    cli::cli_abort("Cannot parse NA periods for annual frequency")
  }

  if (!all(stringr::str_detect(periods, "^fy\\d{4}$"))) {
    cli::cli_abort(c(
      "Invalid period format for annual frequency",
      "x" = "Expected pattern {.code fyXXXX}, got {.val {unique(periods)}}"
    ))
  }

  start_year <- as.integer(stringr::str_sub(periods, 3, 4)) + 2000
  end_year <- as.integer(stringr::str_sub(periods, 5, 6)) + 2000

  list(
    start_date = as.Date(sprintf("%d-04-01", start_year)),
    end_date = as.Date(sprintf("%d-03-31", end_year))
  )
}

#' Validate dataset
#'
#' @param df Data frame to validate
#' @param dataset_name Name of dataset for error messages
#' @return Invisible TRUE if valid
#' @keywords internal
validate_dataset <- function(df, dataset_name = "dataset") {
  required_cols <- c("start_date", "end_date", "period", "statistic", "measure", "value")

  missing <- setdiff(required_cols, names(df))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "Validation failed for {.field {dataset_name}} dataset",
      "x" = "Missing required columns: {.val {missing}}"
    ))
  }

  if (nrow(df) == 0) {
    cli::cli_warn(c(
      "!" = "{.field {dataset_name}} dataset has zero rows"
    ))
  }

  if (all(is.na(df$value))) {
    cli::cli_warn(c(
      "!" = "All values in {.field {dataset_name}} dataset are NA"
    ))
  }

  invisible(TRUE)
}
