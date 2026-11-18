Up: [project brief](../README.md)

# data/: inputs and their provenance

Only a source's own fetch or de-identification script writes here, into its own folder. Each delivery or live
download is a dated vintage folder, never overwritten. Field meanings are in
[data_overview.md](../documentation/data_overview.md).

## Sources

| Folder | What it is | Provider | Vintages | Refresh | Access | Licence, redistribution | Personal data |
|---|---|---|---|---|---|---|---|
| erviss/ | ILI and ARI consultation rates per 100 000, by country and ISO week | ECDC ERVISS weekly export | 2026-11-13 (latest) | fetch-erviss.sh | public | <terms; redistribution allowed?; attribution> | no |
| survey/ | Survey 2024, free text blanked (survey_public_notext.xlsx) | ECDC | 2024 export | make_public_survey.R | public | <terms> | no; verified by make_public_survey.R |
| population/ | population by country and age (population_<year>.fst) | <provider> | <vintage> | <script or manual> | public | <terms> | no |

## Not here

| What | Where | Variable | How to get it |
|---|---|---|---|
| Forecast-hub clone (<size>) | ../hubs/<repo> | HUB_DIR | ./fetch-hub.sh |
| Full survey export with free text | <private location> | SURVEY_FULL_PATH | ask <data owner>; personal data: record <ref>, deletion <date> |
