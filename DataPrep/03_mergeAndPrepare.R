# -------------------------------------------------------------------------
# FILE: 03_merge_and_prepare.R
# PURPOSE: Merge industry data, add country codes, merge with UN voting data
# -------------------------------------------------------------------------

# Clear environment
rm(list = ls())

# Load required libraries
library(dplyr)
library(tidyr)
library(stringr)

# Set working directory (UPDATE THIS PATH)
# setwd("C:/Users/YourName/Documents/FDI_Project")

# -------------------------------------------------------------------------
# LOAD CLEANED INDUSTRY DATA
# -------------------------------------------------------------------------

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("LOADING CLEANED INDUSTRY DATA\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

finance_data <- read.csv("finance_fdi_clean.csv", stringsAsFactors = FALSE)
mining_data <- read.csv("mining_fdi_clean.csv", stringsAsFactors = FALSE)
tech_data <- read.csv("tech_fdi_clean.csv", stringsAsFactors = FALSE)

cat("Finance:", nrow(finance_data), "obs,", n_distinct(finance_data$country), "countries\n")
cat("Mining:", nrow(mining_data), "obs,", n_distinct(mining_data$country), "countries\n")
cat("Tech:", nrow(tech_data), "obs,", n_distinct(tech_data$country), "countries\n")

# -------------------------------------------------------------------------
# COMBINE ALL THREE INDUSTRIES
# -------------------------------------------------------------------------

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("COMBINING INDUSTRIES\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Combine with explicit relationship specification
combined_data <- finance_data %>%
  full_join(mining_data, by = c("country", "year"), 
            relationship = "many-to-many") %>%
  full_join(tech_data, by = c("country", "year"),
            relationship = "many-to-many")

cat("Combined data dimensions:", dim(combined_data), "\n")
cat("Unique countries:", n_distinct(combined_data$country), "\n")
cat("Year range:", min(combined_data$year), "to", max(combined_data$year), "\n\n")

# Check for duplicates
dup_check <- combined_data %>%
  group_by(country, year) %>%
  summarise(n = n(), .groups = "drop") %>%
  filter(n > 1)

if(nrow(dup_check) > 0) {
  cat("⚠ Found", nrow(dup_check), "duplicate country-year combinations\n")
  cat("Removing duplicates (keeping first)...\n")
  combined_data <- combined_data %>%
    group_by(country, year) %>%
    slice(1) %>%
    ungroup()
  cat("After deduplication:", nrow(combined_data), "rows\n")
}

# Summary of missing values
missing_summary <- combined_data %>%
  summarise(
    finance_obs = sum(!is.na(fdi_finance)),
    finance_pos = sum(fdi_finance > 0, na.rm = TRUE),
    mining_obs = sum(!is.na(fdi_mining)),
    mining_pos = sum(fdi_mining > 0, na.rm = TRUE),
    tech_obs = sum(!is.na(fdi_tech)),
    tech_pos = sum(fdi_tech > 0, na.rm = TRUE)
  )

cat("\n=== OBSERVATIONS PER INDUSTRY ===\n")
print(missing_summary)

# -------------------------------------------------------------------------
# CREATE COUNTRY CODE CROSSWALK
# -------------------------------------------------------------------------

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("COUNTRY CODE MAPPING\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Get unique countries from your data
unique_countries <- unique(combined_data$country)
cat("Unique countries in data:", length(unique_countries), "\n")

# Show all countries for review
cat("\nALL COUNTRIES IN DATA:\n")
print(sort(unique_countries))

# Comprehensive country crosswalk (expanded)
country_crosswalk <- data.frame(
  country = c(
    "Argentina", "Aruba", "Australia", "Austria", "Bahamas", "Bahrain", 
    "Barbados", "Belgium", "Bermuda", "Brazil", "Canada", "Cayman Islands", 
    "Chile", "China", "Colombia", "Costa Rica", "Czech Republic", "Denmark", 
    "Dominican Republic", "Ecuador", "Egypt", "El Salvador", "Finland", 
    "France", "Germany", "Greece", "Guatemala", "Honduras", "Hong Kong", 
    "Hungary", "India", "Indonesia", "Ireland", "Israel", "Italy", "Jamaica", 
    "Japan", "Jordan", "Kazakhstan", "Korea, Republic of", "Kuwait", 
    "Luxembourg", "Malaysia", "Mexico", "Netherlands", "Netherlands Antilles",
    "New Zealand", "Nicaragua", "Norway", "Oman", "Panama", "Peru", 
    "Philippines", "Poland", "Portugal", "Qatar", "Romania", "Russia", 
    "Saudi Arabia", "Singapore", "South Africa", "Spain", "Sweden", 
    "Switzerland", "Taiwan", "Thailand", "Trinidad and Tobago", "Turkey", 
    "United Arab Emirates", "United Kingdom", "Uruguay", "Venezuela", 
    "Vietnam"
  ),
  cow_code = c(
    160, 60, 900, 305, 60, 692, 60, 211, 60, 140, 20, 60, 155, 710, 100, 
    94, 316, 390, 94, 130, 651, 94, 375, 220, 255, 350, 94, 94, 1110, 310, 
    750, 850, 205, 666, 325, 94, 740, 663, 705, 731, 690, 60, 820, 70, 210, 
    60, 920, 94, 385, 698, 95, 135, 840, 290, 235, 697, 360, 365, 670, 830, 
    560, 230, 380, 225, 713, 800, 94, 640, 696, 200, 165, 101, 815
  ),
  iso3c = c(
    "ARG", "ABW", "AUS", "AUT", "BHS", "BHR", "BRB", "BEL", "BMU", "BRA", 
    "CAN", "CYM", "CHL", "CHN", "COL", "CRI", "CZE", "DNK", "DOM", "ECU", 
    "EGY", "SLV", "FIN", "FRA", "DEU", "GRC", "GTM", "HND", "HKG", "HUN", 
    "IND", "IDN", "IRL", "ISR", "ITA", "JAM", "JPN", "JOR", "KAZ", "KOR", 
    "KWT", "LUX", "MYS", "MEX", "NLD", "ANT", "NZL", "NIC", "NOR", "OMN", 
    "PAN", "PER", "PHL", "POL", "PRT", "QAT", "ROU", "RUS", "SAU", "SGP", 
    "ZAF", "ESP", "SWE", "CHE", "TWN", "THA", "TTO", "TUR", "ARE", "GBR", 
    "URY", "VEN", "VNM"
  ),
  stringsAsFactors = FALSE
)

# Add country codes
combined_with_codes <- combined_data %>%
  left_join(country_crosswalk, by = "country")

# Check matching
matched <- combined_with_codes %>%
  filter(!is.na(cow_code)) %>%
  distinct(country) %>%
  arrange(country)

unmatched <- combined_with_codes %>%
  filter(is.na(cow_code)) %>%
  distinct(country) %>%
  arrange(country)

cat("\nCountries successfully matched:", nrow(matched), "/", length(unique_countries), "\n")

if(nrow(unmatched) > 0) {
  cat("\n⚠ COUNTRIES NOT MATCHED (these will be dropped from analysis):\n")
  print(unmatched)
  write.csv(unmatched, "unmatched_countries.csv", row.names = FALSE)
  cat("\nUnmatched countries saved to 'unmatched_countries.csv'\n")
}

# Filter to keep only matched countries
combined_matched <- combined_with_codes %>%
  filter(!is.na(cow_code))

cat("\nAfter filtering unmatched countries:", nrow(combined_matched), "observations\n")

# -------------------------------------------------------------------------
# MERGE WITH UN VOTING DATA
# -------------------------------------------------------------------------

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("MERGING WITH UN VOTING DATA\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Load your cleaned UN voting data
if(file.exists("cleaned_unga_us_dyads.csv")) {
  
  unga_data <- read.csv("cleaned_unga_us_dyads.csv")
  cat("✓ UN voting data loaded\n")
  cat("  Dimensions:", dim(unga_data), "\n")
  cat("  Year range:", min(unga_data$year), "to", max(unga_data$year), "\n")
  cat("  Unique countries:", n_distinct(unga_data$other_countries), "\n")
  
  # Merge
  final_data <- combined_matched %>%
    left_join(unga_data, by = c("cow_code" = "other_countries", "year"))
  
  cat("\n--- Merge Results ---\n")
  cat("Final dimensions:", dim(final_data), "\n")
  cat("Observations with UN voting data:", 
      sum(!is.na(final_data$IdealPointDistance)), "\n")
  
  # Observations with both FDI and UN data
  cat("\nObservations with both FDI and UN voting:\n")
  cat("  Finance:", sum(!is.na(final_data$fdi_finance) & !is.na(final_data$IdealPointDistance)), "\n")
  cat("  Mining:", sum(!is.na(final_data$fdi_mining) & !is.na(final_data$IdealPointDistance)), "\n")
  cat("  Tech:", sum(!is.na(final_data$fdi_tech) & !is.na(final_data$IdealPointDistance)), "\n")
  
  # Create regression-ready dataset
  regression_data <- final_data %>%
    mutate(
      ln_fdi_finance = log(fdi_finance + 1),
      ln_fdi_mining = log(fdi_mining + 1),
      ln_fdi_tech = log(fdi_tech + 1),
      has_finance = ifelse(!is.na(fdi_finance) & fdi_finance > 0, 1, 0),
      has_mining = ifelse(!is.na(fdi_mining) & fdi_mining > 0, 1, 0),
      has_tech = ifelse(!is.na(fdi_tech) & fdi_tech > 0, 1, 0)
    )
  
} else {
  cat("\n⚠ WARNING: cleaned_unga_us_dyads.csv not found\n")
  cat("Current directory:", getwd(), "\n")
  cat("Saving combined FDI data only.\n")
  regression_data <- combined_matched
}

# -------------------------------------------------------------------------
# EXPORT FINAL DATASETS
# -------------------------------------------------------------------------

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("EXPORTING DATA\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Export combined data with codes
write.csv(combined_matched, "combined_industry_fdi_with_codes.csv", row.names = FALSE)
cat("✓ Saved: combined_industry_fdi_with_codes.csv\n")

# Export final regression data
write.csv(regression_data, "fdi_unga_merged.csv", row.names = FALSE)
cat("✓ Saved: fdi_unga_merged.csv\n")

# Also save as RDS for faster loading later
saveRDS(regression_data, "fdi_unga_merged.rds")
cat("✓ Saved: fdi_unga_merged.rds\n")

# -------------------------------------------------------------------------
# FINAL SUMMARY
# -------------------------------------------------------------------------

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("FINAL SUMMARY\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

cat("\nData Coverage by Industry (1999-2024):\n")
coverage_summary <- regression_data %>%
  summarise(
    `Finance - Total Obs` = sum(!is.na(fdi_finance)),
    `Finance - Positive` = sum(fdi_finance > 0, na.rm = TRUE),
    `Mining - Total Obs` = sum(!is.na(fdi_mining)),
    `Mining - Positive` = sum(fdi_mining > 0, na.rm = TRUE),
    `Tech - Total Obs` = sum(!is.na(fdi_tech)),
    `Tech - Positive` = sum(fdi_tech > 0, na.rm = TRUE)
  )

print(coverage_summary)

if("IdealPointDistance" %in% names(regression_data)) {
  cat("\nUN Voting Data Coverage:\n")
  cat("  Total country-year obs with UN voting:", 
      sum(!is.na(regression_data$IdealPointDistance)), "\n")
  
  # Quick correlation check
  cat("\nCorrelation with UN Voting (2019-2023):\n")
  recent_cor <- regression_data %>%
    filter(year >= 2019, year <= 2023, !is.na(IdealPointDistance)) %>%
    summarise(
      `Finance (log)` = cor(IdealPointDistance, ln_fdi_finance, use = "complete.obs"),
      `Mining (log)` = cor(IdealPointDistance, ln_fdi_mining, use = "complete.obs"),
      `Tech (log)` = cor(IdealPointDistance, ln_fdi_tech, use = "complete.obs")
    )
  print(recent_cor)
  
  cat("\nInterpretation:\n")
  cat("  Negative correlation = More UN alignment = More FDI\n")
  cat("  Positive correlation = More UN alignment = Less FDI\n")
}

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("✓ SCRIPT COMPLETED SUCCESSFULLY!\n")
cat(paste(rep("=", 60), collapse = ""), "\n")