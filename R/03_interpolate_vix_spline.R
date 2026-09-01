# ------------------------------------------------------------------------
# 03. VIX 缺失值處理：樣條插值 (Spline Interpolation)
#
# VIX（CBOE 波動率指數，俗稱恐慌指數）雖然是日頻資料，但原始資料在假日、
# 非交易日會有缺漏，若直接以最近值填補容易失真。這裡先建立一段完整的
# 連續日期序列，再用三次樣條插值 (na.spline) 補齊缺口，讓數值變化更平滑、
# 更貼近真實走勢，而不是簡單地前向/後向填補。
#
# 輸入: data/raw/VIX_train_raw.csv, data/raw/VIX_test_raw.csv
#       （欄位：observation_date, VIXCLS，皆來自 FRED）
# 輸出: data/train/VIX_train.csv, data/test/VIX_test.csv
# ------------------------------------------------------------------------

library(readr)
library(dplyr)
library(zoo)     # na.spline()

interpolate_vix <- function(input_path, output_path) {
  vix_data <- read_csv(input_path, show_col_types = FALSE) %>%
    rename(Date = observation_date, VIX = VIXCLS) %>%
    mutate(Date = as.Date(Date, format = "%Y/%m/%d")) %>%
    filter(!is.na(Date)) %>%
    arrange(Date)

  # 建立完整、不中斷的日期序列
  full_dates <- tibble(Date = seq(min(vix_data$Date), max(vix_data$Date), by = "day"))

  vix_data_full <- full_dates %>%
    left_join(vix_data, by = "Date") %>%
    mutate(VIX = na.spline(VIX)) %>%
    select(Date, VIX)

  # 統一日期字串格式為 "YYYY/MM/DD"，與其他資料源（如 EPU）對齊，
  # 否則合併腳本（05/06）以 Date 字串做 left_join 時會因格式不一致而配不上
  vix_data_full$Date <- format(vix_data_full$Date, "%Y/%m/%d")

  write_csv(vix_data_full, output_path)
  invisible(vix_data_full)
}

interpolate_vix("data/raw/VIX_train_raw.csv", "data/train/VIX_train.csv")
interpolate_vix("data/raw/VIX_test_raw.csv",  "data/test/VIX_test.csv")
