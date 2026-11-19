# Copy to tests/testthat/test-repo-health.R and add the project's other drift checks. Test
# files carry no header block: their test_that() descriptions document them. Needs readr,
# stringr and purrr attached by code/01_support/setup.R, sourced in tests/testthat/setup.R.

test_that("every relative link in the navigation and documentation pages resolves", {
  markdown_pages <- c(
    here::here("README.md"),
    here::here("data", "DATA_REGISTER.md"),
    list.files(
      here::here("code"), pattern = "^PART_.*\\.md$", recursive = TRUE, full.names = TRUE
    ),
    list.files(
      here::here("documentation"), pattern = "\\.md$", recursive = TRUE, full.names = TRUE
    )
  )
  for (page in markdown_pages) {
    link_targets <- str_match_all(read_file(page), "\\]\\(([^)\\s]+)\\)")[[1]][, 2]
    link_targets <- link_targets[!grepl("^(https?:|mailto:|#)", link_targets)]
    link_paths <- str_remove(link_targets, "#.*$")  # drop a section anchor
    for (link_path in link_paths) {
      expect_true(
        file.exists(file.path(dirname(page), link_path)),
        info = paste(link_path, "in", basename(page))
      )
    }
  }
})

test_that("every environment variable is in .Renviron.example; shell scripts read no other", {
  code_files <- list.files(
    here::here("code"), pattern = "\\.R$", recursive = TRUE, full.names = TRUE
  )
  code_text <- paste(map_chr(code_files, read_file), collapse = "\n")
  read_pattern <- "(?:Sys\\.getenv|env_or_default)\\(\\s*\"([A-Z0-9_]+)\""
  r_names <- unique(str_match_all(code_text, read_pattern)[[1]][, 2])
  example_text <- read_file(here::here(".Renviron.example"))
  for (r_name in r_names) {
    expect_true(grepl(paste0("(^|\n)", r_name, "="), example_text), info = r_name)
  }
  shell_scripts <- list.files(here::here(), pattern = "\\.sh$", full.names = TRUE)
  for (shell_script in shell_scripts) {
    shell_names <- str_match_all(read_file(shell_script), "\\$\\{([A-Z_][A-Z0-9_]*):-")[[1]][, 2]
    unknown_names <- setdiff(shell_names, r_names)  # read by the shell but not by settings()
    expect_equal(length(unknown_names), 0, info = paste(basename(shell_script), unknown_names))
  }
})

test_that("every fig_*.R and run script names its own path", {
  script_paths <- list.files(
    here::here("code"), pattern = "^(fig|run)_.*\\.R$", recursive = TRUE
  )
  for (script_path in file.path("code", script_paths)) {
    script_text <- read_file(here::here(script_path))
    has_own_path <- grepl(paste0("\"", script_path, "\""), script_text, fixed = TRUE)
    expect_true(has_own_path, info = script_path)
  }
})
