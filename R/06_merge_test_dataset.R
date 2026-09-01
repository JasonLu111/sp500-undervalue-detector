# ------------------------------------------------------------------------
# 06. 合併測試集：left join 全部日頻指標
#
# 邏輯與 05_merge_train_dataset.R 相同，套用在 data/test/ 上。測試集
# 刻意「不做」等機率抽樣：保留完整、依時間排序的測試期間資料
# （2023-01-01 ~ 2025-05-20），確保模型評估時看到的是連續、真實的時間
# 序列，而不是被打散重抽樣過的資料。
#
# 輸入: data/test/*.csv
# 輸出: data/processed/merged_test_data.csv
# ------------------------------------------------------------------------

library(dplyr)
library(readr)

test_dir <- "data/test"
files <- list.files(test_dir, pattern = "\\.csv$", full.names = TRUE)

if (length(files) == 0) stop("找不到任何 CSV 檔案，請確認 data/test 是否存在。")

# 明確指定 Date 欄為字串型別，並統一經過 as.Date() 正規化再轉回固定格式：
# readr 對「YYYY/MM/DD」格式的欄位會依抽樣結果自動猜測型別（有時猜成
# Date、有時猜成 character），加上部分來源檔（如未經處理的 EPU）日期沒有
# 補零（"2024/1/1" 而非 "2024/01/01"），這些差異都會讓 left_join 用的字串
# 鍵值對不上，使 join 大量配不到、na.omit() 後資料被過度刪減。
read_with_normalized_date <- function(path) {
  df <- read_csv(path, col_types = cols(Date = col_character()), show_col_types = FALSE)
  colnames(df)[1] <- "Date"
  df$Date <- format(as.Date(df$Date, format = "%Y/%m/%d"), "%Y-%m-%d")
  df
}

main_df <- read_with_normalized_date(files[1])

for (i in 2:length(files)) {
  temp_df <- read_with_normalized_date(files[i])
  main_df <- left_join(main_df, temp_df, by = "Date")
}

main_df <- na.omit(main_df)
main_df$Date <- as.Date(main_df$Date)
main_df <- main_df %>% arrange(Date)

write_csv(main_df, "data/processed/merged_test_data.csv")
