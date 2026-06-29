# Readers for the early annual IAPT reports (2012-13 to 2016-17). These used a
# different format from 2017-18 onwards, so we need bespoke code to extract the
# data. See DEVELOPERS.md for details on what's available in each year.

#' Download a legacy-format annual source file to a temp path
#'
#' Looks up the URL for the given period from the `annual_main_legacy_format`
#' archive in the raw config, downloads it with retry logic, and returns the
#' local temp path.  The caller is responsible for deleting the temp file
#' (use `on.exit(unlink(path))`).
#'
#' @param period Character, specifying reporting period (e.g., `"2016-17"`)
#'
#' @return Character path to the downloaded temp file
#'
#' @keywords internal
download_annual_legacy_format_source <- function(period) {
  raw_config <- load_raw_config()
  archive_sources <- raw_config$archives$annual_main_legacy_format

  source <- validate_period_exists(
    period,
    archive_sources,
    "annual_main_legacy_format"
  )

  temp_file <- tempfile(fileext = paste0(".", source$format))
  download_with_retry(source$url, temp_file)
  temp_file
}

#' Find a row by its label in an XLSX sheet and return it as numbers
#'
#' Looks in column 1 for `row_label` and returns all values in that row as a
#' numeric vector. Position in the vector matches the source column number.
#'
#' @param path Character, specifying path to the XLSX file
#' @param sheet Character, specifying sheet name
#' @param row_label Character, specifying text in column 1 identifying the target row.
#'   Defaults to `"England total"`.
#'
#' @return Numeric vector; positions correspond to source column indices, `NA`
#'   for empty or non-numeric cells
#'
#' @importFrom readxl read_excel
#' @importFrom cli cli_abort
#'
#' @keywords internal
read_legacy_format_row_xlsx <- function(
  path,
  sheet,
  row_label = "England total"
) {
  raw <- read_excel(
    path,
    sheet = sheet,
    col_names = FALSE,
    .name_repair = "unique"
  )
  idx <- which(raw[[1]] == row_label)
  if (length(idx) == 0) {
    cli_abort(
      "Row {.val {row_label}} not found in sheet {.val {sheet}} ({basename(path)})"
    )
  }
  as.numeric(unlist(raw[idx[[1]], ]))
}

#' Read ethnicity x age x gender XLSX table (2012-13 Table_8 / 2013-14 Table 17)
#'
#' Returns every combination of ethnicity, gender, and age band present in the
#' table.  The `"All"/"All"/"All"` row preserves the published England total.
#'
#' Column positions differ between years, so they are parameterised:
#' - 2012-13: male cols 7–11, female cols 13–17
#' - 2013-14: female cols 6–10, male cols 12–16
#'
#' @param path Character, specifying path to the XLSX file
#' @param sheet Character, specifying sheet name
#' @param total_col Integer, specifying column holding the all-genders total (default 4)
#' @param male_cols Integer vector, specifying columns for the five male age bands
#' @param female_cols Integer vector, specifying columns for the five female age bands
#' @param age_bands Character vector, specifying age band labels in column order
#'
#' @return Tibble with columns `ethnicity_group`, `ethnicity`, `gender`,
#'   `age_group`, `count_referrals_received`
#'
#' @importFrom readxl read_excel
#' @importFrom tibble tibble
#' @importFrom dplyr filter select mutate arrange across bind_rows transmute
#' @importFrom tidyr pivot_longer
#' @importFrom stringr str_trim str_remove str_replace_all
#'
#' @keywords internal
read_legacy_format_ethnicity_age_gender_xlsx <- function(
  path,
  sheet,
  total_col = 4L,
  male_cols = 7:11,
  female_cols = 13:17,
  age_bands = c("Under 16", "16 to 17", "18 to 35", "36 to 64", "65 and over")
) {
  raw <- read_excel(
    path,
    sheet = sheet,
    col_names = FALSE,
    .name_repair = "unique"
  )

  stopifnot(
    length(male_cols) == length(age_bands),
    length(female_cols) == length(age_bands)
  )

  male_names <- paste0("male_", gsub("[^a-z0-9]+", "_", tolower(age_bands)))
  female_names <- paste0("female_", gsub("[^a-z0-9]+", "_", tolower(age_bands)))

  tbl <- tibble(
    label_1 = as.character(raw[[1]]),
    label_2 = as.character(raw[[2]]),
    label_3 = as.character(raw[[3]]),
    total = as.numeric(raw[[total_col]])
  )
  for (i in seq_along(age_bands)) {
    tbl[[male_names[i]]] <- as.numeric(raw[[male_cols[i]]])
    tbl[[female_names[i]]] <- as.numeric(raw[[female_cols[i]]])
  }

  tbl <- tbl |>
    filter(
      !is.na(label_1) | !is.na(label_2) | !is.na(label_3),
      !grepl(
        "^(\\(|Data source|Copyright|Table)",
        coalesce(label_1, label_2, label_3),
        ignore.case = TRUE
      )
    )

  # Propagate ethnicity group via state machine.
  # Col-2-only rows with no data are section headers — mark for removal.
  current_group <- NA_character_
  ethnicity_group <- vector("character", nrow(tbl))
  ethnicity <- vector("character", nrow(tbl))
  is_header_row <- vector("logical", nrow(tbl))

  for (i in seq_len(nrow(tbl))) {
    cell1 <- tbl$label_1[[i]]
    cell2 <- tbl$label_2[[i]]
    cell3 <- tbl$label_3[[i]]
    has_data <- !is.na(tbl$total[[i]])

    if (!is.na(cell1)) {
      ethnicity_group[[i]] <- "All"
      ethnicity[[i]] <- cell1
    } else if (!is.na(cell2) && !has_data) {
      current_group <- cell2
      is_header_row[[i]] <- TRUE
    } else if (!is.na(cell2) && has_data) {
      ethnicity_group[[i]] <- cell2
      ethnicity[[i]] <- cell2
    } else if (!is.na(cell3)) {
      ethnicity_group[[i]] <- current_group
      ethnicity[[i]] <- cell3
    }
  }

  tbl$ethnicity_group <- ethnicity_group
  tbl$ethnicity <- ethnicity
  tbl$is_header <- is_header_row

  data <- tbl |>
    filter(!is_header) |>
    select(
      ethnicity_group,
      ethnicity,
      total,
      all_of(c(male_names, female_names))
    )

  total_rows <- data |>
    transmute(
      ethnicity_group,
      ethnicity,
      gender = "All",
      age_group = "All",
      count_referrals_received = total
    )

  breakdown_rows <- data |>
    select(-total) |>
    pivot_longer(
      cols = all_of(c(male_names, female_names)),
      names_to = c("gender", "age_group"),
      names_pattern = "^(male|female)_(.+)$",
      values_to = "count_referrals_received"
    ) |>
    mutate(
      gender = str_to_title(gender),
      age_group = str_replace_all(age_group, "_", " ") |> str_to_sentence()
    )

  bind_rows(total_rows, breakdown_rows) |>
    filter(!is.na(count_referrals_received)) |>
    mutate(across(c(ethnicity_group, ethnicity), \(x) {
      str_trim(str_remove(x, "\\s*\\(\\d+\\)$"))
    })) |>
    arrange(ethnicity_group, ethnicity, gender, age_group)
}

