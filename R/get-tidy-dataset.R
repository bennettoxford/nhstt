#' Get a pre-built tidy dataset
#'
#' Shared core for all user-facing `get_*()` functions. Looks up the dataset
#' in `tidy_data_sources.yml`, downloads the pre-built parquet from the
#' GitHub Release if the cache is missing or stale, and filters to the
#' requested periods.
#'
#' Requested periods are validated against the periods actually present in
#' the downloaded data, so a period that exists in the developer config but
#' not yet in the published parquet raises an error instead of silently
#' returning zero rows.
#'
#' @param dataset Character, dataset name as listed in tidy_data_sources.yml
#' @param periods Character vector of periods, or NULL for all periods
#' @param use_cache Logical, whether to use cached data if available
#'
#' @return Tibble, ordered most-recent period first
#'
#' @importFrom dplyr filter arrange desc
#' @importFrom cli cli_abort
#'
#' @keywords internal
get_tidy_dataset <- function(dataset, periods = NULL, use_cache = TRUE) {
  cfg <- get_tidy_source_config(dataset)

  if (!use_cache || !tidy_source_cache_is_current(dataset, cfg$version)) {
    download_tidy_source(dataset, cfg$url, cfg$version)
  }

  data <- load_tidy_source(dataset)

  if (!is.null(periods)) {
    available <- sort(unique(data$reporting_period), decreasing = TRUE)
    unknown <- setdiff(periods, available)
    if (length(unknown) > 0) {
      cli_abort(c(
        "Period{?s} not available: {.val {unknown}}",
        "i" = "Available periods for {.val {dataset}}: {.val {available}}"
      ))
    }
    data <- filter(data, reporting_period %in% periods)
  }

  arrange(data, desc(reporting_period))
}
