# ------------------------------------------------------------------------
# 高低估分類 v5：修正 look-ahead bias，改用「只看過去」的滾動窗口
#
# 這是這一系列迭代中最關鍵的一次修正：v2~v4 的窗口取「當日前後各 365
# 天」，代表在判斷某一天是否高估/低估時，其實偷看了「未來」股價的分佈，
# 這種 look-ahead bias 會讓離線評估的表現看起來比實際部署時更好，是時間
# 序列建模中必須避免的資料洩漏。
#
# 修正做法：改成只取「當日之前」最多 365 天（約 252 個交易日）的歷史
# 資料計算 rolling z-score，並額外算出「與 200 日均線的乖離幅度」作為
# 輔助判斷。分類也收斂回較符合財經實務用語的 4 級。
#
# 輸入: data/interim/sp500_train_raw.csv (欄位：Date, SP500，由 04 產生)
# 輸出: sp500_evaluated_v5.csv (欄位：Date, SP500, Evaluation)
# ------------------------------------------------------------------------

library(readr)
library(lubridate)
library(dplyr)

data <- read_csv("data/interim/sp500_train_raw.csv", show_col_types = FALSE)

if (!inherits(data$Date, "Date")) {
  data <- data %>% mutate(Date = parse_date(as.character(Date),
                                             format = "%Y/%m/%d",
                                             locale = locale(tz = "UTC")))
  if (any(is.na(data$Date))) {
    data <- data %>% mutate(Date = parse_date(as.character(Date), format = "%Y-%m-%d"))
  }
}

data <- data %>% filter(!is.na(Date)) %>% arrange(Date)

# 專業滾動式評價函數（使用 rolling z-score 與均線乖離）
evaluate_point <- function(current_date, current_value) {
  # 只看當日「之前」最多 365 天的歷史資料，避免使用未來資訊
  window_data <- data %>% filter(Date < current_date & Date >= (current_date - days(365)))

  if (nrow(window_data) < 200) return(NA_character_)  # 資料開頭樣本不足

  rolling_mean <- mean(window_data$SP500, na.rm = TRUE)
  rolling_sd   <- sd(window_data$SP500, na.rm = TRUE)
  z_score <- ifelse(rolling_sd > 0, (current_value - rolling_mean) / rolling_sd, 0)

  # 200 日均線乖離率，作為輔助判斷（本版本先保留計算，未納入最終分類）
  ma_200 <- mean(tail(window_data$SP500, 200), na.rm = TRUE)
  pct_above_ma200 <- (current_value - ma_200) / ma_200 * 100

  case_when(
    z_score < -1               ~ "Significantly Undervalued",
    z_score >= -1 & z_score < 0 ~ "Undervalued",
    z_score >= 0  & z_score < 1 ~ "Overvalued",
    z_score >= 1                ~ "Significantly Overvalued",
    TRUE                        ~ NA_character_
  )
}

data$Evaluation <- mapply(evaluate_point, data$Date, data$SP500)
data <- data %>% mutate(Date = format(Date, "%Y/%m/%d"))

write_csv(data, "sp500_evaluated_v5.csv")
