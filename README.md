## Flood mapping of Duhok District and potential impacts of the floods to the households of displacement affected population groups
# Floods in Iraq after heavy rainfalls


On 19 March 2024, heavy rainfalls swept through and caused flesh floods in Iraq, especially the mountainous Kurdistan Region in northern Iraq. Duhok’s Civil Defense Directorate reported that 2 people were killed by their submerged vehicle. Here presented a remote sensing task for the assessment of flooded area in Duhok District. Google Earth Engine was used to perform flood mapping as to show which region was mostly affected by the floods. With the dataset from REACH Iraq IRQ2308 Cross-Cutting Needs Assessment (CCNA), the HH-level Dataset in the most affected region was processed and analysed by using R software.

![paste to excel](https://github.com/tinatmyiu/Flood-Mapping-for-Iraq-20240319/blob/main/Figure%201.%20Duhok%20District.png)
Figure 1. Duhok District

# Methodology
This flood mapping was based on the best practices recommended by UN-SPIDER. After obtaining images from before and after, speckle filter was applied to eliminate the noise in radar data. Masks were also used to remove permanent water, isolated pixels and steep areas in order the obtain flood with large area. Flood area was then calculated. The dataset from REACH Iraq IRQ2308 CCNA was used to estimate the substantial impacts of the flood to the households (HHs) of displacement-affected population groups, as to address their immediate need.

# Flooded area
The total area of Duhok District is 98704.5 hectares. The flooded area was 1.3 hectares. It was found that the most affected region was Duhok City, the capital city of Duhok District. The red area in the bottom of Figure 2. showed that Duhok City had more flooded area than other regions after the heavy rainfalls on 19 March 2024. The flooded area was mostly around the roads (Figure 3).

![paste to excel](https://github.com/tinatmyiu/Flood-Mapping-for-Iraq-20240319/blob/main/Figure%202.%20Flooded%20area%20in%20lower%20region%20of%20Duhok%20District.png)
Figure 2. Flooded area in lower region of Duhok District

![paste to excel](https://github.com/tinatmyiu/Flood-Mapping-for-Iraq-20240319/blob/main/Figure%203.%20Flooded%20area%20in%20Duhok%20City.png)
Figure 3. Flooded area in Duhok City


# Households of displacement-affected population groups in Duhok City
As Duhok City was the city in Duhok District, which was affected mainly by the floods, the impact of the flood to the households of displacement-affected population groups in Duhok City was estimated, using the dataset in REACH Iraq IRQ2308 CCNA. All the data in Duhok Citywere from out-of-camp IDPs. The dominant shelter issues reported were leaks during heavy and light rain (Figure 4). Shelter housing was also one of their top-priority needs (Figure 5).According to the result of flood mapping, the buildings near the roads were flooded. Based on this leaking issue, they had a high chance of house flooding in their shelters. 

![paste to excel](https://github.com/tinatmyiu/Flood-Mapping-for-Iraq-20240319/blob/main/Figure%203.%20Flooded%20area%20in%20Duhok%20City.png)
Figure 4. Damage/ issues reported from HHs in Duhok City

```r
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


setwd("C:/Users/")
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
```

![paste to excel](https://github.com/tinatmyiu/Flood-Mapping-for-Iraq-20240319/blob/main/Figure%203.%20Flooded%20area%20in%20Duhok%20City.png)
Figure 5. Priority needs reported from HHs in Duhok City

```r
setwd("C:/Users/")
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
```
# Shelter maintenance and temporary shelters
The flood mapping indicated that Duhok City was the main region affected by the flood in Duhok District. Shelters maintenance and temporary shelters were suggested for the out-of-campIDPs in Duhok City after the flood, as their shelters were reported to have leaking issue during light and heavy rain. A decline in their housing condition was very much expected. Providing shelter maintenance and temporary shelters would help them to recover from the floods.
