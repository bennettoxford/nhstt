#' Get annual key performance measures
#'
#' Get annual key performance measures including referrals, assessments,
#' treatment completions, recovery rates, and waiting times by organisation
#'
#' @param periods Character vector, specifying periods (e.g., "2023-24", "2024-25").
#' If NULL (default), returns all available annual periods
#' @param use_cache Logical, specifying whether to use cached data if available. Default TRUE.
#'
#' @return Tibble with key measures data in long format
#'
#' @details
#' Raw data is automatically stored in parquet format for efficient compression.
#'
#' @importFrom purrr map list_rbind
#'
#' @export
#' @examples
#' \dontrun{
#' # Get all annual periods
#' key_measures_df <- get_key_measures_annual()
#'
#' # Get specific annual periods
#' key_measures_df <- get_key_measures_annual(periods = c("2023-24", "2024-25"))
#'
#' # Bypass cache to use latest tidying logic
#' key_measures_df <- get_key_measures_annual(periods = "2023-24", use_cache = FALSE)
#' }
get_key_measures_annual <- function(
  periods = NULL,
  use_cache = TRUE
) {
  frequency <- "annual"
  dataset <- "key_measures_annual"

  periods <- resolve_periods(periods, dataset, frequency)
  periods <- rev(periods)

  data_list <- map(
    periods,
    \(period) {
      if (use_cache && tidy_cache_exists(dataset, period, frequency)) {
        load_tidy_cache(dataset, period, frequency)
      } else {
        download_and_tidy(dataset, period, frequency)
      }
    }
  )

  list_rbind(data_list)
}

#' Get annual Patient Reported Outcome measures (PROMs)
#'
#' Get annual Patient Reported Outcome Measures (PROMs) mean and SD broken down by
#' therapy type, problem descriptor, and providers.
#'
#' @param periods Character vector, specifying periods (e.g., "2023-24", "2024-25").
#' If NULL (default), returns all available annual periods
#' @param use_cache Logical, specifying whether to use cached data if available. Default TRUE.
#'
#' @return Tibble with key measures data in long format
#'
#' @details
#' Raw data is automatically stored in parquet format for efficient compression.
#'
#' @importFrom purrr map list_rbind
#'
#' @export
#' @examples
#' \dontrun{
#' # Get all annual periods
#' proms_df <- get_proms_annual()
#'
#' # Get specific annual periods
#' proms_df <- get_proms_annual(periods = c("2023-24", "2024-25"))
#'
#' # Bypass cache to use latest tidying logic
#' proms_df <- get_proms_annual(periods = "2023-24", use_cache = FALSE)
#' }
get_proms_annual <- function(
  periods = NULL,
  use_cache = TRUE
) {
  frequency <- "annual"
  dataset <- "proms_annual"

  periods <- resolve_periods(periods, dataset, frequency)
  periods <- rev(periods)

  data_list <- map(
    periods,
    \(period) {
      if (use_cache && tidy_cache_exists(dataset, period, frequency)) {
        load_tidy_cache(dataset, period, frequency)
      } else {
        download_and_tidy(dataset, period, frequency)
      }
    }
  )

  list_rbind(data_list)
}

#' Get position of therapy types within the referral pathways
#'
#' Get the number of courses of therapy by therapy type and position within the referral pathway.
#' A course of therapy is a set of 2 or more attended treatment appointments where the same therapy type is recorded that occur within a referral pathway.
#' Counts are based on referrals finishing a course of treatment in the year.
#' Other low/high internsity and low/high employment support therapy types have been excluded from theses analyses.
#'
#' @param periods Character vector, specifying periods (e.g., "2023-24", "2024-25").
#' If NULL (default), returns all available annual periods
#' @param use_cache Logical, specifying whether to use cached data if available. Default TRUE.
#'
#' @return Tibble with key measures data in long format
#'
#' @details
#' Raw data is automatically stored in parquet format for efficient compression.
#'
#' @importFrom purrr map list_rbind
#'
#' @export
#' @examples
#' \dontrun{
#' # Get all annual periods
#' therapy_position_df <- get_therapy_position_annual()
#'
#' # Get specific annual periods
#' therapy_position_df <- get_therapy_position_annual(periods = c("2023-24", "2024-25"))
#'
#' # Bypass cache to use latest tidying logic
#' therapy_position_df <- get_therapy_position_annual(periods = "2023-24", use_cache = FALSE)
#' }
get_therapy_position_annual <- function(
  periods = NULL,
  use_cache = TRUE
) {
  frequency <- "annual"
  dataset <- "therapy_position_annual"

  periods <- resolve_periods(periods, dataset, frequency)
  periods <- rev(periods)

  data_list <- map(
    periods,
    \(period) {
      if (use_cache && tidy_cache_exists(dataset, period, frequency)) {
        load_tidy_cache(dataset, period, frequency)
      } else {
        download_and_tidy(dataset, period, frequency)
      }
    }
  )

  list_rbind(data_list)
}
