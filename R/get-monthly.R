#' Get monthly activity and performance measures
#'
#' Get monthly activity and performance indicators by organisation.
#'
#' @param periods Character vector, specifying periods (e.g., "2025-09", "2025-08").
#' If NULL (default), returns all available monthly periods
#' @param use_cache Logical, specifying whether to use cached data if available. Default TRUE.
#' @param version Character, specifying a pinned data version (e.g., "0.3.0").
#' If NULL (default), the latest version is used. See [available_versions()].
#'
#' @return Tibble with activity and performance data in long format
#'
#' @references
#' NHS England.
#' \href{https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-monthly-statistics-including-employment-advisors}{NHS Talking Therapies Monthly Statistics Including Employment Advisors}
#'
#' NHS England.
#' \href{https://digital.nhs.uk/binaries/content/assets/website-assets/data-and-information/datasets/nhs-talking-therapies/nhs_talking_therapies_dq_note-260327.xlsx}{NHS Talking Therapies Data Quality Note (monthly, quarterly)}
#'
#' @export
#' @examples
#' \dontrun{
#' # Get all monthly periods
#' measures_df <- get_measures_monthly()
#'
#' # Get specific monthly periods
#' measures_df <- get_measures_monthly(periods = c("2025-09", "2025-08"))
#'
#' # Re-download to get the latest data version
#' measures_df <- get_measures_monthly(use_cache = FALSE)
#'
#' # Pin to a specific data version for reproducibility
#' measures_df <- get_measures_monthly(version = "0.3.0")
#' }
get_measures_monthly <- function(
  periods = NULL,
  use_cache = TRUE,
  version = NULL
) {
  get_tidy_dataset("measures_monthly", periods, use_cache, version)
}

#' Get monthly metadata for NHS Talking Therapies measures
#'
#' Gets the definitions, derivations, and construction notes for each
#' reported measure.
#'
#' @inheritParams get_measures_monthly
#'
#' @return Tibble with metadata for each measure
#'
#' @references
#' NHS England.
#' \href{https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-monthly-statistics-including-employment-advisors}{NHS Talking Therapies Monthly Statistics Including Employment Advisors}
#'
#' NHS England.
#' \href{https://digital.nhs.uk/binaries/content/assets/website-assets/data-and-information/datasets/nhs-talking-therapies/reports/nhstalkingtherapies-monthly-metadata-20260511.xlsx}{NHS Talking Therapies Monthly Statistics Including Employment Advisors: Metadata (monthly)}
#'
#' NHS England.
#' \href{https://digital.nhs.uk/binaries/content/assets/website-assets/data-and-information/datasets/nhs-talking-therapies/nhs_talking_therapies_dq_note-260327.xlsx}{NHS Talking Therapies Data Quality Note}
#'
#' @export
#' @examples
#' \dontrun{
#' metadata <- get_metadata_monthly()
#' }
get_metadata_monthly <- function(
  periods = NULL,
  use_cache = TRUE,
  version = NULL
) {
  get_tidy_dataset("metadata_measures_monthly", periods, use_cache, version)
}
