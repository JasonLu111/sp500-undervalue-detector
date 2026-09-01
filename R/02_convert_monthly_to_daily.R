# ------------------------------------------------------------------------
# 02. 月頻資料轉日頻資料 (Monthly -> Daily)
#
# CPI、PPI、JOP（職缺數）、FFR（聯邦基金利率）、RBE（實質有效匯率）、
# INFE2（兩年期通膨預期）皆為月頻公布的總經指標。做法與季頻資料相同：
# 以當月公布值前向填補到當月每一天，統一成日頻資料以便與 S&P 500 對齊。
#
# 這支腳本把原本針對每個指標各自複製貼上的版本，重構為單一可重用函式，
# 並用迴圈處理全部 6 個指標 x train/test，共 12 個檔案。
#
# 輸入: data/raw/{INDICATOR}_train_raw.csv, data/raw/{INDICATOR}_test_raw.csv
# 輸出: data/train/{INDICATOR}_train.csv, data/test/{INDICATOR}_test.csv
# ------------------------------------------------------------------------

library(readr)
library(dplyr)
library(lubridate)

#' 將單一月頻指標展開為日頻資料
#'
#' @param input_path 原始 CSV 路徑，第一欄為當月起始日期，第二欄為數值
#' @param output_path 輸出 CSV 路徑
#' @param indicator_name 指標欄位名稱，會用於輸出檔的欄名
convert_monthly_to_daily <- function(input_path, output_path, indicator_name) {
  monthly_data <- read_csv(input_path, show_col_types = FALSE)
  colnames(monthly_data) <- c("Date", indicator_name)

  monthly_data$Date <- ymd(monthly_data$Date)
  monthly_data[[indicator_name]] <- as.numeric(monthly_data[[indicator_name]])

  daily_rows <- lapply(seq_len(nrow(monthly_data)), function(i) {
    start_date <- monthly_data$Date[i]
    end_date <- ceiling_date(start_date, "month") - days(1)  # 該月最後一天
    data.frame(Date = seq(start_date, end_date, by = "day"),
               value = monthly_data[[indicator_name]][i])
  })

  daily_data <- bind_rows(daily_rows)
  names(daily_data)[2] <- indicator_name
  # 統一日期字串格式為 "YYYY/MM/DD"，與其他資料源（如 EPU）對齊，
  # 否則合併腳本（05/06）以 Date 字串做 left_join 時會因格式不一致而配不上
  daily_data$Date <- format(daily_data$Date, "%Y/%m/%d")

  write_csv(daily_data, output_path)
  invisible(daily_data)
}

monthly_indicators <- c("CPI", "PPI", "JOP", "FFR", "RBE", "INFE2")

for (indicator in monthly_indicators) {
  convert_monthly_to_daily(
    input_path    = sprintf("data/raw/%s_train_raw.csv", indicator),
    output_path   = sprintf("data/train/%s_train.csv", indicator),
    indicator_name = indicator
  )
  convert_monthly_to_daily(
    input_path    = sprintf("data/raw/%s_test_raw.csv", indicator),
    output_path   = sprintf("data/test/%s_test.csv", indicator),
    indicator_name = indicator
  )
}
