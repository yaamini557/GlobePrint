html <- paste(readLines('http://127.0.0.1:3838', warn = FALSE), collapse = '\n')
cat('HTML Length:', nchar(html), '\n')
checks <- c(
  'Title' = grepl('<title>Globeprint \\| 142 countries, 1952-2007</title>', html),
  'Pill Badge' = grepl('142 countries \\| 1952-2007 \\| 12 data points each', html),
  'Map Title' = grepl('The world at a glance \\(142 countries, 1952-2007\\)', html),
  'Gallery Caption' = grepl('Pin-worthy art from 55 years of data, 1952-2007\\.', html),
  'Compare Title' = grepl('Countries like yours \\(1952-2007\\)', html),
  'Footer Fact' = grepl('Globeprint \\| 142 countries \\| 1952-2007 \\| Data ends in 2007', html)
)
print(checks)
if (!all(checks)) stop('Some HTML checks failed!')
cat('All HTTP endpoint checks verified successfully!\n')
