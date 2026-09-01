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

# 明確指定 Date 欄為字串型別：readr 對「YYYY/MM/DD」格式的欄位會依抽樣結果
# 自動猜測型別，有時猜成 Date、有時猜成 character，猜測結果不一致會導致
# 後面 left_join 用的字串鍵值格式對不上（例如 "2000/10/01" vs "2000-10-01"），
# 使 join 全部配不到、na.omit() 後整個資料集被清空。
main_df <- read_csv(files[1], col_types = cols(Date = col_character()), show_col_types = FALSE)
colnames(main_df)[1] <- "Date"

for (i in 2:length(files)) {
  temp_df <- read_csv(files[i], col_types = cols(Date = col_character()), show_col_types = FALSE)
  colnames(temp_df)[1] <- "Date"
  main_df <- left_join(main_df, temp_df, by = "Date")
}

main_df <- na.omit(main_df)
main_df$Date <- as.Date(main_df$Date, format = "%Y/%m/%d")
main_df <- main_df %>% arrange(Date)

write_csv(main_df, "data/processed/merged_test_data.csv")
