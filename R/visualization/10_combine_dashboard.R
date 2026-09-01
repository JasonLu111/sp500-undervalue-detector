# ------------------------------------------------------------------------
# 10. [作品集補充] 將 07–09 的四張圖組成單一 R 視覺化總覽
#
# 求職作品集用：與其在 README 裡貼四張各自獨立的圖，這裡用 patchwork
# 把估值時間軸、總經指標走勢、類別分布、VIX 區隔力盒鬚圖排版成一張
# 版面一致的儀表板圖，展示 R 多圖組合 (multi-panel composition) 的能力。
#
# 前提：需先執行過 07_visualize_sp500_valuation_timeline.R、
# 08_visualize_macro_indicator_trends.R、09_visualize_valuation_distribution.R
# （或直接執行本腳本，會透過 sys.source() 自動重新產生一次）。
#
# 輸出: docs/images/r_visualization_dashboard.png
# ------------------------------------------------------------------------

library(patchwork)
library(ggplot2)

e07 <- new.env(); sys.source("R/visualization/07_visualize_sp500_valuation_timeline.R", envir = e07)
e08 <- new.env(); sys.source("R/visualization/08_visualize_macro_indicator_trends.R", envir = e08)
e09 <- new.env(); sys.source("R/visualization/09_visualize_valuation_distribution.R", envir = e09)

p_timeline <- e07$p
# 組合圖版面較窄，副標題在 patchwork 疊圖時容易被壓縮到看不見，這裡拿掉
p_macro    <- e08$p + labs(subtitle = NULL)
p_balance  <- e09$p_balance
p_vix      <- e09$p_vix

dashboard <- (p_timeline) /
  (p_macro) /
  (p_balance | p_vix) +
  plot_layout(heights = c(2, 2.6, 1.6)) +
  plot_annotation(
    title = "S&P 500 估值偵測器：R 資料視覺化總覽",
    subtitle = "估值時間軸　→　總經指標走勢（small multiples）　→　類別分布與 VIX 特徵區隔力",
    theme = theme(
      plot.title = element_text(face = "bold", size = 18),
      plot.subtitle = element_text(size = 12, color = "grey30")
    )
  )

ggsave("docs/images/r_visualization_dashboard.png", plot = dashboard, width = 12, height = 15, dpi = 150)
