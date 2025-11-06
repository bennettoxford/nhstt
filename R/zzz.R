# Declare global variables to avoid R CMD check NOTEs
utils::globalVariables(c("start_date", "end_date", "measure"))

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
        # During package build/documentation, data may not be available
        # Return NULL silently to avoid breaking devtools::document()
        # This catches all data availability errors but re-throws other errors
        if (grepl("not found", e$message, ignore.case = TRUE) ||
            grepl("not yet downloaded", e$message, ignore.case = TRUE)) {
          return(NULL)
        }
        # Re-throw other errors (permissions, corrupt data, etc.)
        stop(e)
      }
    )
  }
}
