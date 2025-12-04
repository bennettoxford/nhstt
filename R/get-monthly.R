#' Get monthly activity and performance measures
#'
#' Get monthly activity and performance indicators by organisation.
#'
#' @param periods Character vector, specifying periods (e.g., "2025-09", "2025-08").
#' If NULL (default), returns all available monthly periods
#' @param use_cache Logical, specifying whether to use cached data if available. Default TRUE.
#'
#' @return Tibble with activity and performance data in long format
#'
#' @details
#' Raw data is automatically stored in parquet format for efficient compression.
#'
#' @importFrom purrr map list_rbind
#'
#' @export
#' @examples
#' \dontrun{
#' # Get all monthly periods
#' activity_df <- get_activity_performance_monthly()
#'
#' # Get specific monthly periods
#' activity_df <- get_activity_performance_monthly(periods = c("2025-09", "2025-08"))
#'
#' # Bypass cache to use latest tidying logic
#' activity_df <- get_activity_performance_monthly(periods = "2025-09", use_cache = FALSE)
#' }
get_activity_performance_monthly <- function(
  periods = NULL,
  use_cache = TRUE
) {
  frequency <- "monthly"
  dataset <- "activity_performance_monthly"

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

#' Get monthly metadata for NHS Talking Therapies measures
#'
#' Retrieves the definitions, derivations, and construction notes for each
#' reported measure.
#'
#' @inheritParams get_activity_performance_monthly
#'
#' @return Tibble with metadata for each measure
#'
#' @details
#' Raw data is stored in parquet format for efficient compression.
#'
#' If network download fails (e.g., in GitHub Actions), falls back to bundled
#' metadata shipped with the package. This is a temporary workaround for
#' `digital.nhs.uk` blocking CI environments.
#'
#' @importFrom purrr map list_rbind
#' @importFrom arrow read_parquet
#' @importFrom cli cli_alert_warning
#'
#' @export
#' @examples
#' \dontrun{
#' metadata <- get_metadata_monthly()
#' }
get_metadata_monthly <- function(
  periods = NULL,
  use_cache = TRUE
) {
  frequency <- "monthly"
  dataset <- "metadata_measures_monthly"

  periods <- resolve_periods(periods, dataset, frequency)
  periods <- rev(periods)

  data_list <- map(
    periods,
    \(period) {
      if (use_cache && tidy_cache_exists(dataset, period, frequency)) {
        load_tidy_cache(dataset, period, frequency)
      } else {
        tryCatch(
          {
            download_and_tidy(dataset, period, frequency)
          },
          error = function(e) {
            package_path <- get_package_data_path(dataset, period, frequency)
            if (!is.null(package_path)) {
              cli_alert_warning(
                "Download failed, using package metadata for {period}"
              )
              read_parquet(package_path)
            } else {
              stop(e)
            }
          }
        )
      }
    }
  )

  list_rbind(data_list)
}
