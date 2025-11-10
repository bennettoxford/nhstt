# Package hooks

#' Package attach hook
#'
#' Silently sets up package on first load, only shows message if initialization fails
#'
#' @param libname Library name
#' @param pkgname Package name
#' @keywords internal
.onAttach <- function(libname, pkgname) {
  pkg_version <- utils::packageVersion("nhstt")

  cache_dir <- get_cache_dir()

  marker_file <- file.path(cache_dir, ".nhstt_initialized")
  is_first_time <- !file.exists(marker_file)

  if (is_first_time) {
    tryCatch(
      {
        file.create(marker_file)
      },
      error = function(e) {
        packageStartupMessage(
          "nhstt v",
          pkg_version,
          " - initialization failed: ",
          e$message
        )
      }
    )
  }
}
