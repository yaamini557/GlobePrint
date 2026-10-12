library(gapminder)
library(dplyr)
library(countrycode)
library(rnaturalearth)
library(sf)

gap_countries <- distinct(gapminder, country, continent) %>%
  mutate(
    country_char = as.character(country),
    iso3 = countrycode(country_char, origin = "country.name", destination = "iso3c",
                       custom_match = c(
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
                       ))
  )

# Test map_units
mu <- rnaturalearth::ne_countries(scale = "medium", type = "map_units", returnclass = "sf")

# Clean mu iso3
# In rnaturalearth, iso_a3 for France, Norway, etc. might be -99 or adm0_a3 / gu_a3
mu_clean <- mu %>%
  mutate(
    map_iso3 = case_when(
      gu_a3 != "-99" & !is.na(gu_a3) & nchar(gu_a3) == 3 ~ gu_a3,
      adm0_a3 != "-99" & !is.na(adm0_a3) & nchar(adm0_a3) == 3 ~ adm0_a3,
      iso_a3 != "-99" & !is.na(iso_a3) & nchar(iso_a3) == 3 ~ iso_a3,
      TRUE ~ sov_a3
    )
  )

# Check custom fixes for mu
# France in map_units has gu_a3 = "FXX" or "FRA", Norway has "NOR", etc.
cat("France in mu:", mu_clean %>% filter(grepl("France", name)) %>% pull(map_iso3), "\n")
cat("Norway in mu:", mu_clean %>% filter(grepl("Norway", name)) %>% pull(map_iso3), "\n")
cat("Reunion in mu:", mu_clean %>% filter(grepl("Reunion|Réunion", name)) %>% pull(map_iso3), "\n")

# Let's map all 142
matched_mu <- gap_countries$iso3 %in% mu_clean$map_iso3
cat("Total gapminder countries matched in map_units:", sum(matched_mu), "out of", nrow(gap_countries), "\n")

if (sum(!matched_mu) > 0) {
  unm <- gap_countries[!matched_mu, ]
  print(unm)
}
