source("R/plots.R")
source("R/ui_helpers.R")
processed_data <- readRDS("data/processed.rds")
country_summary <- processed_data$country_summary
gap_df <- processed_data$gap_df
all_2007 <- processed_data$all_2007

# Test reactive calculation
c_row <- country_summary %>% filter(country == "India")
c_ts  <- gap_df %>% filter(country == "India")

p1 <- draw_life_stripes(c_ts, "India")
p2 <- draw_growth_spiral(c_ts, "India")
p3 <- draw_bubble_art(c_ts, all_2007, "India")
p4 <- draw_population_rings(c_ts, "India")

# Test saving to png with tiny dimensions to test margin safety
png("test_small_1.png", width = 300, height = 300)
print(p1)
dev.off()

png("test_small_2.png", width = 300, height = 300)
print(p2)
dev.off()

png("test_small_3.png", width = 300, height = 300)
print(p3)
dev.off()

png("test_small_4.png", width = 300, height = 300)
print(p4)
dev.off()

cat("Tiny dimension test finished successfully!\n")
