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
  dataset <- "activity_performance"

  periods <- resolve_periods(periods, dataset, frequency)
  periods <- rev(periods)

  data_list <- map(
    periods,
    \(period) {
      if (use_cache && tidy_cache_exists(dataset, period, frequency)) {
        load_tidy_cache(dataset, period, frequency)
      } else {
        prepare_tidy_data(dataset, period, frequency)
      }
    }
  )

  list_rbind(data_list)
}
