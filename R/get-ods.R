#' Fetch ODS organisation data
#' @keywords internal
#' @importFrom stats setNames
get_ods_data <- function(org_codes, add_names = TRUE) {
  base_url <- "https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations"
  result_list <- list()
  org_data_cache <- list()

  # Fetch each organisation
  for (code in org_codes) {
    tryCatch(
      {
        resp <- httr2::request(base_url) |>
          httr2::req_url_path_append(code) |>
          httr2::req_retry(max_tries = 3) |>
          httr2::req_perform()

        if (httr2::resp_status(resp) != 200) {
          next
        }

        org_data <- httr2::resp_body_json(resp)
        org_data_cache[[code]] <- org_data
        o <- org_data$Organisation

        # Extract operational dates
        start_date <- NA_character_
        end_date <- NA_character_
        if (!is.null(o$Date)) {
          for (d in o$Date) {
            if (d$Type == "Operational") {
              start_date <- d$Start %||% NA_character_
              end_date <- d$End %||% NA_character_
              break
            }
          }
        }

        # Extract primary role
        primary_role <- NA_character_
        if (!is.null(o$Roles$Role)) {
          for (r in o$Roles$Role) {
            if (isTRUE(r$primaryRole)) {
              primary_role <- r$id %||% NA_character_
              break
            }
          }
        }

        # Extract ICB code (RO261 relationship)
        icb_code <- NA_character_
        if (!is.null(o$Rels$Rel)) {
          for (rel in o$Rels$Rel) {
            if (
              rel$Status == "Active" &&
                !is.null(rel$Target$PrimaryRoleId$id) &&
                rel$Target$PrimaryRoleId$id == "RO261"
            ) {
              icb_code <- rel$Target$OrgId$extension %||% NA_character_
              break
            }
          }
        }

        result_list[[code]] <- tibble::tibble(
          org_code = o$OrgId$extension %||% NA_character_,
          org_name = o$Name %||% NA_character_,
          status = o$Status %||% NA_character_,
          start_date = start_date,
          end_date = end_date,
          postcode = o$GeoLoc$Location$PostCode %||% NA_character_,
          town = o$GeoLoc$Location$Town %||% NA_character_,
          icb_code = icb_code,
          region_code = NA_character_,
          primary_role = primary_role
        )
      },
      error = function(e) NULL
    )
  }

  if (length(result_list) == 0) {
    return(tibble::tibble())
  }

  result <- dplyr::bind_rows(result_list)

  # Fill in missing ICB codes by checking parent organizations
  missing_icb_rows <- which(is.na(result$icb_code))

  for (i in missing_icb_rows) {
    code <- result$org_code[i]
    cached_data <- org_data_cache[[code]]

    if (is.null(cached_data)) {
      next
    }

    tryCatch(
      {
        # Look for parent organization (RE6 "is operated by" relationship)
        parent_code <- NA_character_
        if (!is.null(cached_data$Organisation$Rels$Rel)) {
          for (rel in cached_data$Organisation$Rels$Rel) {
            if (rel$id == "RE6" && rel$Status == "Active") {
              parent_code <- rel$Target$OrgId$extension %||% NA_character_
              break
            }
          }
        }

        # If we found a parent, fetch its ICB code
        if (!is.na(parent_code)) {
          parent_resp <- httr2::request(base_url) |>
            httr2::req_url_path_append(parent_code) |>
            httr2::req_retry(max_tries = 3) |>
            httr2::req_perform()

          if (httr2::resp_status(parent_resp) == 200) {
            parent_data <- httr2::resp_body_json(parent_resp)

            # Extract ICB code from parent
            parent_icb <- NA_character_
            if (!is.null(parent_data$Organisation$Rels$Rel)) {
              for (rel in parent_data$Organisation$Rels$Rel) {
                if (
                  rel$Status == "Active" &&
                    !is.null(rel$Target$PrimaryRoleId$id) &&
                    rel$Target$PrimaryRoleId$id == "RO261"
                ) {
                  parent_icb <- rel$Target$OrgId$extension %||% NA_character_
                  break
                }
              }
            }

            # Update the result
            if (!is.na(parent_icb)) {
              result$icb_code[i] <- parent_icb
            }
          }
        }
      },
      error = function(e) NULL
    )
  }

  # Add hierarchy names if requested
  if (add_names) {
    # Get region codes from ICBs
    unique_icbs <- unique(result$icb_code[!is.na(result$icb_code)])

    for (icb_code in unique_icbs) {
      tryCatch(
        {
          resp <- httr2::request(base_url) |>
            httr2::req_url_path_append(icb_code) |>
            httr2::req_retry(max_tries = 3) |>
            httr2::req_perform()

          if (httr2::resp_status(resp) == 200) {
            icb_data <- httr2::resp_body_json(resp)

            # Extract region code (RO209 relationship)
            region_code <- NA_character_
            if (!is.null(icb_data$Organisation$Rels$Rel)) {
              for (rel in icb_data$Organisation$Rels$Rel) {
                if (
                  rel$Status == "Active" &&
                    !is.null(rel$Target$PrimaryRoleId$id) &&
                    rel$Target$PrimaryRoleId$id == "RO209"
                ) {
                  region_code <- rel$Target$OrgId$extension %||% NA_character_
                  break
                }
              }
            }

            result$region_code[result$icb_code == icb_code] <- region_code
          }
        },
        error = function(e) NULL
      )
    }

    # Fetch names for ICBs and regions
    all_codes <- unique(c(result$icb_code, result$region_code))
    all_codes <- all_codes[!is.na(all_codes)]

    names_lookup <- setNames(rep(NA_character_, length(all_codes)), all_codes)

    for (code in all_codes) {
      tryCatch(
        {
          resp <- httr2::request(base_url) |>
            httr2::req_url_path_append(code) |>
            httr2::req_retry(max_tries = 3) |>
            httr2::req_perform()

          if (httr2::resp_status(resp) == 200) {
            org_data <- httr2::resp_body_json(resp)
            names_lookup[code] <- org_data$Organisation$Name %||% NA_character_
          }
        },
        error = function(e) NULL
      )
    }

    result$icb_name <- unname(names_lookup[result$icb_code])
    result$region_name <- unname(names_lookup[result$region_code])
  }

  result
}

#' Get organisation roles
#' @keywords internal
get_org_types <- function(org_codes) {
  if (is.data.frame(org_codes)) {
    org_codes <- org_codes$org_code
  }

  base_url <- "https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations"
  result_list <- list()

  for (code in org_codes) {
    tryCatch(
      {
        resp <- httr2::request(base_url) |>
          httr2::req_url_path_append(code) |>
          httr2::req_retry(max_tries = 3) |>
          httr2::req_perform()

        if (httr2::resp_status(resp) != 200) {
          next
        }

        org_data <- httr2::resp_body_json(resp)
        org_code <- org_data$Organisation$OrgId$extension %||% NA_character_

        if (!is.null(org_data$Organisation$Roles$Role)) {
          for (r in org_data$Organisation$Roles$Role) {
            result_list[[length(result_list) + 1]] <- tibble::tibble(
              org_code = org_code,
              role_id = r$id %||% NA_character_,
              is_primary = isTRUE(r$primaryRole),
              status = r$Status %||% NA_character_
            )
          }
        }
      },
      error = function(e) NULL
    )
  }

  if (length(result_list) == 0) {
    return(tibble::tibble())
  }

  dplyr::bind_rows(result_list)
}
