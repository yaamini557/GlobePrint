# ==============================================================================
# Test Shiny App Launch and HTTP Response
# ==============================================================================

library(shiny)
library(httpuv)

cat("Starting Shiny app background test...\n")

# Run app in child process or background
# We can start app on port 3838
app <- shinyAppFile("app.R")
cat("app.R loaded without syntax errors!\n")
