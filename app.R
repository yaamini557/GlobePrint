# ==============================================================================
# Globeprint R Shiny Application (app.R)
# "142 countries, 1952 to 2007: life, wealth and people, one country at a time."
# ==============================================================================

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(dplyr)
  library(tidyr)
  library(leaflet)
  library(ggplot2)
  library(ggforce)
  library(plotly)
  library(scales)
  library(glue)
  library(shinycssloaders)
  library(memoise)
  library(ragg)
})

# Source custom poster generation and UI helpers
source("R/plots.R")
source("R/ui_helpers.R")

# Load precalculated dataset and map geometries
processed_data <- readRDS("data/processed.rds")
country_summary <- processed_data$country_summary
gap_df          <- processed_data$gap_df
all_2007        <- processed_data$all_2007
map_data        <- processed_data$map_data
global_stats    <- processed_data$global_stats

country_choices <- sort(country_summary$country)
continent_choices <- c("All", "Africa", "Americas", "Asia", "Europe", "Oceania")

# Choropleth color palette for life expectancy gain
pal_gain <- colorNumeric(
  palette = c("#FFF1B8", "#FFD6C9", "#E76F51", "#9D0208"),
  domain = range(country_summary$lifeExp_gain, na.rm = TRUE),
  na.color = "#E5E7EB"
)

# Custom UI Theme
gp_theme <- bs_theme(
  version = 5,
  bg = "#FFF8F3",
  fg = "#3D3A50",
  primary = "#E76F51",
  base_font = font_google("Poppins"),
  heading_font = font_google("Playfair Display")
)

