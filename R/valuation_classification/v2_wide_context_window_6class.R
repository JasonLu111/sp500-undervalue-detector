# ------------------------------------------------------------------------
# 高低估分類 v2：加大時間窗口、細分為 6 級
#
# 針對 v1「窗口太短、雜訊大」的問題，改用「該日前後各 365 天」共約
# 730 筆交易日的資料計算 z-score 平均與標準差，並把 4 級細分為 6 級
# （Low -- / Low - / Low / High / High + / High ++）。
#
# 已知限制（v5 才修正）：
#   - 窗口同時包含「未來」與「過去」資料（current_date 前後各 365 天），
#     在真實預測情境中會造成 look-ahead bias：用未來才會出現的資料，
#     去判斷「當下」是否為高估/低估，這在實際部署時是看不到未來資料的。
#
# 輸入: data/raw/sp500_1998_2024.csv
# 輸出: sp500_eva_1998_2024.csv
# ------------------------------------------------------------------------

library(dplyr)
library(readr)
library(lubridate)

data <- read_csv("data/raw/sp500_1998_2024.csv", col_types = cols(
  Date  = col_date(format = "%Y/%m/%d"),
  SP500 = col_double()
))

data <- data %>% arrange(Date)

evaluate_point <- function(current_date, current_value) {
  start_date <- current_date - days(365)
  end_date   <- current_date + days(365)

  context_data <- data %>% filter(Date != current_date & Date >= start_date & Date <= end_date)

  # 若時間窗口內樣本不足 730 筆，補上其餘日期的資料湊足樣本數
  if (nrow(context_data) < 730) {
    missing <- 730 - nrow(context_data)
    remaining_data <- data %>% filter(Date != current_date & !(Date >= start_date & Date <= end_date))
    context_data <- bind_rows(context_data, head(remaining_data, missing))
  }

  if (nrow(context_data) < 30) return(NA_character_)  # 樣本太小，標準差不穩定

  mean_val <- mean(context_data$SP500)
  sd_val   <- sd(context_data$SP500)
  z <- ifelse(sd_val > 0, (current_value - mean_val) / sd_val, 0)

  case_when(
    z < -1.5              ~ "Low --",
    z >= -1.5 & z < -0.5  ~ "Low -",
    z >= -0.5 & z < 0     ~ "Low",
    z >= 0    & z < 0.5   ~ "High",
    z >= 0.5  & z < 1.5   ~ "High +",
    z >= 1.5              ~ "High ++"
  )
}

data$Evaluation <- mapply(evaluate_point, data$Date, data$SP500)

write_csv(data, "sp500_eva_1998_2024.csv")
