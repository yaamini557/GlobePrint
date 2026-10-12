library(leaflet)
# Test tile URLs
m <- leaflet() %>% addProviderTiles(providers$OpenStreetMap)
cat("OpenStreetMap provider OK\n")

m2 <- leaflet() %>% addProviderTiles(providers$CartoDB.Positron)
cat("CartoDB.Positron provider OK\n")
