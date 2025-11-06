# Declare global variables to avoid R CMD check NOTEs
utils::globalVariables(c("start_date", "end_date", "measure"))

#' Check if running in package build/check/documentation context
#'
#' Detects if the code is being executed during R CMD check, R CMD build,
#' or roxygen2 documentation generation.
#'
#' @return Logical, TRUE if in build/check/documentation context
#' @keywords internal
is_pkg_build_context <- function() {
  # Check R CMD check/build environment variables
  if (identical(Sys.getenv("_R_CHECK_PACKAGE_NAME_"), "nhstt") ||
      Sys.getenv("R_CMD") != "") {
    return(TRUE)
  }

  # Check package option set during .onLoad when roxygen2 is detected
  if (isTRUE(getOption("nhstt.quiet_data_errors", FALSE))) {
    return(TRUE)
  }

  FALSE
}

#' Detect if package is being loaded by roxygen2
#'
#' Checks the call stack for roxygen2 or as.list.environment calls,
#' which indicates documentation is being generated.
#'
#' @return Logical, TRUE if roxygen2 is in the call stack
#' @keywords internal
is_roxygen_context <- function() {
  call_stack <- sys.calls()
  any(vapply(call_stack, function(call) {
    if (length(call) > 0) {
      call_str <- paste(deparse(call[[1]]), collapse = "")
      grepl("roxygenise|roxygenize|as\\.list\\.environment", call_str)
    } else {
      FALSE
    }
  }, logical(1)))
}

.onAttach <- function(libname, pkgname) {
  if (!is_setup()) {
    msg <- cli::format_inline("nhstt: Data not yet downloaded\nRun {.code nhstt_setup()} to download NHS Talking Therapies data")
    packageStartupMessage(msg)
  } else {
    # Check for version updates
    outdated <- check_dataset_versions()
    if (length(outdated) > 0) {
      datasets_arg <- paste0('c("', paste(outdated, collapse = '", "'), '")')
      msg <- cli::format_inline("Update available for dataset{?s}: {.val {outdated}}\nRun {.code nhstt_setup(datasets = {datasets_arg})} to update")
      packageStartupMessage(msg)
    }
  }
}

.onLoad <- function(libname, pkgname) {
  # During roxygen2 documentation, suppress dataset errors to avoid breaking devtools
  if (is_roxygen_context()) {
    options(nhstt.quiet_data_errors = TRUE)
  }

  # Create active bindings for datasets
  create_dataset_bindings(pkgname)
}

#' Create active bindings for all datasets
#' @keywords internal
create_dataset_bindings <- function(pkgname) {
  datasets <- c("key_measures", "medication_status", "therapy_type", "effect_size")
  ns <- asNamespace(pkgname)

  for (ds in datasets) {
    # Check if binding already exists (avoid errors during devtools::load_all)
    if (exists(ds, envir = ns, inherits = FALSE)) {
      if (bindingIsActive(ds, ns)) {
        next  # Already has active binding, skip
      }
    }

    makeActiveBinding(
      sym = ds,
      fun = create_dataset_loader(ds),
      env = ns
    )
  }
}

#' Create a dataset loader function
#' @keywords internal
create_dataset_loader <- function(dataset_name) {
  force(dataset_name)
  function() {
    tryCatch(
      nhstt_data(dataset_name),
      error = function(e) {
        # Check if this is a "data not available" error
        is_data_error <- grepl("not found", e$message, ignore.case = TRUE) ||
          grepl("not yet downloaded", e$message, ignore.case = TRUE)

        if (is_data_error) {
          # During build/check/document, return NULL silently to avoid breaking devtools
          if (is_pkg_build_context()) {
            return(NULL)
          }

          # In normal usage, show helpful message
          cli::cli_abort(c(
            "{.field {dataset_name}} dataset not found",
            "i" = "Run {.code nhstt_setup()} to download NHS Talking Therapies data"
          ))
        }

        # Re-throw other errors (permissions, corrupt data, etc.)
        stop(e)
      }
    )
  }
}
