# Load required libraries
library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
# Function to fetch race data for a specific season and round
fetch_race_data <- function(season, round) {
  base_url <- paste0("https://ergast.com/api/f1/", season, "/", round)
  endpoint <- "/pitstops.json"
  url <- paste0(base_url, endpoint)
  response <- GET(url)
  if (http_error(response)) {
    stop("Error fetching data:", content(response, "text"))
  }
  return(content(response, "parsed"))
}
# Function to fetch pitstop data for all rounds of a specific season
fetch_season_pitstop_data <- function(season) {
  all_rounds <- 1:20 # Assuming 20 rounds in a season, adjust if needed
  pitstop_times <- map_dbl(all_rounds, function(round) {
    race_data <- fetch_race_data(season, round)
    if (length(race_data$MRData$RaceTable$Races) > 0) {
      pitstops <- race_data$MRData$RaceTable$Races[[1]]$PitStops
      if (length(pitstops) > 0) {
        return(mean(as.numeric(sapply(pitstops, function(pitstop) pitstop$duration))))
      }
    }
    return(NA) # Return NA if no pitstop data is available for the round
  })
  return(pitstop_times[!is.na(pitstop_times)]) # Remove NA values
}
# Function to calculate average pitstop timing for each season from 2011 to 2023
calculate_season_average_pitstop_timing <- function(seasons) {
  season_averages <- map_dbl(seasons, ~ mean(fetch_season_pitstop_data(.x)))
  return(season_averages)
}
# Calculate average pitstop timing for each season from 2011 to 2023
seasons <- 2011:2023
season_average_pitstop_timings <- calculate_season_average_pitstop_timing(seasons)
# Print the results
for (i in seq_along(seasons)) {
  cat("Average pitstop timing for the", seasons[i], "season:", round(season_average_pitstop_timings[i], 2),
      "seconds\n")
}
pitstop_data <- data.frame(
  Season = seasons,
  Average_Pitstop_Timing = season_average_pitstop_timings
)
ggplot(pitstop_data, aes(x = Season, y = Average_Pitstop_Timing)) +
  geom_line() +
  geom_point() +
  labs(
    title = "Average Pitstop Timing by Season (2011- 2023)",
    x ="Season",
    y ="Average Pitstop Timing (seconds)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) # Rotate x-axis labels