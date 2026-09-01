# ------------------------------------------------------------------------
# 08. [作品集補充] 總體經濟指標走勢小圖 (Small Multiples)
#
# 求職作品集補充視覺化。將 9 個特徵欄位（VIX、EPU 代理欄位等總經指標）
# 從寬表轉為長表 (pivot_longer)，用 facet_wrap 各自獨立座標軸畫圖，
# 一次檢視所有特徵在訓練期間的走勢與尺度差異，這也是特徵工程前常見的
# 探索性資料分析 (EDA) 作法。
#
# 輸入: data/processed/merged_train_data_ram1000.csv
# 輸出: docs/images/macro_indicator_trends.png
# ------------------------------------------------------------------------

library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)

df <- read_csv("data/processed/merged_train_data_ram1000.csv", show_col_types = FALSE) %>%
  mutate(Date = as.Date(Date))

indicator_cols <- c("CPAT", "CPI", "EPU", "FFR", "INFE2", "JOP", "PPI", "RBE", "VIX")

df_long <- df %>%
  select(Date, all_of(indicator_cols)) %>%
  pivot_longer(-Date, names_to = "indicator", values_to = "value")

p <- ggplot(df_long, aes(x = Date, y = value, color = indicator)) +
  geom_line(linewidth = 0.5, show.legend = FALSE) +
  facet_wrap(~ indicator, scales = "free_y", ncol = 3) +
  labs(
    title = "總體經濟特徵走勢（訓練集抽樣 1000 筆）",
    subtitle = "各指標使用獨立座標尺度，用於建模前的探索性資料分析",
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

ggsave("docs/images/macro_indicator_trends.png", plot = p, width = 11, height = 8, dpi = 150)
