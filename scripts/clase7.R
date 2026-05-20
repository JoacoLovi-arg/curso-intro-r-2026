# 0. Seteamos ####

## librerias ####
library(tidyverse)
#install.packages("sf")
library(sf)
#install.packages("spatialEco")
library(spatialEco)
# install.packages("ggmap")
library(ggmap)
#install.packages("leaflet")
library(leaflet)

# 1 Cargamos datos ####

# DELITOS CABA
df_delitos <- read.csv("https://cdn.buenosaires.gob.ar/datosabiertos/datasets/ministerio-de-justicia-y-seguridad/delitos/delitos_2023.csv",
                       encoding = "UTF-8")

# COMISARÍAS CABA
df_comisarias <- read.csv("https://data.buenosaires.gob.ar/dataset/comisarias-policia-ciudad/resource/juqdkmgo-591-resource/download",
                          encoding = "UTF-8")
# https://data.buenosaires.gob.ar/dataset/comisarias-policia-ciudad

# BARRIOS DE CABA (polígonos)
# nuevo tipo de archivo: .geojson
df_barrios <- st_read("https://data.buenosaires.gob.ar/dataset/barrios/resource/1c3d185b-fdc9-474b-b41b-9bd960a3806e/download")

# LÍNEAS DE SUBTE
# nuevo tipo de archivo: .shp
df_subte <- read_sf("../data/clase7/subterraneo-lineas/Red_de_subterraneo.shp")

# 2 Datos Georreferenciados: un nuevo tipo de dato ####

## Proyecciones ####

# los datos georreferenciados tienen el atributo de la proyección, si bien son numéricos, requieren de un sistema de coordenadas
# que nos permita realizar diferentes operaciones algebraicas

# https://rpubs.com/HAVB/geoinfo

# https://fronterasblog.com/2019/06/25/visualizando-la-distorsion-de-la-proyeccion-de-mercator-con-una-naranja/


# sistema de referencia de coordenadas
st_crs(df_barrios)
st_crs(df_subte)

# los objetos sf tienen geometría + proyección,
# un csv es una tabla, sin info de proyección no es dato georref 

# los csv son tablas normales
class(df_delitos)
class(df_comisarias)

# no tienen geometría
st_crs(df_delitos)
st_crs(df_comisarias)

# aunque tengan latitud y longitud,
# siguen siendo tablas hasta convertirlas en objetos espaciales



## convertimos a sf ####

# delitos
df_delitos_sf <- df_delitos %>%
  st_as_sf(
    coords = c("longitud", "latitud"), # columnas coordenadas
    crs = 4326, # WGS84
    na.fail = F
  )

# comisarías
df_comisarias_sf <- st_as_sf(
  df_comisarias,
  wkt = "geometry", # columna con geometría en texto
  crs = 4326 # sistema de coordenadas
)

# chequeamos
df_delitos_sf
df_comisarias_sf

## 2.1 Tipos de geometrías ####

## puntos ####

# delitos y comisarías son puntos
st_geometry_type(df_delitos_sf)
st_geometry_type(df_comisarias_sf)



## lineas ####

# líneas de subte
st_geometry_type(df_subte)



## poligonos ####

# barrios
st_geometry_type(df_barrios)


### multipoligonos ####

# 3 Operaciones espaciales ####

## calcular area ####

# área de los barrios
df_barrios$area <- st_area(df_barrios)

### calcular perimetro ####

# obtenemos bordes
bordes <- st_boundary(df_barrios)

# calculamos longitud del borde
df_barrios$perimetro <- st_length(bordes)

df_barrios %>%
  select(barrio, perimetro)

### calcular centroide ####
# centro geométrico de cada barrio
df_centroides <- st_centroid(df_barrios)

df_centroides

## buffers: área de influencia ####

# IMPORTANTE:
# para trabajar con distancias reales
# transformamos a una proyección en metros

df_comisarias_metros <- st_transform(df_comisarias_sf, 5347)

# buffer de 1200 metros (algo así como 12 cuadras)
buffer_comisarias <- st_buffer(
  df_comisarias_metros,
  dist = 1200 # algo así como 12 cuadras
)

buffer_comisarias

## join espacial ####

# transformamos delitos a misma proyección
df_delitos_metros <- st_transform(df_delitos_sf, 5347)

# delitos dentro del buffer de cada comisaría
delitos_buffer <- st_join(
  df_delitos_metros,
  buffer_comisarias,
  join = st_within
)

delitos_buffer

## cantidad de delitos por comisaría ####

delitos_comisaria <- delitos_buffer %>%
  st_drop_geometry() %>%
  count(nombre)

delitos_comisaria

### join espacial ####

# 4 Visualizaciones ####

## primer mapa  ####

## Coropletas ####

## superposición de capas ####

## densidad espacial ####

# 5 Visualizaciones interactivas ####
