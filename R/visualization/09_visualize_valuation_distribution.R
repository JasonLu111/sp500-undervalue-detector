# ------------------------------------------------------------------------
# 09. [作品集補充] 估值類別分布與特徵區隔力檢視
#
# 求職作品集補充視覺化，畫兩張圖：
#   (a) 4 個估值類別的樣本數分布（長條圖）：檢查類別是否嚴重不平衡，
#       這會直接影響後續分類模型該用什麼評估指標與抽樣策略。
#   (b) VIX（恐慌指數）在不同估值類別下的盒鬚圖：初步檢視這個特徵是否
#       對「高估 / 低估」有區隔力，呼應原專題用統計檢定/散佈圖做特徵
#       篩選的精神，只是這裡改用 R 直接呈現。
#
# 輸入: data/processed/merged_train_data_ram1000.csv
# 輸出: docs/images/valuation_class_balance.png
#       docs/images/vix_by_valuation_boxplot.png
# ------------------------------------------------------------------------

library(readr)
library(dplyr)
library(ggplot2)

df <- read_csv("data/processed/merged_train_data_ram1000.csv", show_col_types = FALSE) %>%
  mutate(
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

# (a) 類別樣本數分布
p_balance <- ggplot(df, aes(x = Evaluation, fill = Evaluation)) +
  geom_bar() +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.4, size = 3.5) +
  scale_fill_manual(values = valuation_colors, guide = "none") +
  labs(title = "估值類別樣本數分布", x = NULL, y = "筆數") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(angle = 20, hjust = 1)
  )

ggsave("docs/images/valuation_class_balance.png", plot = p_balance, width = 7, height = 5, dpi = 150)

# (b) VIX 在各估值類別下的分布
p_vix <- ggplot(df, aes(x = Evaluation, y = VIX, fill = Evaluation)) +
  geom_boxplot(alpha = 0.85, outlier.size = 1) +
  scale_fill_manual(values = valuation_colors, guide = "none") +
  labs(
    title = "VIX（恐慌指數）於各估值類別的分布",
    x = NULL, y = "VIX"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(angle = 20, hjust = 1)
  )

ggsave("docs/images/vix_by_valuation_boxplot.png", plot = p_vix, width = 7, height = 5, dpi = 150)