#' Read age x gender XLSX block (2014-15 Table 10a)
#'
#' Table 10a stacks England + all CCGs. Column 1 has "England total" only for
#' the first of the five England rows; the rest have `NA` in col 1.  We find
#' the start row and read exactly five consecutive rows.
#'
#' Column layout within each block:
#'   col 4  age group; col 5/6/7  All received/entered/completing;
#'   col 8/9/10 Male; col 11/12/13 Female
#'
#' @param path Character, specifying path to the XLSX file
#' @param sheet Character, specifying sheet name (e.g., `"Table 10a"`)
#'
#' @return Tibble with columns `age_group`, `gender`,
#'   `count_referrals_received`, `count_finished_course_treatment`
#'
#' @importFrom readxl read_excel
#' @importFrom tibble tibble
#' @importFrom dplyr filter rename mutate
#' @importFrom tidyr pivot_longer pivot_wider
#' @importFrom stringr str_to_title
#'
#' @keywords internal
read_legacy_format_age_gender_xlsx <- function(path, sheet) {
  raw <- read_excel(
    path,
    sheet = sheet,
    col_names = FALSE,
    .name_repair = "unique"
  )
  start <- which(as.character(raw[[1]]) == "England total")[1]
  block <- raw[start:(start + 4L), ]

  tibble(
    age_group = as.character(block[[4]]),
    all_received = as.numeric(block[[5]]),
    all_finishing = as.numeric(block[[7]]),
    male_received = as.numeric(block[[8]]),
    male_finishing = as.numeric(block[[10]]),
    female_received = as.numeric(block[[11]]),
    female_finishing = as.numeric(block[[13]])
  ) |>
    filter(!is.na(age_group), !is.na(all_received)) |>
    pivot_longer(
      cols = -age_group,
      names_to = c("gender", "measure"),
      names_pattern = "^(all|male|female)_(.+)$",
      values_to = "value"
    ) |>
    mutate(gender = str_to_title(gender)) |>
    pivot_wider(names_from = measure, values_from = value) |>
    rename(
      count_referrals_received = received,
      count_finished_course_treatment = finishing
    )
}

#' Read a clinical outcome breakdown from a 2014-15 "b-table" XLSX
#'
#' The 2014-15 XLSX report contains outcome tables for ethnicity (Table 11b),
#' sexual orientation (Table 12b), disability (Table 13b), and religion
#' (Table 14b).  All follow the same CCG-block layout:
#'
#'   col 1 — org label ("England total" identifies the block start)
#'   col 2 — CCG code (NA for all England rows)
#'   col 3 — CCG name (NA for England)
#'   col 4 — dimension category
#'   col 5  — count_finished_course_treatment
#'   col 6/7   — at_caseness / not_at_caseness
#'   col 8/9   — improvement count/pct
#'   col 10/11 — no_reliable_change count/pct
#'   col 12/13 — deterioration count/pct
#'   col 14/15 — recovery count/pct
#'   col 16/17 — reliable_recovery count/pct
#'   col 18    — paired scores (ignored)
#'
#' The England block is found by locating "England total" in col 1 and reading
#' until col 2 becomes non-`NA` (= first CCG code row).
#'
#' @param path Character, specifying path to the XLSX file
#' @param sheet Character, specifying sheet name (e.g., `"Table 12b"`)
#' @param dim_col Character, specifying name to assign to the dimension column in output
#'
#' @return Tibble with `dim_col` plus all clinical outcome measure columns
#'
#' @importFrom readxl read_excel
#' @importFrom tibble tibble
#' @importFrom stringr str_trim str_remove
#' @importFrom rlang sym
#'
#' @keywords internal
read_legacy_format_outcome_xlsx <- function(path, sheet, dim_col) {
  raw <- read_excel(
    path,
    sheet = sheet,
    col_names = FALSE,
    .name_repair = "unique"
  )
  col1 <- as.character(raw[[1]])
  col2 <- as.character(raw[[2]])
  start <- which(col1 == "England total")[1]

  # Stops reading at the first CCG row; to also get CCG breakdowns, extend this block past ccg_start
  ccg_start <- which(!is.na(col2) & seq_along(col2) > start)
  end <- if (length(ccg_start) > 0) ccg_start[1] - 1L else nrow(raw)

  block_raw <- raw[start:end, ]
  block <- block_raw[!is.na(as.character(block_raw[[4]])), ]

  dim_str <- str_trim(str_remove(as.character(block[[4]]), "\\s*\\(\\d+\\)$"))

  tibble(
    !!sym(dim_col) := dim_str,
    count_finished_course_treatment = as.numeric(block[[5]]),
    count_at_caseness = as.numeric(block[[6]]),
    count_not_at_caseness = as.numeric(block[[7]]),
    count_improvement = as.numeric(block[[8]]),
    percentage_improvement = as.numeric(block[[9]]),
    count_no_reliable_change = as.numeric(block[[10]]),
    percentage_no_reliable_change = as.numeric(block[[11]]),
    count_deterioration = as.numeric(block[[12]]),
    percentage_deterioration = as.numeric(block[[13]]),
    count_recovery = as.numeric(block[[14]]),
    percentage_recovery = as.numeric(block[[15]]),
    count_reliable_recovery = as.numeric(block[[16]]),
    percentage_reliable_recovery = as.numeric(block[[17]])
  )
}

