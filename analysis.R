library(sf)
library(readr)
library(dplyr)
library(countrycode)
library(ggplot2)

# 读取数据
indices <- read_csv("HDR25_Composite_indices_complete_time_series.csv")
geojson_file <- list.files(
  pattern = "^World_Countries_.*\\.geojson$",
  ignore.case = TRUE
)
world <- st_read(geojson_file[1], quiet = TRUE)
# 计算 2010 到 2019 年的 GII 变化
gii_change <- indices |>
  dplyr::select(iso3, country, gii_2010, gii_2019) |>
  mutate(gii_change = gii_2019 - gii_2010)

# 将地图中的两位国家代码转换为三位代码，再合并数据
world_iso3 <- world |>
  mutate(iso3 = countrycode(ISO, "iso2c", "iso3c"))

world_gii <- world_iso3 |>
  left_join(gii_change, by = "iso3")

# 绘制变化地图
ggplot(world_gii) +
  geom_sf(aes(fill = gii_change), colour = "white", linewidth = 0.1) +
  scale_fill_viridis_c(
    option = "C",
    na.value = "grey85",
    name = "GII change\n(2019 - 2010)"
  ) +
  labs(
    title = "Change in Gender Inequality Index, 2010–2019",
    subtitle = "Negative values indicate a decrease in GII"
  ) +
  theme_minimal()

# 保存合并后的空间数据
world_gii |>
  dplyr::select(COUNTRY, ISO, gii_2010, gii_2019, gii_change, geometry) |>
  st_write("GII_change_2010_2019.geojson", delete_dsn = TRUE)