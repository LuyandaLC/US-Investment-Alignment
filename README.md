# US-Investment-Alignment
# Geopolitical Alignment and U.S. Technology FDI
### Does the U.S. invest more in countries that vote with it at the UN?

![R](https://img.shields.io/badge/Built%20with-R-276DC3?style=flat&logo=r)
![Data](https://img.shields.io/badge/Data-BEA%20%7C%20UN%20%7C%20World%20Bank-lightgrey)
![Panel](https://img.shields.io/badge/Panel-58%20Countries%2C%201999--2024-blue)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## Overview

This paper empirically tests the **"friend-shoring" hypothesis** : the assumption embedded in U.S. policy (CHIPS Act 2022, FIRRMA 2018) that political alignment attracts technology Foreign Direct Investment. Using an unbalanced panel of **58 countries observed annually from 1999 to 2024**, I find that geopolitical alignment with the United States, measured by UN General Assembly voting similarity, is **robustly and negatively associated with ideal point distance** from the U.S., meaning closer allies receive systematically more U.S. Science & Technology FDI as a share of their GDP.

Critically, **no equivalent effect is found in Finance or Mining**, suggesting this is a strategic, sector-specific dynamic rather than a general feature of U.S. outward investment.

---

## Key Finding

> A one-unit decrease in UN Ideal Point Distance (greater alignment) is associated with an increase of **0.150 to 0.184 percentage points of GDP** in U.S. Science & Technology FDI, approximately a **48% increase relative to the sample mean**, significant under both country fixed effects (p < 0.05) and two-way fixed effects (p < 0.05).

A naive OLS estimate produces the opposite sign, a methodological artifact driven by the strong negative correlation between ideal point distance and GDP per capita (r = −0.54). This sign reversal is itself a key diagnostic result, demonstrating why within-country fixed effects are essential for credible identification in cross-country FDI research.

---

## Why This Matters

U.S. foreign investment policy has increasingly treated political alignment as a criterion for technology partnerships:
- **FIRRMA (2018)** expanded CFIUS review to protect U.S. technological superiority
- **CHIPS Act (2022)** explicitly subsidized semiconductor investment in allied nations
- **"Friend-shoring"** (Yellen, 2022) became official U.S. national security strategy

This paper provides one of the first empirical benchmarks testing whether this alignment-investment logic was already present in pre-policy data — and finds evidence that it was.

---

## Data Sources

| Source | Variable | Coverage |
|---|---|---|
| U.S. Bureau of Economic Analysis (BEA, 2024) | Sector-level outward FDI | 1999–2024 |
| Bailey, Strezhnev & Voeten (2017) | UN Ideal Point Distance | 1999–2024 |
| World Bank WDI (2024) | GDP, Trade Openness, Institutional Quality | 1999–2024 |

FDI is scaled as a **percentage of host country GDP** to ensure cross-country comparability and avoid mechanical size bias from larger economies.

---

## Methodology

### Identification Strategy
Three progressive specifications address confounding from unobserved country heterogeneity:

```
(1) Pooled OLS        — baseline (upward biased due to income-alignment correlation)
(2) Country FE        — preferred specification; exploits within-country variation over time
(3) Two-Way FE        — country + year fixed effects; controls for global investment shocks
```

### Key Independent Variable
**UN Ideal Point Distance (IPD)** from Bailey, Strezhnev & Voeten (2017) — a continuous, time-varying measure of geopolitical alignment derived from the full history of UN General Assembly roll-call votes. Lower values indicate closer alignment with the U.S.

### Cross-Sector Comparison
Finance and Mining FDI are used as placebo sectors. Under country fixed effects:
- Science & Tech: β = −0.150 (SE = 0.072, **p < 0.05**) ✅
- Finance: β = −0.406 (SE = 0.812, p = 0.617) ✗
- Mining: β = −0.205 (SE = 0.169, p = 0.225) ✗

---

## Results Summary

| Specification | IPD Coefficient | Std. Error | Significance |
|---|---|---|---|
| Pooled OLS | +0.122 | 0.046 | p < 0.01 (biased ↑) |
| Country FE *(preferred)* | **−0.150** | **0.072** | **p < 0.05** |
| Two-Way FE | **−0.184** | **0.089** | **p < 0.05** |
| Finance (Country FE) | −0.406 | 0.812 | n.s. |
| Mining (Country FE) | −0.205 | 0.169 | n.s. |

---

## Visualizations

**Figure 1** Bimodal distribution of UN voting alignment across 58 countries (Western Europe cluster ≈ IPD 1.5; Global South/BRICS cluster ≈ IPD 2.9)
![Figure 1a](figure1a_ipd_distribution.png)

**Figure 2** IPD coefficient progression across OLS → Country FE → Two-Way FE, showing sign reversal and stabilization of the negative alignment effect
![Figure 5](figure5_coef_plot.png)

**Figure 3** Mean U.S. Science & Tech FDI over time (% of GDP) and average UN voting alignment trend (1999–2024)
![Figure 4a](figure4a_fdi_trend.png)

**Figure 4** IPD coefficient by sector (Science & Tech vs. Finance vs. Mining), showing sector-specificity of the alignment effect
![Figure 6](figure6_sector_comparison.png)

---

## Limitations & Future Work

- **Reverse causality** — large U.S. tech investment may itself shift a country's UN voting behavior; an instrumental variables approach (e.g., rotating UN Security Council membership) would address this
- **Non-random missingness** — BEA suppresses small-cell observations, likely excluding lower-alignment countries and creating upward bias in the alignment effect
- **Alignment measure scope** — UN ideal point scores reflect all resolutions, not technology-specific policy positions

**Proposed extensions:** IV strategy using rotating Security Council membership; firm-level analysis distinguishing intensive vs. extensive margin effects; post-2021 friend-shoring acceleration test

---

## Repository Structure

```
us-investment-alignment/
│
├── README.md
├── analysis.R              # Main regression script (OLS, Country FE, Two-Way FE)
├── data/
│   └── sources.md          # Data documentation and access links
├── outputs/
│   ├── figure1_ipd_dist.png
│   ├── figure2_coef_tech.png
│   ├── figure3a_fdi_time.png
│   ├── figure3b_ipd_time.png
│   └── figure4_sector_comparison.png
└── paper/
    └── UN_Alignment_vs_FDI.pdf
```

---

## References

- Bailey, M., Strezhnev, A., & Voeten, E. (2017). Estimating dynamic state preferences from United Nations voting data. *Journal of Conflict Resolution, 61*(2), 430–456.
- Bureau of Economic Analysis. (2024). U.S. direct investment abroad: Country and industry detail.
- World Bank. (2024). World Development Indicators.
- Yellen, J. (2022). Remarks on way forward for the global economy. Atlantic Council.
- Sullivan, J. (2023). Remarks on renewing American economic leadership. Brookings Institution.

---

## Author

**Luyanda Chibwe**  
B.A. Economics, Minor: Computer Science | Bates College (Expected May 2027)  
[LinkedIn](https://linkedin.com/in/luyanda-chibwe) | luyandachibwe9@gmail.com
