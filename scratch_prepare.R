library(gapminder)
library(dplyr)
library(tidyr)
library(countrycode)
library(rnaturalearth)
library(sf)

# 1. Inspect gapminder data
cat("Total rows:", nrow(gapminder), "\n")
cat("Unique countries:", n_distinct(gapminder$country), "\n")
cat("Years:", sort(unique(gapminder$year)), "\n")
cat("Years count:", length(unique(gapminder$year)), "\n")

# Continent counts
cont_counts <- gapminder %>% distinct(country, continent) %>% count(continent)
print(cont_counts)

# ISO3 mapping
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

print(filter(gap_countries, is.na(iso3)))

# Check rnaturalearth shapes
world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
cat("World countries in rnaturalearth:", nrow(world), "\n")

# Match with world
world_iso3 <- unique(c(world$iso_a3, world$adm0_a3, world$gu_a3, world$su_a3, world$sov_a3))

matched <- gap_countries$iso3 %in% world$iso_a3
cat("Direct iso_a3 matches:", sum(matched), "out of", nrow(gap_countries), "\n")

if (sum(!matched) > 0) {
  unmatched <- gap_countries[!matched, ]
  print(unmatched)
  for (i in 1:nrow(unmatched)) {
    code <- unmatched$iso3[i]
    cname <- unmatched$country_char[i]
    # search in world
    w_match <- world[world$adm0_a3 == code | world$gu_a3 == code | world$su_a3 == code | world$sov_a3 == code | grepl(code, world$iso_a3_eh), ]
    cat(cname, "(", code, ") matches in world adm0/gu/su:", nrow(w_match), "\n")
  }
}
