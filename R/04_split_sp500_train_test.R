# ------------------------------------------------------------------------
# 04. S&P 500 原始資料切分為訓練集 / 測試集
#
# 依日期範圍切分 S&P 500 每日收盤價：
#   - 訓練期間: 2000-01-01 ~ 2022-12-31（供模型學習估值型態）
#   - 測試期間: 2023-01-01 ~ 2025-05-20（模擬「未來」資料，驗證模型）
# 採用「時間切分」而非隨機切分，避免用未來資訊預測過去（look-ahead bias），
# 這對時間序列問題是必要的資料切分方式。
#
# 輸出寫到 data/interim/ 而非 data/train|test/：這裡只是「切好時間範圍的
# 純股價」，還沒有估值標籤，不該被 05/06 合併腳本當成最終特徵誤merge進去
# （估值分類完成後的版本是 zEVA_sp500_train.csv，才是進入合併的檔案）。
#
# 輸入: data/raw/sap500_raw.csv (欄位：Date, SP500)
# 輸出: data/interim/sp500_train_raw.csv, data/interim/sp500_test_raw.csv
# ------------------------------------------------------------------------

library(readr)
library(dplyr)

data <- read_csv("data/raw/sap500_raw.csv", col_names = c("Date", "SP500"), skip = 1,
                  show_col_types = FALSE)
data$Date <- as.Date(data$Date, format = "%Y/%m/%d")

sp500_train <- filter(data, Date >= as.Date("2000-01-01") & Date <= as.Date("2022-12-31"))
sp500_test  <- filter(data, Date >= as.Date("2023-01-01") & Date <= as.Date("2025-05-20"))

write_csv(sp500_train, "data/interim/sp500_train_raw.csv")
write_csv(sp500_test,  "data/interim/sp500_test_raw.csv")
