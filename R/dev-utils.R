#' Validate that an archive exists in the configuration
#'
#' @param archive_name Character, archive name to validate
#' @param raw_config List, raw configuration
#'
#' @return Archive sources list (invisibly)
#'
#' @importFrom cli cli_abort
#'
#' @keywords internal
validate_archive_exists <- function(archive_name, raw_config) {
  if (!archive_name %in% names(raw_config$archives)) {
    available <- names(raw_config$archives)
    cli_abort(c(
      "Archive {.val {archive_name}} not found",
      "i" = "Available archives: {.val {available}}"
    ))
  }
  invisible(raw_config$archives[[archive_name]])
}

#' Validate that a period exists for an archive
#'
#' @param period Character, period to validate
#' @param archive_sources List, archive sources configuration
#' @param archive_name Character, archive name for error messages
#'
#' @return Archive configuration for the period
#'
#' @importFrom cli cli_abort
#' @importFrom purrr map_chr
#'
#' @keywords internal
validate_period_exists <- function(period, archive_sources, archive_name) {
  archive <- Find(function(x) x$period == period, archive_sources)

  if (is.null(archive)) {
    available_periods <- map_chr(archive_sources, "period")
    cli_abort(c(
      "Period {.val {period}} not found in archive {.val {archive_name}}",
      "i" = "Available periods: {.val {available_periods}}"
    ))
  }

  archive
}

#' Get available periods for an archive
#'
#' @param archive_sources List, archive sources configuration
#'
#' @return Character vector of periods sorted descending
#'
#' @importFrom purrr map_chr
#'
#' @keywords internal
get_available_periods <- function(archive_sources) {
  periods <- map_chr(archive_sources, "period")
  sort(periods, decreasing = TRUE)
}

#' List available archives and their periods
#'
#' Returns all archives defined in the raw configuration files along with
#' their available periods.
#'
#' @return Named list where names are archive names (e.g., "annual_main",
#'   "annual_metadata") and values are character vectors of available periods
#'   (e.g., c("2024-25", "2023-24")) sorted in descending order
#'
#' @importFrom cli cli_abort
#' @importFrom purrr map
#'
#' @keywords internal
list_archives_periods <- function() {
  raw_config <- load_raw_config()

  if (!"archives" %in% names(raw_config)) {
    cli_abort(c(
      "No archives found in configuration",
      "i" = "Check raw data config files in {.path inst/config/}"
    ))
  }

  # Build named list of archives and their periods
  map(raw_config$archives, get_available_periods)
}

#' List files in archives
#'
#' Downloads archives and lists all CSV files for specified periods.
#'
#' @param archive_name Character, archive name (e.g., "annual_main").
#'   Use \code{list_archives_periods()} to see available archives
#' @param periods Character vector, periods to list files for (e.g., c("2024-25", "2023-24")).
#'   If NULL (default), returns files for all available periods
#'
#' @return Named list where names are periods and values are character vectors
#'   of CSV filenames, sorted alphabetically
#'
#' @importFrom cli cli_abort
#' @importFrom purrr set_names map
#' @importFrom utils unzip
#' @importFrom archive archive_extract
#'
#' @keywords internal
list_archive_files <- function(archive_name, periods = NULL) {
  raw_config <- load_raw_config()

  # Validate archive exists
  archive_sources <- validate_archive_exists(archive_name, raw_config)

  # Get all available periods if not specified
  if (is.null(periods)) {
    periods <- get_available_periods(archive_sources)
  }

  # Build named list of periods and their files
  set_names(periods) |>
    map(
      ~ {
        archive <- validate_period_exists(.x, archive_sources, archive_name)

        # Download and extract archive
        temp_ext <- paste0(".", archive$format)
        temp_file <- tempfile(fileext = temp_ext)
        temp_dir <- tempfile()

        tryCatch(
          {
            download_with_retry(archive$url, temp_file)
            dir.create(temp_dir)

            tryCatch(
              {
                if (archive$format == "zip") {
                  unzip(temp_file, exdir = temp_dir)
                } else if (archive$format == "rar") {
                  archive_extract(temp_file, dir = temp_dir)
                } else {
                  cli_abort(c(
                    "Unsupported archive format: {.val {archive$format}}",
                    "i" = "Supported formats: zip, rar"
                  ))
                }

                csv_files <- list.files(
                  temp_dir,
                  pattern = "\\.csv$",
                  full.names = FALSE,
                  recursive = TRUE,
                  ignore.case = TRUE
                )
                # Normalise to basenames so downstream matching works even when archives contain nested directories
                sort(unique(basename(csv_files)))
              },
              finally = {
                unlink(temp_dir, recursive = TRUE)
              }
            )
          },
          finally = {
            if (file.exists(temp_file)) {
              unlink(temp_file)
            }
          }
        )
      }
    )
}

