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

set.seed(123)
main_df <- main_df %>% slice_sample(n = 1000) %>% arrange(Date)

write_csv(main_df, "data/processed/merged_train_data_ram1000.csv")
