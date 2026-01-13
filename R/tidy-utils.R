#' Clean strings to snake_case
#'
#' @param x Character, specifying string to clean (e.g., "CamelCase" or "Column Name")
#' @param strip_numbers Logical, specifying whether to remove numbers from the string (default FALSE)
#'
#' @return Clean string
#'
#' @keywords internal
clean_str <- function(x, strip_numbers = FALSE) {
  # Define pattern based on whether to strip numbers
  pattern <- if (strip_numbers) "[^a-zA-Z]+" else "[^a-zA-Z0-9]+"

  x |>
    gsub(pattern, "_", x = _) |>
    gsub("([a-z])([A-Z])", "\\1_\\2", x = _) |>
    gsub("([A-Z]+)([A-Z][a-z])", "\\1_\\2", x = _) |>
    gsub("_{2,}", "_", x = _) |>
    gsub("^_|_$", "", x = _) |>
    tolower()
}

#' Replace NHS suppression markers with NA
#'
#' Converts NHS suppression markers ("*", "-", "NULL", etc.) to NA and coerces to numeric
#'
#' @param x Character or numeric vector, specifying values to convert
#'
#' @return Numeric vector with suppression markers as NA
#'
#' @importFrom dplyr case_when
#'
#' @keywords internal
replace_suppression_with_na <- function(x) {
  if (is.numeric(x)) {
    return(x)
  }

  x <- case_when(
    x %in% c("*", "-", "", "N/A", "NA", "NULL", "Null", "null") ~ NA_character_,
    .default = as.character(x)
  )

  suppressWarnings(as.numeric(x))
}

#' Convert measure columns to numeric
#'
#' Converts NULL to NA and coerces measure columns to numeric
#'
#' @param df Tibble, specifying data to tidy
#' @param measure_cols Character vector, specifying measure column names
#'
#' @return Tibble with measure columns as numeric
#'
#' @importFrom dplyr mutate across
#' @importFrom tidyselect all_of
#'
#' @keywords internal
convert_to_numeric <- function(df, measure_cols) {
  measure_cols_present <- intersect(measure_cols, names(df))

  df |>
    mutate(across(
      all_of(measure_cols_present),
      replace_suppression_with_na
    ))
}

#' Rename columns
#'
#' Renames columns using a mapping (for year-specific inconsistencies).
#' Supports both global renames (applied to all periods) and period-specific renames.
#'
#' @param df Tibble, specifying data with columns to rename
#' @param rename_config List or named vector, specifying rename configuration.
#'   Can contain:
#'   - Simple mappings: `new_name: old_name` (applied to all periods)
#'   - Period-specific mappings: `"YYYY-YY": {new_name: old_name}`
#' @param period Character, specifying current period (e.g., "2023-24", "2025-09")
#'
#' @return Tibble with renamed columns
#'
#' @importFrom dplyr rename
#'
#' @keywords internal
rename_columns <- function(df, rename_config, period = NULL) {
  if (is.null(rename_config) || length(rename_config) == 0) {
    return(df)
  }

  # Separate global and period-specific renames
  is_period_key <- grepl("^\\d{4}-(\\d{2}|\\d{2})$", names(rename_config))

  # Extract global renames (not period-specific)
  global_renames <- rename_config[!is_period_key]

  # Extract period-specific renames for current period
  period_renames <- list()
  if (!is.null(period) && period %in% names(rename_config)) {
    period_renames <- rename_config[[period]]
  }

  # Combine: period-specific renames take precedence over global
  # Start with global, then override with period-specific
  all_renames <- global_renames
  if (length(period_renames) > 0) {
    # Override global renames with period-specific ones
    all_renames[names(period_renames)] <- period_renames
  }

  if (length(all_renames) == 0) {
    return(df)
  }

  # Convert to character vector (unlist if needed)
  all_renames_vec <- unlist(all_renames)

  # Only apply renames for columns that exist in the data
  # Note: all_renames_vec has new_name as name, old_name as value
  valid_mapping <- all_renames_vec[all_renames_vec %in% names(df)]

  if (length(valid_mapping) == 0) {
    return(df)
  }

  # Apply renames: new_name = old_name
  # YAML format is: new_name: old_name -> c(new_name = "old_name")
  # For dplyr, we need: c(new_name = old_name)
  # Keep the mapping as-is (just ensure it's unnamed properly)
  rename(df, !!!stats::setNames(unname(valid_mapping), names(valid_mapping)))
}

