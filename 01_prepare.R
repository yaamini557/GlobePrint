# ==============================================================================
# Globeprint Data Preparation Script
# Builds data/processed.rds containing all precalculated country statistics,
# time-series data, similarity metrics, and sf world map boundaries.
# ==============================================================================

suppressPackageStartupMessages({
  library(gapminder)
  library(dplyr)
  library(tidyr)
  library(countrycode)
  library(rnaturalearth)
  library(sf)
})

message("--> Step 1: Processing Gapminder dataset...")

# Ensure factors are characters and sorted consistently
gap_df <- gapminder::gapminder %>%
  mutate(
    country = as.character(country),
    continent = as.character(continent)
  ) %>%
  arrange(country, year)

# Manual ISO3 mapping to ensure 100% precision
custom_iso3 <- c(
  "Cote d'Ivoire" = "CIV",
  "Congo, Dem. Rep." = "COD",
  "Congo, Rep." = "COG",
  "Hong Kong, China" = "HKG",
  "Korea, Dem. Rep." = "PRK",
  "Korea, Rep." = "KOR",
  "Reunion" = "REU",
  "Sao Tome and Principe" = "STP",
  "Slovak Republic" = "SVK",
  "Swaziland" = "SWZ",
  "Yemen, Rep." = "YEM"
)

# 1952 baseline and 2007 endline summaries
summary_1952 <- gap_df %>%
  filter(year == 1952) %>%
  select(
    country, continent,
    lifeExp_1952 = lifeExp,
    pop_1952 = pop,
    gdpPercap_1952 = gdpPercap
  )

summary_2007 <- gap_df %>%
  filter(year == 2007) %>%
  select(
    country,
    lifeExp_2007 = lifeExp,
    pop_2007 = pop,
    gdpPercap_2007 = gdpPercap
  )

# Combine and compute metrics
country_summary <- left_join(summary_1952, summary_2007, by = "country") %>%
  mutate(
    lifeExp_gain = round(lifeExp_2007 - lifeExp_1952, 1),
    gdp_multiple = round(gdpPercap_2007 / gdpPercap_1952, 1),
    pop_multiple = round(pop_2007 / pop_1952, 1),
    iso3 = countrycode(country, origin = "country.name", destination = "iso3c", custom_match = custom_iso3)
  )

# Overall rank: 1 = largest life expectancy gain, unique ranks 1..142
country_summary <- country_summary %>%
  arrange(desc(lifeExp_gain), country) %>%
  mutate(rank = row_number()) %>%
  arrange(country)

# Grouped continent rank
country_summary <- country_summary %>%
  group_by(continent) %>%
  arrange(desc(lifeExp_gain), country) %>%
  mutate(rank_continent = row_number(), total_in_continent = n()) %>%
  ungroup() %>%
  arrange(country)

message("--> Step 2: Calculating 'Countries like yours' similarity matrix...")

# Standardize 1952 baseline: life expectancy and log10(GDP per capita)
z_life <- scale(country_summary$lifeExp_1952)[, 1]
z_gdp  <- scale(log10(country_summary$gdpPercap_1952))[, 1]

n_countries <- nrow(country_summary)
dist_matrix <- as.matrix(dist(cbind(z_life, z_gdp)))

# For each country, find top 3 similar countries (preferring same continent)
similar_list <- vector("list", n_countries)
names(similar_list) <- country_summary$country

for (i in 1:n_countries) {
  this_country <- country_summary$country[i]
  this_cont <- country_summary$continent[i]
  
  df_sim <- data.frame(
    country = country_summary$country,
    continent = country_summary$continent,
    dist = dist_matrix[i, ],
    stringsAsFactors = FALSE
  ) %>%
    filter(country != this_country) %>%
    mutate(same_continent = (continent == this_cont)) %>%
    arrange(desc(same_continent), dist)
  
  # Pick top 3
  similar_list[[this_country]] <- df_sim$country[1:3]
}

country_summary$similar_countries <- similar_list[country_summary$country]

message("--> Step 3: Preparing world map boundary layers...")

world_sf <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

# Clean ISO3 codes in Natural Earth
world_sf <- world_sf %>%
  mutate(
    iso3 = case_when(
      name == "France" ~ "FRA",
      name == "Norway" ~ "NOR",
      name == "Kosovo" ~ "XKX",
      name == "Northern Cyprus" ~ "CYN",
      name == "Somaliland" ~ "SOM",
      !is.na(iso_a3) & iso_a3 != "-99" & nchar(iso_a3) == 3 ~ iso_a3,
      !is.na(adm0_a3) & adm0_a3 != "-99" & nchar(adm0_a3) == 3 ~ adm0_a3,
      !is.na(gu_a3) & gu_a3 != "-99" & nchar(gu_a3) == 3 ~ gu_a3,
      !is.na(sov_a3) & sov_a3 != "-99" & nchar(sov_a3) == 3 ~ sov_a3,
      TRUE ~ NA_character_
    )
  )

