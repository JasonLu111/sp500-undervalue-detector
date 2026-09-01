# ------------------------------------------------------------------------
# 01. 季頻資料轉日頻資料 (Quarterly -> Daily)
#
# CPAT（稅後企業利潤）等總經指標僅以「季」為頻率公布，但目標變數 S&P 500
# 與其他多數特徵（VIX、EPU...）皆為日頻資料。為了讓所有特徵能以「日」為
# 單位對齊、合併，這裡以該季第一天的公布值，前向填補 (forward-fill) 到
# 該季的每一天。
#
# 輸入 (raw, 未清理): data/raw/CPAT_train_raw.csv, data/raw/CPAT_test_raw.csv
# 輸出 (清理後，日頻): data/train/CPAT_train.csv, data/test/CPAT_test.csv
# ------------------------------------------------------------------------

library(readr)
library(dplyr)
library(lubridate)

#' 將單一季頻指標展開為日頻資料
#'
#' @param input_path 原始 CSV 路徑，第一欄為當季起始日期，第二欄為數值
#' @param output_path 輸出 CSV 路徑
#' @param indicator_name 指標欄位名稱（例如 "CPAT"），會用於輸出檔的欄名
convert_quarterly_to_daily <- function(input_path, output_path, indicator_name) {
  quarterly_data <- read_csv(input_path, show_col_types = FALSE)
  colnames(quarterly_data) <- c("Date", indicator_name)

  quarterly_data$Date <- ymd(quarterly_data$Date)
  quarterly_data[[indicator_name]] <- as.numeric(quarterly_data[[indicator_name]])

  daily_rows <- lapply(seq_len(nrow(quarterly_data)), function(i) {
    start_date <- quarterly_data$Date[i]
    end_date <- start_date %m+% months(3) - days(1)  # 該季最後一天
    data.frame(Date = seq(start_date, end_date, by = "day"),
               value = quarterly_data[[indicator_name]][i])
  })

  daily_data <- bind_rows(daily_rows)
  names(daily_data)[2] <- indicator_name
  # 統一日期字串格式為 "YYYY/MM/DD"，與其他資料源（如 EPU）對齊，
  # 否則合併腳本（05/06）以 Date 字串做 left_join 時會因格式不一致而配不上
  daily_data$Date <- format(daily_data$Date, "%Y/%m/%d")

  write_csv(daily_data, output_path)
  invisible(daily_data)
}

convert_quarterly_to_daily("data/raw/CPAT_train_raw.csv", "data/train/CPAT_train.csv", "CPAT")
convert_quarterly_to_daily("data/raw/CPAT_test_raw.csv",  "data/test/CPAT_test.csv",   "CPAT")
