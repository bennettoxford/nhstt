#' Get annual metadata for data measures
#'
#' Combines the "Data measures (main)" and "Data measures (additional)"
#' sheets released alongside the annual NHS Talking Therapies reports.
#'
#' @references
#' NHS England.
#' \href{https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports}{NHS Talking Therapies for Anxiety and Depression Annual Reports}
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
  get_tidy_dataset("metadata_measures_annual", periods, use_cache)
}

#' Get annual metadata for variable derivations
#'
#' Combines the "Variables (main)" and "Variables (additional)" sheets
#' released alongside the annual NHS Talking Therapies reports.
#'
#' @references
#' NHS England.
#' \href{https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports}{NHS Talking Therapies for Anxiety and Depression Annual Reports}
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
  get_tidy_dataset("metadata_variables_annual", periods, use_cache)
}
