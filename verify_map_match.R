library(gapminder)
library(dplyr)
library(countrycode)
library(rnaturalearth)
library(sf)

# 1. Base world
world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

# Clean world iso3
world <- world %>%
  mutate(
    iso3 = case_when(
      !is.na(iso_a3) & iso_a3 != "-99" & nchar(iso_a3) == 3 ~ iso_a3,
      !is.na(adm0_a3) & adm0_a3 != "-99" & nchar(adm0_a3) == 3 ~ adm0_a3,
      !is.na(gu_a3) & gu_a3 != "-99" & nchar(gu_a3) == 3 ~ gu_a3,
      !is.na(sov_a3) & sov_a3 != "-99" & nchar(sov_a3) == 3 ~ sov_a3,
      TRUE ~ NA_character_
    ),
    # Explicit override for France and Norway
    iso3 = case_when(
      name == "France" ~ "FRA",
      name == "Norway" ~ "NOR",
      TRUE ~ iso3
    )
  )

# Add Reunion from map_units if not in world
if (!("REU" %in% world$iso3)) {
  mu <- rnaturalearth::ne_countries(scale = "medium", type = "map_units", returnclass = "sf")
  reu <- mu %>% filter(iso_a3 == "REU" | gu_a3 == "REU" | name == "Réunion" | name == "Reunion")
  if (nrow(reu) > 0) {
    reu_sf <- reu[1, ]
    reu_sf$iso3 <- "REU"
    # match columns
    common_cols <- intersect(names(world), names(reu_sf))
    world <- bind_rows(world[, common_cols], reu_sf[, common_cols])
  }
}

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

matched <- gap_countries$iso3 %in% world$iso3
cat("Total gapminder countries matched:", sum(matched), "out of", nrow(gap_countries), "\n")
if (sum(!matched) > 0) {
  cat("Unmatched:\n")
  print(gap_countries[!matched, ])
} else {
  cat("ALL 142 COUNTRIES MATCHED PERFECTLY!\n")
}
