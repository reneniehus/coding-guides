# <Project title>

<Two lines: what the project estimates or monitors, for whom, from which data.>

**Status:** <public or private> repo; access: <who can see the repo, and who can see its restricted inputs> (see [Published / withheld](#published--withheld));
data as of <YYYY-MM-DD>; settings <vN>; latest tag <report-YYYY-MM-DD-name>.

## Start here

1. `./fetch-<source>.sh`: fetch each external source kept outside git, if any (<size>; see data/DATA_REGISTER.md).
2. `AS_OF=<YYYY-MM-DD> ./reproduce.sh`: rebuild every output.
   <Any cheaper mode, such as `./reproduce.sh page`, and what it needs.>
3. `Rscript run_tests.R`: offline tests, under a minute.

Results: `output/tables/`, `output/figures/`; deliverables in `artefact/`.
Restricted inputs: <file>, <access level>; ask <data owner> for access.
Without them: <what falls back to the public copy, and what is skipped>.
Environment and full setup: [quickstart](documentation/quickstart.md).

## Aim

<One paragraph.>

## Research questions

- RQ1: <question>
- RQ2: <question>

## In scope

- <countries, seasons, indicators, models>

## Out of scope

- <what is deliberately not done, and why>

## Headline findings

- <one-line finding> ([findings.md, YYYY-MM-DD](documentation/findings.md);
  `output/tables/<file>.csv`)

## Map

| Path | Holds | Link |
|---|---|---|
| reproduce.sh, fetch-*.sh, refresh-*.sh, run_tests.R | root entry points | see Start here |
| code/00_main.R | the runner | [00_main.R](code/00_main.R) |
| code/01_support/, code/02_settings/ | setup, helpers, settings_vN.R | [01_support](code/01_support/), [02_settings](code/02_settings/) |
| code/03_data/ | load and check inputs | [part page](code/03_data/PART_03_data.md) |
| code/04_analysis/ | fit and score models | [part page](code/04_analysis/PART_04_analysis.md) |
| code/05_figures/ | draw every figure | [part page](code/05_figures/PART_05_figures.md) |
| code/06_report/ | build the deliverables | [part page](code/06_report/PART_06_report.md) |
| stan/ | Stan models, one per file | [stan/](stan/) |
| data/ | inputs, one folder per source | [data/DATA_REGISTER.md](data/DATA_REGISTER.md) |
| output/ | everything code writes | regenerable; see Start here |
| artefact/ | deliverables that leave the project | tagged, see decisions.md |
| tests/testthat/ | unit and regression tests | run with run_tests.R |
| documentation/decisions.md | dated decision log | [decisions](documentation/decisions.md) |
| documentation/findings.md | lab notebook of results | [findings](documentation/findings.md) |
| documentation/reflections.md | interpretation and caveats | [reflections](documentation/reflections.md) |
| documentation/data_overview.md | what the data mean | [data overview](documentation/data_overview.md) |
| documentation/quickstart.md | clone to first result | [quickstart](documentation/quickstart.md) |
| documentation/guides/GUIDES.md | the guides repository, tagged version, date last checked | [guides](documentation/guides/GUIDES.md) |

## Published / withheld

| Published | Withheld |
|---|---|
| <file, and the script that made it> | <file, and why> |

## Guides

Built to the R Code Style Guide and the Repo Practice Guide, kept in [coding-guides](https://github.com/reneniehus/coding-guides).
Tag in use and date last checked: [guides/GUIDES.md](documentation/guides/GUIDES.md)

## Licence

Code: <licence> (LICENSE). Data: per source, see data/DATA_REGISTER.md.

## Caveats

- <limits a reader must know before quoting a number>
