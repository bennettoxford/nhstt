# Readers for the annual reports before 2017-18. Up to 2014-15 these are XLSX
# workbooks. 2015-16 and 2016-17 are ZIP packs of CSVs. The layout changes
# every year. We read the England totals only. The `annual_legacy` archive in
# raw_annual_data_config.yml says where each measure is in each file.

#' Read the England row of a legacy annual table
#'
#' CSV tables mark England with `"England"` in the first column. XLSX sheets
#' mark it with `"England total"` in the first column.
#'
#' @param path Character, specifying path to the ZIP pack or XLSX workbook
#' @param table Character, specifying the CSV file pattern (ZIP) or sheet name (XLSX)
#'
#' @return List of the England row's values. CSV values are named by column
#'   header. XLSX values have no names, so pick them by column number.
#'
#' @importFrom readxl read_excel
#' @importFrom tools file_ext
#' @importFrom cli cli_abort
#'
#' @keywords internal
read_annual_legacy_england_row <- function(path, table) {
  if (tolower(file_ext(path)) == "zip") {
    raw <- extract_csv_from_archive(path, table)
    england <- raw[raw[[1]] %in% "England", ]
  } else {
    raw <- read_excel(
      path,
      sheet = table,
      col_names = FALSE,
      .name_repair = "minimal"
    )
    england <- raw[raw[[1]] %in% "England total", ]
  }

  if (nrow(england) != 1) {
    cli_abort(
      "Expected 1 England row in {.val {table}} ({basename(path)}), found {nrow(england)}"
    )
  }

  as.list(england)
}

#' Extract England totals from one legacy annual source file
#'
#' @param path Character, specifying path to the ZIP pack or XLSX workbook
#' @param tables Named list, specifying for each table a named list of
#'   `measure = column`, where column is a CSV header or an XLSX column number
#'
#' @return One-row tibble in the wide format used by the `measures_annual`
#'   tidy config, with one column per configured measure
#'
#' @importFrom tibble tibble
#' @importFrom cli cli_abort
#'
#' @keywords internal
extract_annual_legacy_totals <- function(path, tables) {
  values <- list()

  for (table in names(tables)) {
    row <- read_annual_legacy_england_row(path, table)

    for (measure in names(tables[[table]])) {
      column <- tables[[table]][[measure]]
      found <- if (is.numeric(column)) {
        column <= length(row)
      } else {
        column %in% names(row)
      }
      if (!found) {
        cli_abort(
          "Column {.val {column}} for {.val {measure}} not found in {.val {table}} ({basename(path)})"
        )
      }
      values[[measure]] <- as.numeric(row[[column]])
    }
  }

  # Modern raw files use the string "NULL" for an empty breakdown
  tibble(
    org_type = "England",
    org_code = "All",
    org_name = "All",
    variable_type = "Total",
    variable_a = "NULL",
    variable_b = "NULL",
    !!!values
  )
}

#' Check legacy annual England totals for misread columns
#'
#' Recalculates each published percentage from its count. Stops if the two
#' differ by more than 0.1, which catches a column read from the wrong
#' position. Also stops if a value is missing, a count is negative, a
#' percentage is outside 0 to 100, or reliable recovery is larger than
#' recovery.
#'
#' Improvement, no reliable change and deterioration are divided by finished
#' treatment. Recovery and reliable recovery are divided by finished treatment
#' minus those not at caseness. 2013-14 does not publish the number not at
#' caseness, so there we divide by the number at caseness.
#'
#' @param df One-row tibble, as returned by [extract_annual_legacy_totals()]
#' @param period Character, specifying reporting period for error messages
#'
#' @return Invisibly returns `df`
#'
#' @importFrom cli cli_abort
#'
#' @keywords internal
check_annual_legacy_totals <- function(df, period) {
  counts <- unlist(df[grepl("^count_", names(df))])
  percentages <- unlist(df[grepl("^percentage_", names(df))])

  problems <- c(
    if (any(is.na(counts) | counts < 0)) "a count is missing or negative",
    if (any(is.na(percentages) | percentages < 0 | percentages > 100)) {
      "a percentage is missing or outside 0 to 100"
    },
    if (isTRUE(df[["count_reliable_recovery"]] > df[["count_recovery"]])) {
      "reliable recovery is larger than recovery"
    }
  )

  recovery_denominator <- if ("count_not_at_caseness" %in% names(df)) {
    df[["count_finished_course_treatment"]] - df[["count_not_at_caseness"]]
  } else {
    df[["count_at_caseness"]]
  }
  denominators <- c(
    improvement = df[["count_finished_course_treatment"]],
    no_reliable_change = df[["count_finished_course_treatment"]],
    deterioration = df[["count_finished_course_treatment"]],
    recovery = recovery_denominator,
    reliable_recovery = recovery_denominator
  )

  for (measure in names(denominators)) {
    published <- df[[paste0("percentage_", measure)]]
    if (is.null(published)) {
      next
    }
    expected <- 100 * df[[paste0("count_", measure)]] / denominators[[measure]]
    # A missing value is already reported above
    if (isTRUE(abs(published - expected) > 0.1)) {
      problems <- c(
        problems,
        sprintf(
          "percentage_%s is %s but its count gives %.1f",
          measure,
          published,
          expected
        )
      )
    }
  }

  if (length(problems) > 0) {
    cli_abort(c(
      "Legacy annual England totals for {.val {period}} look wrong",
      set_names(problems, rep("x", length(problems)))
    ))
  }

  invisible(df)
}

#' Build tidy England totals for the legacy annual periods
#'
#' Developer tool, called by [build_tidy_data()] for datasets with a
#' `legacy_archive` in the raw config. Downloads each file in that archive,
#' then reads and checks its England totals. Runs the dataset's tidy config,
#' so the rows have the same format as 2017-18 onwards.
#'
#' @param dataset Character, specifying dataset name (e.g., `"measures_annual"`)
#'
#' @return Tibble in the dataset's tidy schema
#'
#' @importFrom purrr map map_chr set_names
#' @importFrom dplyr filter
#'
#' @keywords internal
tidy_annual_legacy_totals <- function(dataset) {
  raw_config <- load_raw_config()
  legacy_archive <- raw_config$datasets[[dataset]]$legacy_archive
  sources <- raw_config$archives[[legacy_archive]]

  data_list <- map(sources, \(source) {
    path <- tempfile(fileext = paste0(".", source$format))
    on.exit(unlink(path))
    download_with_retry(source$url, path)
    extract_annual_legacy_totals(path, source$tables) |>
      check_annual_legacy_totals(source$period)
  }) |>
    set_names(map_chr(sources, "period"))

  # Measures not published in a period come out of the pivot as NA
  tidy_dataset(data_list, dataset, "annual") |>
    filter(!is.na(value))
}
