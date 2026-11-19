# R Code Style Guide

*How should a piece of code read?*

*Version 1.1, 19 November 2026. Maintained in [coding-guides](https://github.com/reneniehus/coding-guides); what changed between versions is in the [changelog](CHANGELOG.md).*

## Purpose and scope

Code should read like a well-kept lab notebook: the comments tell the story, the code tells the steps, and a colleague can follow both without running anything.

- **Governs** how code inside `.R` files, and R chunks in Quarto `.qmd` documents (the standard; legacy `.Rmd` follows the same rules until converted), reads: layout, comments, names, grammar, functions, console output and plots.
- **Does not govern** how the repository is organised, how data moves between scripts, or how tests are applied. That is the [Repo Practice Guide](REPO_PRACTICE_GUIDE.md).
- **Built on** a preferred house style where it makes code easier to read (the `+++` banners, `|-` section markers, one `params` list, coloured progress lines), and on the tidyverse style guide for everything else. Where this guide is silent, the tidyverse style guide applies.
- **Two strengths of rule.** *Must* is the default, broken only with a comment saying why. *Prefer* is a default that judgement may overrule.

Four principles sit behind every rule:

1. **Write for the reader six months from now.** Usually that is the author, under time pressure, checking a number before a meeting.
2. **Say why, show what.** Comments carry intent, assumptions and units; the code carries the mechanics.
3. **Make wrong data and every data change loud.** Code that reads data checks it first, and wrong data stops the run or raises a warning that cannot be missed. Every change to the data is counted and reported (rows or columns dropped, columns renamed), and the code says what it wrote.
4. **Prefer explicit, unsurprising code over compact code.** Spell out the steps, name the intermediate results, and choose the obvious construct over the clever one; a reader should never have to decode a line to trust it.

## Anatomy of a script

Every .R file is either a run script or a function file, and each kind has one fixed shape that a reader can scan.

A run script is an entry point: it reads, transforms and writes, and its header has a Run line. A function file only defines functions and constants for `code/00_main.R` or `setup.R` to source. Where each kind lives is set by the [Repo Practice Guide](REPO_PRACTICE_GUIDE.md).

### Header block

- **Must** open every file with a header block: the `+++` banner, then `Purpose`, `Inputs`, `Outputs` and `Run` lines, then a `Part` line. A function file has `Purpose`, `Sourced by:` and `Part`, plus an `Outputs` line when it defines stage functions that write, such as `write_` or `draw_` functions called from `00_main.R`. The `Part` line points to the part page (PART\_\<folder>.md) that says why the script exists, and is the file's link back up the documentation hierarchy; `code/00_main.R`, the files in `01_support/` and `02_settings/`, and test helper and setup files have no part page and write `Part: README.md (the project brief)`. Test files (`test-*.R`), which their `test_that()` descriptions document, and files a tool generates, such as `renv/activate.R`, carry no header.
- **Prefer** writing a `Sourced by:` list of functions as prose, starting each continuation line with a word (`#             and newest_vintage()`). A comment line that holds only function calls is what lintr reports as commented-out code.
- **Must** title the banner in plain words that say what the file makes (`### Weekly ILI rates by country ####`), not with the file path. The title is the RStudio outline entry, and the Run line already carries the path.
- **Must** write Inputs and Outputs as exact repo-relative paths, and give each output's grain and units. An input from outside the repo, such as a local clone of a forecast hub, names its environment variable, the path inside it and the vintage rule.
- **Prefer** naming a params field in the header only when it changes what the script produces, such as `params$as_of`. A full list of fields goes stale within weeks.
- **Prefer** keeping Inputs, Outputs, Run and Part within the first 15 lines. Reasoning about one step sits at that step's `|-` marker; a dated decision also gets an entry in `documentation/decisions.md` and a one-line pointer.

### Run scripts

- **Must** make a run script self-contained: it sources `setup.R` and the settings file itself and uses only what it reads, creates or takes from `params`. `Rscript <path>` from the project root then behaves exactly as sourcing it from `00_main.R`.
- **Must** keep one order: header, setup, constants, numbered `|-` steps in run order, writes last. Each step reports as it goes, and local helpers sit above their first use.
- **Prefer** `SCRIPT <- "<path>"` and `here::i_am(SCRIPT)` as the first code lines, with figure captions built from `SCRIPT`. `here::i_am()` errors when the file has moved, so a caption cannot name a stale path.
- **Prefer** in a function file that builds captions, such as a `fig_<name>.R` defining `plot_<name>()`, naming its own path once in a string literal inside the function, which the repo-health test checks against the file's path. A shared constant such as `SCRIPT` would not do: each sourced file would overwrite it.
- **Prefer** one output family per run script; if Outputs lists unrelated files, split the script.

### Function files and the runner

- **Must** let a function file define functions and constants only: sourcing it reads, writes and prints nothing and touches no `params`. Each function gets its own `|-` marker, in the order the functions are called.
- **Prefer** keeping `code/00_main.R` as the project's table of contents: one `verb_object(params, ...)` call per stage with a short comment, and no data manipulation.
- **Prefer** in `.qmd` files (and any `.Rmd` not yet converted), a first chunk that sources `setup.R` and the settings, a label on every chunk, and heavy work in `.R` functions. knitr runs chunks in the document's folder, so every path goes through `here::here()`.

A function file has this shape:

```r
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
### ISO week helpers ########################################################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Purpose:    put every weekly row on the project convention (Sunday week_end)
# Sourced by: code/01_support/setup.R; defines year_week_of(), week_end_of()
# Part:       README.md (the project brief)

# ---- |-year_week_of ----
# ISO year-week label of a date, e.g. "2026-W45"
year_week_of <- function(x) {  # x: Date vector
  sprintf("%d-W%02d", lubridate::isoyear(x), lubridate::isoweek(x))
}

# ---- |-week_end_of ----
# Sunday that ends the ISO week of a date
week_end_of <- function(x) {  # x: Date vector
  lubridate::floor_date(x, "week", week_start = 1) + 6  # Monday + 6 days
}
```

### Exemplar run script

The script below follows every rule in this guide. `newest_vintage()` is a setup.R helper, shown under Data safety in code.

```r
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
### Weekly ILI rates by country #############################################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Purpose: one ERVISS ILI series per country, dated by ISO week like hub truth
# Inputs:  data/erviss/<newest vintage on or before params$as_of>/erviss_iliari.csv
#          data/reference/countries.csv (one row per ERVISS country name)
# Outputs: output/tables/ili_by_country_week.csv: one row per country_iso2 x year_week;
#          ili_per_100k per 100 000 sentinel population; NA = not reported
# Run:     Rscript code/03_data/build_ili_weekly.R
# Part:    code/03_data/PART_03_data.md

SCRIPT <- "code/03_data/build_ili_weekly.R"  # this file; named in logs and captions
here::i_am(SCRIPT)
source(here::here("code/01_support/setup.R"))  # packages, conflicts, helpers
source(here::here("code/02_settings/settings_v3.R"))
params <- settings()  # params$as_of comes from AS_OF, default today

# ---- |-0. Constants ----
COUNTRY_FILE <- "data/reference/countries.csv"  # ERVISS country name -> country_iso2
OUT_FILE <- "output/tables/ili_by_country_week.csv"  # one row per country_iso2 x year_week
SUNDAY <- 7L  # ISO weekday, Monday = 1
EXCLUDE <- c(LU = "series alternates 0 and 2200, a reporting artefact")  # iso2 = reason

# ---- |-1. Read the vintage for the as-of date ----
cli_h1("Weekly ILI rates by country, as of {params$as_of}")
erviss_vintage <- newest_vintage("data/erviss", before = params$as_of)  # aborts if none
erviss_rows <- read_csv(
  here::here(erviss_vintage$path, "erviss_iliari.csv"),
  col_types = cols(.default = col_character(), value = col_double()),
  na = c("", "-")  # ERVISS writes "-" for not reported
)
stop_for_problems(erviss_rows)
ili_raw <- erviss_rows |>
  filter(indicator == "ILIconsultationrate", age == "total") |>
  select(country_name = countryname, year_week = yearweek, ili_per_100k = value)
week_span <- paste(range(ili_raw$year_week), collapse = " to ")
cli_alert_info("Vintage {erviss_vintage$vintage}: {nrow(ili_raw)} rows, ISO weeks {week_span}")
cli_alert_info("Kept {ncol(ili_raw)} of {ncol(erviss_rows)} columns: {.field {names(ili_raw)}}")

# ---- |-2. Code countries and apply exclusions ----
country_lookup <- read_csv(here::here(COUNTRY_FILE), col_types = cols(.default = "c"))
ili_coded <- inner_join(
  ili_raw,
  select(country_lookup, country_name, country_iso2),
  by = join_by(country_name),
  relationship = "many-to-one",   # one code per country name
  unmatched = c("error", "drop")  # every ERVISS name must be known; unused codes may go
)
ili_kept <- filter(ili_coded, !(country_iso2 %in% names(EXCLUDE)))
n_excluded <- nrow(ili_coded) - nrow(ili_kept)
cli_alert_warning("Excluded {n_excluded} row{?s} for {.val {names(EXCLUDE)}}: {EXCLUDE}")

# ---- |-3. Date each row by its ISO week ----
ili_by_country_week <- ili_kept |>
  complete(nesting(country_name, country_iso2), year_week) |>  # a missing report is NA, not 0
  mutate(
    week_end = ISOweek::ISOweek2date(paste0(year_week, "-", SUNDAY)),  # Sunday ending the week
    unit = "per 100 000 sentinel population",
    vintage = erviss_vintage$vintage
  )
stopifnot(
  "every week_end is a Sunday" = all(wday(ili_by_country_week$week_end, week_start = 1) == SUNDAY),
  "one row per country and ISO week" =
    !anyDuplicated(ili_by_country_week[c("country_iso2", "year_week")])
)
n_missing <- sum(is.na(ili_by_country_week$ili_per_100k))
cli_alert_info("{n_missing} country-week{?s} not reported, kept as NA")

# ---- |-4. Write and report ----
write_csv(ili_by_country_week, here::here(OUT_FILE), na = "")
cli_alert_success("Wrote {.file {OUT_FILE}}: {nrow(ili_by_country_week)} rows, {week_span}")
```

## Signature comments

Comments follow the house layout and carry the reasoning, shapes and history that the code itself cannot show.

```r
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
### Severity model ##########################################################
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# ---- |-severity_modulated ----
# Severity after vaccination, assuming no waning
severity_modulated <- function(severity_baseline,  # [a] risk of a severe outcome per infection
                               vaccine_uptake,     # [t, a] fraction vaccinated
                               ve_severe) {        # [1] VE against severe outcomes
  # 1: a vaccinated person keeps (1 - VE) of the baseline risk
  severity_factor <- 1 - vaccine_uptake * ve_severe  # [t, a]
  # 2: scale each age column by its own baseline; m * v would recycle down columns
  severity_by_week_age <- sweep(severity_factor, 2, severity_baseline, `*`)  # [t, a]
  return(severity_by_week_age)
}
```

- **Must** mark each big part with the three-line banner: a `# +++` line, a `### Title ##########` line and a `# +++` line. The title line is what RStudio shows in its outline.
- **Must** mark subsections with `# ---- |-Name ----`, closed by at least four dashes. RStudio folds only lines that end in four or more `-`, `=` or `#`, so `# ---- |-The end`, with no closing dashes, is not a section.
- **Prefer** one `#` before `---- |-` and two outline levels only. A third level is a plain `# short heading` line without closing dashes, so the outline stays at two levels.
- **Must** write comments that answer what the code cannot: why this step exists, what it assumes (units, grain, completeness, which week convention), and what could be misread (a filter that also drops NAs, recycling, a provisional value). A comment that translates a function name into English (`# filter rows`, `# join tables`) is noise; delete it. Numbered narrative steps that describe a block at a higher level than its code (`# 1: combine the factors impacting severity`) are welcome.
- **Must** give arrays and list fields a shape comment in one notation, `# [t, a]`, with scalars as `# [1]`. The letters are defined once, in a `Symbols:` line in setup.R's header (`t = ISO week index, a = age group`); a file that adds letters adds its own.
- **Prefer** stating the grain wherever a table is created or reshaped: `# one row per country_iso2 x year_week`. A wrong grain is the usual cause of a bad join.
- **Must** give every params entry and constant an inline comment saying what it controls, with its unit when it has one. For a switch, say what each value does: `params$rapid_stan_fit <- TRUE  # TRUE: variational fit, minutes not hours`.
- **Must** name the incident in one line wherever code guards against a past failure. It stops a later tidy-up from bringing the bug back.
- **Must** write TODOs as `# TODO(name, YYYY-MM): what and why`. An owner and a month make stale notes findable.
- **Must** leave no commented-out code: no old versions, alternatives or disabled `library()` calls, because git keeps them. A one-line usage example with its result (`# e.g. odds(0.4) is 0.667`) and one line on an approach that was tried and why it lost are welcome.
- **Must** keep identifying data, credentials and machine-specific paths out of comments. Comments travel with the code into every clone and every public mirror.
- **Prefer** documenting a function with one line above it and an inline comment per argument, as above; package-shaped repos (`R/`) use roxygen `#'` blocks instead. Fragments, lowercase and a first-person notebook voice are fine; ALL-CAPS emphasis is not.

```r
# Avoid
#forecasts_final <- forecasts[forecasts$round != max(forecasts$round), ]
# MUST USE FINAL ROUNDS ONLY!!!
forecasts_final <- filter(forecasts, origin_date < params$as_of)

# Prefer
# only rounds closed before as_of: an open round's provisional ensemble
# (10 of 13 models) was nearly used once
forecasts_final <- filter(forecasts, origin_date < params$as_of)
# TODO(jdoe, 2026-12): read the expected number of models per round from hub metadata
```

## Naming

A name says what a value holds, at what grain and in what unit, so a reader never has to open the data to find out.

| Kind | Pattern | Example |
| --- | --- | --- |
| Data object | content_by_grain | `ili_by_country_week`, `draws_by_season` |
| Stage or side-effect function | verb_object | `load_erviss()`, `fit_sir_model()`, `write_hub_submission()` |
| Quantity function | noun of the quantity | `severity_modulated()`, `odds()` |
| Constant | UPPER_SNAKE, top of file | `PER_100K`, `QUANTILE_LEVELS` |
| Logical column or flag | `is_`, `has_` | `is_eu_eea`, `has_full_interval` |
| params switch | yes/no phrase | `rapid_stan_fit`, `save_submission`, `use_ecdc_db` |
| Count | `n_` | `n_countries`, `n_reports` |
| One-quantity column | quantity_unit | `ili_per_100k`, `delay_days`, `positivity_pct`, `positivity_prop` |
| Weekly time | fixed names | `week_end` (Sunday), `year_week` (`"2026-W45"`), `iso_year`, `iso_week` |
| Daily date | event_date | `onset_date`, `report_date`, `snapshot_date`, `origin_date` |
| Season | fixed names | `season` (`"2026/27"`), `season_week` (1 = W40) |
| Country code | country_system | `country_iso2`, `country_ecdc` |

- **Must** use snake_case for objects, functions, columns and files. Rename at read only source names that are not snake_case or that mislead (`countryname` to `country_name`, `value` to `ili_per_100k`); keep community schemas such as the hubverse columns (`origin_date`, `target_end_date`, `output_type_id`), and the file and folder names a community format requires, verbatim. A verbatim name does not make a source's value a safe key: see Dates and ISO weeks.
- **Must** name data objects for their content and grain: `ili_by_country_week`, never `df2`, `mout` or `fc`.
- **Must** name pipeline-stage and side-effect functions verb_object, so 00_main.R reads as sentences. A pure function that returns one named quantity may be a noun, as base R's `mean()` is.
- **Must** reserve UPPER_SNAKE for values fixed by the method or the source, set at the top of the file. Anything a user might change between runs lives in params; values derived from data are lowercase (`last_obs_week`, `forecast_round`).
- **Must** start logical columns with `is_` or `has_`, and prefer the same for local flags. A params switch may be any yes/no phrase that reads well after `if (params$...)`.
- **Must** put the unit in the name of a column that holds one quantity, and keep proportions (`_prop`, 0-1) apart from percentages (`_pct`, 0-100). A long table that mixes indicators carries a `unit` column joined from the indicator lookup instead.
- **Must** start counts with `n_`, including those dplyr makes: `count(location, name = "n_reports")`, `summarise(n_weeks = n_distinct(week_end))`.
- **Must** name time columns by the conventions in the table, never a bare `date` or `week`. A date column says what it dates; a weekly column says which day of the week it holds.
- **Must** name the code system in a country-code column. Greece is GR in ISO and the hubs but EL at ECDC and Eurostat, and a join across the two drops it silently.
- **Must** never name an object `df`, `df2`, `tmp`, `temp`, `res`, `out`, `mout`, `mlist`, `list_out`, `final`, `new`, `T`, `F` or `c`. Allowed: `data` for the runner's input list and as a data-first helper's first argument; `x`, `p`, `v` in small generic helpers; `t`, `a` as `[t, a]` indices; model symbols (`S`, `I`, `R`, `beta`) that mirror the Stan file.
- **Must** abbreviate only with the glossary below and spell everything else out: `forecast`, not `fc`; `quantile_level`, not `qtl`. Apart from constants and Stan symbols, names are lowercase; `R0` and `Rt` keep their capital because `r` is a growth rate (`growth_rate_per_day`).
- **Must** keep private aliases out of project code and call the standard function instead; for example, `mlast()` becomes `dplyr::last()`, `mstand()` becomes `proportions()`, `inv_logit()` becomes `stats::plogis()`. Personal shortcuts such as `g <- glimpse` live in `~/.Rprofile` inside `if (interactive())`, which renv projects load only with `RENV_CONFIG_USER_PROFILE=TRUE`.

The glossary lives in the header of setup.R; adding an abbreviation means adding a row there.

| Abbreviation | Meaning | In code | In labels |
| --- | --- | --- | --- |
| `ili`, `ari`, `sari` | influenza-like illness, acute respiratory infection, severe ARI | `ili_per_100k` | ILI, ARI, SARI |
| `msp`, `wis` | example of a project's own metric, defined in its root README.md; weighted interval score | `msp`, `wis` | MSP, WIS |
| `ve` | vaccine effectiveness | `ve_severe` | VE |
| `R0`, `Rt` | basic and time-varying reproduction number | `R0`, `Rt` | R0, Rt |
| `gi` | generation interval | `gi_mean_days` | generation interval |
| `ci`, `cri`, `qi` | confidence, credible and quantile interval | `qi_lower` | CI, CrI |
| `nfp` | national focal point | `n_expected_nfp` | NFP |
| `eu_eea` | EU/EEA | `is_eu_eea` | EU/EEA |
| `iso` | ISO 8601 weeks, ISO 3166 codes | `iso_week`, `country_iso2` | ISO week |
| `obs`, `sim` | observed, simulated | `n_obs`, `sim_draws` | observed, simulated |
| `n_` | number of | `n_countries` | Number of countries |

## Tidyverse grammar

Each repo writes one dialect of the tidyverse, and every pipeline reads top to bottom as one named transformation.

- **Must** use one pipe per repo: the native `|>` in new repos, `%>%` in existing `%>%` repos, never both. The committed `.lintr` enforces it (see Formatting); examples in this guide use `|>`.
- **Must** name the result at the left margin, never with `%<>%` or right-assignment `->`. Both hide that an object was created or changed.
- **Prefer** one verb per line with the pipe at the line end, and about ten steps per pipeline. A longer chain becomes named intermediates whose names state their grain.
- **Prefer** plain calls for simple base operations (`n_zero_weeks <- sum(ili_per_100k == 0)`), and never `. %>%` functional sequences.
- **Must** never leave data grouped: use `.by =` for one-off grouping, or `summarise(.groups = "drop")`. With `.by`, `arrange()` before any step that depends on row order, and give `slice_*()` helpers `by =`, not `.by =`.
- **Must** recode with `case_when(..., .default = ...)` or `if_else()`, never `ifelse()`. `ifelse()` strips the Date class and coerces types silently.
- **Must** write anonymous functions as `\(x)` in new code, whatever the pipe; `~ .x` stays only in untouched old files, never both in one file. In `across()`, pass no extra arguments through `...`, and use `if_any()` or `if_all()` inside `filter()`.
- **Must** iterate with `map()` over a named list and combine with `list_rbind(names_to = ...)`. Never grow an object with `rbind()` in a loop, and never use `sapply()`, whose return type depends on its input.
- **Must** index loops with `seq_along()` or `seq_len()`, never `1:length(x)`, which runs over 1 and 0 when `x` is empty.
- **Prefer** a pre-allocated for loop for side effects and sequential state, such as one file per country or SIR time steps. A loop is the honest shape for stepwise state.
- **Prefer** base R where it reads as the model, such as matrix algebra on `[t, a]` arrays. Scale a `[t, a]` matrix by a per-age vector with `sweep()`, never `m * v`, which recycles down the columns without a warning.
- **Must** deduplicate versions deliberately: `arrange()` by the stated preference, `distinct()` on the key, then report how many rows were superseded. Which revision survives changes results.

```r
# Avoid
ili_raw %<>% filter(age == "total")
erviss_rows %>% filter(indicator == "ILIconsultationrate") -> xtyping

# Prefer
peak_ili_by_country_season <- ili_by_country_week |>
  summarise(peak_ili_per_100k = max(ili_per_100k), .by = c(country_iso2, season)) |>
  arrange(country_iso2, season)  # .by keeps first-appearance order
```

```r
# Avoid
parameters <- NULL
for (i in 1:length(countries)) {
  parameters <- rbind(parameters, extract_parameters(fit_country(params, ili, countries[i])))
}

# Prefer
fits_by_country <- map(
  set_names(params$run_countries),
  \(country_iso2) fit_country(params, ili_by_country_week, country_iso2),
  .progress = "Fitting countries"
)
parameters_by_country <- fits_by_country |>
  map(extract_parameters) |>
  list_rbind(names_to = "country_iso2")
```

```r
# Avoid: recycles [a] down the columns of [t, a], wrong and silent
severity_by_week_age <- severity_factor * severity_baseline

# Prefer
stopifnot("one baseline per age group" = length(severity_baseline) == ncol(severity_factor))
severity_by_week_age <- sweep(severity_factor, 2, severity_baseline, `*`)  # [t, a] by [a]
```

```r
# one row per location x year_week: the newest snapshot wins over earlier revisions
ili_latest <- ili_all_snapshots |>
  arrange(location, year_week, desc(snapshot_date)) |>
  distinct(location, year_week, .keep_all = TRUE)
n_superseded <- nrow(ili_all_snapshots) - nrow(ili_latest)
cli_alert_info("{n_superseded} superseded revision{?s} dropped")
```

## Functions

A function does one named job, takes everything it needs as arguments and says what it returns.

- **Prefer** one job per function, about one screen (50 lines) long: fitting, extracting, plotting and assembling are separate functions. A longer body becomes named steps.
- **Must** give `params` as the first argument to every stage function, meaning every function called from `code/00_main.R`: `load_data(params)`, `run_model(params, data, models_in)`. `run_survey_analysis(survey, params)` is an example to avoid; fix such a signature when its file is next touched.
- **Prefer** data first, then only the values needed, for small helpers: `add_season_columns(ili_by_country_week, season_start_week = params$season_start_week)`. They then work in a pipe and can be tested without params.
- **Must** validate inputs where data or settings enter (stage functions, readers, anything taking params or a path) and fail with `cli_abort()` naming the bad value. Use `rlang::arg_match()` for choices; internal helpers trust their validated callers.
- **Must** end `settings()` by checking params once: required fields present, no unknown fields, types and ranges valid. setup.R sets `options(warnPartialMatchDollar = TRUE)`, because `params$sim` otherwise silently returns `params$simulation_seed`.
- **Must** take analysis choices (as-of date, countries, season start, indicator, tolerances, seed) from params or arguments, never from literals, defaults or `Sys.getenv()`. `settings()` is the only place that reads environment variables.
- **Must** read nothing hidden: a function uses its arguments, helpers and UPPER_SNAKE constants from setup.R, from `code/01_support/reference.R` or from the top of its own file. A constant fixed by a source and needed by more than one part, such as a hub's `DAYS_ORIGIN_TO_H1`, lives in reference.R; one that could change between runs is a params entry. Data, params and results always come in as arguments, and `<<-` is never used.
- **Must** return a tibble whose grain is stated, or a named list whose elements are named for content and carry a shape comment.
- **Prefer** ending a multi-line function with an explicit `return(name)`, which shows where it exits; one-line helpers return implicitly.
- **Must** either compute or act: computing functions do not plot, write files or print results, though cli progress lines are fine. Side-effect functions are named `plot_`, `write_` or `save_` and return their object or path invisibly.
- **Must** refer to a column as `.env$name` inside dplyr verbs when an argument has the same name. `filter(ili, country_iso2 == country_iso2)` compares the column with itself and keeps every row.
- **Prefer** forwarding column arguments with `{{ }}` inside the body; for names held as strings, use `.data[[col]]` in data-masking verbs and `all_of()` in tidy-select. No `enquo()` or `!!` in new code.
- **Prefer** writing a loop body as a function of one element, mapped over the elements and called by hand to debug. It replaces `# i = 1` stepping notes.
- **Prefer** wrapping long safety idioms once in setup.R so each costs one line: `newest_vintage()`, `muffle_warning()`, `save_figure()`, `week_end_of()`, and `load_or_build(name, build, regenerate = params$regenerate)` as the only caching pattern.

```r
# ---- |-fit_country ----
# Fit the SIR model to one country; run_model() maps it over params$run_countries
fit_country <- function(params, ili_by_country_week, country_iso2) {
  country_iso2 <- rlang::arg_match(country_iso2, params$run_countries)
  ili_one_country <- filter(ili_by_country_week, country_iso2 == .env$country_iso2)
  stan_fit <- rstan::stan(
    file = here::here("stan/sir.stan"),
    data = make_stan_data(ili_one_country),
    seed = params$simulation_seed,
    chains = params$n_chains
  )
  return(list(
    stan_fit = stan_fit,             # stanfit with draws of every model parameter
    n_weeks = nrow(ili_one_country)  # [1] country-weeks passed to the fit
  ))
}

# at the console, never in the file: debug one country by hand
fit_austria <- fit_country(params, ili_by_country_week, "AT")
```

```r
# ---- |-summarise_quantiles ----
# Median and 80% interval of a value column per group
summarise_quantiles <- function(data, value, by) {
  data |>
    summarise(
      q10 = quantile({{ value }}, 0.1),
      q50 = quantile({{ value }}, 0.5),
      q90 = quantile({{ value }}, 0.9),
      .by = {{ by }}
    )
}

peak_summary <- summarise_quantiles(peak_draws, peak_ili_per_100k, by = c(country_iso2, season))
hub_keys <- select(hub_rows, all_of(params$key_columns))
```

```r
# ---- |-write_ili_table ----
# Write the weekly ILI table and report it
write_ili_table <- function(ili_by_country_week, path) {  # path: repo-relative
  write_csv(ili_by_country_week, here::here(path), na = "")
  week_span <- paste(range(ili_by_country_week$year_week), collapse = " to ")
  cli_alert_success("Wrote {.file {path}}: {nrow(ili_by_country_week)} rows, {week_span}")
  return(invisible(path))
}
```

## Console output

Console output exists so a scientist can supervise a run as it happens: glance at the console and see which stage is running, whether the data looks as expected, and when something needs attention. Colour carries that at a glance (stages as headers, green for written, yellow for dropped or odd, red for failures), and every line is informative: it reports what was read, dropped and written, and every problem names its values. The same lines remain afterwards as the run's audit trail.

| Event | Call | Example line in the log |
| --- | --- | --- |
| Stage | `cli_h1()`, `cli_h2()` | `-- 2. Coding countries --` |
| Read | `cli_alert_info()` | Vintage 2026-11-13: 12 340 rows, ISO weeks 2015-W40 to 2026-W45 |
| Dropped | `cli_alert_warning()` | Excluded 96 rows for "LU": series alternates 0 and 2200 |
| Wrote | `cli_alert_success()` | Wrote output/tables/ili_by_country_week.csv: 12 402 rows, 2015-W40 to 2026-W45 |
| Unhandled problem | `cli_warn()` | ILI: 2 hub files unreadable: ... |
| Fixable failure | `cli_abort()` | Hub clone not found ... i Set HUB_DIR in .Renviron |

- **Must** send all console output through cli, using the calls in the table. `cat(green(...))` and bare `cat()` go when their file is next touched; `print()` stays only for a summary table under a stage header.
- **Must** put values into cli messages by interpolation (`{n}`, `{.val {x}}`, `{.file {path}}`), never by `paste()` or `sprintf()` into the template. cli evaluates braces, so a pasted path containing `{` aborts the run. A template too long for one line is split as `paste0()` of string literals that hold no values, or, in `cli_abort()` and `cli_warn()`, as a `c()` of lines; a line break inside the string prints as one.
- **Prefer** calling cli directly in new code; older helpers such as `step()` and `say()` stay in setup.R only as shims for old call sites, inserting their text as a value.
- **Must** report each read: rows, ISO-week range and vintage, where vintage is the snapshot or publication date read from the data, never `Sys.Date()`.
- **Prefer** adding to the read report the expected countries that are absent and the number of countries reporting in each of the last three weeks. An incomplete newest week then shows before it reaches a figure.
- **Must** report every drop on every run: how many rows, which keys and why. A step that drops or renames columns reports that too: how many columns it kept, out of how many, and their new names. Printing each excluded country with its reason makes the results auditable.
- **Must** report each write: the path, the rows and the key range.
- **Prefer** timing long stages and showing progress on long loops: `map(..., .progress = "Fitting countries")`, or `cli_progress_bar()`, `cli_progress_update()` and `cli_progress_done()` around a for loop.
- **Must** stop a failure a user can fix with `cli_abort()`, naming the value, what was expected and an `i` hint. Guard internal invariants with `stopifnot()` and named conditions, whose names become the error message.
- **Must** raise a real `cli_warn()` for a problem nobody handled that may change a result, and report a known source quirk the code handles as one combined notice per run. Coloured text can be neither caught nor counted.
- **Must** muffle only a named, expected warning, around the one call that raises it, with `muffle_warning()` or `suppressWarnings(expr, classes = ...)`. The one blanket form allowed is `suppressPackageStartupMessages()` around `library()` calls.
- **Prefer** pluralising with `{?s}`, with the count interpolated directly before the noun or set with `cli::qty()`. Example to avoid: "1 weeks behind".
- **Prefer** switching detail lines with `params$verbose` through one option and one `detail()` helper; stage headers, warnings and errors always print.
- **Prefer** never attaching tidylog, which masks `filter()`, `mutate()` and the joins. Call `tidylog::filter()` by name at the one step being audited.

```r
# Avoid
pr <- paste("> Wrote", out_path, "|", nrow(ili_by_country_week), "rows")
cat(green(pr))
cli_alert_success(paste("Wrote", out_path))  # a { in the path breaks cli

# Prefer
cli_alert_success("Wrote {.file {out_path}}: {nrow(ili_by_country_week)} rows, {week_span}")
```

```r
# a known quirk the code handles: one combined notice per run
cli_alert_warning(
  "{n_off_day} countr{?y/ies} report on days other than Wednesday: {.val {off_day_countries}}"
)
# a problem nobody handled that may change a result: a real warning
cli_warn("{indicator}: {n_unreadable} hub file{?s} unreadable: {.file {unreadable_paths}}")
# a failure the user can fix
cli_abort(c(
  "Hub clone not found: {.file {params$hub_dir}}.",
  i = "Set {.envvar HUB_DIR} in {.file .Renviron}; see {.file .Renviron.example}."
))
```

```r
# ---- |-muffle_warning ----
# Muffle one expected warning, matched on a version-stable fragment of its message
muffle_warning <- function(expr, fragment) {
  withCallingHandlers(
    expr,
    warning = \(w) {
      if (grepl(fragment, cli::ansi_strip(conditionMessage(w)), fixed = TRUE)) {
        invokeRestart("muffleWarning")
      }
    }
  )
}

# ---- |-detail ----
# Detail line, printed unless 00_main.R set options(project.verbose = params$verbose) to FALSE
detail <- function(text) {
  if (isTRUE(getOption("project.verbose", TRUE))) {
    cli::cli_alert_info("{text}")
  }
  return(invisible(text))
}

# ---- |-step and say ----
# Shims for old call sites; text is inserted as a value, so braces stay literal
step <- function(title) cli::cli_h2("{title}")
say <- function(...) {
  text <- paste0(...)
  cli::cli_alert_info("{text}")
}
```

## Data safety in code

Wrong data must stop the run or show up in the log; nothing that changes a result may happen silently.

### Joins and keys

- **Must** declare `relationship =` in every join. When every row of x must find a partner, use `inner_join(..., unmatched = c("error", "drop"))`; after a `left_join()`, whose `unmatched` checks only y, assert the joined columns hold no NA.
- **Must** join on every key column, never on a pasted composite key, and never compare computed doubles with `==`. A label matched on a pasted "location + series" string can hit the wrong row. Key quantile levels on a normalised label, `sprintf("%.3f", as.numeric(output_type_id))`, never on the hub's character `output_type_id`: one hub writes the same level as `"0.1"` in some files and `"0.100"` in others, so a duplicate-key check misses the pair.
- **Must** assert after every join and before every write that the key is unique at the stated grain and the row count is as expected. After a filter, report what went and assert the expected set is still there.
- **Must** address columns by name and ordered categories by level, never by position. Age groups are factors with levels from one constant (`AGE_GROUPS`), and every `[t, a]` array gets dimnames from it, asserted before Stan, which matches by position.
- **Must** declare column types on read with `.default`, set `na` to the source's own missing markers, and stop on parse problems with `readr::stop_for_problems()`. Convert text to numbers only on rows that must be numeric, so any coercion warning is real.
- **Must** check that a field means what its name says before building on it, use the value that is coherent by definition, and report disagreement each run in the log and as a row of a committed check table, which documentation pages cite. For example, one forecast hub's `median` column disagreed with its own 0.5 quantile in 60% of rows.

```r
# every admissions row must find a population; unused population years may drop
admissions_with_population <- inner_join(
  admissions_by_country_week,
  population_by_country_year,
  by = join_by(country_iso2, iso_year),
  relationship = "many-to-one",
  unmatched = c("error", "drop")
)

# a left join keeps unmatched rows as NA, so assert there are none
admissions_with_population <- left_join(
  admissions_by_country_week,
  population_by_country_year,
  by = join_by(country_iso2, iso_year),
  relationship = "many-to-one"
)
stopifnot("every country-year has a population" = !anyNA(admissions_with_population$population))
```

### Missing values

- **Must** keep three states apart: a reported value, a reported zero and no report. Complete the expected grid with NA (never 0), and filter zeros and gaps in separate, counted steps.
- **Must** remember that `filter()` drops rows whose condition is NA: choose `!=` (drops them) or `!(x %in% y)` (keeps them) and comment the choice. Give each `na.rm = TRUE` block a why-comment, and count every zero denominator set to NA and every epsilon fix.

```r
# Avoid: drops gaps together with zeros, and NA country codes together with LU
ili_log_axis <- filter(ili_by_country_week, country_iso2 != "LU", ili_per_100k > 0)

# Prefer
n_zero <- sum(ili_by_country_week$ili_per_100k == 0, na.rm = TRUE)  # reported zeros only
n_gap <- sum(is.na(ili_by_country_week$ili_per_100k))  # not reported
ili_log_axis <- filter(ili_by_country_week, ili_per_100k > 0)  # log axis: zeros and gaps go
cli_alert_info("Log axis leaves out {n_zero} reported zero{?s} and {n_gap} gap{?s}")
```

### Dates and ISO weeks

- **Must** parse dates to Date once, at read, and date each weekly row by `week_end`, the Sunday ending its ISO week, with `year_week` (`"2026-W45"`) beside it. Convert other conventions (Monday, mid-week Wednesday, `"2026-45"`) once with `week_end_of()` and `year_week_of()`, and join sources on `year_week`.
- **Must** derive `week_end` from the source's own week label when a source carries both a week label and a date. Keep the source's date only for a counted agreement check, reported and written to a check table, then drop it. One hub's `truth_date` ran 7 days late in early snapshots, so 2020-W53 and 2021-W01 shared a date and a key built on it broke.
- **Must** assert weekdays with `lubridate::wday(x, week_start = 1)` against a named constant (`SUNDAY <- 7L`), never `weekdays(x) == "Sunday"`, which depends on the locale.
- **Must** do week arithmetic on ISO weeks and never assume 52 weeks: no `1:52`, `[1:52]` or 364-day shift. 2026-W53 runs from 28 December 2026 to 3 January 2027; one helper handles W53 by one stated rule and reports the rows it touched.
- **Must** define the season once, on ISO weeks: `params$season_start_week <- 40L`, labels like `"2026/27"`, and `season_week` 1 = W40, never derived from a month and day.

### Vintages and sources

- **Must** set the as-of date once, as `params$as_of` in settings, and apply it to every input: forecast rounds before it, the newest vintage on or before it. Derived tables carry their vintage, and no script calls `Sys.Date()` or `Sys.getenv("AS_OF")` itself.
- **Must** name the truth vintage when scoring forecasts (as known at each round, or the latest revision) and state it in the log, the caption and the output. Scores change with the truth vintage.
- **Must** validate the overlap before splicing two sources: per country and indicator, compute `n_overlap_weeks` and the median relative difference, and splice only within `MIN_OVERLAP_WEEKS` and `SPLICE_TOL`. The newer source wins, and the agreement and not-spliced tables are written and feed the caption notes.
- **Must** read reference data (country codes and names, EU/EEA membership, population and its year, indicator units and any per-location unit exceptions) from one lookup, never from vectors retyped in a script. A fact a source states only in prose, such as the few locations whose rates are per 100 000 consultations, goes into a lookup in `data/reference/` with a register row, read by the loader. Hand-made exclusions sit in one named vector at the top, applied in one filter and printed every run.
- **Prefer** flagging the newest weeks still open to revision with `is_provisional`, set from `N_PROVISIONAL_WEEKS`, and drawing them distinctly. ERVISS values move after first publication.

```r
# ---- |-read_as_of ----
# As-of date from AS_OF; unset or empty: `default` in dev and refresh runs, an abort in a full run
# Defined in the settings file and called only by settings(), after params$mode is set
read_as_of <- function(mode, default = Sys.Date()) {  # mode: "dev", "refresh" or "full"
  # default: today, or the newest committed vintage when every input is one
  as_of_text <- Sys.getenv("AS_OF")
  if (!nzchar(as_of_text) && mode == "full") {
    cli::cli_abort("A full run needs {.envvar AS_OF} (YYYY-MM-DD); none is set.")
  }
  as_of <- if (nzchar(as_of_text)) as.Date(as_of_text, format = "%Y-%m-%d") else default
  if (is.na(as_of)) {
    cli::cli_abort(c(
      "{.envvar AS_OF} must look like {.val 2026-11-16}; got {.val {as_of_text}}.",
      i = "Fix or unset {.envvar AS_OF}; unset means {.val {default}}."
    ))
  }
  return(as_of)
}

# ---- |-newest_vintage ----
# Newest vintage folder dated on or before `before`; folders are named YYYY-MM-DD
newest_vintage <- function(dir, before) {  # dir: repo-relative source folder; before: Date
  vintage_names <- basename(list.dirs(here::here(dir), recursive = FALSE))
  vintage_dates <- as.Date(vintage_names, format = "%Y-%m-%d")  # NA for any other folder
  is_usable <- !is.na(vintage_dates) & vintage_dates <= before
  if (!any(is_usable)) {
    cli::cli_abort(c(
      "No vintage folder in {.file {dir}} on or before {before}.",
      i = "Fetch or freeze the vintage first; see {.file data/DATA_REGISTER.md}."
    ))
  }
  vintage <- max(vintage_dates[is_usable])
  return(list(
    path = file.path(dir, format(vintage)),  # [1] repo-relative vintage folder
    vintage = vintage  # [1] Date the vintage was delivered or frozen
  ))
}
```

### Units, randomness and files

- **Must** keep a source's rate on the source's denominator; for example, ERVISS ILI and ARI are per 100 000 sentinel population, so never rescale them, turn them into counts or pool them across countries. A rate the code computes uses `PER_100K`, with the population source and year in its comment.
- **Must** aggregate rates and proportions as summed numerators over summed denominators, never as a mean of rates. A mean gives a country with 10 tests the weight of one with 10 000.
- **Must** seed randomness from `params$simulation_seed` at the point of use: `seed =` in every Stan call, `withr::with_seed()` for local draws, `furrr::furrr_options(seed = ...)` for parallel maps.
- **Must** read and write text with readr, which uses UTF-8 whatever the locale, and tables with `write_csv()` and a stated `na`. Never use `write.csv()` or base `readLines()`/`writeLines()`; write non-ASCII characters in R strings as escapes such as `"\u2013"` for an en dash.

```r
PER_100K <- 1e5  # population: Eurostat demo_pjan, 1 January 2024
admission_rates_by_country_week <- admissions_with_population |>
  mutate(admissions_per_100k = n_admissions / population * PER_100K)

# EU/EEA positivity: summed detections over summed tests, never a mean of country rates
positivity_eu_eea <- detections_by_country_week |>
  filter(is_eu_eea) |>
  summarise(
    positivity_prop = if_else(sum(n_tests) > 0, sum(n_detections) / sum(n_tests), NA),
    .by = year_week
  )

bootstrap_rows <- withr::with_seed(params$simulation_seed, sample(n_draws, replace = TRUE))
```

## Plots

Every figure belongs to one visual family, shows its units and provenance, and never loses data without saying so.

- **Must** build every figure on `theme_project()` from setup.R, adding only local tweaks with `+ theme()`.
- **Must** colour each category from one fixed, named, colourblind-safe palette in setup.R, through a wrapper such as `scale_colour_indicator()`, never default hue cycling. New projects start from Okabe-Ito; a repo whose palette is already shared with its HTML artefacts keeps that one.
- **Must** check that every category has a colour before plotting with one setup.R helper, `check_palette(fig_data$indicator, palette_indicator)`, which aborts and names the unmapped values. A category missing from `values` is drawn grey without a warning.
- **Must** label axes with units (`"ILI consultations per 100 000 sentinel population"`); a long table takes the label from its unit column.
- **Must** caption every figure with the data source, the data vintage (`data as of 2026-11-13`, read from the data) and the building script from `SCRIPT`. Without the script in the caption, a figure cannot be traced back to its code.
- **Must** state in the caption every rule that shapes what is shown: exclusions, truncation, the scale rule and unspliced series, generated from the tables that hold them, never typed as literals.
- **Must** not draw ILI or ARI levels of different countries on one shared axis: use a free scale per country or change against each country's baseline, and say so in the caption. Case definitions, sentinel coverage and denominators differ by country. Unitless relative measures, such as the percent difference from each country's newest value, may share an axis when the caption says so.
- **Must** zoom position axes with `coord_cartesian()`, never with `xlim()`, `ylim()` or position-scale limits, which turn out-of-range values into NA and drop them. Ribbons can lose points that way without a message.
- **Prefer** a robust colour or fill scale when one outlier would flatten the rest: limits from a stated quantile, `oob = scales::oob_squish`, and the rule in the caption.
- **Must** drop degenerate cases explicitly, with a comment and a reported count, before ggplot drops them silently: `filter(n() >= 2, .by = c(location, round))  # one-point lines would vanish`.
- **Must** draw isolated observations with `geom_point()` after completing a weekly grid with NA, and report their count in the log and the caption. A reported week between two gaps has no neighbour to join, so `geom_line()` drops it; 182 weeks once vanished from three figures that way.
- **Must** place sentinels where the scale transform sends them to the panel edge: on a log10 axis write `ymin = 0`, which becomes -Inf, never `ymin = -Inf`, which becomes NaN and vanishes. Muffle the resulting warning by name (see Console output).
- **Must** keep plot text ASCII (`-`, `+/-`, `f1^2 / f2`) unless the font is known to carry the glyphs. For example, en-dashes, middots and subscripts can render as dots in a server's font.
- **Prefer** ISO-week ticks such as `W45`, with the ISO year on the first tick and where the year changes (`2026-W52`, `W53`, `2027-W01`).
- **Must** save with `ggsave()` or `save_figure()`, giving width, height, units, dpi, bg and device, to a `here()` path, then report the path and open the rendered file. The device is `ragg::agg_png` with ragg in renv.lock, or else `device = "png", type = "cairo"`. Problems such as a shaded rectangle that vanishes on a log axis, or broken glyphs, show only in the rendered file.

```r
# Okabe-Ito based; a category keeps its colour in every figure
palette_indicator <- c(
  "ILI" = "#0072B2",      # blue
  "ARI" = "#E69F00",      # orange
  "COVID-19" = "#009E73"  # bluish green
)
scale_colour_indicator <- function(...) scale_colour_manual(values = palette_indicator, ...)
```

```r
fig_ili <- ggplot(ili_plot, aes(week_end, ili_per_100k)) +
  geom_line(colour = palette_indicator[["ILI"]]) +
  facet_wrap(vars(country_iso2), scales = "free_y") +  # levels differ by sentinel system
  coord_cartesian(xlim = c(season_start, params$as_of)) +
  labs(
    x = "ISO week (week ending Sunday)",
    y = "ILI consultations per 100 000 sentinel population",
    caption = paste0(
      "Source: ERVISS, data as of ", erviss_vintage$vintage, ". ",
      "Excluded: ", paste0(names(EXCLUDE), " (", EXCLUDE, ")", collapse = "; "), ". ",
      "Free y scale: levels are not comparable between countries. Built by ", SCRIPT, "."
    )
  ) +
  theme_project()
ggsave(
  here::here("output/figures/ili_by_country.png"),
  fig_ili,
  width = 16,
  height = 10,
  units = "cm",
  dpi = 300,
  bg = "white",
  device = ragg::agg_png
)
cli_alert_success("Wrote {.file output/figures/ili_by_country.png}")
```

```r
COLOUR_LIMIT_QUANTILE <- 0.90  # colour limits from the 90th percentile of |slope|, not the maximum
slope_limit <- quantile(abs(slopes$change_prop_per_week), COLOUR_LIMIT_QUANTILE)
fig_slope <- fig_slope +
  scale_colour_gradient2(limits = c(-slope_limit, slope_limit), oob = scales::oob_squish)
```

## Formatting

styler and lintr enforce the mechanical rules, so reviews can spend their time on names, comments and logic.

- **Must** format with styler in its tidyverse style with `strict = FALSE` (`styler::style_file(path, strict = FALSE)`), and lint with the committed `.lintr` below. The default strict mode cuts the two spaces before every inline comment to one and undoes aligned argument comments, against every example in this guide. The rules in this section are what those tools check.
- **Must** assign with `<-`, use `=` only for arguments, and never right-assign with `->`.
- **Must** write `TRUE` and `FALSE`, never `T` and `F`, which are ordinary variables anyone can overwrite.
- **Must** quote strings with double quotes, and use single quotes only when the string contains a double quote.
- **Must** keep lines at most 100 characters and indent with 2 spaces. Break a long call one argument per line, with the closing parenthesis on its own line.
- **Must** write one statement per line, never `;`, with spaces around binary operators and after commas, and none just inside parentheses.
- **Must** spell argument names in full: `ggsave(units = "cm")`, not `unit = "cm"`, which works only by partial matching.
- **Must** attach the tidyverse component packages a project uses (dplyr, tidyr, readr, purrr, stringr, lubridate, ggplot2), never `library(tidyverse)`. The meta-package adds about 30 packages to renv.lock, and a machine can hold the components without it.
- **Must** load packages with `library()` in one `suppressPackageStartupMessages({ })` block at the top of setup.R or the script. Never use `require()`, which returns FALSE and lets the script carry on, and never redefine `library()`.
- **Must** attach only packages a script uses throughout, and call one-off functions as `pkg::fun()`, above all `data.table::fread()`. Attached after dplyr and lubridate, data.table masks `isoweek()`, `wday()`, `first()`, `last()` and `between()`.
- **Must** resolve every remaining conflict with `conflicted::conflicts_prefer()` in setup.R, never by hand re-masking such as `select <- dplyr::select`.
- **Must** check once in setup.R that R and the key packages are new enough for the idioms in this guide: R 4.2.0, dplyr 1.1.0, purrr 1.0.0, tidyselect 1.2.0 and conflicted 1.2.0.
- **Prefer** aligning `=` only inside `tribble()` and argument lists, which styler preserves with `strict = FALSE`.
- **Prefer** restyling an existing repo in one mechanical styler commit, with `strict = FALSE`, listed in `.git-blame-ignore-revs`. Renames and pipe or return rewrites happen when a file is next touched, with its tests run.

```r
# Avoid
params$save_submission = F; params$rapid_stan_fit=T
select <- dplyr::select
ggsave(path, fig, unit = 'cm')

# Prefer
params$save_submission <- FALSE  # TRUE: write the hub submission file
params$rapid_stan_fit <- TRUE  # TRUE: variational fit, minutes not hours
ggsave(
  here::here(figure_path),
  fig_ili,
  width = 16,
  height = 10,
  units = "cm",
  dpi = 300,
  bg = "white",
  device = ragg::agg_png
)
```

```r
# ---- |-Packages ----
suppressPackageStartupMessages({
  library(conflicted)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(purrr)
  library(lubridate)
  library(ggplot2)
  library(cli)
})
stopifnot(
  "R >= 4.2.0" = getRversion() >= "4.2.0",
  "dplyr >= 1.1.0" = packageVersion("dplyr") >= "1.1.0",
  "purrr >= 1.0.0" = packageVersion("purrr") >= "1.0.0",
  "tidyselect >= 1.2.0" = packageVersion("tidyselect") >= "1.2.0",
  "conflicted >= 1.2.0" = packageVersion("conflicted") >= "1.2.0"
)
conflicts_prefer(dplyr::filter, dplyr::select, dplyr::lag, lubridate::wday)
options(warnPartialMatchDollar = TRUE)  # a misspelt params field must not match silently
```

The committed `.lintr` for a `|>` repo, copy-ready as [templates/lintr](templates/lintr); a `%>%` repo sets `pipe = "%>%"`. The defaults already flag `=`, `->`, `T`/`F`, `1:length(x)`, `;`, single quotes and commented-out code. `object_usage_linter` is off: in a repo of sourced scripts it reports every helper defined in another file and every dplyr column as undefined, so a clean lint becomes unattainable and real lints drown.

```text
linters: linters_with_defaults(
    line_length_linter(100L),
    object_name_linter(styles = c("snake_case", "SNAKE_CASE", "symbols")),
    object_usage_linter = NULL,
    pipe_consistency_linter(pipe = "|>"),
    undesirable_function_linter(fun = c(setwd = "use here::here()", attach = NA,
      browser = NA, View = NA, require = "use library()",
      sapply = "use map_*() or vapply()", install.packages = "install through renv")),
    undesirable_operator_linter()
  )
encoding: "UTF-8"
exclusions: list("renv", "code/99_sandbox")
```

## Habits to avoid

Each habit below can cost a run, a figure or a colleague's afternoon, and each has a better form that costs a line or two.

- **Must** never override package functions globally, for example by redefining `ggplot()`, `geom_ribbon()`, `mean_qi()` and `library()` in setup.R. Write a named wrapper instead (`theme_project()`, `scale_colour_indicator()`, `mean_qi80()`), so the same call gives everyone the same result.
- **Must** never call `setwd()` or write absolute or `../` paths: use `here::here()` for project files and `params` fields for machine locations. The settings file reads those once from environment variables with defaults, such as the path to a local forecast hub clone in `HUB_DIR`.
- **Must** never keep `if (FALSE)` scratch blocks in working code: move them, titles included (for example "adventures in re-scaling"), to the sandbox script. Where the sandbox lives is set by the [Repo Practice Guide](REPO_PRACTICE_GUIDE.md).
- **Must** never leave `browser()` in code: replace it with a `cli_abort()` that names the values, and debug with `debugonce()` or an RStudio breakpoint. `browser()` halts a batch run and explains nothing.
- **Must** name every number that encodes a result-changing decision (seeds, tolerances, thresholds, cut-offs, quantile levels, dates, Stan tuning) as a params entry or commented constant. Formula coefficients, plain unit conversions (7 days, 100 for percent) and plot cosmetics stay inline.
- **Must** never swallow errors with `tryCatch(..., error = function(e) NULL)`: collect failures with `purrr::safely()` and report them, or let the run fail. Unreadable files otherwise vanish from results unseen.
- **Must** never rely on session state: no `attach()` and no `rm(list = ls())`; restart R or use `Rscript` for a clean state. `gc()` frees memory but does not clear the environment.
- **Prefer** `saveRDS()` and `readRDS()` of one named object at a `here()` path over `save()` and `load()`, which drop objects with unseen names into the environment.
- **Must** remove interactive leftovers before committing: `View()`, stray `print()`, plots drawn mid-function, `clc()` and `install.packages()`. Packages are installed through renv.

```r
# Avoid
setwd("C:/Users/me/flu")
hub_rows <- tryCatch(fread("../Big data/hub.csv"), error = function(e) NULL)
if (nrow(infinite_positivity) > 0) {browser()}
fit <- rstan::vb(sir_model, data = stan_data, seed = 12, tol_rel_obj = 0.018, grad_samples = 2)

# Prefer
hub_paths <- file.path(params$hub_dir, "model-output", hub_file_names)
read_attempts <- map(set_names(hub_paths), safely(read_hub_file))
failed_paths <- names(keep(read_attempts, \(attempt) !is.null(attempt$error)))
if (length(failed_paths) > 0) {
  cli_warn("{length(failed_paths)} hub file{?s} unreadable: {.file {failed_paths}}")
}
if (nrow(infinite_positivity) > 0) {
  cli_abort("Infinite positivity for {.val {unique(infinite_positivity$country_iso2)}}.")
}
fit <- rstan::vb(
  sir_model,
  data = stan_data,
  seed = params$simulation_seed,
  tol_rel_obj = params$vb_tol_rel_obj,  # relative ELBO change that counts as converged
  grad_samples = params$vb_grad_samples  # draws per gradient step
)
```

The habits below are owned by other sections; each rule lives in one place only.

| Habit | Do instead | Rule lives in |
| --- | --- | --- |
| Growing an object with `rbind()` in a loop | `map()` then `list_rbind()` | Tidyverse grammar |
| Commented-out code | Delete it; leave one line on what was tried | Signature comments |
| `suppressWarnings()` around a block | Fix the cause, or `muffle_warning()` one named warning | Console output |
| `<<-` and hidden globals | Pass values as arguments and return results | Functions |
| `require()`, a redefined `library()` | `library()` in one quiet block in setup.R | Formatting |
| Private aliases (`mlast()`, `g`) | dplyr and stats functions; `~/.Rprofile` | Naming |

## Before committing a script

Before considering a file ready, read it top to bottom as a colleague encountering it for the first time. Each question below should be answered by the file itself, without running it or asking its author.

| Reader's question | What the code should provide | Where this guide covers it |
| --- | --- | --- |
| Why does this file exist? | A short, current orientation | Anatomy of a script |
| What does one row represent? | A visible input and output grain | Anatomy of a script, Naming |
| What do these objects mean? | Informative names and clear units | Naming, Signature comments |
| Where does the scientific judgement enter? | Named settings and honest comments | Signature comments, Habits to avoid |
| What is removed, combined or expanded? | Explicit filters, grouping and join contracts | Tidyverse grammar, Data safety in code |
| What happens to missing or invalid values? | Deliberate, visible rules | Data safety in code |
| What can this function change? | Clear inputs, outputs and side effects | Functions |
| How will a problem be noticed? | Contextual conditions and proportionate diagnostics | Console output, Data safety in code |

Then run the mechanical checks below.

Run these ten checks before a script's change reaches main or feeds any shared table, figure or artefact. Work-in-progress commits on a branch can be pushed freely.

1. The header is true: Purpose, Inputs, Outputs, Run (or Sourced by) and Part match what the file reads, writes and how it runs.
2. The script runs clean from a fresh R session at the project root with its Run line. A Stan fit may use `params$rapid_stan_fit <- TRUE` for this check.
3. One run with warnings as errors passes: `Rscript -e 'options(warn = 2, warnPartialMatchDollar = TRUE, warnPartialMatchArgs = TRUE); source("code/03_data/build_ili_weekly.R")'`. Any remaining warning is fixed, or muffled by name with a comment.
4. The log shows each read (rows, ISO weeks, vintage), each drop with its reason, and each write (path, rows, range).
5. Every join declares its relationship, keys are asserted unique at the stated grain, no key is pasted, and columns are addressed by name.
6. Weekly rows carry a Sunday `week_end` and a `"YYYY-Www"` `year_week`, W53 is handled, and every input is filtered by `params$as_of`. No `Sys.Date()` or date literal sits outside the settings file.
7. Every value column has its unit in its name or in a unit column, NA stays distinct from 0, and exclusions print with their reasons.
8. Every figure was opened as the rendered file; its caption names source, data vintage, script and every shaping rule, and its axes carry units.
9. `styler::style_file(path, strict = FALSE)` changes nothing and `lintr::lint()` reports nothing, or each exception carries a comment saying why.
10. The repo-level checks pass as the [Repo Practice Guide](REPO_PRACTICE_GUIDE.md) sets them: what may be committed, private data, tests and renv.