#' Filter rows
#'
#' Filters rows based on configuration
#'
#' @param df Tibble, specifying data to filter
#' @param filter_config Named list, specifying filter values (e.g., list(org_type = c("Provider")))
#'
#' @return Filtered tibble
#'
#' @importFrom dplyr filter
#' @importFrom rlang .data expr
#' @importFrom purrr map2 compact
#'
#' @keywords internal
filter_rows <- function(df, filter_config) {
  if (is.null(filter_config) || length(filter_config) == 0) {
    return(df)
  }

  conditions <- map2(
    names(filter_config),
    filter_config,
    \(col_name, values) {
      if (col_name %in% names(df)) {
        expr(.data[[!!col_name]] %in% !!values)
      } else {
        NULL
      }
    }
  ) |>
    compact()

  if (length(conditions) == 0) {
    return(df)
  }

  filter(df, !!!conditions)
}

#' Pivot measures to long format
#'
#' @param data_list Named list, specifying tibbles (e.g., list("2023-24" = df1, "2024-25" = df2))
#' @param pivot_config List, specifying pivot configuration with elements:
#'   - id_cols: Character vector, ID columns to preserve
#'   - measure_cols: Character vector, measure columns to pivot
#'   - sep: Character, regex pattern to separate measure names
#'   - names_to: Character vector, output column names for separated parts
#'
#' @return Tibble in long format
#'
#' @importFrom purrr imap list_rbind
#' @importFrom dplyr mutate
#' @importFrom tidyr pivot_longer extract
#' @importFrom tidyselect any_of
#'
#' @keywords internal
pivot_longer_measures <- function(data_list, pivot_config) {
  measure_cols <- pivot_config$measure_cols
  sep_pattern <- pivot_config$sep
  names_to <- pivot_config$names_to

  data_list |>
    imap(\(df, reporting_period) {
      mutate(df, reporting_period = reporting_period)
    }) |>
    list_rbind() |>
    pivot_longer(
      cols = any_of(measure_cols),
      names_to = "full_measure",
      values_to = "value"
    ) |>
    extract(
      col = "full_measure",
      into = names_to,
      regex = sep_pattern,
      remove = TRUE
    )
}

#' Add period date columns
#'
#' Detects period format (annual "2023-24" or monthly "2025-09") and adds
#' appropriate start_date and end_date columns
#'
#' @param df Tibble, specifying data with reporting_period column
#'
#' @return Tibble with start_date and end_date columns
#'
#' @importFrom purrr map list_c
#' @importFrom dplyr mutate
#'
#' @keywords internal
add_period_columns <- function(df) {
  first_period <- df$reporting_period[1]
  is_annual <- is_financial_year_period(first_period)

  parser_fn <- if (is_annual) {
    parse_annual_period_bounds
  } else {
    parse_monthly_period_bounds
  }

  period_info <- map(df$reporting_period, parser_fn)

  df |>
    mutate(
      start_date = map(period_info, "start") |> list_c(),
      end_date = map(period_info, "end") |> list_c()
    )
}

#' Parse reporting period date strings
#'
#' Handles ISO (YYYY-MM-DD) and UK-style (DD/MM/YYYY) formats
#'
#' @param x Character vector or Date, specifying dates to parse (e.g., "2023-04-01" or "01/04/2023")
#'
#' @return Date vector
#'
#' @keywords internal
parse_reporting_date <- function(x) {
  if (inherits(x, "Date")) {
    return(x)
  }

  x <- as.character(x)
  out <- rep(as.Date(NA), length(x))

  iso_mask <- grepl("^\\d{4}-\\d{2}-\\d{2}$", x)
  if (any(iso_mask)) {
    out[iso_mask] <- as.Date(x[iso_mask])
  }

  dmy_mask <- grepl("^\\d{2}/\\d{2}/\\d{4}$", x)
  if (any(dmy_mask)) {
    out[dmy_mask] <- as.Date(x[dmy_mask], format = "%d/%m/%Y")
  }

  out
}

