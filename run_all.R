# Master replication script. Run from repository root: Rscript run_all.R
options(warn = 1)
dir.create("outputs", showWarnings = FALSE, recursive = TRUE)
dir.create("logs", showWarnings = FALSE, recursive = TRUE)
cat("Replication attempt started\n")
cat("Working directory:", getwd(), "\n")
data_path <- "data/SPA_combined_sample.xls"
if (!file.exists(data_path)) {
  cat("BLOCKED: required original data file missing:", data_path, "\n")
  cat("Existing LaTeX comparison table is preserved in outputs; it was NOT regenerated.\n")
  cat("The full estimation pipeline cannot run without the original data.\n")
} else {
  cat("Found input data. Running Tobit estimation.\n")
  source("tobitModel_econProject_092526.R", echo = FALSE)
  cat("Estimation finished.\n")
}
cat("\n--- R environment ---\n")
print(sessionInfo())
if (!file.exists(data_path)) quit(save = "no", status = 1)
