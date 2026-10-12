pkgs <- c("shiny", "bslib", "tidyverse", "gapminder", "sf", 
            "rnaturalearth", "rnaturalearthdata", "countrycode", 
            "leaflet", "ggplot2", "ggforce", "ragg", "showtext", 
            "sysfonts", "scales", "glue", "plotly", "shinycssloaders", "memoise")

for (p in pkgs) {
  res <- tryCatch({
    suppressPackageStartupMessages(library(p, character.only = TRUE))
    "OK"
  }, error = function(e) conditionMessage(e))
  cat(sprintf("%-20s: %s\n", p, res))
}
