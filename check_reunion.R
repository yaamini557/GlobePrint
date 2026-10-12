library(rnaturalearth)
library(sf)

world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
cat("World names:\n")
print(head(names(world), 20))

# Search for Reunion in world
hits <- which(grepl("Reunion|Réunion|REU", paste(world$name, world$name_long, world$formal_en, world$gu_a3, world$adm0_a3, world$iso_a3), ignore.case = TRUE))
cat("Hits in ne_countries:", hits, "\n")
if (length(hits) > 0) {
  print(world[hits, c("name", "iso_a3", "adm0_a3", "gu_a3")])
}

# Check ne_download or tiny polygons or map units
# Let's check rnaturalearth::ne_countries(type = "map_units")
mu <- tryCatch(rnaturalearth::ne_countries(scale = "medium", type = "map_units", returnclass = "sf"), error = function(e) e)
if (!inherits(mu, "error")) {
  hits_mu <- which(grepl("Reunion|Réunion|REU", paste(mu$name, mu$name_long, mu$gu_a3, mu$adm0_a3, mu$iso_a3), ignore.case = TRUE))
  cat("Hits in map_units:", hits_mu, "\n")
  if (length(hits_mu) > 0) print(mu[hits_mu, c("name", "iso_a3", "adm0_a3", "gu_a3")])
}
