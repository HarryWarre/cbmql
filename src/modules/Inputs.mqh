//+------------------------------------------------------------------+
//| Inputs.mqh - All Input Parameters                                |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

input group "========= CORE ========="
input ENUM_EXEC_SPEED InpExecSpeed     = EXEC_BAR_CLOSE;
input ENUM_MTF_MODE   InpMTFMode       = MTF_TRIPLE;
input ENUM_TIMEFRAMES InpBaseTF        = PERIOD_M5;
input ENUM_TIMEFRAMES InpMidTF         = PERIOD_M15;
input ENUM_TIMEFRAMES InpHighTF        = PERIOD_H1;
input int             InpMagicNumber   = 888999;

input group "========= ICHIMOKU (Ch.1-6) ========="
input int    InpTenkanPeriod     = 9;       // Tenkan Period (Ch.5)
input int    InpKijunPeriod      = 26;      // Kijun Period (Ch.6)
input int    InpSenkouPeriod     = 52;      // Senkou Period (Ch.10)
input int    InpKijunFlatBars    = 5;       // Số nến Kijun phẳng = Range (Ch.8)
input double InpMinKumoThick    = 10.0;    // Bề dày Kumo tối thiểu để xác nhận (Ch.12)

input group "========= DCA STRATEGY ========="
input double InpEntryLot         = 0.01;    // Lot cố định cho lệnh Entry
input string InpDCATPs           = "10,15,20,30";          // TP pips mỗi tầng DCA
input string InpDCASteps         = "15,20,30,40";          // Quãng DCA pips mỗi tầng
input double InpDCARiskPct       = 2.0;     // Max % equity cho mỗi DCA
input int    InpDCACooldownBars  = 3;       // Chờ tối thiểu N nến giữa các DCA
input double InpMinDCAGap        = 0;     // Khoảng cách tối thiểu  DCA (pips)
input bool   InpDCAIgnoreTrend   = false;   // DCA bất chấp trend (Chỉ L0 theo trend)

input group "========= PYRAMID DCA (Thuận Trend) ========="
input bool   InpEnablePyramid    = true;    // Bật Pyramid DCA dương
input double InpMinPyramidGap    = 0;     // Khoảng cách tối thiểu giữa các lệnh Pyramid
input bool   InpPyramidTrailingKijun = true; // Trailing SL theo Kijun

input group "========= HÒA VỐN (Breakeven) ========="
input bool   InpEnableBE         = true;    // Bật chế độ hòa vốn
input int    InpBEAfterDCA       = 2;       // Kích hoạt hòa vốn sau DCA level X
input double InpBEPips           = 5.0;     // Mức lợi nhuận (pips) để đóng hòa vốn

input group "========= TỈA LỆNH & HEDGE ========="
input bool   InpEnableTrim       = true;    // Bật tỉa lệnh Z-Score
input bool   InpEnableHedgeMode  = true;    // Bật Hedge đảo chiều (Sanyaku)
input bool   InpHedgeWaitKumoBreak = true;  // Hedge chờ giá thoát mây HighTF
input ENUM_HEDGE_TYPE InpHedgeType = HEDGE_NONE; // Chế độ Hedge khi đảo trend
input bool   InpEnableTrimTotalBE= true;    // Tính Lot tỉa để Gồng Hòa Vốn Tổng
input bool   InpHedgeMergeVolume = false;   // Gộp số lượng lệnh Hedge và Chính lấy mốc Tỉa
input int    InpTrimAfterDCA     = 2;       // Tỉa sau DCA level X
input string InpTrimDCATPs       = "15,20,30,40";           // TP pips rổ tỉa
input string InpTrimDCASteps     = "15,20,30,40";           // Quãng DCA pips rổ tỉa
input bool   InpTrimIgnoreTrend  = false;   // Tỉa/Hedge DCA bất chấp trend
input int    InpTrimZPeriod      = 50;      // Chu kỳ Z-Score
input double InpTrimZThreshold   = 2.0;     // Mức Z-Score kích hoạt tỉa
input int    InpTrimBEAfterDCA   = 2;       // Kích hòa vốn tỉa sau DCA level X
input double InpTrimBEPips       = 5.0;     // Mức hòa vốn (pips) rổ tỉa

input group "========= GỘP TP (Merged TP) ========="
input bool   InpEnableMergedTP   = true;    // Bật gộp TP rổ chính
input int    InpMergedTPLevel    = 3;       // Lấy TP của DCA level này để đóng hết
input bool   InpEnableTrimMTP    = true;    // Bật gộp TP rổ tỉa
input int    InpTrimMTPLevel     = 2;       // Lấy TP của tỉa level này để đóng rổ tỉa

input group "========= PROFIT RECYCLER (Tái chế lợi nhuận) ========="
input bool   InpEnableRecycler   = false;   // Bật tái chế lợi nhuận (Dùng lãi cũ diệt lỗ mới)
input int    InpRecyclerLookback = 10;      // Số lệnh chốt lãi gần nhất để tính toán
input bool   InpRecyclerReset    = true;    // Reset danh sách sau khi đã "thịt" lệnh lỗ

input group "========= ADVANCED EXIT ========="
input bool   InpCloseOnHighTFReversal = true; // Đóng toàn bộ lệnh khi khung lớn (HighTF) đảo chiều

input group "========= PROPFIRM COMPLIANCE ========="
input bool   InpPropFirmMode     = false;   // Bật chế độ PropFirm (set SL giả)
input double InpFakeSLPips       = 500.0;   // SL giả (pips) - đặt xa không để chạm
input double InpDailyLossPct     = 5.0;     // Giới hạn lỗ tối đa trong ngày (%)
input double InpMaxDrawdownPct   = 10.0;    // Giới hạn Drawdown tối đa (%)

input group "========= SESSION & TIME ========="
input bool   InpUseTimeFilter    = true;
input string InpTokyo            = "00:00-09:00";
input string InpLondon           = "07:00-16:00";
input string InpNewYork          = "13:00-22:00";
input bool   InpCloseOnFriday    = true;
input int    InpFridayCloseHour  = 22;
input bool   InpUseNewsFilter    = false;  // Lọc tin tức (không vào L0 khi có tin)
input int    InpNewsMinutes      = 30;     // Phút tránh tin trước/sau

input group "========= RSI FILTER ========="
input bool   InpEnableRSIFilter  = true;    // Bật lọc RSI (chỉ lọc L0 entry)
input bool   InpFilterHighKumo   = true;    // Bật lọc mây khung lớn nhất cho lệnh đầu
input ENUM_TIMEFRAMES InpRSITimeframe = PERIOD_M15; // Khung thời gian RSI
input int    InpRSIPeriod        = 14;      // Chu kỳ RSI
input double InpRSIOverbought    = 70.0;    // Vùng quá mua (Cấm BUY L0)
input double InpRSIOversold      = 30.0;    // Vùng quá bán (Cấm SELL L0)

input group "========= GUI ========="
input bool   InpShowGUI          = true;
input color  InpGUIBG            = C'15,20,30';
input color  InpGUIText          = C'200,200,200';

input int    InpMaxSpread        = 50;      // Spread tối đa (points)
