# install.packages
install.packages("dplyr")
library(dplyr)
install.packages("tidyverse")
library(tidyverse)
library(readxl)
install.packages("hablar")
library(hablar)
install.packages('base')
library('base')
install.packages("forstringr")
library(forstringr)


setwd("C:/Users/danny/Desktop/Tina/job/IMPACT/Iraq")
data <- read_excel("shelter issue2.xlsx")
data <- data[1:13, ]
data <- data[!data$Counts == "0",]


# install.packages("dplyr")
# install.packages("scales")
library(dplyr)
library(scales)

# Data transformation
df <- data %>% 
  mutate(perc = `Counts` / sum(`Counts`)) %>% 
  arrange(perc) %>%
  mutate(labels = scales::percent(perc))%>%
  mutate(prop = `Counts` / sum(`Counts`) *100) %>%
  mutate(ypos = cumsum(prop)- 0.5*prop )




# install.packages("ggplot2")
library(ggplot2)

# Basic piechart
ggplot(df, aes(x = "", y = df$Counts, fill = df$`Shelter Issue`)) +
  geom_col() +
  geom_text(aes(x= 1.6, label = labels),
            position = position_stack(vjust = 0.5),
            show.legend = FALSE)+
  guides(fill = guide_legend(title = "Damage/ issues reported from HHs in Duhok City")) +
  theme_void()+
  coord_polar("y", start=0)
