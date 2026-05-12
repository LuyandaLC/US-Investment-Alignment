# -------------------------------------------------------------------------
# FILE: 01_clean_bea_industry.R
# PURPOSE: Function to clean BEA industry data
# -------------------------------------------------------------------------

clean_bea_industry <- function(filepath, industry_name) {
  
  library(dplyr)
  library(tidyr)
  library(stringr)
  
  cat("\n", paste(rep("=", 60), collapse = ""), "\n")
  cat("Processing:", industry_name, "\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  # Read the file, skipping rows 1-4
  df <- read.csv(filepath, 
                 skip = 4,
                 header = TRUE,
                 check.names = FALSE,
                 stringsAsFactors = FALSE)
  
  cat("Initial dimensions:", dim(df), "\n")
  
  # The first column has no name - rename it to "country"
  names(df)[1] <- "country"
  
  # Remove any columns that are all NA
  df <- df[, !sapply(df, function(x) all(is.na(x)))]
  
  # Clean up country names: remove leading/trailing spaces
  df$country <- str_trim(df$country)
  
  # Count before filtering
  n_before <- nrow(df)
  
  # Define patterns to remove (aggregates, regions, footnotes)
  remove_patterns <- c(
    # Regional aggregates
    "^All Countries Total$", "^Europe$", "^Asia$", "^Africa$", "^Oceania$",
    "^North America$", "^South America$", "^Central America$", "^Caribbean$",
    "^European Union$", "^EU$", "^ASEAN$", "^Latin America$", "^Middle East$",
    "^GCC$", "^OPEC$", "^OECD$", "^G7$", "^G20$",
    # Total variations
    "Total", "Total$", "Subtotal", "Sub-total",
    # Footnote indicators (often appear as standalone numbers or symbols)
    "^[0-9]+$", "^[0-9]+[0-9]$", "^[0-9]+[0-9][0-9]$",
    "^p$", "^r$", "^e$", "^P$", "^R$", "^E$",
    "^1$", "^2$", "^3$", "^4$", "^5$", "^6$", "^7$", "^8$", "^9$",
    "^Memorandum", "^Of which",
    # Empty strings
    "^$"
  )
  
  # Filter out unwanted rows
  df <- df %>%
    filter(
      # Remove empty country names
      country != "",
      !is.na(country),
      # Remove rows that match any pattern
      !grepl(paste(remove_patterns, collapse = "|"), country, ignore.case = TRUE)
    )
  
  cat("Removed", n_before - nrow(df), "aggregate/total/footnote rows\n")
  cat("Remaining rows:", nrow(df), "\n")
  
  # Convert from wide to long format
  df_long <- suppressWarnings(
    df %>%
      pivot_longer(
        cols = -country,
        names_to = "year",
        values_to = "fdi_value"
      ) %>%
      mutate(
        year = as.numeric(year),
        original_value = as.character(fdi_value),
        fdi_value = as.numeric(fdi_value)
      ) %>%
      filter(!is.na(year)) %>%
      rename(!!paste0("fdi_", industry_name) := fdi_value)
  )
  
  # Check for duplicates (same country and year)
  duplicates <- df_long %>%
    group_by(country, year) %>%
    summarise(n = n(), .groups = "drop") %>%
    filter(n > 1)
  
  if(nrow(duplicates) > 0) {
    cat("\n⚠ Found", nrow(duplicates), "duplicate country-year combinations\n")
    cat("Removing duplicates (keeping first observation)...\n")
    
    # Remove duplicates, keep first occurrence
    df_long <- df_long %>%
      group_by(country, year) %>%
      slice(1) %>%
      ungroup()
    
    cat("After deduplication:", nrow(df_long), "rows\n")
  }
  
  # Diagnostic
  suppressed_count <- df_long %>%
    filter(grepl("\\(D\\)|\\(NA\\)|\\(S\\)", original_value)) %>%
    nrow()
  
  cat("\n--- Data Quality Report ---\n")
  cat("Total country-year observations:", nrow(df_long), "\n")
  cat("Observations with suppressed values (D, NA, S):", suppressed_count, "\n")
  cat("Valid FDI observations:", sum(!is.na(df_long[[paste0("fdi_", industry_name)]])), "\n")
  cat("Year range:", min(df_long$year, na.rm = TRUE), "to", 
      max(df_long$year, na.rm = TRUE), "\n")
  cat("Unique countries:", n_distinct(df_long$country), "\n")
  
  # Show first few country names to verify
  cat("\nFirst 15 countries in dataset:\n")
  print(head(sort(unique(df_long$country)), 15))
  
  return(df_long)
}

cat("✓ Function 'clean_bea_industry' loaded successfully\n")

# -------------------------------------------------------------------------
# PURPOSE: Clean all three industry datasets using the function
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# APPLY TO ALL THREE INDUSTRIES
# -------------------------------------------------------------------------

# Clean each industry (update file paths to match your actual filenames)
finance_data <- clean_bea_industry("financeInsurance.csv", "finance")
mining_data <- clean_bea_industry("mining.csv", "mining")
tech_data <- clean_bea_industry("sciencetechserv.csv", "tech")

# -------------------------------------------------------------------------
# SAVE INDIVIDUAL INDUSTRY FILES
# -------------------------------------------------------------------------

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("SAVING INDIVIDUAL INDUSTRY FILES\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Remove original_value column before saving
finance_clean <- finance_data %>% select(-original_value)
mining_clean <- mining_data %>% select(-original_value)
tech_clean <- tech_data %>% select(-original_value)

# Save
write.csv(finance_clean, "finance_fdi_clean.csv", row.names = FALSE)
write.csv(mining_clean, "mining_fdi_clean.csv", row.names = FALSE)
write.csv(tech_clean, "tech_fdi_clean.csv", row.names = FALSE)

cat("✓ Saved: finance_fdi_clean.csv\n")
cat("✓ Saved: mining_fdi_clean.csv\n")
cat("✓ Saved: tech_fdi_clean.csv\n")

# Save the raw (with original_value) for debugging if needed
saveRDS(finance_data, "finance_data_raw.rds")
saveRDS(mining_data, "mining_data_raw.rds")
saveRDS(tech_data, "tech_data_raw.rds")

cat("✓ Saved RDS files for debugging\n")

# -------------------------------------------------------------------------
# SUMMARY
# -------------------------------------------------------------------------

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("PROCESSING SUMMARY\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

cat("\nFinance Industry:\n")
cat("  Observations:", nrow(finance_clean), "\n")
cat("  Countries:", n_distinct(finance_clean$country), "\n")
cat("  Years:", min(finance_clean$year), "-", max(finance_clean$year), "\n")

cat("\nMining Industry:\n")
cat("  Observations:", nrow(mining_clean), "\n")
cat("  Countries:", n_distinct(mining_clean$country), "\n")
cat("  Years:", min(mining_clean$year), "-", max(mining_clean$year), "\n")

cat("\nScience & Tech Industry:\n")
cat("  Observations:", nrow(tech_clean), "\n")
cat("  Countries:", n_distinct(tech_clean$country), "\n")
cat("  Years:", min(tech_clean$year), "-", max(tech_clean$year), "\n")

cat("\n✓ File 02 complete. Ready to run 03_merge_and_prepare.R\n")