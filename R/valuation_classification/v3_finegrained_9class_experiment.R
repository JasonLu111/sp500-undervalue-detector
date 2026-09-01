# ------------------------------------------------------------------------
# 高低估分類 v3：實驗性的 9 級細分（後續證明過於細碎，未採用）
#
# 延續 v2 的 ±365 天窗口，嘗試把分類切得更細（9 級），並加入
# problems()/stop() 檢查，確保日期欄位有正確解析成 Date 型別，避免
# 靜默吃掉解析失敗的資料列。
#
# 結果：9 級分類在下游建模時類別樣本數過於稀疏、彼此邊界意義不大，
# 最終在 v5/v6 收斂回 4 級的「顯著低估 / 低估 / 高估 / 顯著高估」，
# 這也是實務上更常見、更容易解讀的財經分類方式。
#
# 輸入: data/interim/sp500_train_raw.csv (由 04_split_sp500_train_test.R 產生)
# 輸出: sp500_evaluated.csv
# ------------------------------------------------------------------------

library(dplyr)
library(readr)
library(lubridate)

data <- read_csv("data/interim/sp500_train_raw.csv", col_types = cols(
  Date  = col_date(format = "%Y-%m-%d"),
  SP500 = col_double()
))

if (any(is.na(data$Date))) {
  stop("讀取失敗：日期欄位包含 NA，請確認原始 CSV 的日期格式。")
}

data <- data %>% arrange(Date)

evaluate_point <- function(current_date, current_value, full_data) {
  start_date <- current_date - days(365)
  end_date   <- current_date + days(365)

  context_data <- full_data %>% filter(Date != current_date & Date >= start_date & Date <= end_date)

  if (nrow(context_data) < 730) {
    missing <- 730 - nrow(context_data)
    remaining_data <- full_data %>% filter(Date != current_date & !(Date >= start_date & Date <= end_date))
    context_data <- bind_rows(context_data, head(remaining_data, missing))
  }

  if (nrow(context_data) < 30) return(NA_character_)

  mean_val <- mean(context_data$SP500)
  sd_val   <- sd(context_data$SP500)
  z <- ifelse(sd_val > 0, (current_value - mean_val) / sd_val, 0)

  case_when(
    z < -2               ~ "Low --",
    z >= -2   & z < -1.5 ~ "Low --",
    z >= -1.5 & z < -1   ~ "Low -",
    z >= -1   & z < -0.5 ~ "Low",
    z >= -0.5 & z < 0    ~ "Low +",
    z >= 0    & z < 0.5  ~ "High +",
    z >= 0.5  & z < 1    ~ "High",
    z >= 1    & z < 1.5  ~ "High -",
    z >= 1.5  & z < 2    ~ "High --",
    z >= 2                ~ "High --"
  )
}

data$Evaluation <- mapply(evaluate_point, data$Date, data$SP500, MoreArgs = list(full_data = data))

write_csv(data, "sp500_evaluated.csv")
