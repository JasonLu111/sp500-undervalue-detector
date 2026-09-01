# ------------------------------------------------------------------------
# 高低估分類 v1：基準版本
#
# 想法：對 log(S&P 500) 取 30 個交易日的滾動平均與滾動標準差，計算
# rolling z-score，再以 z-score 切成 4 個等級。這是最早、最單純的版本。
#
# 已知限制（後續版本逐步修正）：
#   - 30 天窗口過短，雜訊大、分類容易抖動
#   - 未針對日期解析失敗做防呆
#
# 輸入: data/raw/sp500_test_raw.csv (欄位：date, sp500)
# 輸出: sp500_classification.csv (Date, category)
# ------------------------------------------------------------------------

library(dplyr)
library(readr)
library(zoo)

data <- read_csv("data/raw/sp500_test_raw.csv", col_names = c("date", "sp500"),
                  skip = 1, show_col_types = FALSE)

data$date <- as.Date(data$date, format = "%Y/%m/%d")
data <- data[!is.na(data$date), ]

data <- data %>%
  arrange(date) %>%
  mutate(
    log_price    = log(sp500),
    rolling_mean = rollapply(log_price, width = 30, FUN = mean, align = "right", fill = NA),
    rolling_sd   = rollapply(log_price, width = 30, FUN = sd,   align = "right", fill = NA),
    z_score      = (log_price - rolling_mean) / rolling_sd,
    category     = case_when(
      z_score < -1               ~ "低位",
      z_score >= -1 & z_score < 0 ~ "略低",
      z_score >= 0  & z_score < 1 ~ "略高",
      z_score >= 1                ~ "高位",
      TRUE                        ~ NA_character_
    )
  )

write_csv(select(data, date, category), "sp500_classification.csv")