# Add Reunion polygon from map_units if not already present
if (!("REU" %in% world_sf$iso3)) {
  mu <- rnaturalearth::ne_countries(scale = "medium", type = "map_units", returnclass = "sf")
  reu <- mu %>% filter(iso_a3 == "REU" | gu_a3 == "REU" | name == "Réunion" | name == "Reunion")
  if (nrow(reu) > 0) {
    reu_sf <- reu[1, ]
    reu_sf$iso3 <- "REU"
    common_cols <- intersect(names(world_sf), names(reu_sf))
    world_sf <- bind_rows(world_sf[, common_cols], reu_sf[, common_cols])
  }
}

# Simplify geometry slightly for snappy WebGL/Leaflet rendering
world_sf_clean <- world_sf %>%
  select(iso3, map_name = name, geometry) %>%
  st_simplify(dTolerance = 0.01, preserveTopology = TRUE)

# Join country summary with world map
map_data <- left_join(world_sf_clean, country_summary, by = "iso3") %>%
  mutate(
    in_gapminder = !is.na(country),
    display_name = ifelse(in_gapminder, country, map_name)
  )

message("--> Step 4: Running Rigorous Data Assertions...")

# 1. Total countries == 142
stopifnot("Must have exactly 142 countries" = nrow(country_summary) == 142)

# 2. Total data points == 142 * 12 = 1704
stopifnot("Must have 1704 total observations (142 * 12)" = nrow(gap_df) == 142 * 12)

# 3. Exactly 12 data points per country
pts_per_country <- gap_df %>% count(country) %>% pull(n)
stopifnot("Each country must have exactly 12 data points" = all(pts_per_country == 12))

# 4. Years: 1952 to 2007 in 5-year intervals
expected_years <- as.integer(seq(1952, 2007, by = 5))
actual_years <- as.integer(sort(unique(gap_df$year)))
stopifnot("Years must be 1952 to 2007 every 5 years" = identical(actual_years, expected_years))

# 5. Continents: Africa 52, Americas 25, Asia 33, Europe 30, Oceania 2
continent_tally <- table(country_summary$continent)
stopifnot(
  "Africa count must be 52"   = continent_tally["Africa"] == 52,
  "Americas count must be 25" = continent_tally["Americas"] == 25,
  "Asia count must be 33"     = continent_tally["Asia"] == 33,
  "Europe count must be 30"   = continent_tally["Europe"] == 30,
  "Oceania count must be 2"   = continent_tally["Oceania"] == 2
)

# 6. No NAs in key metrics
stopifnot(
  "No NA in lifeExp_gain" = !any(is.na(country_summary$lifeExp_gain)),
  "No NA in gdp_multiple" = !any(is.na(country_summary$gdp_multiple)),
  "No NA in pop_multiple" = !any(is.na(country_summary$pop_multiple)),
  "No NA in ISO3"         = !any(is.na(country_summary$iso3))
)

# 7. Unique ranks 1..142
stopifnot("Ranks must be unique 1 to 142" = identical(sort(country_summary$rank), 1:142))

# 8. All 142 countries present in map dataset
map_countries_present <- map_data %>% filter(in_gapminder) %>% pull(country) %>% unique()
missing_map <- setdiff(country_summary$country, map_countries_present)
if (length(missing_map) > 0) {
  warning("Countries missing map shape: ", paste(missing_map, collapse = ", "))
}
stopifnot("All 142 countries must be present in map polygons" = length(map_countries_present) == 142)

message("--> All assertions PASSED successfully!")

# All 2007 data for background context in Bubble Art
all_2007 <- gap_df %>% filter(year == 2007)

# Precalculate 2007 global stats
global_stats <- list(
  total_countries = 142,
  year_start = 1952,
  year_end = 2007,
  years_count = 12,
  continent_counts = as.list(continent_tally)
)

processed_data <- list(
  country_summary = country_summary,
  gap_df = gap_df,
  all_2007 = all_2007,
  map_data = map_data,
  global_stats = global_stats
)

message("--> Step 5: Saving data/processed.rds...")
saveRDS(processed_data, file = "data/processed.rds", compress = "xz")
message("--> data/processed.rds created successfully (", round(file.size("data/processed.rds") / 1024, 1), " KB)!")