#' Return a function that extracts a named column from `df` as numeric
#'
#' Returned closure returns `NA_real_` when the column is absent, allowing
#' `coalesce()` to pick the first available name variant across years.
#'
#' @param df Data frame, specifying data whose columns will be looked up
#'
#' @return A function `\(nm) numeric_or_NA`
#'
#' @keywords internal
col_lookup <- function(df) {
  \(nm) if (nm %in% names(df)) as.numeric(df[[nm]]) else NA_real_
}

#' Read an age x gender CSV table (2015-16 / 2016-17 table-8a)
#'
#' Column names differ between years but resolve consistently after
#' `clean_str()`:
#' - 2015-16: `ALL_REC`, `ALL_FIN`, `FEMALE_REC`, …
#' - 2016-17: `AllReferralsReceived`, …
#'
#' @param zip_path Character, specifying path to the ZIP archive
#' @param pattern Character, specifying regex identifying the CSV file inside the archive
#'
#' @return Tibble with columns `age_group`, `gender`,
#'   `count_referrals_received`, `count_finished_course_treatment`
#'
#' @importFrom dplyr filter mutate rename coalesce
#' @importFrom tidyr pivot_longer pivot_wider
#' @importFrom stringr str_to_title
#'
#' @keywords internal
read_legacy_format_age_gender_csv <- function(zip_path, pattern) {
  raw <- extract_csv_from_archive(zip_path, pattern) |>
    (\(df) df[df[[1]] == "England", ])() # Keeps England totals only; remove this filter to also get CCG rows

  names(raw) <- sapply(names(raw), clean_str)
  col_or_na <- col_lookup(raw)

  tibble(
    age_group = as.character(raw[[grep("age", names(raw))[1]]]),
    all_received = as.numeric(coalesce(
      col_or_na("all_rec"),
      col_or_na("all_referrals_received")
    )),
    all_finishing = as.numeric(coalesce(
      col_or_na("all_fin"),
      col_or_na("all_finished_course_treatment")
    )),
    male_received = as.numeric(coalesce(
      col_or_na("male_rec"),
      col_or_na("male_referrals_received")
    )),
    male_finishing = as.numeric(coalesce(
      col_or_na("male_fin"),
      col_or_na("male_finished_course_treatment")
    )),
    female_received = as.numeric(coalesce(
      col_or_na("female_rec"),
      col_or_na("female_referrals_received")
    )),
    female_finishing = as.numeric(coalesce(
      col_or_na("female_fin"),
      col_or_na("female_finished_course_treatment")
    ))
  ) |>
    filter(!is.na(age_group), !is.na(all_received)) |>
    pivot_longer(
      cols = -age_group,
      names_to = c("gender", "measure"),
      names_pattern = "^(all|male|female)_(.+)$",
      values_to = "value"
    ) |>
    mutate(gender = str_to_title(gender)) |>
    pivot_wider(names_from = measure, values_from = value) |>
    rename(
      count_referrals_received = received,
      count_finished_course_treatment = finishing
    )
}

