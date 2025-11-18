test_cache_dir <- tempfile("nhstt_test_cache_")
dir.create(test_cache_dir, recursive = TRUE)
Sys.setenv(NHSTT_TEST_CACHE_DIR = test_cache_dir)

#' Load raw fixture for testing
#'
#' @param dataset Character, dataset name
#' @param period Character, period (e.g., "2023-24")
#' @param frequency Character, "annual" or "monthly"
#'
#' @return Tibble with fixture data
#' @keywords internal
load_raw_fixture <- function(dataset, period, frequency) {
  fixture_path <- test_path(
    "fixtures",
    "schemas",
    frequency,
    dataset,
    "raw",
    paste0(period, ".csv")
  )

  if (!file.exists(fixture_path)) {
    cli::cli_abort(
      "Fixture not found: {.file {fixture_path}}"
    )
  }

  vroom::vroom(fixture_path, show_col_types = FALSE, delim = ",")
}

#' Load tidy schema for testing
#'
#' @param dataset Character, dataset name
#' @param frequency Character, "annual" or "monthly"
#'
#' @return Tibble with expected tidy schema
#' @keywords internal
load_tidy_schema <- function(dataset, frequency) {
  schema_path <- test_path(
    "fixtures",
    "schemas",
    frequency,
    dataset,
    "tidy",
    "schema.csv"
  )

  if (!file.exists(schema_path)) {
    cli::cli_abort(
      "Schema not found: {.file {schema_path}}"
    )
  }

  vroom::vroom(schema_path, show_col_types = FALSE, delim = ",")
}

#' Get expected tidy column names
#'
#' @param dataset Character, dataset name
#' @param frequency Character, "annual" or "monthly"
#'
#' @return Character vector of expected column names
#' @keywords internal
expected_tidy_columns <- function(dataset, frequency) {
  schema <- load_tidy_schema(dataset, frequency)
  names(schema)
}

#' Load and prepare raw fixtures for tidying
#'
#' Loads raw fixture(s) and creates the named list format expected by tidy functions
#'
#' @param dataset Character, dataset name
#' @param periods Character vector of periods (e.g., c("2023-24", "2024-25"))
#' @param frequency Character, "annual" or "monthly"
#'
#' @return Named list of raw data tibbles
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' # Single period
#' raw_data <- load_raw_data("key_measures", "2023-24", "annual")
#'
#' # Multiple periods
#' raw_data <- load_raw_data("key_measures", c("2023-24", "2024-25"), "annual")
#' }
load_raw_data <- function(dataset, periods, frequency) {
  raw_data <- purrr::map(
    periods,
    ~ load_raw_fixture(dataset, .x, frequency)
  )
  names(raw_data) <- periods
  raw_data
}
