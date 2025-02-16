library(dplyr)
library(ggplot2)
library(zoo)

#Data from the data file
NY_spot <- Gasoline_spot$NY_spot
NY_Futures <- Gasoline_spot$NY_Futures

# dataframe
data <- data.frame(Date = as.Date(Gasoline_spot$Date), 
                   NY_spot = Gasoline_spot$NY_spot, 
                   NY_Futures = Gasoline_spot$NY_Futures)

# returns
spot_return <- diff(log(data$NY_spot))
futures_return <- diff(log(data$NY_Futures))

# we remove the first row 
data <- data[-1, ]

# we add the returns to the dataframe
data <- data %>%
  mutate(spot_return = spot_return,
         futures_return = futures_return)

# static hedge ratio
static_hedge_ratio <- lm(spot_return ~ futures_return, data = data)$coefficients[2]

# dynamic hedge ratio using a 30-day rolling window
rolling_window <- 30
data <- data %>%
  mutate(roll_hedge_ratio = rollapply(data = ., 
                                      width = rolling_window, 
                                      FUN = function(x) lm(spot_return ~ futures_return, data = as.data.frame(x))$coefficients[2], 
                                      by.column = FALSE, 
                                      align = 'right', 
                                      fill = NA))

# hedged returns for both ratios
data <- data %>%
  mutate(static_hedged_return = spot_return - static_hedge_ratio * futures_return,
         dynamic_hedged_return = spot_return - roll_hedge_ratio * futures_return)

# comparison plot of hedged returns
comparison_plot <- ggplot(data, aes(x = Date)) +
  geom_line(aes(y = static_hedged_return, color = 'Static Hedged Return')) +
  geom_line(aes(y = dynamic_hedged_return, color = 'Dynamic Hedged Return')) +
  labs(title = "Comparison of Static and Dynamic Hedged Returns",
       x = "Date",
       y = "Hedged Return",
       color = "Hedged Return Type") +
  theme_minimal()

print(comparison_plot)

# var of returns
var <- data %>%
  summarise(static_hedge_variance = var(static_hedged_return, na.rm = TRUE),
            dynamic_hedge_variance = var(dynamic_hedged_return, na.rm = TRUE))

print(var)