#' Read a clinical outcome breakdown from a CSV pack (2015-16 / 2016-17)
#'
#' Handles tables: `table-9b` (ethnicity outcomes), `table-10b` (sexual
#' orientation), `table-11b` (disability), `table-12b` (religion),
#' `table-13b` (IMD), `table-14` (LTC).
#'
#' The dimension category is always in column 3.  Column names differ between
#' tables and years; all variants are merged via `coalesce()` after
#' `clean_str()`.
#'
#' Known data quirks handled:
#' - 2016-17 `table-14` typo: `NoRelibableChange`
#' - 2016-17 `table-12b` typo: `StartedNoCaseness`
#' - 2016-17 `table-9b`/`table-10b`: uses `All*` prefix column naming
#'   (e.g. `AllImprovement`) instead of the 2015-16 `ALL_*` style
#'
#' @param zip_path Character, specifying path to the ZIP archive
#' @param pattern Character, specifying regex identifying the CSV file inside the archive
#'
#' @return Tibble with the dimension column followed by all available clinical
#'   outcome measure columns
#'
#' @importFrom tibble tibble
#' @importFrom stringr str_trim str_remove
#' @importFrom rlang sym
#' @importFrom dplyr coalesce
#'
#' @keywords internal
read_legacy_format_outcome_csv <- function(zip_path, pattern) {
  raw <- extract_csv_from_archive(zip_path, pattern) |>
    (\(df) df[df[[1]] == "England", ])() # Keeps England totals only; remove this filter to also get CCG rows

  names(raw) <- sapply(names(raw), clean_str)
  dim_col <- names(raw)[3]
  col_or_na <- col_lookup(raw)

  tibble(
    !!sym(dim_col) := str_trim(str_remove(
      as.character(raw[[dim_col]]),
      "\\s*\\(\\d+\\)$"
    )),
    count_finished_course_treatment = as.numeric(coalesce(
      col_or_na("all_fin"),
      col_or_na("finished_treatment"),
      col_or_na("finished_course_treatment"),
      col_or_na("all_finished_course_treatment")
    )),
    count_improvement = as.numeric(coalesce(
      col_or_na("all_rel_imp"),
      col_or_na("improvement"),
      col_or_na("all_improvement")
    )),
    percentage_improvement = as.numeric(coalesce(
      col_or_na("all_rel_imp_pcnt"),
      col_or_na("improvement_rate"),
      col_or_na("all_improvement_rate")
    )),
    count_no_reliable_change = as.numeric(coalesce(
      col_or_na("all_no_rel_change"),
      col_or_na("no_reliable_change"),
      col_or_na("all_no_reliable_change"),
      col_or_na("no_relibable_change") # 2016-17 table-14 typo
    )),
    percentage_no_reliable_change = as.numeric(coalesce(
      col_or_na("all_no_rel_change_pcnt"),
      col_or_na("no_reliable_change_rate"),
      col_or_na("all_no_reliable_change_rate"),
      col_or_na("no_relibable_change_rate")
    )),
    count_deterioration = as.numeric(coalesce(
      col_or_na("all_rel_det"),
      col_or_na("deterioration"),
      col_or_na("all_deterioration")
    )),
    percentage_deterioration = as.numeric(coalesce(
      col_or_na("all_rel_det_pcnt"),
      col_or_na("deterioration_rate"),
      col_or_na("all_deterioration_rate")
    )),
    count_at_caseness = as.numeric(coalesce(
      col_or_na("all_started_caseness"),
      col_or_na("started_caseness")
    )),
    count_not_at_caseness = as.numeric(coalesce(
      col_or_na("all_started_not_caseness"),
      col_or_na("started_not_caseness"),
      col_or_na("started_no_caseness") # 2016-17 table-12b typo
    )),
    count_recovery = as.numeric(coalesce(
      col_or_na("all_recovered"),
      col_or_na("recovery"),
      col_or_na("all_recovery")
    )),
    percentage_recovery = as.numeric(coalesce(
      col_or_na("all_recovered_pcnt"),
      col_or_na("recovery_rate"),
      col_or_na("all_recovery_rate")
    )),
    count_reliable_recovery = as.numeric(coalesce(
      col_or_na("all_rel_rec"),
      col_or_na("reliable_recovery"),
      col_or_na("all_reliable_recovery")
    )),
    percentage_reliable_recovery = as.numeric(coalesce(
      col_or_na("all_rel_rec_pcnt"),
      col_or_na("reliable_recovery_rate"),
      col_or_na("all_reliable_recovery_rate")
    ))
  )
}

#' Derive Age Group and Gender rows from an age x gender tibble (wide format)
#'
#' Handles both age-band x gender combinations (2014-15 onwards, where the
#' source table contains an "All" gender row per age band) and the
#' aggregated structure used in 2012-13/2013-14 (where age rows must be summed
#' across male/female).
#'
#' Also handles tibbles without `count_finished_course_treatment` (2012-13/
#' 2013-14 where the source table only contains referrals received).
#'
#' @param ag_data Tibble, specifying age-gender breakdown data with `age_group`,
#'   `gender`, and one or both count columns
#'
#' @return Tibble in wide format with columns `org_type`, `org_code`,
#'   `org_name`, `variable_type`, `variable_a`, `variable_b`, and the
#'   available measure columns
#'
#' @importFrom dplyr filter select rename mutate group_by summarise across bind_rows
#' @importFrom tidyselect all_of
#'
#' @keywords internal
extract_legacy_format_age_gender_breakdowns_wide <- function(ag_data) {
  measure_cols <- intersect(
    c("count_referrals_received", "count_finished_course_treatment"),
    names(ag_data)
  )

  age_rows <- ag_data |>
    filter(gender == "All") |>
    select(age_group, all_of(measure_cols)) |>
    rename(variable_a = age_group) |>
    mutate(
      org_type = "England",
      org_code = "All",
      org_name = "All",
      variable_type = "Age Group",
      variable_b = NA_character_
    )

  gender_rows <- ag_data |>
    filter(gender != "All") |>
    group_by(gender) |>
    summarise(
      across(all_of(measure_cols), \(x) sum(x, na.rm = TRUE)),
      .groups = "drop"
    ) |>
    rename(variable_a = gender) |>
    mutate(
      org_type = "England",
      org_code = "All",
      org_name = "All",
      variable_type = "Gender",
      variable_b = NA_character_
    )

  bind_rows(age_rows, gender_rows)
}

