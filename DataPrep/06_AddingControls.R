# -------------------------------------------------------------------------
# FILE: 06_add_controls.R (CLEAN + ROBUST VERSION)
# PURPOSE: Add control variables (GDP, trade openness, distance)
# -------------------------------------------------------------------------

rm(list = ls())

# -------------------------------------------------------------------------
# LIBRARIES
# -------------------------------------------------------------------------
library(dplyr)
library(WDI)
library(countrycode)

# -------------------------------------------------------------------------
# STEP 1: LOAD DATA
# -------------------------------------------------------------------------
cat("\n========== LOADING DATA ==========\n")

file_path <- if (file.exists("fdi_unga_merged.rds")) {
  "fdi_unga_merged.rds"
} else if (file.exists("fdi_unga_merged.csv")) {
  "fdi_unga_merged.csv"
} else {
  stop("❌ No input data found. Run previous script first.")
}

df <- if (grepl(".rds$", file_path)) {
  readRDS(file_path)
} else {
  read.csv(file_path, stringsAsFactors = FALSE)
}

cat("✓ Data loaded:", dim(df)[1], "rows\n")

# -------------------------------------------------------------------------
# STEP 2: CREATE ISO3 CODES (ROBUST)
# -------------------------------------------------------------------------
cat("\n========== COUNTRY CODE MATCHING ==========\n")

df <- df %>%
  mutate(
    iso3c = countrycode(country, "country.name", "iso3c", warn = FALSE)
  )

# Manual fixes (ONLY if needed)
manual_fixes <- c(
  "Korea, Republic of" = "KOR",
  "Russia" = "RUS",
  "Vietnam" = "VNM",
  "Egypt" = "EGY",
  "Hong Kong" = "HKG",
  "Taiwan" = "TWN"
)

df$iso3c[is.na(df$iso3c)] <- manual_fixes[df$country[is.na(df$iso3c)]]

# Drop unmatched
df <- df %>% filter(!is.na(iso3c))

cat("✓ Countries matched:", n_distinct(df$iso3c), "\n")

# -------------------------------------------------------------------------
# STEP 3: DOWNLOAD WDI DATA (FIXED)
# -------------------------------------------------------------------------
cat("\n========== DOWNLOADING WDI ==========\n")

# Remove problematic countries (e.g., Taiwan)
valid_iso3 <- unique(df$iso3c)
valid_iso3 <- valid_iso3[valid_iso3 != "TWN"]

# Define indicators (keep ORIGINAL names)
indicators <- c(
  "NY.GDP.MKTP.KD",
  "NY.GDP.PCAP.KD",
  "NE.TRD.GNFS.ZS"
)

wdi_data <- WDI(
  country = valid_iso3,
  indicator = indicators,
  start = min(df$year),
  end = max(df$year),
  extra = FALSE
)

# Rename AFTER download (correct names)
wdi_data <- wdi_data %>%
  rename(
    gdp_constant = NY.GDP.MKTP.KD,
    gdp_per_capita = NY.GDP.PCAP.KD,
    trade_openness = NE.TRD.GNFS.ZS
  ) %>%
  select(iso3c, year, gdp_constant, gdp_per_capita, trade_openness)

cat("✓ WDI downloaded:", nrow(wdi_data), "rows\n")

# -------------------------------------------------------------------------
# STEP 4: DISTANCE DATA
# -------------------------------------------------------------------------
cat("\n========== ADDING DISTANCE ==========\n")

distance_data <- data.frame(
  iso3c = c("USA","CAN","MEX","BRA","GBR","FRA","DEU","JPN","CHN","IND"),
  distance_to_us = c(0, 2100, 2000, 7800, 5900, 6500, 7100, 10800, 11100, 13000)
)

# (You can expand this later if needed)

# -------------------------------------------------------------------------
# STEP 5: MERGE EVERYTHING (SAFE JOINS)
# -------------------------------------------------------------------------
cat("\n========== MERGING ==========\n")

df_final <- df %>%
  left_join(wdi_data, by = c("iso3c", "year")) %>%
  left_join(distance_data, by = "iso3c")

cat("✓ Merge complete\n")

# -------------------------------------------------------------------------
# STEP 6: TRANSFORM VARIABLES
# -------------------------------------------------------------------------
cat("\n========== TRANSFORMING VARIABLES ==========\n")

df_final <- df_final %>%
  mutate(
    # Logs (safe)
    ln_gdp = log(pmax(gdp_constant, 1)),
    ln_gdp_pc = log(pmax(gdp_per_capita, 1)),
    ln_trade = log(pmax(trade_openness, 1)),
    ln_distance = log(pmax(distance_to_us, 1)),
    
    # FDI logs (safe)
    ln_fdi_tech = log(pmax(fdi_tech, 0) + 1),
    ln_fdi_finance = log(pmax(fdi_finance, 0) + 1),
    ln_fdi_mining = log(pmax(fdi_mining, 0) + 1),
    
    # Fixed effects
    country_fe = as.factor(country),
    year_fe = as.factor(year)
  )

cat("✓ Transformations done\n")

# -------------------------------------------------------------------------
# STEP 7: DATA CHECK
# -------------------------------------------------------------------------
cat("\n========== DATA CHECK ==========\n")

vars <- c("ln_fdi_tech", "IdealPointDistance", "ln_gdp", "ln_trade")

for (v in vars) {
  if (v %in% names(df_final)) {
    cat(v, "missing:", round(mean(is.na(df_final[[v]])) * 100, 1), "%\n")
  }
}

reg_sample <- df_final %>%
  filter(!is.na(ln_fdi_tech), !is.na(IdealPointDistance))

cat("\nRegression observations:", nrow(reg_sample), "\n")

# -------------------------------------------------------------------------
# STEP 8: SAVE OUTPUT
# -------------------------------------------------------------------------
cat("\n========== SAVING ==========\n")

saveRDS(df_final, "fdi_unga_with_controls.rds")
write.csv(df_final, "fdi_unga_with_controls.csv", row.names = FALSE)

cat("✓ Files saved\n")

# -------------------------------------------------------------------------
# DONE
# -------------------------------------------------------------------------
cat("\n========== DONE ==========\n")