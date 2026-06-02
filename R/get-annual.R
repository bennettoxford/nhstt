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
#' @references
#' NHS England.
#' \href{https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports}{NHS Talking Therapies for Anxiety and Depression Annual Reports}
#'
#' @importFrom dplyr filter arrange desc
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
#' # Re-download to get the latest data version
#' key_measures_df <- get_key_measures_annual(use_cache = FALSE)
#' }
get_key_measures_annual <- function(
  periods = NULL,
  use_cache = TRUE
) {
  dataset <- "key_measures_annual"

  if (!is.null(periods)) {
    periods <- resolve_periods(periods, dataset, "annual")
  }

  cfg <- get_tidy_source_config(dataset)

  if (!use_cache || !tidy_source_cache_is_current(dataset, cfg$version)) {
    download_tidy_source(dataset, cfg$url, cfg$version)
  }

  data <- load_tidy_source(dataset)

  if (!is.null(periods)) {
    data <- filter(data, reporting_period %in% periods)
  }

  arrange(data, desc(reporting_period))
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
#' @references
#' NHS England.
#' \href{https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports}{NHS Talking Therapies for Anxiety and Depression Annual Reports}
#'
#' @importFrom dplyr filter arrange desc
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
#' # Re-download to get the latest data version
#' proms_df <- get_proms_annual(use_cache = FALSE)
#' }
get_proms_annual <- function(
  periods = NULL,
  use_cache = TRUE
) {
  dataset <- "proms_annual"

  if (!is.null(periods)) {
    periods <- resolve_periods(periods, dataset, "annual")
  }

  cfg <- get_tidy_source_config(dataset)

  if (!use_cache || !tidy_source_cache_is_current(dataset, cfg$version)) {
    download_tidy_source(dataset, cfg$url, cfg$version)
  }

  data <- load_tidy_source(dataset)

  if (!is.null(periods)) {
    data <- filter(data, reporting_period %in% periods)
  }

  arrange(data, desc(reporting_period))
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
#' @references
#' NHS England.
#' \href{https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports}{NHS Talking Therapies for Anxiety and Depression Annual Reports}
#'
#' @importFrom dplyr filter arrange desc
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
#' # Re-download to get the latest data version
#' therapy_position_df <- get_therapy_position_annual(use_cache = FALSE)
#' }
get_therapy_position_annual <- function(
  periods = NULL,
  use_cache = TRUE
) {
  dataset <- "therapy_position_annual"

  if (!is.null(periods)) {
    periods <- resolve_periods(periods, dataset, "annual")
  }

  cfg <- get_tidy_source_config(dataset)

  if (!use_cache || !tidy_source_cache_is_current(dataset, cfg$version)) {
    download_tidy_source(dataset, cfg$url, cfg$version)
  }

  data <- load_tidy_source(dataset)

  if (!is.null(periods)) {
    data <- filter(data, reporting_period %in% periods)
  }

  arrange(data, desc(reporting_period))
}
