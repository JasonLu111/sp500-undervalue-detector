# ------------------------------------------------------------------------
# 05. 合併訓練集：left join 全部日頻指標 + 時間序列抽樣
#
# 讀取 data/train/ 底下所有已轉為日頻的 CSV（CPAT, CPI, PPI, JOP, FFR,
# RBE, INFE2, VIX, zEVA_sp500），以 Date 為鍵依序 left join 成單一寬表，
# 並移除任一欄位為缺失值的日期（確保每個交易日的所有特徵都齊全）。
#
# 因為完整日頻資料在建模上筆數過多、且日與日之間高度自相關，這裡依時間
# 排序後，用固定亂數種子做等機率抽樣至 1000 筆，抽樣後再依時間重新排序，
# 兼顧「資料量精簡」與「保留時間序列走勢」。
#
# 輸入: data/train/*.csv
# 輸出: data/processed/merged_train_data_ram1000.csv
# ------------------------------------------------------------------------

library(dplyr)
library(readr)

train_dir <- "data/train"
files <- list.files(train_dir, pattern = "\\.csv$", full.names = TRUE)

if (length(files) == 0) stop("找不到任何 CSV 檔案，請確認 data/train 是否存在。")

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

set.seed(123)
main_df <- main_df %>% slice_sample(n = 1000) %>% arrange(Date)

write_csv(main_df, "data/processed/merged_train_data_ram1000.csv")