# ==============================================================================
# UI DEFINITION
# ==============================================================================
ui <- page_fluid(
  theme = gp_theme,
  title = "Globeprint | 142 countries, 1952-2007",
  
  tags$head(
    tags$link(rel = "icon", type = "image/svg+xml", href = "favicon.svg"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$script(HTML("
      $(document).on('click', '.continent-btn', function() {
        $('.continent-btn').removeClass('active');
        $(this).addClass('active');
      });
    "))
  ),
  
  # ----------------------------------------------------------------------------
  # 1. HEADER BAND
  # ----------------------------------------------------------------------------
  tags$header(
    class = "globeprint-header",
    tags$div(
      class = "row align-items-center",
      tags$div(
        class = "col-lg-7 col-md-12 mb-3 mb-lg-0",
        tags$div(
          class = "header-brand",
          tags$img(src = "logo.svg", class = "header-logo", alt = "Globeprint Logo"),
          tags$div(
            class = "brand-text",
            tags$div(
              class = "wordmark-row",
              tags$h1(class = "wordmark", "Globeprint"),
              tags$span(class = "facts-pill", "142 countries | 1952-2007 | 12 data points each")
            ),
            tags$div(class = "tagline", "Every country has a Globeprint."),
            tags$div(class = "header-subtitle", "142 countries, 1952 to 2007: life, wealth and people, one country at a time.")
          )
        )
      ),
      tags$div(
        class = "col-lg-5 col-md-12",
        tags$div(
          class = "header-controls",
          selectizeInput(
            inputId = "country",
            label = "Choose your country",
            choices = country_choices,
            selected = "India",
            options = list(maxOptions = 150, placeholder = "Type to search...")
          ),
          tags$div(
            tags$label("Filter by Continent:"),
            tags$div(
              class = "continent-pill-container",
              lapply(continent_choices, function(cont) {
                actionButton(
                  inputId = paste0("btn_cont_", tolower(cont)),
                  label = cont,
                  class = paste("continent-btn", if (cont == "All") "active" else "")
                )
              })
            )
          )
        )
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # MAIN CONTAINER
  # ----------------------------------------------------------------------------
  tags$main(
    class = "app-container",
    
    # --------------------------------------------------------------------------
    # 2. KPI ROW (4 Cards)
    # --------------------------------------------------------------------------
    uiOutput("kpi_cards_ui"),
    
    # --------------------------------------------------------------------------
    # 3. MAP + STORY ROW (60% Left / 40% Right)
    # --------------------------------------------------------------------------
    tags$section(
      class = "map-story-grid",
      
      # LEFT: Interactive Leaflet Map
      tags$div(
        class = "gp-card map-card",
        tags$div(
          class = "card-title-lg",
          tags$span("The world at a glance (142 countries, 1952-2007)")
        ),
        leafletOutput("world_map", height = "440px")
      ),
      
      # RIGHT: Stacked Cards (Story + Top 5)
      tags$div(
        class = "d-flex flex-column gap-3",
        
        # (a) Your country's story
        tags$div(
          class = "gp-card story-card",
          tags$div(class = "card-title-lg", "Your country's story"),
          uiOutput("story_text_ui")
        ),
        
        # (b) Top 5 Health Gainers
        tags$div(
          class = "gp-card top5-card",
          tags$div(
            class = "card-title-lg",
            uiOutput("top5_title_ui")
          ),
          uiOutput("top5_gainers_ui")
        )
      )
    ),
    
    # --------------------------------------------------------------------------
    # 4. GALLERY "YOUR GLOBEPRINTS" (Pinterest Masonry)
    # --------------------------------------------------------------------------
    tags$section(
      class = "gallery-section",
      tags$div(
        class = "gallery-section-header",
        tags$h2(class = "gallery-title", "Your Globeprints"),
        tags$p(class = "gallery-caption", "Pin-worthy art from 55 years of data, 1952-2007.")
      ),
      
      tags$div(
        class = "masonry-gallery",
        
        # Pin 1: LIFE STRIPES (Landscape 4:3)
        build_pin_card(
          card_id = "stripes",
          name = "Life Stripes",
          how_to_read = "12 chunky vertical bars show life expectancy from 1952 to 2007 (12 data points, every 5 years). Warmer colors indicate higher life expectancy.",
          plot_output = withSpinner(imageOutput("poster_life_stripes", width = "100%", height = "auto"), color = "#FFD6C9", type = 4),
          download_btn_id = "dl_life_stripes"
        ),
        
        # Pin 2: GROWTH SPIRAL (Square 1:1)
        build_pin_card(
          card_id = "spiral",
          name = "Growth Spiral",
          how_to_read = "A temporal spiral from 1952 at center to 2007 at outer ring. Dot size reflects life expectancy; distance represents GDP per capita.",
          plot_output = withSpinner(imageOutput("poster_growth_spiral", width = "100%", height = "auto"), color = "#FFD6C9", type = 4),
          download_btn_id = "dl_growth_spiral"
        ),
        
        # Pin 3: BUBBLE ART (Tall 3:4)
        build_pin_card(
          card_id = "bubble",
          name = "Bubble Art",
          how_to_read = "Tracks prosperity and longevity across 55 years against all 142 world nations in 2007 (background dots). Bubbles sized by population.",
          plot_output = withSpinner(imageOutput("poster_bubble_art", width = "100%", height = "auto"), color = "#FFD6C9", type = 4),
          download_btn_id = "dl_bubble_art"
        ),
        
        # Pin 4: POPULATION RINGS (Tall 4:5)
        build_pin_card(
          card_id = "rings",
          name = "Population Rings",
          how_to_read = "12 concentric rings from 1952 (inner) to 2007 (outer). Ring thickness and vibrant hues reflect growing population.",
          plot_output = withSpinner(imageOutput("poster_population_rings", width = "100%", height = "auto"), color = "#FFD6C9", type = 4),
          download_btn_id = "dl_population_rings"
        )
      )
    ),
    
    # --------------------------------------------------------------------------
    # 5. COMPARE STRIP
    # --------------------------------------------------------------------------
    tags$section(
      class = "gp-card compare-container",
      tags$div(
        class = "card-title-lg",
        tags$span("Countries like yours (1952-2007)"),
        radioButtons(
          inputId = "compare_metric",
          label = NULL,
          choices = c("Life expectancy", "Income", "Population"),
          selected = "Life expectancy",
          inline = TRUE
        )
      ),
      plotlyOutput("compare_plot", height = "380px")
    ),
    
    # --------------------------------------------------------------------------
    # 6. FOOTER
    # --------------------------------------------------------------------------
    tags$footer(
      class = "globeprint-footer",
      tags$div(
        class = "footer-top",
        tags$div(class = "footer-wordmark", "Globeprint"),
        tags$div(class = "footer-badge", "142 countries | 1952-2007 | 12 data points each")
      ),
      tags$div(
        class = "footer-note",
        "Globeprint | 142 countries | 1952-2007 | Data ends in 2007, so this is a historical story, not current news. It shows what happened, not why."
      ),
      tags$div(
        class = "footer-license",
        "Data: Gapminder.org via the gapminder R package (CC BY 4.0). Built with R Shiny, bslib, ggplot2, and Leaflet."
      )
    )
  )
)

# ==============================================================================
# SERVER LOGIC
# ==============================================================================
server <- function(input, output, session) {
  
  # Reactive value for continent filter
  selected_continent <- reactiveVal("All")
  
  # Handle Continent Filter Buttons
  observeEvent(input$btn_cont_all, { selected_continent("All") })
  observeEvent(input$btn_cont_africa, { selected_continent("Africa") })
  observeEvent(input$btn_cont_americas, { selected_continent("Americas") })
  observeEvent(input$btn_cont_asia, { selected_continent("Asia") })
  observeEvent(input$btn_cont_europe, { selected_continent("Europe") })
  observeEvent(input$btn_cont_oceania, { selected_continent("Oceania") })
  
  # Current selected country name with robust default
  active_country <- reactive({
    if (is.null(input$country) || input$country == "") "India" else input$country
  })
  
  # Current selected country summary row
  current_country_row <- reactive({
    cname <- active_country()
    row <- country_summary %>% filter(country == cname)
    if (nrow(row) == 0) country_summary %>% filter(country == "India") else row[1, ]
  })
  
  # Current selected country time series data (12 observations)
  current_country_ts <- reactive({
    cname <- active_country()
    gap_df %>% filter(country == cname)
  })
  
  # ----------------------------------------------------------------------------
  # 2. KPI Cards Rendering
  # ----------------------------------------------------------------------------
  output$kpi_cards_ui <- renderUI({
    row <- current_country_row()
    
    gain_sign <- ifelse(row$lifeExp_gain >= 0, "+", "")
    life_val  <- paste0(gain_sign, format(round(row$lifeExp_gain, 1), nsmall = 1), " yrs")
    gdp_val   <- paste0("x", format(round(row$gdp_multiple, 1), nsmall = 1))
    pop_val   <- paste0("x", format(round(row$pop_multiple, 1), nsmall = 1))
    rank_val  <- paste0("#", row$rank, " of 142")
    
    tags$div(
      class = "kpi-row",
      build_kpi_card("Life Expectancy Gained", life_val, "1952 to 2007", "🌱", "kpi-peach"),
      build_kpi_card("Income Growth", gdp_val, "GDP per person, 1952 to 2007", "📈", "kpi-butter"),
      build_kpi_card("Population Change", pop_val, "1952 to 2007", "👥", "kpi-sky"),
      build_kpi_card("Health Progress Rank", rank_val, "by years of life gained, 1952 to 2007", "🏆", "kpi-lilac")
    )
  })
  
  # ----------------------------------------------------------------------------
  # 3. Interactive Leaflet Map (No basemap, clean pastel surface)
  # ----------------------------------------------------------------------------
  output$world_map <- renderLeaflet({
    leaflet(
      map_data,
      options = leafletOptions(
        minZoom = 1,
        maxZoom = 6,
        zoomControl = TRUE,
        attributionControl = FALSE
      )
    ) %>%
      fitBounds(lng1 = -170, lat1 = -58, lng2 = 190, lat2 = 85) %>%
      addLegend(
        position = "bottomleft",
        pal = pal_gain,
        values = ~lifeExp_gain,
        title = "Years gained, 1952-2007",
        opacity = 0.9,
        na.label = "No data",
        className = "info legend gp-map-legend"
      )
  })
  
  # Reactive observer to update map polygons based on country selection & continent filter
  observe({
    sel_country <- active_country()
    filter_cont <- selected_continent()
    req(sel_country, filter_cont)
    
    map_df <- map_data %>%
      mutate(
        is_selected = (!is.na(country) & country == sel_country),
        is_in_filter = if (filter_cont == "All") TRUE else (!is.na(continent) & continent == filter_cont),
        poly_opacity = case_when(
          !in_gapminder ~ 0.40,
          !is_in_filter ~ 0.18,
          is_selected   ~ 0.95,
          TRUE          ~ 0.82
        ),
        poly_stroke_color = case_when(
          is_selected ~ "#1F1C2B",
          is_in_filter & in_gapminder ~ "#FFFFFF",
          TRUE ~ "#E5E7EB"
        ),
        poly_weight = case_when(
          is_selected ~ 3.0,
          is_in_filter ~ 0.9,
          TRUE ~ 0.4
        ),
        unique_layer_id = ifelse(in_gapminder & !is.na(country), country, paste0("no_data_", iso3))
      )
    
    labels <- lapply(seq_len(nrow(map_df)), function(i) {
      r <- map_df[i, ]
      if (r$in_gapminder) {
        HTML(paste0(
          "<div style='font-family: Poppins, sans-serif; padding: 2px;'>",
          "<strong>", r$country, "</strong> (", r$continent, ")<br/>",
          "Gain: <strong>+", r$lifeExp_gain, " years</strong> (1952-2007)<br/>",
          "2007 Life Expectancy: ", round(r$lifeExp_2007, 1), " yrs<br/>",
          "Global Rank: #", r$rank, " of 142",
          "</div>"
        ))
      } else {
        HTML(paste0("<strong>", r$map_name, "</strong><br/><span style='color: #888;'>No data in this dataset</span>"))
      }
    })
    
    leafletProxy("world_map", data = map_df) %>%
      clearShapes() %>%
      addPolygons(
        fillColor = ~pal_gain(lifeExp_gain),
        fillOpacity = ~poly_opacity,
        color = ~poly_stroke_color,
        weight = ~poly_weight,
        layerId = ~unique_layer_id,
        label = labels,
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "6px 10px"),
          textsize = "13px",
          direction = "auto"
        ),
        highlightOptions = highlightOptions(
          weight = 3.2,
          color = "#E76F51",
          fillOpacity = 0.95,
          bringToFront = TRUE
        )
      )
  })
  
  # Leaflet Shape Click: Sync map click to selectize dropdown
  observeEvent(input$world_map_shape_click, {
    click <- input$world_map_shape_click
    req(click, click$id)
    if (is.character(click$id) && length(click$id) == 1 && nzchar(click$id) && click$id %in% country_choices) {
      updateSelectizeInput(session, "country", selected = click$id)
    }
  })
  
  # ----------------------------------------------------------------------------
  # Story and Top 5 Outputs
  # ----------------------------------------------------------------------------
  output$story_text_ui <- renderUI({
    row <- current_country_row()
    tags$p(class = "story-paragraph", HTML(build_story_paragraph(row)))
  })
  
  output$top5_title_ui <- renderUI({
    filter_cont <- selected_continent()
    if (filter_cont == "All") {
      tags$span("Top 5 health gainers (All countries)")
    } else {
      tags$span(paste0("Top 5 health gainers (", filter_cont, ")"))
    }
  })
  
  output$top5_gainers_ui <- renderUI({
    build_top5_list(country_summary, active_country(), selected_continent())
  })
  
  # ----------------------------------------------------------------------------
  # 4. Poster Images Rendering (Using ragg for ultra-sharp, fault-tolerant rendering)
  # ----------------------------------------------------------------------------
  output$poster_life_stripes <- renderImage({
    cname <- active_country()
    outfile <- tempfile(fileext = ".png")
    ragg::agg_png(outfile, width = 800, height = 600, res = 110)
    print(memo_life_stripes(current_country_ts(), cname))
    dev.off()
    list(src = outfile, contentType = "image/png", width = "100%", alt = paste("Life Stripes -", cname))
  }, deleteFile = TRUE)
  
  output$poster_growth_spiral <- renderImage({
    cname <- active_country()
    outfile <- tempfile(fileext = ".png")
    ragg::agg_png(outfile, width = 720, height = 720, res = 110)
    print(memo_growth_spiral(current_country_ts(), cname))
    dev.off()
    list(src = outfile, contentType = "image/png", width = "100%", alt = paste("Growth Spiral -", cname))
  }, deleteFile = TRUE)
  
  output$poster_bubble_art <- renderImage({
    cname <- active_country()
    outfile <- tempfile(fileext = ".png")
    ragg::agg_png(outfile, width = 640, height = 820, res = 110)
    print(memo_bubble_art(current_country_ts(), all_2007, cname))
    dev.off()
    list(src = outfile, contentType = "image/png", width = "100%", alt = paste("Bubble Art -", cname))
  }, deleteFile = TRUE)
  
  output$poster_population_rings <- renderImage({
    cname <- active_country()
    outfile <- tempfile(fileext = ".png")
    ragg::agg_png(outfile, width = 680, height = 820, res = 110)
    print(memo_population_rings(current_country_ts(), cname))
    dev.off()
    list(src = outfile, contentType = "image/png", width = "100%", alt = paste("Population Rings -", cname))
  }, deleteFile = TRUE)
  
  # ----------------------------------------------------------------------------
  # Download Handlers (300 DPI Museum-Quality PNGs via ragg)
  # ----------------------------------------------------------------------------
  output$dl_life_stripes <- downloadHandler(
    filename = function() {
      paste0("Globeprint_", gsub("[^A-Za-z0-9]", "_", active_country()), "_life_stripes.png")
    },
    content = function(file) {
      p <- draw_life_stripes(current_country_ts(), active_country(), export = TRUE)
      ggsave(file, plot = p, device = ragg::agg_png, width = 24, height = 18, units = "in", dpi = 300)
    }
  )
  
  output$dl_growth_spiral <- downloadHandler(
    filename = function() {
      paste0("Globeprint_", gsub("[^A-Za-z0-9]", "_", active_country()), "_growth_spiral.png")
    },
    content = function(file) {
      p <- draw_growth_spiral(current_country_ts(), active_country(), export = TRUE)
      ggsave(file, plot = p, device = ragg::agg_png, width = 20, height = 20, units = "in", dpi = 300)
    }
  )
  
  output$dl_bubble_art <- downloadHandler(
    filename = function() {
      paste0("Globeprint_", gsub("[^A-Za-z0-9]", "_", active_country()), "_bubble_art.png")
    },
    content = function(file) {
      p <- draw_bubble_art(current_country_ts(), all_2007, active_country(), export = TRUE)
      ggsave(file, plot = p, device = ragg::agg_png, width = 18, height = 24, units = "in", dpi = 300)
    }
  )
  
  output$dl_population_rings <- downloadHandler(
    filename = function() {
      paste0("Globeprint_", gsub("[^A-Za-z0-9]", "_", active_country()), "_population_rings.png")
    },
    content = function(file) {
      p <- draw_population_rings(current_country_ts(), active_country(), export = TRUE)
      ggsave(file, plot = p, device = ragg::agg_png, width = 19.2, height = 24, units = "in", dpi = 300)
    }
  )
  
  # ----------------------------------------------------------------------------
  # 5. Compare Strip (Plotly Line Chart)
  # ----------------------------------------------------------------------------
  output$compare_plot <- renderPlotly({
    target_c <- active_country()
    sel_row <- current_country_row()
    req(target_c, nrow(sel_row) > 0)
    
    similar_names <- unlist(sel_row$similar_countries)
    compare_countries <- unique(c(target_c, similar_names))
    compare_countries <- compare_countries[!is.na(compare_countries) & nzchar(compare_countries)]
    
    comp_df <- gap_df %>%
      filter(country %in% compare_countries) %>%
      mutate(
        is_target = (country == target_c),
        display_label = ifelse(is_target, paste0(country, " (Your country)"), country)
      )
    
    metric_choice <- if (is.null(input$compare_metric)) "Life expectancy" else input$compare_metric
    
    y_col <- case_when(
      metric_choice == "Life expectancy" ~ "lifeExp",
      metric_choice == "Income" ~ "gdpPercap",
      TRUE ~ "pop"
    )
    
    y_title <- case_when(
      metric_choice == "Life expectancy" ~ "Life Expectancy (Years)",
      metric_choice == "Income" ~ "GDP per Person (USD)",
      TRUE ~ "Population"
    )
    
    # Elegant Color Palette
    palette_colors <- c("#E76F51", "#457B9D", "#2A9D8F", "#E9C46A")
    color_map <- setNames(palette_colors[seq_along(compare_countries)], compare_countries)
    
    p <- plot_ly()
    
    for (i in seq_along(compare_countries)) {
      cname <- compare_countries[i]
      sub_df <- comp_df %>% filter(country == cname) %>% arrange(year)
      is_tgt <- (cname == target_c)
      
      line_width <- if (is_tgt) 4.5 else 2.2
      line_dash  <- if (is_tgt) "solid" else "dash"
      clr        <- color_map[cname]
      
      y_vals <- sub_df[[y_col]]
      hover_text <- paste0(
        "<b>", cname, "</b> (", sub_df$year, ")<br>",
        metric_choice, ": ",
        if (metric_choice == "Life expectancy") paste0(round(y_vals, 1), " yrs")
        else if (metric_choice == "Income") paste0("$", format(round(y_vals), big.mark = ","))
        else paste0(round(y_vals / 1e6, 2), "M")
      )
      
      p <- p %>% add_trace(
        data = sub_df,
        x = ~year,
        y = y_vals,
        name = if (is_tgt) paste0(cname, " (Selected)") else cname,
        type = "scatter",
        mode = "lines+markers",
        line = list(color = clr, width = line_width, dash = line_dash),
        marker = list(color = clr, size = if (is_tgt) 8 else 5),
        hoverinfo = "text",
        text = hover_text
      )
    }
    
    p %>% layout(
      xaxis = list(
        title = "Year (1952 to 2007)",
        dtick = 5,
        gridcolor = "#F0ECE6",
        zeroline = FALSE
      ),
      yaxis = list(
        title = y_title,
        gridcolor = "#F0ECE6",
        zeroline = FALSE
      ),
      legend = list(orientation = "h", x = 0.1, y = 1.15),
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor = "rgba(0,0,0,0)",
      margin = list(t = 20, b = 40, l = 50, r = 20),
      hovermode = "closest"
    ) %>%
      config(displayModeBar = FALSE)
  })
}

# Run the Shiny application
shinyApp(ui = ui, server = server)
