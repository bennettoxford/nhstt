#' Get data source links for annual reports
#'
#' URLs for annual report zip files. Each zip contains multiple CSV files.
#'
#' @return Named list of URLs by period
#' @keywords internal
get_annual_report_links <- function() {
  list(
    "fy1718" = "https://files.digital.nhs.uk/82/2CCBED/psych-ther-ann-2017-18-csvs.zip",
    "fy1819" = "https://files.digital.nhs.uk/88/EBA9A6/psych-ther-ann-2018-19-csvs.rar",
    "fy1920" = "https://files.digital.nhs.uk/1A/F2ABB3/psych-ther-ann-2019-20-csvs.zip",
    "fy2021" = "https://files.digital.nhs.uk/62/DBF395/psych-ther-ann-rep-csvs-2020-21.zip",
    "fy2122" = "https://files.digital.nhs.uk/DC/9E8751/psych-ther-ann-rep-csvs-2021-22.zip",
    "fy2223" = "https://files.digital.nhs.uk/CA/8F53D1/psych-ther-ann-rep-csvs-2022-23.zip",
    "fy2324" = "https://files.digital.nhs.uk/4E/6D88C2/psych-ther-ann-rep-csvs-2023-24.zip",
    "fy2425" = "https://files.digital.nhs.uk/4E/2104A0/psych-ther-ann-rep-csv-2024-25-2.zip"
  )
}

#' Get data source links for metadata files
#'
#' URLs for metadata Excel files (one per period).
#' Placeholder for future implementation.
#'
#' @return Named list of URLs by period
#' @keywords internal
get_metadata_links <- function() {
  list()
}

#' Get all source links by type
#'
#' @param source_type Character, the type of source
#' @return Named list of URLs
#' @keywords internal
get_source_links <- function(source_type) {
  switch(source_type,
    "annual_reports" = get_annual_report_links(),
    "metadata" = get_metadata_links(),
    stop("Unknown source type: ", source_type)
  )
}

#' Get available periods for a source type
#'
#' @param source_type Character, the data source type
#' @return Character vector of available periods
#' @keywords internal
get_available_periods <- function(source_type = "annual_reports") {
  links <- get_source_links(source_type)

  if (length(links) == 0) {
    cli::cli_abort(c(
      "No data available for source type: {.val {source_type}}",
      "i" = "This may not be implemented yet"
    ))
  }

  names(links)
}

#' Get package version
#'
#' @return Character, package version string
#' @keywords internal
get_package_version <- function() {
  as.character(utils::packageVersion("nhstt"))
}
