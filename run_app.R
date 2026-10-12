# Launch script for Globeprint Shiny App
options(shiny.port = 3838, shiny.host = "127.0.0.1")
message("Launching Globeprint on http://127.0.0.1:3838 ...")
shiny::runApp(appDir = ".", port = 3838, host = "127.0.0.1", launch.browser = FALSE)
