## Flood mapping of Duhok District and potential impacts of the floods to the households of displacement affected population groups
# Floods in Iraq after heavy rainfalls


On 19 March 2024, heavy rainfalls swept through and caused flesh floods in Iraq, especially the mountainous Kurdistan Region in northern Iraq. Duhok’s Civil Defense Directorate reported that 2 people were killed by their submerged vehicle. Here presented a remote sensing task for the assessment of flooded area in Duhok District. Google Earth Engine was used to perform flood mapping as to show which region was mostly affected by the floods. With the dataset from REACH Iraq IRQ2308 Cross-Cutting Needs Assessment (CCNA), the HH-level Dataset in the most affected region was processed and analysed by using R software.

![paste to excel](https://github.com/tinatmyiu/Flood-Mapping-for-Iraq-20240319/blob/main/Figure%201.%20Duhok%20District.png)
Figure 1. Duhok District

# Methodology
This flood mapping was based on the best practices recommended by UN-SPIDER. After obtaining images from before and after, speckle filter was applied to eliminate the noise in radar data. Masks were also used to remove permanent water, isolated pixels and steep areas in order the obtain flood with large area. Flood area was then calculated. The dataset from REACH Iraq IRQ2308 CCNA was used to estimate the substantial impacts of the flood to the households (HHs) of displacement-affected population groups, as to address their immediate need.

Here is the link of the javascript code used in ths flood mapping task:
https://code.earthengine.google.com/3cb1bf50a51cf0b1a80ebefbe732d056

# Flooded area

```javascript
var admin2 = ee.FeatureCollection("FAO/GAUL_SIMPLIFIED_500m/2015/level2"),
    hydrosheds = ee.Image("WWF/HydroSHEDS/03VFDEM"),
    gsw = ee.Image("JRC/GSW1_4/GlobalSurfaceWater");

var beforeStart = '2024-03-05'
var beforeEnd = '2024-03-19'
var afterStart = '2024-03-19'
var afterEnd = '2024-04-02'

var dahuk = admin2.filter(ee.Filter.eq('ADM2_NAME', 'Dahuk'))
var geometry = dahuk.geometry()
Map.addLayer(geometry, {color: 'grey'}, 'Dahuk District');

var fc = ee.FeatureCollection(geometry).style({fillColor:'00000000'})

Map.addLayer(fc, {}, "Transparent Duhok");


var collection= ee.ImageCollection('COPERNICUS/S1_GRD')
  .filter(ee.Filter.eq('instrumentMode','IW'))
  .filter(ee.Filter.listContains('transmitterReceiverPolarisation', 'VH'))
  .filter(ee.Filter.eq('orbitProperties_pass', 'DESCENDING')) 
  .filter(ee.Filter.eq('resolution_meters',10))
  .filterBounds(geometry, 24)
  .select('VH');

var beforeCollection = collection.filterDate(beforeStart, beforeEnd)
var afterCollection = collection.filterDate(afterStart,afterEnd)

var before = beforeCollection.mosaic().clip(geometry);
var after = afterCollection.mosaic().clip(geometry);

Map.addLayer(before, {min:-25,max:0}, 'Before Floods', false);
Map.addLayer(after, {min:-25,max:0}, 'After Floods', false); 

var beforeFiltered = ee.Image(toDB(RefinedLee(toNatural(before))))
var afterFiltered = ee.Image(toDB(RefinedLee(toNatural(after))))

Map.addLayer(beforeFiltered, {min:-25,max:0}, 'Before Filtered', false);
Map.addLayer(afterFiltered, {min:-25,max:0}, 'After Filtered', false); 

var difference = afterFiltered.divide(beforeFiltered);

// Define a threshold
var diffThreshold = 1.25;
// Initial estimate of flooded pixels
var flooded = difference.gt(diffThreshold).rename('water').selfMask();
Map.addLayer(flooded, {min:0, max:1, palette: ['orange']}, 'Initial Flood Area', false);


// Mask out area with permanent/semi-permanent water
var permanentWater = gsw.select('seasonality').gte(5).clip(geometry)
var flooded = flooded.where(permanentWater, 0).selfMask()
Map.addLayer(permanentWater.selfMask(), {min:0, max:1, palette: ['blue']}, 'Permanent Water')

// Mask out areas with more than 5 percent slope using the HydroSHEDS DEM
var slopeThreshold = 5;
var terrain = ee.Algorithms.Terrain(hydrosheds);
var slope = terrain.select('slope');
var flooded = flooded.updateMask(slope.lt(slopeThreshold));
Map.addLayer(slope.gte(slopeThreshold).selfMask(), {min:0, max:1, palette: ['cyan']}, 'Steep Areas', false)

        
// Remove isolated pixels
// connectedPixelCount is Zoom dependent, so visual result will vary
var connectedPixelThreshold = 8;
var connections = flooded.connectedPixelCount(25)
var flooded = flooded.updateMask(connections.gt(connectedPixelThreshold))
Map.addLayer(connections.lte(connectedPixelThreshold).selfMask(), {min:0, max:1, palette: ['yellow']}, 'Disconnected Areas', false)

Map.addLayer(flooded, {min:0, max:1, palette: ['red'], border: '5px solid black'}, 'Flooded Areas');

Map.centerObject (geometry)

// Calculate Affected Area
print('Total District Area (Ha)', geometry.area().divide(10000))


//############################
// Speckle Filtering Functions
//############################

// Function to convert from dB
function toNatural(img) {
  return ee.Image(10.0).pow(img.select(0).divide(10.0));
}

//Function to convert to dB
function toDB(img) {
  return ee.Image(img).log10().multiply(10.0);
}

//Apllying a Refined Lee Speckle filter as coded in the SNAP 3.0 S1TBX:

//https://github.com/senbox-org/s1tbx/blob/master/s1tbx-op-sar-processing/src/main/java/org/esa/s1tbx/sar/gpf/filtering/SpeckleFilters/RefinedLee.java
//Adapted by Guido Lemoine

// by Guido Lemoine
function RefinedLee(img) {
  // img must be in natural units, i.e. not in dB!
  // Set up 3x3 kernels 
  var weights3 = ee.List.repeat(ee.List.repeat(1,3),3);
  var kernel3 = ee.Kernel.fixed(3,3, weights3, 1, 1, false);

  var mean3 = img.reduceNeighborhood(ee.Reducer.mean(), kernel3);
  var variance3 = img.reduceNeighborhood(ee.Reducer.variance(), kernel3);

  // Use a sample of the 3x3 windows inside a 7x7 windows to determine gradients and directions
  var sample_weights = ee.List([[0,0,0,0,0,0,0], [0,1,0,1,0,1,0],[0,0,0,0,0,0,0], [0,1,0,1,0,1,0], [0,0,0,0,0,0,0], [0,1,0,1,0,1,0],[0,0,0,0,0,0,0]]);

  var sample_kernel = ee.Kernel.fixed(7,7, sample_weights, 3,3, false);

  // Calculate mean and variance for the sampled windows and store as 9 bands
  var sample_mean = mean3.neighborhoodToBands(sample_kernel); 
  var sample_var = variance3.neighborhoodToBands(sample_kernel);

  // Determine the 4 gradients for the sampled windows
  var gradients = sample_mean.select(1).subtract(sample_mean.select(7)).abs();
  gradients = gradients.addBands(sample_mean.select(6).subtract(sample_mean.select(2)).abs());
  gradients = gradients.addBands(sample_mean.select(3).subtract(sample_mean.select(5)).abs());
  gradients = gradients.addBands(sample_mean.select(0).subtract(sample_mean.select(8)).abs());

  // And find the maximum gradient amongst gradient bands
  var max_gradient = gradients.reduce(ee.Reducer.max());

  // Create a mask for band pixels that are the maximum gradient
  var gradmask = gradients.eq(max_gradient);

  // duplicate gradmask bands: each gradient represents 2 directions
  gradmask = gradmask.addBands(gradmask);

  // Determine the 8 directions
  var directions = sample_mean.select(1).subtract(sample_mean.select(4)).gt(sample_mean.select(4).subtract(sample_mean.select(7))).multiply(1);
  directions = directions.addBands(sample_mean.select(6).subtract(sample_mean.select(4)).gt(sample_mean.select(4).subtract(sample_mean.select(2))).multiply(2));
  directions = directions.addBands(sample_mean.select(3).subtract(sample_mean.select(4)).gt(sample_mean.select(4).subtract(sample_mean.select(5))).multiply(3));
  directions = directions.addBands(sample_mean.select(0).subtract(sample_mean.select(4)).gt(sample_mean.select(4).subtract(sample_mean.select(8))).multiply(4));
  // The next 4 are the not() of the previous 4
  directions = directions.addBands(directions.select(0).not().multiply(5));
  directions = directions.addBands(directions.select(1).not().multiply(6));
  directions = directions.addBands(directions.select(2).not().multiply(7));
  directions = directions.addBands(directions.select(3).not().multiply(8));

  // Mask all values that are not 1-8
  directions = directions.updateMask(gradmask);

  // "collapse" the stack into a singe band image (due to masking, each pixel has just one value (1-8) in it's directional band, and is otherwise masked)
  directions = directions.reduce(ee.Reducer.sum());  

  //var pal = ['ffffff','ff0000','ffff00', '00ff00', '00ffff', '0000ff', 'ff00ff', '000000'];
  //Map.addLayer(directions.reduce(ee.Reducer.sum()), {min:1, max:8, palette: pal}, 'Directions', false);

  var sample_stats = sample_var.divide(sample_mean.multiply(sample_mean));

  // Calculate localNoiseVariance
  var sigmaV = sample_stats.toArray().arraySort().arraySlice(0,0,5).arrayReduce(ee.Reducer.mean(), [0]);

  // Set up the 7*7 kernels for directional statistics
  var rect_weights = ee.List.repeat(ee.List.repeat(0,7),3).cat(ee.List.repeat(ee.List.repeat(1,7),4));

  var diag_weights = ee.List([[1,0,0,0,0,0,0], [1,1,0,0,0,0,0], [1,1,1,0,0,0,0], 
    [1,1,1,1,0,0,0], [1,1,1,1,1,0,0], [1,1,1,1,1,1,0], [1,1,1,1,1,1,1]]);

  var rect_kernel = ee.Kernel.fixed(7,7, rect_weights, 3, 3, false);
  var diag_kernel = ee.Kernel.fixed(7,7, diag_weights, 3, 3, false);

  // Create stacks for mean and variance using the original kernels. Mask with relevant direction.
  var dir_mean = img.reduceNeighborhood(ee.Reducer.mean(), rect_kernel).updateMask(directions.eq(1));
  var dir_var = img.reduceNeighborhood(ee.Reducer.variance(), rect_kernel).updateMask(directions.eq(1));

  dir_mean = dir_mean.addBands(img.reduceNeighborhood(ee.Reducer.mean(), diag_kernel).updateMask(directions.eq(2)));
  dir_var = dir_var.addBands(img.reduceNeighborhood(ee.Reducer.variance(), diag_kernel).updateMask(directions.eq(2)));

  // and add the bands for rotated kernels
  for (var i=1; i<4; i++) {
    dir_mean = dir_mean.addBands(img.reduceNeighborhood(ee.Reducer.mean(), rect_kernel.rotate(i)).updateMask(directions.eq(2*i+1)));
    dir_var = dir_var.addBands(img.reduceNeighborhood(ee.Reducer.variance(), rect_kernel.rotate(i)).updateMask(directions.eq(2*i+1)));
    dir_mean = dir_mean.addBands(img.reduceNeighborhood(ee.Reducer.mean(), diag_kernel.rotate(i)).updateMask(directions.eq(2*i+2)));
    dir_var = dir_var.addBands(img.reduceNeighborhood(ee.Reducer.variance(), diag_kernel.rotate(i)).updateMask(directions.eq(2*i+2)));
  }

  // "collapse" the stack into a single band image (due to masking, each pixel has just one value in it's directional band, and is otherwise masked)
  dir_mean = dir_mean.reduce(ee.Reducer.sum());
  dir_var = dir_var.reduce(ee.Reducer.sum());

  // A finally generate the filtered value
  var varX = dir_var.subtract(dir_mean.multiply(dir_mean).multiply(sigmaV)).divide(sigmaV.add(1.0));

  var b = varX.divide(dir_var);

  var result = dir_mean.add(b.multiply(img.subtract(dir_mean)));
  return(result.arrayFlatten([['sum']]));
}

```

The total area of Duhok District is 98704.5 hectares. The flooded area was 1.3 hectares. It was found that the most affected region was Duhok City, the capital city of Duhok District. The red area in the bottom of Figure 2. showed that Duhok City had more flooded area than other regions after the heavy rainfalls on 19 March 2024. The flooded area was mostly around the roads (Figure 3).

![paste to excel](https://github.com/tinatmyiu/Flood-Mapping-for-Iraq-20240319/blob/main/Figure%202.%20Flooded%20area%20in%20lower%20region%20of%20Duhok%20District.png)
Figure 2. Flooded area in lower region of Duhok District

![paste to excel](https://github.com/tinatmyiu/Flood-Mapping-for-Iraq-20240319/blob/main/Figure%203.%20Flooded%20area%20in%20Duhok%20City.png)
Figure 3. Flooded area in Duhok City

Here is the code in Google Earth Engine to obtain Figure 2 and 3.
https://code.earthengine.google.com/ee248ddcc718a729b757b90246274a64

# Households of displacement-affected population groups in Duhok City
As Duhok City was the city in Duhok District, which was affected mainly by the floods, the impact of the flood to the households of displacement-affected population groups in Duhok City was estimated, using the dataset in REACH Iraq IRQ2308 CCNA. All the data in Duhok Citywere from out-of-camp IDPs. The dominant shelter issues reported were leaks during heavy and light rain (Figure 4). Shelter housing was also one of their top-priority needs (Figure 5).According to the result of flood mapping, the buildings near the roads were flooded. Based on this leaking issue, they had a high chance of house flooding in their shelters. 

![paste to excel](https://github.com/tinatmyiu/Flood-Mapping-for-Iraq-20240319/blob/main/pie%20shelter%20needs1.png)
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

![paste to excel](https://github.com/tinatmyiu/Flood-Mapping-for-Iraq-20240319/blob/main/pie%20shelter%20needs2.png)
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
