pkgs <- c(
  "shiny", "bslib", "tidyverse", "gapminder", "sf", 
  "rnaturalearth", "rnaturalearthdata", "countrycode", 
  "leaflet", "ggplot2", "ggforce", "ragg", "showtext", 
  "sysfonts", "scales", "glue", "plotly", "shinycssloaders", "memoise"
)

installed <- rownames(installed.packages())
missing_pkgs <- setdiff(pkgs, installed)

if (length(missing_pkgs) > 0) {
  message("Installing missing packages: ", paste(missing_pkgs, collapse = ", "))
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
} else {
  message("All required packages are already installed!")
}