#' Build the breakdown list for CSV-pack years (2015-16 and 2016-17)
#'
#' All seven breakdowns read from the same table names in both CSV packs;
#' `read_legacy_format_outcome_csv()` and `read_legacy_format_age_gender_csv()` handle year-specific column
#' name differences internally.
#'
#' @param zip_path Character, specifying path to the ZIP archive
#' @param breakdowns Character vector, specifying requested breakdown dimensions
#'
#' @return Named list of wide tibbles suitable for passing to `compact()` +
#'   `bind_rows()`
#'
#' @importFrom dplyr mutate if_else rename
#' @importFrom stringr str_detect str_extract
#' @importFrom rlang sym
#' @importFrom purrr compact
#'
#' @keywords internal
read_legacy_format_zip_breakdowns <- function(zip_path, breakdowns) {
  list(
    age_gender = if ("age_gender" %in% breakdowns) {
      extract_legacy_format_age_gender_breakdowns_wide(
        read_legacy_format_age_gender_csv(zip_path, "table-8a")
      )
    },
    ethnicity = if ("ethnicity" %in% breakdowns) {
      read_legacy_format_outcome_csv(zip_path, "table-9b") |>
        mutate(
          ethnicity_group = if_else(
            str_detect(ethnicity, " - "),
            str_extract(ethnicity, "^(.+?) - ", group = 1L),
            ethnicity
          ),
          ethnicity = if_else(
            str_detect(ethnicity, " - "),
            str_extract(ethnicity, " - (.+)$", group = 1L),
            NA_character_
          )
        ) |>
        rename(variable_a = ethnicity_group, variable_b = ethnicity) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Ethnic Group"
        )
    },
    sexual_orientation = if ("sexual_orientation" %in% breakdowns) {
      (\(data) {
        data |>
          rename(variable_a = !!sym(names(data)[1])) |>
          mutate(
            org_type = "England",
            org_code = "All",
            org_name = "All",
            variable_type = "Sexual Orientation Type",
            variable_b = NA_character_
          )
      })(read_legacy_format_outcome_csv(zip_path, "table-10b"))
    },
    religion = if ("religion" %in% breakdowns) {
      read_legacy_format_outcome_csv(zip_path, "table-12b") |>
        rename(variable_a = religion) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Religion",
          variable_b = NA_character_
        )
    },
    imd = if ("imd" %in% breakdowns) {
      read_legacy_format_outcome_csv(zip_path, "table-13b") |>
        rename(variable_a = imd) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Indices of Deprivation Decile",
          variable_b = NA_character_
        )
    },
    disability = if ("disability" %in% breakdowns) {
      read_legacy_format_outcome_csv(zip_path, "table-11b") |>
        rename(variable_a = disability) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Disability Type",
          variable_b = NA_character_
        )
    },
    ltc = if ("ltc" %in% breakdowns) {
      read_legacy_format_outcome_csv(zip_path, "table-14") |>
        rename(variable_a = ltc) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Long Term Condition Status",
          variable_b = NA_character_
        )
    }
  )
}

#' Extract measures for 2016-17 (CSV pack)
#'
#' Sources: `table-1a` (referrals), `table-7a` (outcomes).
#' Breakdowns available: age_gender, ethnicity, sexual_orientation,
#' disability, religion, imd, ltc.
#'
#' @param zip_path Character, specifying path to the v3.0 ZIP archive
#' @param breakdowns Character vector, specifying breakdown dimensions (see file header for valid values)
#'
#' @return Tibble with Total + breakdown rows in wide format
#'
#' @importFrom tibble tibble
#' @importFrom dplyr filter bind_rows
#' @importFrom purrr compact
#'
#' @keywords internal
extract_annual_legacy_format_2016_17 <- function(
  zip_path,
  breakdowns = character(0)
) {
  # Keeps England totals only; remove these filters to also get CCG rows
  table_1a <- extract_csv_from_archive(zip_path, "table-1a") |>
    filter(CCG == "England")
  table_7a <- extract_csv_from_archive(zip_path, "table-7a") |>
    filter(CCG == "England")

  total <- tibble(
    org_type = "England",
    org_code = "All",
    org_name = "All",
    variable_type = "Total",
    variable_a = NA_character_,
    variable_b = NA_character_,
    count_referrals_received = table_1a$ReferralsReceived,
    count_finished_course_treatment = table_7a$FinishedCourseTreatment,
    count_at_caseness = table_7a$StartedCaseness,
    count_not_at_caseness = table_7a$StartedNotCaseness,
    count_improvement = table_7a$Improvement,
    percentage_improvement = table_7a$ImprovementRate,
    count_deterioration = table_7a$Deterioration,
    percentage_deterioration = table_7a$DeteriorationRate,
    count_no_reliable_change = table_7a$NoReliableChange,
    percentage_no_reliable_change = table_7a$NoReliableChangeRate,
    count_recovery = table_7a$Recovery,
    percentage_recovery = table_7a$RecoveryRate,
    count_reliable_recovery = table_7a$ReliableRecovery,
    percentage_reliable_recovery = table_7a$ReliableRecoveryRate
  )

  bind_rows(c(
    list(total),
    compact(read_legacy_format_zip_breakdowns(zip_path, breakdowns))
  ))
}

