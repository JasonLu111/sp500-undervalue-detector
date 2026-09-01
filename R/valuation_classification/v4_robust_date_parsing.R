# ------------------------------------------------------------------------
# 高低估分類 v4：強化日期解析的容錯性
#
# 實際串接多個資料源後，發現日期欄位偶爾會混雜不同格式（"%Y/%m/%d" 與
# "%Y-%m-%d"），若用單一格式解析，容易讓整批資料被靜默轉成 NA 而不自知。
# 這個版本改成：先嘗試主要格式，解析失敗（產生 NA）時再嘗試備用格式，
# 最後仍為 NA 的資料列直接剔除並印出筆數，讓資料品質問題「看得見」。
#
# 輸入: data/raw/sp500_1998_2024.csv
# 輸出: sp500_eva_1998_2024.csv
# ------------------------------------------------------------------------

library(dplyr)
library(readr)
library(lubridate)

data <- read_csv("data/raw/sp500_1998_2024.csv", show_col_types = FALSE)

if (!inherits(data$Date, "Date")) {
  data <- data %>% mutate(Date = parse_date(as.character(Date),
                                             format = "%Y/%m/%d",
                                             locale = locale(tz = "UTC")))
  if (any(is.na(data$Date))) {
    data <- data %>% mutate(Date = parse_date(as.character(Date), format = "%Y-%m-%d"))
  }
}

n_unparsed <- sum(is.na(data$Date))
if (n_unparsed > 0) message(sprintf("有 %d 筆日期無法解析，已剔除。", n_unparsed))

data <- data %>% filter(!is.na(Date)) %>% arrange(Date)

evaluate_point <- function(current_date, current_value) {
  start_date <- current_date - days(365)
  end_date   <- current_date + days(365)

  context_data <- data %>% filter(Date != current_date & Date >= start_date & Date <= end_date)

  if (nrow(context_data) < 730) {
    missing <- 730 - nrow(context_data)
    remaining_data <- data %>% filter(Date != current_date & !(Date >= start_date & Date <= end_date))
    context_data <- bind_rows(context_data, head(remaining_data, missing))
  }

  if (nrow(context_data) < 30) return(NA_character_)

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
data <- data %>% mutate(Date = format(Date, "%Y/%m/%d"))

write_csv(data, "sp500_eva_1998_2024.csv")
