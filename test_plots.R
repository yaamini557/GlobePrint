source("R/plots.R")
processed <- readRDS("data/processed.rds")

# Test with India, Rwanda, Norway, China
test_countries <- c("India", "Rwanda", "Norway", "China")

dir.create("test_output", showWarnings = FALSE)

for (cname in test_countries) {
  cat("Testing country:", cname, "\n")
  cdf <- processed$gap_df %>% filter(country == cname)
  
  p1 <- draw_life_stripes(cdf, cname)
  p2 <- draw_growth_spiral(cdf, cname)
  p3 <- draw_bubble_art(cdf, processed$all_2007, cname)
  p4 <- draw_population_rings(cdf, cname)
  
  # Test ggsave with ragg
  ggsave(file.path("test_output", paste0("test_", cname, "_stripes.png")), p1, device = ragg::agg_png, width = 8, height = 6, dpi = 150)
  ggsave(file.path("test_output", paste0("test_", cname, "_spiral.png")), p2, device = ragg::agg_png, width = 7, height = 7, dpi = 150)
  ggsave(file.path("test_output", paste0("test_", cname, "_bubble.png")), p3, device = ragg::agg_png, width = 6, height = 8, dpi = 150)
  ggsave(file.path("test_output", paste0("test_", cname, "_rings.png")), p4, device = ragg::agg_png, width = 6.4, height = 8, dpi = 150)
  
  cat("  -> All 4 posters generated successfully for", cname, "\n")
}
cat("Poster generation test completed successfully!\n")