#' Read a file from an archive
#'
#' Downloads an archive and reads a specific CSV file from it.
#'
#' @param archive_name Character, archive name (e.g., "annual_main")
#' @param period Character, archive period (e.g., "2024-25")
#' @param file_pattern Character, CSV filename or pattern to match (e.g., "main", "therapy-type")
#'
#' @return Tibble with raw data from the CSV file
#'
#' @importFrom cli cli_abort
#'
#' @keywords internal
read_archive_file <- function(archive_name, period, file_pattern) {
  raw_config <- load_raw_config()

  # Validate archive exists
  archive_sources <- validate_archive_exists(archive_name, raw_config)

  # Validate period exists
  archive <- validate_period_exists(period, archive_sources, archive_name)

  # Download and extract CSV
  temp_ext <- paste0(".", archive$format)
  temp_file <- tempfile(fileext = temp_ext)

  tryCatch(
    {
      download_with_retry(archive$url, temp_file)
      extract_csv_from_archive(temp_file, file_pattern)
    },
    finally = {
      if (file.exists(temp_file)) {
        unlink(temp_file)
      }
    }
  )
}

#' Extract schemas from archive files
#'
#' Extracts column names from all CSV files in an archive across specified periods.
#' Returns a data frame useful for tracking schema changes over time and spotting
#' column name variations across periods.
#'
#' @param archive_name Character, archive name (e.g., "annual_main")
#' @param periods Character vector, periods to extract schemas for (e.g., c("2024-25", "2023-24")).
#'   If NULL (default), extracts schemas for all available periods
#'
#' @return Data frame with columns:
#'   \describe{
#'     \item{period}{Character, reporting period (e.g., "2024-25")}
#'     \item{archive_name}{Character, archive name}
#'     \item{csv_file}{Character, CSV filename}
#'     \item{column}{Character, column name from the raw data}
#'   }
#'   Sorted by period (descending), csv_file, and column name.
#'
#' @importFrom cli cli_abort cli_process_start cli_process_done cli_alert_warning
#' @importFrom purrr imap map flatten compact
#' @importFrom dplyr bind_rows arrange desc
#'
#' @keywords internal
extract_archive_schemas <- function(archive_name, periods = NULL) {
  raw_config <- load_raw_config()

  # Validate archive exists
  validate_archive_exists(archive_name, raw_config)

  # Get files for all periods
  cli_process_start("Extracting schemas from {.val {archive_name}}")

  files_by_period <- list_archive_files(archive_name, periods)

  # Build schema data frame
  schema_rows <- imap(files_by_period, function(csv_files, period) {
    map(csv_files, function(csv_file) {
      tryCatch(
        {
          raw_data <- read_archive_file(archive_name, period, csv_file)
          column_names <- names(raw_data)

          # Create data frame for this file
          data.frame(
            period = period,
            archive_name = archive_name,
            csv_file = csv_file,
            column = column_names,
            stringsAsFactors = FALSE
          )
        },
        error = function(e) {
          # Skip files that can't be read
          cli_alert_warning(
            "Could not read {.file {csv_file}} from {period}: {e$message}"
          )
          NULL
        }
      )
    })
  }) |>
    flatten() |>
    compact()

  cli_process_done()

  # Combine all rows and sort
  if (length(schema_rows) == 0) {
    return(data.frame(
      period = character(),
      archive_name = character(),
      csv_file = character(),
      column = character(),
      stringsAsFactors = FALSE
    ))
  }

  bind_rows(schema_rows) |>
    arrange(desc(period), csv_file, column)
}