#' Extract measures for 2015-16 (CSV pack)
#'
#' Sources: `table-1a` (referrals), `table-7a` (outcomes).
#' Breakdowns available: age_gender, ethnicity, sexual_orientation,
#' disability, religion, imd, ltc.
#'
#' @param zip_path Character, specifying path to the ZIP archive
#' @param breakdowns Character vector, specifying breakdown dimensions (see file header for valid values)
#'
#' @return Tibble with Total + breakdown rows in wide format
#'
#' @importFrom tibble tibble
#' @importFrom dplyr filter bind_rows
#' @importFrom purrr compact
#'
#' @keywords internal
extract_annual_legacy_format_2015_16 <- function(
  zip_path,
  breakdowns = character(0)
) {
  # Keeps England totals only; remove these filters to also get CCG rows
  table_1a <- extract_csv_from_archive(zip_path, "table-1a") |>
    filter(IC_CCG == "England")
  table_7a <- extract_csv_from_archive(zip_path, "table-7a") |>
    filter(CCG_CODE == "England")

  total <- tibble(
    org_type = "England",
    org_code = "All",
    org_name = "All",
    variable_type = "Total",
    variable_a = NA_character_,
    variable_b = NA_character_,
    count_referrals_received = table_1a$RECEIVED,
    count_finished_course_treatment = table_7a$FINISH_TREAT,
    count_at_caseness = table_7a$STARTED_CASENESS,
    count_not_at_caseness = table_7a$STARTED_NOT_CASENESS,
    count_improvement = table_7a$REL_IMP,
    percentage_improvement = table_7a$REL_IMP_PCNT,
    count_deterioration = table_7a$REL_DET,
    percentage_deterioration = table_7a$REL_DET_PCNT,
    count_no_reliable_change = table_7a$NO_REL_CHANGE,
    percentage_no_reliable_change = table_7a$NO_REL_CHANGE_PCNT,
    count_recovery = table_7a$RECOVERED,
    percentage_recovery = table_7a$RECOVERED_PCNT,
    count_reliable_recovery = table_7a$REL_REC,
    percentage_reliable_recovery = table_7a$REL_REC_PCNT
  )

  bind_rows(c(
    list(total),
    compact(read_legacy_format_zip_breakdowns(zip_path, breakdowns))
  ))
}

#' Extract measures for 2014-15 (XLSX)
#'
#' Sources: `Table 1a` (referrals), `Table 9a` (outcomes).
#' Breakdowns available: age_gender (Table 10a), ethnicity (Table 11b),
#' sexual_orientation (Table 12b), disability (Table 13b), religion (Table 14b).
#' imd and ltc are only available from 2015-16.
#'
#' Table 9a column positions:
#'   4 = at_caseness; 5 = not_at_caseness; 6/7 = improvement count/pct;
#'   8/9 = no_reliable_change; 10/11 = deterioration; 12/13 = recovery;
#'   14/15 = reliable_recovery; 16 = paired-data count (ignored)
#'
#' @param xlsx_path Character, specifying path to the XLSX file
#' @param breakdowns Character vector, specifying breakdown dimensions (see file header for valid values)
#'
#' @return Tibble with Total + breakdown rows in wide format
#'
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows mutate if_else rename
#' @importFrom stringr str_detect str_extract
#' @importFrom purrr compact
#'
#' @keywords internal
extract_annual_legacy_format_2014_15 <- function(
  xlsx_path,
  breakdowns = character(0)
) {
  table_1a <- read_legacy_format_row_xlsx(xlsx_path, "Table 1a")
  table_9a <- read_legacy_format_row_xlsx(xlsx_path, "Table 9a")

  total <- tibble(
    org_type = "England",
    org_code = "All",
    org_name = "All",
    variable_type = "Total",
    variable_a = NA_character_,
    variable_b = NA_character_,
    count_referrals_received = table_1a[3],
    count_finished_course_treatment = table_1a[5],
    count_at_caseness = table_9a[4],
    count_not_at_caseness = table_9a[5],
    count_improvement = table_9a[6],
    percentage_improvement = table_9a[7],
    count_no_reliable_change = table_9a[8],
    percentage_no_reliable_change = table_9a[9],
    count_deterioration = table_9a[10],
    percentage_deterioration = table_9a[11],
    count_recovery = table_9a[12],
    percentage_recovery = table_9a[13],
    count_reliable_recovery = table_9a[14],
    percentage_reliable_recovery = table_9a[15]
  )

  breakdown_list <- list(
    age_gender = if ("age_gender" %in% breakdowns) {
      extract_legacy_format_age_gender_breakdowns_wide(
        read_legacy_format_age_gender_xlsx(xlsx_path, "Table 10a")
      )
    },
    ethnicity = if ("ethnicity" %in% breakdowns) {
      read_legacy_format_outcome_xlsx(
        xlsx_path,
        "Table 11b",
        dim_col = "ethnicity"
      ) |>
        mutate(
          ethnicity_group = if_else(
            str_detect(ethnicity, " - "),
            str_extract(ethnicity, "^(.+?) - ", group = 1L),
            ethnicity
          ),
          ethnicity = if_else(
            str_detect(ethnicity, " - "),
            str_extract(ethnicity, " - (.+)$", group = 1L),
            NA_character_
          )
        ) |>
        rename(variable_a = ethnicity_group, variable_b = ethnicity) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Ethnic Group"
        )
    },
    sexual_orientation = if ("sexual_orientation" %in% breakdowns) {
      read_legacy_format_outcome_xlsx(
        xlsx_path,
        "Table 12b",
        dim_col = "sexual_orientation"
      ) |>
        rename(variable_a = sexual_orientation) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Sexual Orientation Type",
          variable_b = NA_character_
        )
    },
    disability = if ("disability" %in% breakdowns) {
      read_legacy_format_outcome_xlsx(
        xlsx_path,
        "Table 13b",
        dim_col = "disability"
      ) |>
        rename(variable_a = disability) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Disability Type",
          variable_b = NA_character_
        )
    },
    religion = if ("religion" %in% breakdowns) {
      read_legacy_format_outcome_xlsx(
        xlsx_path,
        "Table 14b",
        dim_col = "religion"
      ) |>
        rename(variable_a = religion) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Religion",
          variable_b = NA_character_
        )
    }
  )

  bind_rows(c(list(total), compact(breakdown_list)))
}

