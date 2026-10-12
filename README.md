# Globeprint

> **Every country has a Globeprint.**  
> *142 countries, 1952 to 2007: life, wealth and people, one country at a time.*

---

## 🌍 Overview

**Globeprint** is an editorial-grade, interactive R Shiny application and data-art generative platform. By selecting a single country—either via the searchable selector or by clicking anywhere on the interactive world map—Globeprint synthesizes 55 years of human progress (1952 to 2007) into key performance indicators, an auto-generated narrative story, global & regional rankings, an interactive comparative cohort analysis, and **four museum-grade, pin-worthy generative data art posters** rendered directly with `ggplot2` and `ggforce`.

---

## 📊 Certified Data Facts

All metrics in Globeprint are computed deterministically from real historical observations with zero interpolation or data synthesis:
- **Total Countries:** 142 countries
- **Time Horizon:** 1952 to 2007 (55 years)
- **Observations per Country:** 12 data points (every 5 years: 1952, 1957, 1962, 1967, 1972, 1977, 1982, 1987, 1992, 1997, 2002, 2007)
- **Total Data Points:** 1,704 observations (142 × 12)
- **Continents Distribution:**
  - 🌍 **Africa:** 52 countries
  - 🌎 **Americas:** 25 countries
  - 🌏 **Asia:** 33 countries
  - 🌍 **Europe:** 30 countries
  - 🌏 **Oceania:** 2 countries

---

## 🖼️ The Four Globeprints (Generative Art Gallery)

1. **Life Stripes (Landscape 4:3)**  
   *12 chunky vertical bars, one per 5-year observation, color-graded from soft ocean blue through warm cream to rich coral, highlighting the 1952 baseline and 2007 longevity milestone.*
2. **Growth Spiral (Square 1:1)**  
   *An Archimedean spiral on a deep midnight navy canvas (`#1B1F3B`) expanding from 1952 at center to 2007 outer ring. Distance represents GDP per capita (log scale), dot size represents life expectancy, and glowing node hues transition from cyan to sunset red.*
3. **Bubble Art (Tall 3:4)**  
   *A prosperity-versus-longevity trail over 55 years on a warm cream canvas (`#FAF7F0`), mapping life expectancy against log GDP per capita, sized by population, set against the faint backdrop of all 142 world nations in 2007.*
4. **Population Rings (Tall 4:5)**  
   *12 concentric geometric ring arcs on a deep teal canvas (`#0B252C`) from 1952 inner ring to 2007 outer perimeter, where ring thickness and color warmth dynamically scale with population growth.*

Every poster is downloadable as a high-resolution, print-ready 300 DPI PNG (`Globeprint_<Country>_<poster>.png`) powered by the `ragg` graphics engine.

---

## 🏗️ Project Structure

```
globeprint/
├── install.R                 # Package checker and automated dependency installer
├── 01_prepare.R              # Data wrangling, similarity clustering, assertions & map prep
├── app.R                     # Complete Shiny application UI and Server logic
├── R/
│   ├── plots.R               # 4 artistic poster generators with memoisation & ragg export
│   └── ui_helpers.R          # Modular UI components (KPIs, story builder, Top 5, Pin cards)
├── www/
│   ├── styles.css            # Pastel design system, Pinterest masonry columns, responsive styling
│   ├── logo.svg              # Vector logo icon (globe with flowing wave ribbon)
│   └── favicon.svg           # Vector favicon icon
├── data/
│   └── processed.rds         # Precalculated dataset, summaries, and sf polygon boundaries
├── screenshots/
│   ├── desktop_1400.png      # High-res desktop UI screenshot
│   └── mobile_390.png        # Responsive mobile UI screenshot
├── exports/                  # High-res 300 DPI exported sample posters
├── run_app.R                 # Standalone Shiny runner script
├── test_acceptance.R         # 9-point acceptance test suite
├── test_all_142.R            # Loop test verifying all 4 posters across all 142 countries
└── README.md                 # Project documentation and specifications
```

---

## 🚀 Getting Started

### 1. Prerequisites
- **R 4.3+**
- Packages required: `shiny`, `bslib`, `tidyverse`, `gapminder`, `sf`, `rnaturalearth`, `rnaturalearthdata`, `countrycode`, `leaflet`, `ggplot2`, `ggforce`, `ragg`, `showtext`, `sysfonts`, `scales`, `glue`, `plotly`, `shinycssloaders`, `memoise`.

### 2. Install Dependencies
Run the installer script to automatically check and install any missing packages:
```bash
Rscript install.R
```

### 3. Build & Assert Data
Prepare the unified dataset with strict data integrity assertions:
```bash
Rscript 01_prepare.R
```

### 4. Launch the Application
Start the Shiny app on `http://127.0.0.1:3838`:
```bash
Rscript run_app.R
```
Or within an active R console:
```r
shiny::runApp(port = 3838)
```

---

## 🧪 Acceptance Test Suite

Run the automated acceptance suite verifying all 9 requirements:
```bash
Rscript test_acceptance.R
```
All tests pass with 100% verification:
- ✅ **Test 1:** Exactly 142 countries, 12 years each, no NAs, unique ranks 1..142.
- ✅ **Test 2:** All 142 countries mapped with valid Natural Earth sf polygons.
- ✅ **Test 3:** All 4 poster generators render without error for all 142 countries (568 plots).
- ✅ **Test 4:** Dropdown and map click stay in sync; continent filters update map and Top 5.
- ✅ **Test 5:** Data facts ("142 countries", "1952-2007") verified across all 9 required UI locations.
- ✅ **Test 6:** 300 DPI high-res exports generate valid PNGs with standard file names.
- ✅ **Test 7:** Masonry gallery is responsive and balanced across desktop (1400px) and mobile (390px).
- ✅ **Test 8:** Elegant typography, high-contrast labels, and zero overlapping elements.
- ✅ **Test 9:** Shiny application live on `http://127.0.0.1:3838`.

---

## 📜 Attribution & License
- **Data Source:** [Gapminder.org](https://www.gapminder.org) via the `gapminder` R package by Jennifer Bryan (Creative Commons Attribution 4.0 International - CC BY 4.0).
- **Map Boundaries:** Natural Earth public domain map dataset via `rnaturalearth`.
- **Note:** *Data ends in 2007, so this is a historical story, not current news. It shows what happened, not why.*