#' Determine if a reporting period represents a financial year
#'
#' Accepts both legacy "FY2023-24" codes and new "2023-24" format.
#' Values ending in 13-31 are treated as financial years
#'
#' @param period Character, specifying period to check (e.g., "2023-24" or "FY2023-24")
#'
#' @return Logical
#'
#' @keywords internal
is_financial_year_period <- function(period) {
  if (grepl("^FY\\d{4}-\\d{2}$", period)) {
    return(TRUE)
  }

  if (!grepl("^\\d{4}-\\d{2}$", period)) {
    return(FALSE)
  }

  suffix <- as.integer(substr(period, 6, 7))
  !is.na(suffix) && suffix > 12
}

#' Parse annual period bounds
#'
#' Converts financial year code to start/end dates
#'
#' @param period Character, specifying financial year (e.g., "2023-24")
#'
#' @return List with start and end dates
#'
#' @importFrom cli cli_abort
#'
#' @keywords internal
parse_annual_period_bounds <- function(period) {
  normalized <- if (grepl("^FY", period)) {
    sub("^FY", "", period)
  } else {
    period
  }

  if (!grepl("^\\d{4}-\\d{2}$", normalized)) {
    cli_abort(
      "Invalid financial year format: {.val {period}}. Expected format: 2023-24"
    )
  }

  suffix <- as.integer(substr(normalized, 6, 7))
  if (is.na(suffix) || suffix <= 12) {
    cli_abort(
      "Invalid financial year value: {.val {period}}. Expected second part between 13 and 31."
    )
  }

  start_year <- as.integer(substr(normalized, 1, 4))
  list(
    start = as.Date(paste0(start_year, "-04-01")),
    end = as.Date(paste0(start_year + 1, "-03-31"))
  )
}

#' Parse monthly period bounds
#'
#' Converts ISO year-month format to start/end dates of that month
#'
#' @param period Character, specifying monthly period (e.g., "2025-09")
#'
#' @return List with start and end dates
#'
#' @importFrom cli cli_abort
#'
#' @keywords internal
parse_monthly_period_bounds <- function(period) {
  if (!grepl("^\\d{4}-\\d{2}$", period)) {
    cli_abort("Invalid monthly period format: {.val {period}}")
  }

  year <- as.integer(substr(period, 1, 4))
  month <- as.integer(substr(period, 6, 7))

  start_date <- as.Date(paste0(year, "-", sprintf("%02d", month), "-01"))

  if (month == 12) {
    next_month_start <- as.Date(paste0(year + 1, "-01-01"))
  } else {
    next_month_start <- as.Date(paste0(
      year,
      "-",
      sprintf("%02d", month + 1),
      "-01"
    ))
  }
  end_date <- next_month_start - 1

  list(
    start = start_date,
    end = end_date
  )
}

#' Clean column values to snake_case
#'
#' Applies clean_str to values in specified columns
#'
#' @param df Tibble, specifying data with columns to clean
#' @param column_names Character vector, specifying column names to clean (e.g., c("measure", "statistic"))
#' @param strip_numbers Logical, specifying whether to remove numbers from strings (default FALSE)
#'
#' @return Tibble with cleaned column values
#'
#' @importFrom dplyr mutate across
#' @importFrom tidyselect all_of
#'
#' @keywords internal
clean_column_values <- function(
  df,
  column_names = NULL,
  strip_numbers = FALSE
) {
  if (is.null(column_names) || length(column_names) == 0) {
    return(df)
  }

  columns_to_clean <- intersect(column_names, names(df))

  if (length(columns_to_clean) == 0) {
    return(df)
  }

  df |>
    mutate(
      across(
        all_of(columns_to_clean),
        \(x) clean_str(x, strip_numbers = strip_numbers)
      )
    )
}


