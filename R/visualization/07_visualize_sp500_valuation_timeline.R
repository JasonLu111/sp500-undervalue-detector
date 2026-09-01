# ------------------------------------------------------------------------
# 07. [作品集補充] S&P 500 走勢與高低估分類時間軸
#
# 這支腳本不屬於原始課堂專題繳交內容，是求職作品集另外補上的 R
# 視覺化，目的是把 valuation_classification/ 產生的 4 級估值標籤，
# 疊加畫在 S&P 500 實際股價走勢上，直接看出模型判斷「顯著低估／
# 顯著高估」的時間點是否符合直覺（例如 2020 疫情崩盤、2022 升息熊市）。
#
# 輸入: data/processed/merged_train_data_ram1000.csv
# 輸出: docs/images/sp500_valuation_timeline.png
# ------------------------------------------------------------------------

library(readr)
library(dplyr)
library(ggplot2)

df <- read_csv("data/processed/merged_train_data_ram1000.csv", show_col_types = FALSE) %>%
  mutate(
    Date = as.Date(Date),
    Evaluation = factor(
      Evaluation,
      levels = c("Significantly Undervalued", "Undervalued", "Overvalued", "Significantly Overvalued")
    )
  )

valuation_colors <- c(
  "Significantly Undervalued" = "#1a7f5a",
  "Undervalued"               = "#7fc9a6",
  "Overvalued"                = "#f2a679",
  "Significantly Overvalued"  = "#c0392b"
)

p <- ggplot(df, aes(x = Date, y = SP500)) +
  geom_line(color = "grey40", linewidth = 0.4) +
  geom_point(aes(color = Evaluation), size = 1.6, alpha = 0.85) +
  scale_color_manual(values = valuation_colors, name = "估值分類") +
  labs(
    title = "S&P 500 走勢與模型估值分類（訓練集抽樣 1000 筆）",
    subtitle = "以過去 365 天 rolling z-score 判斷當下相對歷史的高低估程度",
    x = NULL, y = "S&P 500 收盤價"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave("docs/images/sp500_valuation_timeline.png", plot = p, width = 10, height = 5.5, dpi = 150)
