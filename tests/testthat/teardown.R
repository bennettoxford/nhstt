test_cache_dir <- Sys.getenv("NHSTT_TEST_CACHE_DIR", unset = "")

if (nzchar(test_cache_dir) && dir.exists(test_cache_dir)) {
  unlink(test_cache_dir, recursive = TRUE)
}

Sys.unsetenv("NHSTT_TEST_CACHE_DIR")
