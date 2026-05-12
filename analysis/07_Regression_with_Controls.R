# -------------------------------------------------------------------------
# FILE: 07_regression_with_controls.R
# PURPOSE: Run panel regressions with controls (publication-ready)
# -------------------------------------------------------------------------

rm(list = ls())

library(dplyr)
library(fixest)

# -------------------------------------------------------------------------
# STEP 1: LOAD DATA
# -------------------------------------------------------------------------
cat("\n========== LOADING DATA ==========\n")

df <- readRDS("fdi_unga_with_controls.rds")

cat("✓ Data loaded:", nrow(df), "rows\n")

# -------------------------------------------------------------------------
# STEP 2: PREPARE REGRESSION SAMPLE
# -------------------------------------------------------------------------
cat("\n========== PREPARING DATA ==========\n")

df_reg <- df %>%
  filter(
    !is.na(ln_fdi_tech),
    !is.na(IdealPointDistance)
  )

cat("✓ Regression observations:", nrow(df_reg), "\n")
cat("✓ Countries:", n_distinct(df_reg$country), "\n")

# -------------------------------------------------------------------------
# STEP 3: BASELINE MODEL
# -------------------------------------------------------------------------
cat("\n========== BASELINE MODEL ==========\n")

model_1 <- feols(
  ln_fdi_tech ~ IdealPointDistance | country + year,
  data = df_reg,
  cluster = ~country
)

summary(model_1)

# -------------------------------------------------------------------------
# STEP 4: ADD ECONOMIC CONTROLS
# -------------------------------------------------------------------------
cat("\n========== ADDING CONTROLS ==========\n")

model_2 <- feols(
  ln_fdi_tech ~ IdealPointDistance + ln_gdp + ln_trade | country + year,
  data = df_reg,
  cluster = ~country
)

summary(model_2)

# -------------------------------------------------------------------------
# STEP 5: FULL MODEL (WITH DISTANCE)
# -------------------------------------------------------------------------
cat("\n========== FULL MODEL ==========\n")

model_3 <- feols(
  ln_fdi_tech ~ IdealPointDistance + ln_gdp + ln_trade + ln_distance | country + year,
  data = df_reg,
  cluster = ~country
)

summary(model_3)

# -------------------------------------------------------------------------
# STEP 6: ROBUSTNESS (ALTERNATIVE DV)
# -------------------------------------------------------------------------
cat("\n========== ROBUSTNESS CHECK ==========\n")

model_4 <- feols(
  ln_fdi_finance ~ IdealPointDistance + ln_gdp + ln_trade | country + year,
  data = df_reg,
  cluster = ~country
)

summary(model_4)

# -------------------------------------------------------------------------
# STEP 7: EXPORT RESULTS
# -------------------------------------------------------------------------
cat("\n========== EXPORTING RESULTS ==========\n")

etable(
  model_1, model_2, model_3, model_4,
  file = "regression_results.txt"
)

cat("✓ Results saved to regression_results.txt\n")
# -------------------------------------------------------------------------
# STEP 7: ADD LAGGED IPD
# -------------------------------------------------------------------------
cat("\n========== ADDING LAGGED IPD ==========\n")
df_reg <- df_reg %>%
  group_by(country) %>%
  arrange(year) %>%
  mutate(IdealPointDistance_lag1 = lag(IdealPointDistance, 1)) %>%
  ungroup()

model_lag <- feols(
  ln_fdi_tech ~ IdealPointDistance + IdealPointDistance_lag1 + ln_gdp + ln_trade | country + year,
  data = df_reg,
  cluster = ~country
)
summary(model_lag)

# -------------------------------------------------------------------------
# STEP 8: NO FIXED EFFECTS MODEL (DIAGNOSTIC)
# -------------------------------------------------------------------------
cat("\n========== NO FIXED EFFECTS MODEL ==========\n")
model_noFE <- feols(
  ln_fdi_tech ~ IdealPointDistance + ln_gdp + ln_trade,
  data = df_reg,
  cluster = ~country
)
summary(model_noFE)

# -------------------------------------------------------------------------
# STEP 9: INTERACTION WITH GDP
# -------------------------------------------------------------------------
cat("\n========== INTERACTION: IPD x GDP ==========\n")
model_IPD_GDP <- feols(
  ln_fdi_tech ~ IdealPointDistance * ln_gdp + ln_trade | country + year,
  data = df_reg,
  cluster = ~country
)
summary(model_IPD_GDP)

# -------------------------------------------------------------------------
# STEP 10: EXPORT ALL RESULTS
# -------------------------------------------------------------------------
cat("\n========== EXPORTING RESULTS ==========\n")
etable(
  model_1, model_2, model_3, model_4,
  model_lag, model_noFE, model_IPD_GDP,
  file = "regression_results_updated.txt"
)
cat("✓ Updated results saved to regression_results_updated.txt\n")

# -------------------------------------------------------------------------
# DONE
# -------------------------------------------------------------------------
cat("\n========== DONE ==========\n")
