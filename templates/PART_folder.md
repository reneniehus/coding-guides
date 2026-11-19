Up: [project brief](../../README.md)

# code/03_data: load and check inputs

<One paragraph: what this part does, what it hands to the next part, and why.>

**Status:** <running, or "data ready; waiting for the owner's plan"
([plan_objective<N>.md](../../documentation/plan_objective<N>.md))>. A part that waits lists
no planned scripts: its one script is a placeholder entry function that reports the wait and
the data in place, and writes nothing.

**Needs:** data/erviss/<vintage>/ (public); $SURVEY_FULL_PATH (restricted; without it,
data/survey/survey_public_notext.xlsx is used and free-text outputs are skipped);
params$as_of.

## Entry functions (called by code/00_main.R)

- `load_erviss(params)`: ILI and ARI rates per 100 000 by country and ISO week
- `load_survey(params)`: survey answers, one row per country

## Scripts, in run order

| Order | Script | Purpose | Run |
|---|---|---|---|
| 1 | load_erviss.R | read and check the ERVISS vintage for params$as_of | sourced by 00_main.R |
| 2 | load_survey.R | read the survey, full or public copy | sourced by 00_main.R |

What each script reads and writes is in its header block.

## Outputs by question (optional)

| Output | Serves (objective or question in the brief) |
|---|---|
| output/figures/<name>.png | <objective N: what it shows> |

## Params used

- `params$as_of`, `params$scope_start`, `params$n_expected_countries`

## Assertions in this part

- <what is checked, and where the run stops>

## Known issues

- <YYYY-MM-DD: issue, or "none">