#' Clean NHS Talking Therapies provider names
#'
#' The provider names are all caps in the data, for visualisations they should be clean.
#'
#' @param x Character, specifying NHS TT provider name in all caps
#'
#' @return Clean NHS TT provider name
#'
#' @importFrom stringr str_c str_to_title str_to_lower str_replace_all str_squish regex
#'
#' @keywords internal
clean_org_names <- function(x) {
  lower_case_words <- c(
    "and",
    "are",
    "at",
    "by",
    "for",
    "from",
    "in",
    "of",
    "on",
    "or",
    "the",
    "to",
    "with",
    "you"
  )

  all_caps_words <- c(
    "NHS",
    "IAPT",
    "CIC",
    "LTD",
    "UK",
    "SMS",
    "HQ",
    "Bmhc",
    "Ftb",
    "Eltt",
    "Lgbt",
    "Llr",
    "Iccs",
    "Pts"
  )

  # Pattern assumes that this comes after str_to_title()
  camel_case_words <- c(
    "Talkingspace" = "TalkingSpace",
    "Vitaminds" = "VitaMinds"
  )

  # lower-case words: only when preceded by a space (not first word)
  lower_pattern <- str_c(
    "(?<=\\s)(",
    str_c(str_to_title(lower_case_words), collapse = "|"),
    ")\\b"
  )

  # all-caps words: match Title Case versions, whole words
  upper_pattern <- str_c(
    "\\b(",
    str_c(str_to_title(str_to_lower(all_caps_words)), collapse = "|"),
    ")\\b"
  )

  x |>
    str_replace_all(":\\s*", ": ") |>
    str_replace_all(regex("(?<=\\S)\\("), " (") |>
    str_squish() |>
    str_to_title() |>
    str_replace_all(regex(lower_pattern), tolower) |>
    str_replace_all(regex(upper_pattern), toupper) |>
    str_replace_all(regex(camel_case_words))
}

#' Extract SNOMED CT codes from text
#'
#' To extract SNOMED CT codes we use a regex pattern that matches 6 to 18 digit numbers that don't start with zero.
#'
#' @param x A character vector containing text
#'
#' @return A list of character vectors
#'
#' @importFrom stringr str_extract_all str_c
#' @importFrom purrr map_chr
#' @keywords internal
str_extract_snomed <- function(x) {
  snomed_regex_pattern <- "\\b[1-9][0-9]{5,17}\\b"
  snomed_codes_list <- str_extract_all(x, snomed_regex_pattern)

  # Note: Codes are collapsed into a single character string per input element to prioritise human readability.
  # This simplifies inspection but is less convient for downstream analysis workflows.
  # Return NA if no code found
  # Otherwise collapse all codes into one string
  snomed_codes <- map_chr(
    snomed_codes_list,
    ~ if (length(.x) == 0) {
      NA_character_
    } else {
      str_c(.x, collapse = ", ")
    }
  )
  snomed_codes
}

#' Extract ICD-10 codes from text
#'
#' To extract ICD-10 codes we use a regex pattern that matches the standard ICD-10 format:
#' a letter (A-Z) followed by two digits, optionally followed by a decimal point and 1-2 more digits.
#'
#' @param x A character vector containing text
#'
#' @return A character vector with extracted standardised ICD-10 codes (comma-separated with no decimal point) or NA
#'
#' @importFrom stringr str_extract_all str_c str_remove_all
#' @importFrom purrr map_chr
#' @keywords internal
str_extract_icd10 <- function(x) {
  icd10_regex_pattern <- "\\b[A-Z][0-9]{2,3}(\\.[0-9]{1,2})?\\b(?!\\.)"
  icd10_codes_list <- str_extract_all(x, icd10_regex_pattern)

  # Note: Codes are collapsed into a single character string per input element to prioritise human readability.
  # This simplifies inspection but is less convient for downstream analysis workflows.
  # Return NA if no code found
  # Otherwise collapse all codes into one string
  icd10_codes <- map_chr(
    icd10_codes_list,
    ~ if (length(.x) == 0) {
      NA_character_
    } else {
      str_c(
        str_remove_all(.x, "\\."), # standardises icd10 codes removing decimal points
        collapse = ", "
      )
    }
  )
  icd10_codes
}