#' Extract measures for 2013-14 (XLSX)
#'
#' Sources: `Table 1a` (referrals), `Table 10a` (outcomes).
#' Breakdowns available: age_gender and ethnicity (both from `Table 17`).
#' `not_at_caseness` is derived as `finished_course - at_caseness` (not in
#' Table 10a).
#'
#' Table 10a column positions (with empty separator cols between groups):
#'   4 = at_caseness; 6/7 = improvement; 9/10 = no_reliable_change;
#'   12/13 = deterioration; 15/16 = recovery; 18/19 = reliable_recovery
#'
#' @param xlsx_path Character, specifying path to the XLSX file
#' @param breakdowns Character vector, specifying breakdown dimensions (e.g., `"age_gender"`, `"ethnicity"`)
#'
#' @return Tibble with Total + breakdown rows in wide format
#'
#' @importFrom tibble tibble
#' @importFrom readxl excel_sheets
#' @importFrom dplyr bind_rows filter group_by summarise rename mutate select
#' @importFrom purrr compact
#'
#' @keywords internal
extract_annual_legacy_format_2013_14 <- function(
  xlsx_path,
  breakdowns = character(0)
) {
  all_sheets <- excel_sheets(xlsx_path)
  sheet_10a <- all_sheets[grep("10a", all_sheets, ignore.case = TRUE)]

  table_1a <- read_legacy_format_row_xlsx(xlsx_path, "Table 1a")
  table_10a <- read_legacy_format_row_xlsx(xlsx_path, sheet_10a)

  finished_course <- table_1a[5]
  at_caseness <- table_10a[4]

  total <- tibble(
    org_type = "England",
    org_code = "All",
    org_name = "All",
    variable_type = "Total",
    variable_a = NA_character_,
    variable_b = NA_character_,
    count_referrals_received = table_1a[3],
    count_finished_course_treatment = finished_course,
    count_at_caseness = at_caseness,
    count_not_at_caseness = finished_course - at_caseness, # derived
    count_improvement = table_10a[6],
    percentage_improvement = table_10a[7],
    count_no_reliable_change = table_10a[9],
    percentage_no_reliable_change = table_10a[10],
    count_deterioration = table_10a[12],
    percentage_deterioration = table_10a[13],
    count_recovery = table_10a[15],
    percentage_recovery = table_10a[16],
    count_reliable_recovery = table_10a[18],
    percentage_reliable_recovery = table_10a[19]
  )

  # Table 17: female first (cols 6-10), male second (cols 12-16)
  if (any(c("age_gender", "ethnicity") %in% breakdowns)) {
    eth_ag <- read_legacy_format_ethnicity_age_gender_xlsx(
      xlsx_path,
      "Table 17",
      male_cols = 12:16,
      female_cols = 6:10
    )
    all_groups <- eth_ag |> filter(ethnicity == "All ethnic groups")
  }

  breakdown_list <- list(
    age_gender = if ("age_gender" %in% breakdowns) {
      age_rows <- all_groups |>
        filter(gender != "All", age_group != "All") |>
        group_by(age_group) |>
        summarise(
          count_referrals_received = sum(
            count_referrals_received,
            na.rm = TRUE
          ),
          .groups = "drop"
        ) |>
        rename(variable_a = age_group) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Age Group",
          variable_b = NA_character_
        )

      gender_rows <- all_groups |>
        filter(gender != "All") |>
        group_by(gender) |>
        summarise(
          count_referrals_received = sum(
            count_referrals_received,
            na.rm = TRUE
          ),
          .groups = "drop"
        ) |>
        rename(variable_a = gender) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Gender",
          variable_b = NA_character_
        )

      bind_rows(age_rows, gender_rows)
    },
    ethnicity = if ("ethnicity" %in% breakdowns) {
      eth_ag |>
        filter(
          gender == "All",
          age_group == "All",
          ethnicity != "All ethnic groups"
        ) |>
        select(ethnicity_group, ethnicity, count_referrals_received) |>
        rename(variable_a = ethnicity_group, variable_b = ethnicity) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Ethnic Group"
        )
    }
  )

  bind_rows(c(list(total), compact(breakdown_list)))
}

