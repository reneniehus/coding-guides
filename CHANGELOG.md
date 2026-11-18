# Changelog

Each release is a git tag. Under each version, "Projects" says what a project that follows the previous version should do.

## v1.0 (2026-11-18)

First release, after one review round in comments.

- **R Code Style Guide:** how code inside `.R` files and Quarto chunks reads. Covers the header block (Purpose, Inputs, Outputs, Run, Part), the `+++` banners and `|-` markers, comments that say why, naming with units, tidyverse grammar, functions with `params` first, `cli` console output for supervising a run, data safety, plots, formatting, habits to avoid, and a read-through before every commit.
- **Repo Practice Guide:** how a project is built and kept healthy. Covers the documentation hierarchy (brief, `PART_<folder>.md` pages, script headers), the folder layout, inputs and outputs, one-command runs, reproducibility, tests, git hygiene with private data, and routine upkeep.
- **Templates:** project brief, part page, data register, guides pointer, script and function-file headers, `.gitignore` and `.Renviron.example`.

Projects: add `documentation/guides/GUIDES.md` from [templates/GUIDES.md](templates/GUIDES.md), record the version and the date checked, and list any lasting departures there.
