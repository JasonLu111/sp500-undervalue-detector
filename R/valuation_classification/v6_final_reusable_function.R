# ------------------------------------------------------------------------
# 高低估分類 v6（最終版）：整理成可重用函式，整合進正式 pipeline
#
# 邏輯與 v5 相同（只看過去 365 天、rolling z-score + 200 日均線乖離、
# 4 級財經分類），但抽取成單一 evaluate_point() 函式並套用在正式的
# train / test 切分檔上，取代原本散落各處、互相覆蓋輸出檔的實驗腳本。
# 這一版產生的 zEVA_sp500_*.csv 會在 05/06 合併腳本中，與各項總經指標
# 一起 left join 成最終建模用資料集（data/processed/）。
#
# 輸入: data/interim/sp500_train_raw.csv, data/interim/sp500_test_raw.csv
#       （由 04_split_sp500_train_test.R 產生）
# 輸出: data/train/zEVA_sp500_train.csv, data/test/zEVA_sp500_test.csv
# ------------------------------------------------------------------------

library(readr)
library(dplyr)
library(lubridate)

#' 依 rolling z-score 與 200 日均線乖離，將某一天的 S&P 500 收盤價
#' 分類為 4 級財經估值標籤
#'
#' @param current_date 當日日期 (Date)
#' @param current_value 當日 S&P 500 收盤價
#' @param history 完整歷史資料 (需含 Date, SP500 欄位，已依日期排序)
#' @return 估值分類字串，樣本數不足時回傳 NA
evaluate_point <- function(current_date, current_value, history) {
  # 只看當日「之前」最多 365 天的歷史資料，避免 look-ahead bias
  window_data <- history %>% filter(Date < current_date & Date >= (current_date - days(365)))

  if (nrow(window_data) < 200) return(NA_character_)

  rolling_mean <- mean(window_data$SP500, na.rm = TRUE)
  rolling_sd   <- sd(window_data$SP500, na.rm = TRUE)
  z_score <- ifelse(rolling_sd > 0, (current_value - rolling_mean) / rolling_sd, 0)

  # 200 日均線乖離率，作為輔助判斷指標
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

classify_sp500_valuation <- function(input_path, output_path) {
  data <- read_csv(input_path, show_col_types = FALSE) %>%
    mutate(Date = as.Date(Date)) %>%
    filter(!is.na(Date)) %>%
    arrange(Date)

  data$Evaluation <- mapply(evaluate_point, data$Date, data$SP500, MoreArgs = list(history = data))
  data <- data %>% mutate(Date = format(Date, "%Y/%m/%d"))

  write_csv(data, output_path)
  invisible(data)
}

classify_sp500_valuation("data/interim/sp500_train_raw.csv", "data/train/zEVA_sp500_train.csv")
classify_sp500_valuation("data/interim/sp500_test_raw.csv",   "data/test/zEVA_sp500_test.csv")