#' Extract measures for 2012-13 (XLSX)
#'
#' Sources: `Table_1a` (referrals), `Table_5a` (outcomes).
#' Breakdowns available: age_gender and ethnicity (both from `Table_8`).
#'
#' 2012-13 uses a 4-category outcome classification rather than the 5-category
#' structure used from 2013-14 onwards.  Official summary totals are used:
#'   col 18 = "Total recovered", col 19 = "Total improved",
#'   col 20 = "Total deteriorated".
#'
#' Percentage rates are omitted: 2012-13 uses `at_caseness` as denominator
#' rather than `finished_course` as in later years, making rates not directly
#' comparable.
#'
#' @param xlsx_path Character, specifying path to the XLSX file
#' @param breakdowns Character vector, specifying breakdown dimensions (e.g., `"age_gender"`, `"ethnicity"`)
#'
#' @return Tibble with Total + breakdown rows in wide format (count measures only)
#'
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows filter group_by summarise rename mutate select
#' @importFrom purrr compact
#'
#' @keywords internal
extract_annual_legacy_format_2012_13 <- function(
  xlsx_path,
  breakdowns = character(0)
) {
  table_1a <- read_legacy_format_row_xlsx(xlsx_path, "Table_1a")
  table_5a <- read_legacy_format_row_xlsx(xlsx_path, "Table_5a")

  finished_course <- table_1a[5]
  at_caseness <- table_5a[4]

  total <- tibble(
    org_type = "England",
    org_code = "All",
    org_name = "All",
    variable_type = "Total",
    variable_a = NA_character_,
    variable_b = NA_character_,
    count_referrals_received = table_1a[3],
    count_finished_course_treatment = finished_course,
    count_at_caseness = at_caseness,
    count_not_at_caseness = finished_course - at_caseness,
    # Rates omitted — see function documentation above
    count_improvement = table_5a[19],
    count_deterioration = table_5a[20],
    count_no_reliable_change = table_5a[6] + table_5a[9],
    count_recovery = table_5a[18],
    count_reliable_recovery = table_5a[15]
  )

  if (any(c("age_gender", "ethnicity") %in% breakdowns)) {
    # Table_8: male first (cols 7-11), female second (cols 13-17)
    eth_ag <- read_legacy_format_ethnicity_age_gender_xlsx(xlsx_path, "Table_8")
    all_groups <- eth_ag |> filter(ethnicity == "All ethnic groups")
  }

  breakdown_list <- list(
    age_gender = if ("age_gender" %in% breakdowns) {
      age_rows <- all_groups |>
        filter(gender != "All", age_group != "All") |>
        group_by(age_group) |>
        summarise(
          count_referrals_received = sum(
            count_referrals_received,
            na.rm = TRUE
          ),
          .groups = "drop"
        ) |>
        rename(variable_a = age_group) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Age Group",
          variable_b = NA_character_
        )

      gender_rows <- all_groups |>
        filter(gender != "All") |>
        group_by(gender) |>
        summarise(
          count_referrals_received = sum(
            count_referrals_received,
            na.rm = TRUE
          ),
          .groups = "drop"
        ) |>
        rename(variable_a = gender) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Gender",
          variable_b = NA_character_
        )

      bind_rows(age_rows, gender_rows)
    },
    ethnicity = if ("ethnicity" %in% breakdowns) {
      eth_ag |>
        filter(
          gender == "All",
          age_group == "All",
          ethnicity != "All ethnic groups"
        ) |>
        select(ethnicity_group, ethnicity, count_referrals_received) |>
        rename(variable_a = ethnicity_group, variable_b = ethnicity) |>
        mutate(
          org_type = "England",
          org_code = "All",
          org_name = "All",
          variable_type = "Ethnic Group"
        )
    }
  )

  bind_rows(c(list(total), compact(breakdown_list)))
}

#' Extract and combine all legacy-format annual periods (2012-13 to 2016-17)
#'
#' Downloads source files for each period, runs the appropriate bespoke
#' extractor, and returns a named list of wide-format tibbles.
#'
#' This is a developer tool called by `build_annual_legacy_format_measures()`.
#' It downloads ~15 MB of source files and takes ~30 seconds.
#'
#' @param breakdowns Character vector, specifying optional breakdown dimensions
#'   (e.g., `"age_gender"`, `"ethnicity"`, `"sexual_orientation"`,
#'   `"disability"`, `"religion"`, `"imd"`, `"ltc"`).
#'   Availability varies by year — see the file header table.
#'   Unavailable breakdowns are silently ignored.
#'
#' @return Named list of wide-format tibbles, one per reporting period
#'   (`"2012-13"` to `"2016-17"`).  Each tibble has columns
#'   `org_type`, `org_code`, `org_name`, `variable_type`, `variable_a`,
#'   `variable_b`, and the available measure columns.  Pass to
#'   `pivot_longer_measures()` to produce the final long-format schema.
#'
#' @importFrom cli cli_process_start cli_process_done
#'
#' @keywords internal
extract_annual_legacy_format <- function(
  breakdowns = c(
    "age_gender",
    "ethnicity",
    "sexual_orientation",
    "disability",
    "religion",
    "imd",
    "ltc"
  )
) {
  cli_process_start("Downloading legacy-format annual sources")

  zip_2016_17 <- download_annual_legacy_format_source("2016-17")
  on.exit(unlink(zip_2016_17), add = TRUE)

  zip_2015_16 <- download_annual_legacy_format_source("2015-16")
  on.exit(unlink(zip_2015_16), add = TRUE)

  xlsx_2014_15 <- download_annual_legacy_format_source("2014-15")
  on.exit(unlink(xlsx_2014_15), add = TRUE)

  xlsx_2013_14 <- download_annual_legacy_format_source("2013-14")
  on.exit(unlink(xlsx_2013_14), add = TRUE)

  xlsx_2012_13 <- download_annual_legacy_format_source("2012-13")
  on.exit(unlink(xlsx_2012_13), add = TRUE)

  cli_process_done()

  list(
    "2012-13" = extract_annual_legacy_format_2012_13(xlsx_2012_13, breakdowns),
    "2013-14" = extract_annual_legacy_format_2013_14(xlsx_2013_14, breakdowns),
    "2014-15" = extract_annual_legacy_format_2014_15(xlsx_2014_15, breakdowns),
    "2015-16" = extract_annual_legacy_format_2015_16(zip_2015_16, breakdowns),
    "2016-17" = extract_annual_legacy_format_2016_17(zip_2016_17, breakdowns)
  )
}
