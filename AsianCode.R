# Setting up the working directory
setwd("D:/Rfiles/AsianCode")

# First, we need to visualize the data
# Bar graph ---------------------------------------------------------------


if (!require (tidyverse)) {install.packages ("tidyverse")}

# For dendrogram visualization
if (!require (ggdendro)) {install.packages ("ggdendro")}

library(tidyverse)  # For data manipulation
library(readr)
library(dplyr)
library(ggplot2)
library(readxl)
library(readr)
library (ggdendro)  # For dendrogram visualization




# Census data of Asian Immigrant 2017
CensusData2017 <- read_csv("CensusData2017.csv")

# Short names for states. These will be helpful during labelling of the figure
StateShort <- read_excel("StateShort.xlsx")
# View(StateShort)

# Total population of each state in 2017
TotalPop <- read_csv("TotalPop.csv", col_types = cols(GEO.id = col_skip(), 
                                                      GEO.id2 = col_skip(), Id = col_skip(), 
                                                      Id2 = col_skip(), `Margin of Error; Total` = col_skip(), 
                                                      X1 = col_skip()), skip = 1)



# Adding all the Asian Immigrant population together

Total <- CensusData2017 %>% 
  select (-State) %>% 
  rowwise() %>% 
  do((.) %>% as.data.frame %>% 
       mutate (TotalAsian = sum(.))) %>% 
  ungroup() %>% 
  cbind(CensusData2017$State) 

# Renaming the column name

Total <- Total %>% 
  rename(State = "CensusData2017$State")


Total1 <- TotalPop %>% 
  inner_join(Total, by= c("Geography" = "State")) %>%
  inner_join(StateShort, by = c("Geography" = "State")) %>% 
  mutate (percent = (TotalAsian/Total)*100)


# Visualization using ggplot2           
ggplot(data = Total1, aes(x = reorder (Abbreviation, -percent), y = percent, fill =
                               reorder (Geography, -percent)))+
  geom_bar(stat= "identity")+
  theme_bw()+
  theme(legend.title = element_blank(), legend.position = c(0.7, 0.6), 
        legend.background = element_rect(color = "black", size=1, linetype= "solid"))+
  scale_y_continuous(breaks = c(0, 5, 10, 15, 20, 25, 30, 35))+
  labs(x = 'States', y = " Total immigrant ", title = " Immigrant Population Percentage in 50 States and Puerto Rico")


# Cluster Analysis --------------------------------------------------------


# Cluster Analysis 
h.clust <- Total1 %>%
  select (., Geography, percent) %>% 
  column_to_rownames(., "Geography") 


str(h.clust)

is.null(h.clust)  # To check is there is any Null values


h.clust1 <- hclust(dist(h.clust), method = "complete")

ggdendrogram(h.clust1)+ 
  ggtitle(" Dendrogram of States with Asian Population") +
  labs( x = " States", y = "Euclidean Distance", title = "Dendrogram")

plot(h.clust1, hang = -1, xlab = " States", 
     ylab = "Euclidean Distance",ps = 10,
     main = "Cluster dendrogram of Asian population of States - 2017 Census")

rect.hclust(h.clust1, h=2 )

sub_grp <- cutree(h.clust1, k = 7)

groups <- as.data.frame(sub_grp) %>% 
  rownames_to_column("State")


# Map ---------------------------------------------------------------------

if (! require (rgdal)) {install.packages ("rgdal")}
if (! require (geojsonio)) {install.packages ("geojsonio")}
if (! require (RColorBrewer)) {install.packages ("RColorBrewer")}
if (! require (broom)) {install.packages ("broom")}
if (! require (rgeos)) {install.packages ("rgeos")}
if (! require (mapproj)) {install.packages ("mapproj")}

library (rgdal)
library (geojsonio)
library (broom)
library (RColorBrewer)
library (mapproj)

# The importance of Hexmap are as follows:
#   1. It gives every constituency (or States) the same visual weight
# 2. Eliminate discrepancies in US state sizes
# The disadvantages are
# 1. Not appropriate for statistical analysis
# 2. Size is significantly distorted


map1 <- geojson_read("us_states_hexgrid.geojson", what = "sp") # reads the file
plot(map1) # To see if the file is what we need


map1@data = map1@data %>%
  mutate(google_name = gsub(" \\(United States\\)", "", google_name))
map1@data = map1@data %>% mutate(google_name = gsub(" \\(United States\\)", "", google_name))

map1_fortified <- tidy(map1, region = "google_name")
head(map1_fortified)


library(rgeos)

centers <- cbind.data.frame(data.frame(gCentroid(map1, byid=TRUE), 
                                       id=map1@data$iso3166_2))


groups1 <- map1_fortified %>% 
  inner_join(groups, by = c("id" = "State")) 
  
# Plotting 
ggplot()+
  
  geom_polygon ( data = groups1, 
                 aes (x = long, y = lat, 
                      fill = as.factor(sub_grp), group = id),
                 color = "white")+
  
  geom_text(data=centers, aes(x=x, y=y, label=id))+
  
  coord_map()+
  
  theme_bw()+
  
  theme (panel.background = element_rect(fill = "#f5f5f2", color = NA))+
  
  theme(axis.title.x=element_blank(), axis.text.x=element_blank(), 
        axis.ticks.x=element_blank())+
  
  theme(axis.title.y=element_blank(), 
        axis.text.y=element_blank(), axis.ticks.y=element_blank())+

  ggtitle ("Map of the United States in Hexbin")+
  
  #theme (legend.position = "none")+
  
  labs (caption = "Map created by \n Rajesh Sigdel")



   
