# ECON 5560 replication project — incomplete data package

## Paper replicated
This project attempts to reproduce the experimental-auction Tobit results for willingness to pay for neonicotinoid-free plant labels. **The full paper citation and permanent paper URL have not been verified and must be added by the student.**

## Data provenance
The required source file is `SPA_combined_sample.xls`. It was referenced by a teammate's R script but **was not included in the shared GitHub ZIP**. The original archive URL and download date are unknown. The missing data have **not** been fabricated or substituted. Add the authentic data to `data/` if obtained, after checking that no file exceeds 50 MB.

## How to run
Install R and the `readxl` package (e.g. in R: `install.packages("readxl")`). Clone this repository, open a terminal in its root, then run:

Windows PowerShell:
```powershell
Rscript run_all.R *> logs\run_log.txt
```

macOS/Linux:
```sh
Rscript run_all.R > logs/run_log.txt 2>&1
```

The script reports the missing dataset and exits with status 1 when the dataset is unavailable. **A completed successful fresh-clone run is not possible with the current package.** The R environment information is printed at the end of the log, even when data are missing. If data become available, the script will attempt to estimate models and save `outputs/tobit_table6.csv`.

## Files
- `run_all.R` — master script, missing-data check, and environment reporting.
- `tobitModel_econProject_092526.R` — teammate's Tobit model code, modified to use relative input path and save CSV output.
- `tobit_recreation_table_092926.tex` — pre-existing comparison table from teammate; not newly generated.
- `Shortened_Table.zip` — original supplied ZIP containing a LaTeX `main.tex` file.
- `data/` — expected location of original Excel dataset (currently absent).
- `outputs/tobit_recreation_table_092926.tex` — preserved copy of teammate's pre-existing table, not reproduced by this run.
- `logs/` — place for actual run log from a fresh clone.
- `.gitkeep` — keeps otherwise empty directories under version control.

## Software and dependencies
R, base `stats`, and `readxl` are required for model estimation. **Exact R and package versions are not yet known**; consult the `sessionInfo()` output in the log after running on the student's computer. LaTeX is optional for compiling `.tex` tables.

## Runtime
Not measured: the full pipeline cannot run without the source dataset.

## Known limitations and replication differences
- **Blocking:** original `SPA_combined_sample.xls` data are absent, so no Tobit estimates can be regenerated or independently verified.
- The included `.tex` results are pre-existing teammate output; they are not evidence of a successful fresh run.
- Teammate code omits the paper's individual random-effects term, substitutes plant dummies because a plant dictionary was unavailable, uses delta-method WTP standard errors and normal z-tests, and excludes missing attitude-importance observations in subgroups.
- The complete paper citation, data source URL, and download date need to be supplied and verified.
- A fresh-clone execution and genuine run log must be completed by the student; no successful run is claimed.
