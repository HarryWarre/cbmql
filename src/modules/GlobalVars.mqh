//+------------------------------------------------------------------+
//| GlobalVars.mqh - Global Objects & State Variables               |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

CTrade      m_trade;
CSymbolInfo m_symbol;
int         m_rsiHandle = INVALID_HANDLE;

// Trạng thái DCA
int      g_direction     = 0;      // 1=BUY, -1=SELL, 0=chờ tín hiệu
int      g_dcaLevel      = 0;      // Tầng DCA hiện tại (0=entry, 1-N=DCA)
datetime g_lastDCATime   = 0;      // Thời gian DCA gần nhất
datetime g_lastPyramidTime = 0;    // Thời gian Pyramid DCA gần nhất
int      g_cycleWins     = 0;      // Số chu kỳ thắng
double   g_cycleProfit   = 0;      // Tổng profit tích lũy

// Parsed DCA arrays
double   g_dcaTP[];                // TP pips mỗi tầng rổ chính
double   g_dcaStep[];              // Quãng DCA pips mỗi tầng rổ chính
double   g_trimDcaTP[];            // TP pips mỗi tầng rổ tỉa
double   g_trimDcaStep[];          // Quãng DCA pips mỗi tầng rổ tỉa

// Trim tracking
bool     g_trimActive    = false;  // Có rổ tỉa đang hoạt động
int      g_trimDirection = 0;      // Hướng của rổ tỉa (1=BUY, -1=SELL)
int      g_trimDcaLevel  = 0;      // Tầng DCA của rổ tỉa
datetime g_lastTrimTime  = 0;      // Thời gian DCA của rổ tỉa

// PropFirm tracking
double   g_dayStartBalance = 0;
int      g_lastDay = 0;
double   g_initialBalance = 0;
bool     g_propFirmLocked = false; // Khóa giao dịch khi vượt giới hạn

// Ichimoku state
ENUM_ICHI_STATE g_ichiState = ICHI_RANGE;
double   g_point    = 0;
double   g_p2p      = 1;           // Point to Pip multiplier
datetime g_lastBar  = 0;

// Matrix scoring (dùng để confirm tín hiệu)
int g_scoreBuy  = 0;
int g_scoreSell = 0;
int g_scoreNet  = 0;
