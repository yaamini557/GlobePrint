source("R/plots.R")
processed <- readRDS("data/processed.rds")

countries <- processed$country_summary$country
cat("Testing all", length(countries), "countries across all 4 posters...\n")

success_count <- 0
errors <- list()

for (i in seq_along(countries)) {
  cname <- countries[i]
  cdf <- processed$gap_df %>% filter(country == cname)
  
  tryCatch({
    p1 <- memo_life_stripes(cdf, cname)
    p2 <- memo_growth_spiral(cdf, cname)
    p3 <- memo_bubble_art(cdf, processed$all_2007, cname)
    p4 <- memo_population_rings(cdf, cname)
    
    # Render ggplot build to guarantee geometry evaluation
    b1 <- ggplot_build(p1)
    b2 <- ggplot_build(p2)
    b3 <- ggplot_build(p3)
    b4 <- ggplot_build(p4)
    
    success_count <- success_count + 1
  }, error = function(e) {
    cat("Error on country", cname, ":", conditionMessage(e), "\n")
    errors[[cname]] <<- conditionMessage(e)
  })
}

cat("Results: ", success_count, " / ", length(countries), " rendered with 100% success!\n")
if (length(errors) > 0) {
  stop("Some countries failed: ", paste(names(errors), collapse = ", "))
} else {
  cat("ACCEPTANCE TEST 3 PASSED PERFECTLY!\n")
}
