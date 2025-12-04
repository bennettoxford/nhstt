#' Helper to load and combine main and additional metadata sheets
#'
#' @param dataset_base Base name ("metadata_measures" or "metadata_variables")
#' @param period Reporting period
#' @param frequency Frequency ("annual")
#' @param use_cache Whether to use cache
#'
#' @return Combined tibble
#' @keywords internal
load_combined_metadata <- function(dataset_base, period, frequency, use_cache) {
  dataset_main <- paste0(dataset_base, "_main_", frequency)
  dataset_additional <- paste0(dataset_base, "_additional_", frequency)

  main_df <- if (
    use_cache && tidy_cache_exists(dataset_main, period, frequency)
  ) {
    load_tidy_cache(dataset_main, period, frequency)
  } else {
    download_and_tidy(dataset_main, period, frequency)
  }

  additional_df <- if (
    use_cache && tidy_cache_exists(dataset_additional, period, frequency)
  ) {
    load_tidy_cache(dataset_additional, period, frequency)
  } else {
    download_and_tidy(dataset_additional, period, frequency)
  }

  list_rbind(list(main_df, additional_df))
}

#' Get annual metadata for data measures
#'
#' Combines the "Data measures (main)" and "Data measures (additional)"
#' sheets released alongside the annual NHS Talking Therapies reports.
#'
#' @inheritParams get_key_measures_annual
#'
#' @return Tibble containing metadata rows for each annual measure field
#' @export
#' @examples
#' \dontrun{
#' measures_meta <- get_metadata_measures_annual()
#' }
get_metadata_measures_annual <- function(
  periods = NULL,
  use_cache = TRUE
) {
  frequency <- "annual"
  dataset_base <- "metadata_measures"

  periods <- resolve_periods(
    periods,
    paste0(dataset_base, "_main_", frequency),
    frequency
  )
  periods <- rev(periods)

  data_list <- map(
    periods,
    \(period) load_combined_metadata(dataset_base, period, frequency, use_cache)
  )

  list_rbind(data_list)
}

#' Get annual metadata for variable derivations
#'
#' Combines the "Variables (main)" and "Variables (additional)" sheets
#' released alongside the annual NHS Talking Therapies reports.
#'
#' @inheritParams get_key_measures_annual
#'
#' @return Tibble containing metadata rows for each annual variable definition
#' @export
#' @examples
#' \dontrun{
#' variables_meta <- get_metadata_variables_annual()
#' }
get_metadata_variables_annual <- function(
  periods = NULL,
  use_cache = TRUE
) {
  frequency <- "annual"
  dataset_base <- "metadata_variables"

  periods <- resolve_periods(
    periods,
    paste0(dataset_base, "_main_", frequency),
    frequency
  )
  periods <- rev(periods)

  data_list <- map(
    periods,
    \(period) load_combined_metadata(dataset_base, period, frequency, use_cache)
  )

  list_rbind(data_list)
}
