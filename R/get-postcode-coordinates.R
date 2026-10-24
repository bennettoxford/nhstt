#' Look up postcode coordinates from postcodes.io
#'
#' Developer tool, run as part of [build_metadata_providers()]. Looks up
#' current postcodes in batches. The bulk endpoint leaves out postcodes that
#' are no longer in use, so these are looked up one by one from the terminated
#' postcodes endpoint.
#'
#' @param postcodes Character vector, postcodes to look up
#'
#' @return Tibble with columns postcode, latitude, and longitude
#'
#' @keywords internal
get_postcode_coordinates <- function(postcodes) {
  postcodes <- unique(postcodes[!is.na(postcodes)])

  # postcodes.io accepts at most 100 postcodes per bulk request
  batches <- split(postcodes, ceiling(seq_along(postcodes) / 100))

  coordinates <- purrr::map(batches, \(batch) {
    results <- httr2::request("https://api.postcodes.io/postcodes") |>
      httr2::req_body_json(list(postcodes = as.list(batch))) |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_perform() |>
      httr2::resp_body_json()

    purrr::map(results$result, \(x) {
      tibble::tibble(
        postcode = x$query,
        latitude = x$result$latitude %||% NA_real_,
        longitude = x$result$longitude %||% NA_real_
      )
    }) |>
      purrr::list_rbind()
  }) |>
    purrr::list_rbind()

  not_found <- coordinates$postcode[is.na(coordinates$latitude)]

  terminated <- purrr::map(not_found, \(postcode) {
    resp <- httr2::request("https://api.postcodes.io/terminated_postcodes") |>
      httr2::req_url_path_append(gsub(" ", "", postcode)) |>
      httr2::req_error(is_error = \(resp) FALSE) |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_perform()

    result <- if (httr2::resp_status(resp) == 200) {
      httr2::resp_body_json(resp)$result
    }

    tibble::tibble(
      postcode = postcode,
      latitude = result$latitude %||% NA_real_,
      longitude = result$longitude %||% NA_real_
    )
  }) |>
    purrr::list_rbind()

  coordinates <- coordinates |>
    dplyr::filter(!is.na(latitude)) |>
    dplyr::bind_rows(terminated)

  n_missing <- sum(is.na(coordinates$latitude))
  if (n_missing > 0) {
    cli::cli_warn("No coordinates found for {n_missing} postcode{?s}")
  }

  coordinates
}
