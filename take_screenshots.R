edge_path <- "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
dir.create("screenshots", showWarnings = FALSE)

p1 <- normalizePath("screenshots/desktop_1400.png", winslash = "\\", mustWork = FALSE)
p2 <- normalizePath("screenshots/mobile_390.png", winslash = "\\", mustWork = FALSE)

cat("Target 1:", p1, "\n")
cat("Target 2:", p2, "\n")

cat("Taking desktop screenshot...\n")
system2(edge_path, args = c(
  "--headless=new",
  "--disable-gpu",
  "--hide-scrollbars",
  "--window-size=1400,2800",
  paste0("--screenshot=", p1),
  "http://127.0.0.1:3838"
))

cat("Taking mobile screenshot...\n")
system2(edge_path, args = c(
  "--headless=new",
  "--disable-gpu",
  "--hide-scrollbars",
  "--window-size=390,3400",
  paste0("--screenshot=", p2),
  "http://127.0.0.1:3838"
))

cat("Desktop screenshot exists:", file.exists(p1), if (file.exists(p1)) paste0("(", round(file.size(p1)/1024), " KB)") else "", "\n")
cat("Mobile screenshot exists:", file.exists(p2), if (file.exists(p2)) paste0("(", round(file.size(p2)/1024), " KB)") else "", "\n")
