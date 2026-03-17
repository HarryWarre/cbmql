//+------------------------------------------------------------------+
//| Defines.mqh - Enumerations & Constants                           |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

// Trạng thái thị trường theo Ichimoku (Ch.13)
enum ENUM_ICHI_STATE {
   ICHI_STRONG_UP    = 2,    // Xu hướng tăng mạnh (Giá > TK > KJ > Kumo)
   ICHI_WEAK_UP      = 1,    // Xu hướng tăng yếu
   ICHI_RANGE        = 0,    // Đi ngang / Tích lũy (Ch.8-9: fake cross)
   ICHI_WEAK_DOWN    = -1,   // Xu hướng giảm yếu
   ICHI_STRONG_DOWN  = -2    // Xu hướng giảm mạnh
};

// Mức DCA dựa trên Ichimoku (Ch.5, 6, 12)
enum ENUM_DCA_LEVEL {
   DCA_NONE      = 0,   // Chưa DCA
   DCA_TENKAN    = 1,   // Pullback tới Tenkan (Ch.5: bệ đỡ đầu tiên)
   DCA_KIJUN     = 2,   // Pullback tới Kijun (Ch.6: cân bằng trung hạn)
   DCA_KUMO      = 3,   // Pullback vào Kumo (Ch.12: vùng cản mạnh)
   DCA_KUMO_DEEP = 4    // Pullback tới Senkou Span 2 (Ch.10: phòng tuyến cuối)
};

// Chế độ Hedge (đảo chiều rổ chính)
enum ENUM_HEDGE_TYPE {
   HEDGE_NONE          = 0, // Không dùng
   HEDGE_FULL_VOLUME   = 1, // Hedge 100% Volume
   HEDGE_AUTO_RECOVERY = 2  // Auto Hedge (Hòa vốn tại TP)
};

enum ENUM_MTF_MODE {
   MTF_SINGLE = 0,   // 1 khung thời gian (nhanh nhất)
   MTF_TRIPLE = 1    // 3 khung (M5+M15+H1, chuẩn)
};

enum ENUM_EXEC_SPEED {
   EXEC_BAR_CLOSE  = 0,   // Chờ đóng nến (an toàn, tránh fake)
   EXEC_EVERY_TICK = 1    // Mỗi tick (nhanh, rủi ro nhiễu)
};

// Sakata Candle Patterns
enum ENUM_SAKATA {
   SAK_NONE        = 0,
   SAK_BULL_ENGULF = 1,  SAK_BEAR_ENGULF = -1,
   SAK_MORNING     = 2,  SAK_EVENING     = -2,
   SAK_HAMMER      = 3,  SAK_SHOOTING    = -3,
   SAK_3SOLDIERS   = 4,  SAK_3CROWS      = -4,
   SAK_DOJI        = 5,
   SAK_MARUBOZU_B  = 7,  SAK_MARUBOZU_S  = -7
};
