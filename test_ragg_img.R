library(shiny)
library(ragg)
source("R/plots.R")

processed <- readRDS("data/processed.rds")
cdf <- processed$gap_df %>% filter(country == "India")

tmp <- tempfile(fileext = ".png")
ragg::agg_png(tmp, width = 700, height = 525, res = 100)
print(memo_life_stripes(cdf, "India"))
dev.off()

cat("Generated temp image:", file.exists(tmp), "(", file.size(tmp), "bytes )\n")