#' Compare schemas across periods
#'
#' Reads the schema file and creates a comparison table showing which columns
#' exist in which periods.
#'
#' @param file_pattern Character, pattern to match CSV files (e.g., "effect-size", "main")
#' @param schema_file Character, path to schema CSV file. If NULL (default),
#'   uses the schema file from the installed package. Requires package to be
#'   installed with \code{pak::local_install()}
#'
#' @return Invisibly returns a data frame.
#'
#' @importFrom cli cli_abort cli_rule col_green col_red col_yellow style_bold symbol
#' @importFrom purrr map_chr
#' @importFrom utils read.csv
#'
#' @keywords internal
compare_schemas <- function(
  file_pattern,
  schema_file = NULL
) {
  # Get schema file path from installed package
  if (is.null(schema_file)) {
    schema_file <- system.file(
      "schemas",
      "annual_main_schemas.csv",
      package = "nhstt"
    )

    if (schema_file == "") {
      cli_abort(c(
        "Schema file not found in package installation",
        "i" = "Install the package with {.code pak::local_install()}",
        "i" = "Then run {.code just update-schemas} to generate schemas"
      ))
    }
  }

  # Check custom schema file exists if provided
  if (!is.null(schema_file) && !file.exists(schema_file)) {
    cli_abort(c(
      "Schema file not found: {.path {schema_file}}"
    ))
  }

  # Read schema file
  schemas <- read.csv(schema_file, stringsAsFactors = FALSE)

  # Filter by file pattern
  matching_schemas <- schemas[
    grepl(file_pattern, schemas$csv_file, ignore.case = TRUE),
  ]

  if (nrow(matching_schemas) == 0) {
    available_files <- unique(schemas$csv_file)
    cli_abort(c(
      "No files matching pattern {.val {file_pattern}} found",
      "i" = "Available files: {.val {available_files}}"
    ))
  }

  # Get unique columns and periods
  all_columns <- unique(matching_schemas$column)
  all_periods <- sort(unique(matching_schemas$period), decreasing = TRUE)

  # Prioritize key columns (exact names from raw data)
  priority_columns <- c(
    "OrgType",
    "OrgCode",
    "OrgName",
    "VariableType",
    "VariableA",
    "VariableB"
  )

  # Separate priority columns that exist from other columns
  priority_cols_present <- intersect(priority_columns, all_columns)
  other_cols <- setdiff(all_columns, priority_columns)

  # Combine: priority first, then others alphabetically
  ordered_columns <- c(priority_cols_present, sort(other_cols))

  # Create comparison data frame
  comparison <- data.frame(
    column = ordered_columns,
    stringsAsFactors = FALSE
  )

  # Add a logical column for each period
  for (period in all_periods) {
    period_columns <- matching_schemas$column[
      matching_schemas$period == period
    ]
    comparison[[period]] <- ordered_columns %in% period_columns
  }

  # Identify complete vs partial columns
  n_periods <- length(all_periods)
  complete_columns <- comparison$column[rowSums(comparison[, -1]) == n_periods]
  partial_columns <- comparison$column[rowSums(comparison[, -1]) != n_periods]

  # Get archive name from data
  archive_name <- unique(matching_schemas$archive_name)[1]

  # Print formatted output
  # Print header
  cli_rule(
    left = paste("Schema comparison for", file_pattern, "in", archive_name)
  )
  cat(
    col_green(paste0(
      symbol$tick,
      " ",
      length(complete_columns),
      " columns present in all periods"
    )),
    "\n"
  )
  cat(
    col_red(paste0(
      symbol$cross,
      " ",
      length(partial_columns),
      " columns missing in some periods"
    )),
    "\n"
  )
  cli_rule()
  cat("\n")

  # Calculate max column name length for padding
  max_col_length <- max(nchar(comparison$column))

  # Print complete columns section
  if (length(complete_columns) > 0) {
    cat(
      col_green(style_bold("Columns present in all periods:")),
      "\n"
    )
    cat(strrep("\u2500", max_col_length + 2 + (n_periods * 3)), "\n")

    for (col_name in complete_columns) {
      col_padded <- sprintf(paste0("%-", max_col_length + 2, "s"), col_name)
      ticks <- paste(
        rep(col_green(symbol$tick), n_periods),
        collapse = " "
      )
      cat(col_green(col_padded), ticks, "\n")
    }
    cat("\n")
  }

  # Print partial columns section
  if (length(partial_columns) > 0) {
    cat(
      col_yellow(style_bold("Columns missing in some periods:")),
      "\n"
    )
    cat(strrep("\u2500", max_col_length + 2 + (n_periods * 3)), "\n")

    for (col_name in partial_columns) {
      col_padded <- sprintf(paste0("%-", max_col_length + 2, "s"), col_name)
      present_in <- comparison[comparison$column == col_name, -1]

      # Create tick/cross for each period
      status_symbols <- map_chr(present_in, function(p) {
        if (p) {
          col_green(symbol$tick)
        } else {
          col_red(symbol$cross)
        }
      })
      status_str <- paste(status_symbols, collapse = " ")

      cat(col_yellow(col_padded), status_str, "\n")
    }
    cat("\n")
  }

  invisible(comparison)
}
