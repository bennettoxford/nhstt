#' Get provider organisation metadata
#'
#' Organisation details for every provider in the annual reports, from the
#' NHS Organisation Data Service (ODS).
#'
#' @inheritParams get_measures_annual
#'
#' @return Tibble with provider organisation metadata. Latitude and longitude
#'   come from each provider's postcode, looked up on
#'   [postcodes.io](https://postcodes.io/). `retrieved_date` is the day the
#'   data was taken from ODS. `*_last_reported` is the last period each
#'   provider appears in the annual, quarterly, and monthly data.
#'   `*_latest_period` is the latest period in that data.
#'
#' @export
#' @examples
#' \dontrun{
#' # Get provider metadata
#' nhstt_providers <- get_metadata_providers()
#' }
get_metadata_providers <- function(use_cache = TRUE, version = NULL) {
  get_tidy_dataset(
    "metadata_providers",
    use_cache = use_cache,
    version = version
  )
}

#' Build provider organisation metadata from ODS
#'
#' Developer tool, run as part of [build_tidy_data()]. Looks up
#' every provider in the published annual measures in ODS, adds latitude and
#' longitude for each postcode, and adds the last period each provider
#' reported in the annual, quarterly, and monthly data.
#'
#' @return Tibble with provider organisation metadata
#'
#' @keywords internal
build_metadata_providers <- function() {
  measures_annual <- get_measures_annual()

  provider_codes <- measures_annual |>
    dplyr::filter(org_type == "Provider") |>
    dplyr::distinct(org_code) |>
    dplyr::pull(org_code)

  provider_ods_data <- get_ods_data(provider_codes, add_names = TRUE)

  provider_ods_data |>
    dplyr::mutate(
      org_name = clean_org_names(org_name),
      town = stringr::str_to_title(town),
      region_name = clean_org_names(
        stringr::str_replace_all(region_name, " COMMISSIONING REGION", "")
      ),
      icb_name = clean_org_names(
        stringr::str_replace_all(icb_name, " INTEGRATED CARE BOARD", "")
      ),
      # ODS is a live service, so status reflects the day the data was pulled
      retrieved_date = Sys.Date()
    ) |>
    dplyr::left_join(
      get_postcode_coordinates(provider_ods_data$postcode),
      by = "postcode"
    ) |>
    dplyr::select(
      org_code,
      org_name,
      status,
      start_date,
      end_date,
      postcode,
      latitude,
      longitude,
      town,
      icb_code,
      icb_name,
      region_code,
      region_name,
      retrieved_date
    ) |>
    add_provider_reporting(
      measures_annual,
      get_measures_quarterly(),
      get_measures_monthly()
    )
}

#' Add the last period each provider reported
#'
#' For each of the annual, quarterly, and monthly datasets, adds the last
#' period a provider appears in (`*_last_reported`, NA if never) and the
#' latest period in the whole dataset (`*_latest_period`).
#'
#' Developer tool, run as part of [build_metadata_providers()].
#'
#' @param providers Tibble, providers with an `org_code` column
#' @param measures_annual Tibble, as returned by [get_measures_annual()]
#' @param measures_quarterly Tibble, as returned by [get_measures_quarterly()]
#' @param measures_monthly Tibble, as returned by [get_measures_monthly()]
#'
#' @return `providers` with six added columns
#'
#' @keywords internal
add_provider_reporting <- function(
  providers,
  measures_annual,
  measures_quarterly,
  measures_monthly
) {
  # Each dataset stores provider codes in a different column
  provider_periods <- list(
    annual = measures_annual |>
      dplyr::filter(org_type == "Provider") |>
      dplyr::select(org_code, reporting_period),
    quarterly = measures_quarterly |>
      dplyr::filter(org_type %in% c("Provider", "SubICB-Provider")) |>
      dplyr::select(org_code = provider_code, reporting_period),
    monthly = measures_monthly |>
      dplyr::filter(group_type %in% c("Provider", "SubICB/Provider")) |>
      dplyr::select(org_code = org_code2, reporting_period)
  )

  last_reported <- purrr::imap(provider_periods, \(periods, frequency) {
    periods |>
      dplyr::summarise(
        "{frequency}_last_reported" := max(reporting_period),
        .by = org_code
      )
  }) |>
    purrr::reduce(dplyr::full_join, by = "org_code")

  # Period strings sort in time order, so max() gives the latest period
  providers |>
    dplyr::left_join(last_reported, by = "org_code") |>
    dplyr::mutate(
      annual_latest_period = max(measures_annual$reporting_period),
      quarterly_latest_period = max(measures_quarterly$reporting_period),
      monthly_latest_period = max(measures_monthly$reporting_period)
    )
}
