#!/usr/bin/env Rscript

devtools::load_all(quiet = TRUE)

cli::cli_h1("Integration Tests")

tryCatch(
  {
    df_km <- get_key_measures_annual(periods = c("2024-25", "2022-23"))
    df_proms <- get_proms_annual(periods = c("2024-25", "2022-23"))
    df_therapy <- get_therapy_types_annual(periods = c("2024-25", "2022-23"))
    df_ap <- get_activity_performance_monthly(periods = c("2025-09", "2024-06"))
    df_meta_monthly <- get_metadata_measures_annual()
    df_meta_annual <- get_metadata_variables_annual()
    cli::cli_alert_success("All tests passed")
  },
  error = function(e) {
    cli::cli_alert_danger(paste0("Test failed: ", e$message))
    quit(status = 1)
  }
)
