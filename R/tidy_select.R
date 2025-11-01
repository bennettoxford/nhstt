#' Select tables by pattern
#'
#' @param raw_data Named list of data frames by period
#' @param pattern Regex pattern to match table names
#' @return Filtered list
#' @keywords internal
select_tables_by_pattern <- function(raw_data, pattern) {
  purrr::map(raw_data, function(tables) {
    keep_idx <- stringr::str_detect(names(tables), pattern)
    tables[keep_idx]
  })
}

#' Flatten nested list by one level
#'
#' After pattern matching, validates that exactly one table matched per period
#' and extracts it. Raises an error if zero or multiple tables matched.
#'
#' @param data Nested list of matched tables by period
#' @param dataset_name Dataset identifier for error messaging
#' @return List flattened by one level (one data frame per period)
#' @keywords internal
flatten_one_level <- function(data, dataset_name = "dataset") {
  purrr::imap(data, function(period_tables, period) {
    table_count <- length(period_tables)

    if (table_count == 0) {
      cli::cli_abort(c(
        "No tables matched pattern for {.field {dataset_name}}",
        "x" = "Period {.field {period}} contains zero matching tables"
      ))
    }

    if (table_count > 1) {
      cli::cli_abort(c(
        "Multiple tables matched pattern for {.field {dataset_name}}",
        "x" = "Period {.field {period}} matched {table_count} tables"
      ))
    }

    period_tables[[1]]
  })
}
