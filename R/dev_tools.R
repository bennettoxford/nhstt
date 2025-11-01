#' Download raw NHS TT data files as published on NHS Digital
#'
#' Downloads and extracts raw data without tidying. Table names are simplified
#' for easier exploration, but column names and data values remain exactly as
#' they appear in the source files. Useful for package developers to inspect
#' raw data structure.
#'
#' @param periods Character vector, specifying which periods to download.
#'   If NULL, downloads all available periods.
#'   Default is NULL.
#' @param source_type Character, specifying the data source type.
#'   Default is "annual_reports".
#'
#' @return Named list of raw data frames by period with simplified table names
#' @export
#'
#' @examples
#' \donttest{
#' # Download all raw annual data
#' raw <- nhstt_get_raw()
#'
#' # Download specific years
#' raw <- nhstt_get_raw(periods = c("fy2324", "fy2425"))
#'
#' # Inspect structure
#' names(raw)
#' names(raw$fy2425)
#' }
nhstt_get_raw <- function(periods = NULL,
                          source_type = "annual_reports") {
  # Get available periods
  available_periods <- get_available_periods(source_type)

  # Validate periods
  if (is.null(periods)) {
    periods <- available_periods
  } else {
    invalid <- setdiff(periods, available_periods)
    if (length(invalid) > 0) {
      cli::cli_abort(c(
        "Invalid periods for {.val {source_type}}: {.val {invalid}}",
        "i" = "Available periods: {.val {available_periods}}"
      ))
    }
  }

  cli::cli_alert_info("Downloading raw data for {.val {length(periods)}} period{?s}")

  # Download data
  source_links <- get_source_links(source_type)[periods]

  raw_data <- purrr::map(source_links, function(url) {
    download_data_by_type(url, source_type)
  }, .progress = list(
    type = "iterator",
    format = "Downloading {cli::pb_bar} {cli::pb_current}/{cli::pb_total}",
    clear = FALSE
  ))

  names(raw_data) <- periods

  cli::cli_alert_success("Downloaded {length(periods)} period{?s}")

  # Simplify table names for easier exploration
  simplify_raw_table_names(raw_data)
}

#' Check column names across years for a dataset
#'
#' Displays a detailed comparison of column names across all years for a specific
#' table, showing which columns are present in all years vs missing in some years.
#' Uses colour-coded output for easy visual inspection.
#'
#' @param raw_data Raw data from nhstt_get_raw()
#' @param table_name Name of table to check (e.g., "main", "therapy_type", "therapist_role")
#' @param clean_names Logical, whether to apply janitor::make_clean_names() before comparison.
#'   Default is TRUE to match how tidy pipeline processes names.
#'
#' @return Invisibly returns list with complete columns, partial columns, and presence matrix
#' @export
#'
#' @examples
#' \donttest{
#' raw <- nhstt_get_raw()
#'
#' # Check main dataset
#' nhstt_check_columns(raw, "key_measures")
#'
#' # Check therapy type
#' nhstt_check_columns(raw, "therapy_type")
#'
#' # Check with original (non-cleaned) names
#' nhstt_check_columns(raw, "key_measures", clean_names = FALSE)
#' }
nhstt_check_columns <- function(raw_data, table_name, clean_names = TRUE) {
  # Extract column names for specified table from each period
  period_columns <- purrr::map(raw_data, function(period_tables) {
    if (table_name %in% names(period_tables)) {
      cols <- names(period_tables[[table_name]])
      if (clean_names) {
        janitor::make_clean_names(cols)
      } else {
        cols
      }
    } else {
      character(0)
    }
  })

  # Get all unique columns (preserving original order where possible)
  all_columns_unsorted <- unique(unlist(period_columns))
  all_columns_sorted <- sort(all_columns_unsorted)

  periods <- names(period_columns)
  n_periods <- length(periods)

  # Create presence matrix
  presence <- purrr::map(all_columns_sorted, function(col) {
    purrr::map_lgl(period_columns, ~ col %in% .x)
  })
  names(presence) <- all_columns_sorted
  presence <- tibble::as_tibble(presence)

  # Find complete columns (present in all periods, preserving original order)
  complete_columns_sorted <- all_columns_sorted[purrr::map_lgl(all_columns_sorted, ~ all(presence[[.x]]))]
  complete_columns <- all_columns_unsorted[all_columns_unsorted %in% complete_columns_sorted]

  # Find partial columns (missing in some periods)
  partial_columns <- all_columns_sorted[purrr::map_lgl(all_columns_sorted, ~ !all(presence[[.x]]))]

  # Calculate display width
  max_col_length <- max(nchar(c(complete_columns, partial_columns)))
  header_width <- max_col_length + 2 + (n_periods * 3)

  # Print header
  cli::cli_rule(left = paste("Column comparison:", table_name))
  cli::cli_alert_success("{length(complete_columns)} column{?s} present in ALL {n_periods} period{?s}")
  if (length(partial_columns) > 0) {
    cli::cli_alert_warning("{length(partial_columns)} column{?s} missing in some periods")
  }
  cli::cli_rule()
  cat("\n")
  cat("Column")

  # Print complete columns
  if (length(complete_columns) > 0) {
    cli::cli_alert_success("Present in all periods:")
    purrr::walk(complete_columns, function(col) {
      status_symbols <- purrr::map_chr(periods, ~ cli::col_green(cli::symbol$tick))
      col_padded <- stringr::str_pad(col, max_col_length + 2, "right")
      year_status <- paste(status_symbols, collapse = "  ")
      cat(cli::col_green(col_padded), year_status, "\n")
    })
    cat("\n")
  }

  # Print partial columns
  if (length(partial_columns) > 0) {
    cli::cli_alert_warning("Missing in some periods:")
    purrr::walk(partial_columns, function(col) {
      present_in <- presence[[col]]
      status_symbols <- purrr::map_chr(present_in, function(p) {
        if (p) cli::col_green(cli::symbol$tick) else cli::col_red(cli::symbol$cross)
      })

      col_padded <- stringr::str_pad(col, max_col_length + 2, "right")
      year_status <- paste(status_symbols, collapse = "  ")
      cat(cli::col_yellow(col_padded), year_status, "\n")
    })
    cat("\n")
  }

  # Print summary
  cli::cli_rule()
  if (clean_names) {
    cli::cli_alert_info("Column names shown after applying {.code janitor::make_clean_names()}")
  }

  invisible(
    list(
      complete = complete_columns,
      partial = partial_columns,
      presence = presence,
      table_name = table_name,
      n_periods = n_periods
    )
  )
}
