setwd("C:/Users/danny/Desktop/Tina/job/IMPACT/Iraq")
library("readxl")
data <- read_excel("Need2.xlsx")
data <- data[1:12, ]
data <- data[!data$Count == "0",]


# install.packages("dplyr")
# install.packages("scales")
library(dplyr)
library(scales)

# Data transformation
df <- data %>% 
  mutate(perc = `Count` / sum(`Count`)) %>% 
  arrange(perc) %>%
  mutate(labels = scales::percent(perc))


# install.packages("ggplot2")
library(ggplot2)

# Basic piechart
ggplot(df, aes(x = "", y = perc, fill = `Need priorities`)) +
  geom_col() +
  geom_text(aes(x= 1.6, label = labels),
            position = position_stack(vjust = 0.5),
            show.legend = FALSE)+
  guides(fill = guide_legend(title = "Priority needs reported from HHs in Duhok City")) +
  theme_void()+
  coord_polar("y", start = 180)
