//+------------------------------------------------------------------+
//| Ichimoku.mqh - MTF Data Engine & Analyzer (Ch.3-15)             |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| SECTION 4: ICHIMOKU MTF DATA ENGINE (Ch.15)                      |
//+------------------------------------------------------------------+
struct S_IchiData {
   double tenkan;    // Tenkan sen (Ch.5)
   double kijun;     // Kijun sen (Ch.6)
   double ssa;       // Senkou Span A (Ch.11)
   double ssb;       // Senkou Span B (Ch.10)
   double chikou;    // Chikou span (Ch.14)
};

class C_Ichimoku {
private:
   int m_handle;
public:
   C_Ichimoku() { m_handle = INVALID_HANDLE; }
   ~C_Ichimoku() { if(m_handle != INVALID_HANDLE) IndicatorRelease(m_handle); }

   bool Init(string sym, ENUM_TIMEFRAMES tf, int t, int k, int s) {
      m_handle = iIchimoku(sym, tf, t, k, s);
      return (m_handle != INVALID_HANDLE);
   }

   bool Get(int shift, S_IchiData &d) {
      double buf[1];
      if(CopyBuffer(m_handle, 0, shift, 1, buf) < 1) return false; d.tenkan = buf[0];
      if(CopyBuffer(m_handle, 1, shift, 1, buf) < 1) return false; d.kijun  = buf[0];
      if(CopyBuffer(m_handle, 2, shift, 1, buf) < 1) return false; d.ssa    = buf[0];
      if(CopyBuffer(m_handle, 3, shift, 1, buf) < 1) return false; d.ssb    = buf[0];
      if(CopyBuffer(m_handle, 4, shift, 1, buf) < 1) return false; d.chikou = buf[0];
      return true;
   }

   double KumoTop(S_IchiData &d)    { return MathMax(d.ssa, d.ssb); }
   double KumoBottom(S_IchiData &d) { return MathMin(d.ssa, d.ssb); }
   double KumoThick(S_IchiData &d)  { return MathAbs(d.ssa - d.ssb) / (g_point * g_p2p); }
};

C_Ichimoku m_ichiBase, m_ichiMid, m_ichiHigh;

//+------------------------------------------------------------------+
//| SECTION 7: ICHIMOKU ANALYZER (Ch.3-15)                           |
//+------------------------------------------------------------------+

// 7.1: Kijun Flatness - Phát hiện Range (Ch.8)
bool IsKijunFlat(C_Ichimoku &ichi, int periods) {
   S_IchiData d0;
   if(!ichi.Get(0, d0)) return false;
   int flat = 0;
   for(int i=1; i<=periods; i++) {
      S_IchiData di;
      if(!ichi.Get(i, di)) continue;
      if(MathAbs(d0.kijun - di.kijun) <= 2.0 * g_point * g_p2p)
         flat++;
   }
   return (flat >= periods - 1);
}

// 7.2: Kijun Slope - Authentic Cross (Ch.7)
// Returns: +1 (lên), 0 (ngang), -1 (xuống)
int KijunSlope(C_Ichimoku &ichi) {
   S_IchiData d0, d2;
   if(!ichi.Get(0, d0) || !ichi.Get(2, d2)) return 0;
   double diff = d0.kijun - d2.kijun;
   if(diff > 2.0 * g_point * g_p2p) return 1;
   if(diff < -2.0 * g_point * g_p2p) return -1;
   return 0;
}

// 7.3: Overextended - Giá quá xa Tenkan (Ch.5)
bool IsOverextended(C_Ichimoku &ichi, double price, double maxPips) {
   S_IchiData d;
   if(!ichi.Get(0, d)) return false;
   return (MathAbs(price - d.tenkan) > maxPips * g_point * g_p2p);
}

// 7.4: Chikou Momentum (Ch.14)
// Returns pips of momentum
double ChikouMomentum(C_Ichimoku &ichi, ENUM_TIMEFRAMES tf) {
   double chikouVal = iClose(_Symbol, tf, 0);
   double pastPrice = iClose(_Symbol, tf, InpKijunPeriod);
   return (chikouVal - pastPrice) / (g_point * g_p2p);
}

// 7.5: Sanyaku State (Ch.3)
// Trả về: 1 (Sanyaku Kouten), -1 (Gyakuten), 0 (không có)
int SanyakuState(C_Ichimoku &ichi, double price, ENUM_TIMEFRAMES tf) {
   S_IchiData d0, d1;
   if(!ichi.Get(0, d0) || !ichi.Get(1, d1)) return 0;

   double kumoTop = MathMax(d0.ssa, d0.ssb);
   double kumoBot = MathMin(d0.ssa, d0.ssb);

   double chikouVal  = iClose(_Symbol, tf, 0);
   double pastPrice  = iClose(_Symbol, tf, InpKijunPeriod);

   // Sanyaku Kouten (BUY)
   if(d0.tenkan > d0.kijun && price > kumoTop && chikouVal > pastPrice) {
      if(d0.kijun >= d1.kijun) return 1;
   }

   // Sanyaku Gyakuten (SELL)
   if(d0.tenkan < d0.kijun && price < kumoBot && chikouVal < pastPrice) {
      if(d0.kijun <= d1.kijun) return -1;
   }

   return 0;
}

// 7.6: Market State (Ch.13, 8-9)
ENUM_ICHI_STATE GetMarketState(C_Ichimoku &ichi, double price, ENUM_TIMEFRAMES tf) {
   S_IchiData d;
   if(!ichi.Get(0, d)) return ICHI_RANGE;

   if(IsKijunFlat(ichi, InpKijunFlatBars)) return ICHI_RANGE;

   double kumoTop = MathMax(d.ssa, d.ssb);
   double kumoBot = MathMin(d.ssa, d.ssb);

   if(price >= kumoBot && price <= kumoTop) return ICHI_RANGE;

   if(price > d.tenkan && d.tenkan > d.kijun && d.kijun > kumoTop) return ICHI_STRONG_UP;
   if(price < d.tenkan && d.tenkan < d.kijun && d.kijun < kumoBot) return ICHI_STRONG_DOWN;

   if(price > kumoTop) return ICHI_WEAK_UP;
   if(price < kumoBot) return ICHI_WEAK_DOWN;

   return ICHI_RANGE;
}

// 7.7: DCA Level Check (Ch.5, 6, 10, 12)
ENUM_DCA_LEVEL CheckPullbackLevel(C_Ichimoku &ichi, double price, int dir) {
   S_IchiData d;
   if(!ichi.Get(0, d)) return DCA_NONE;

   double kumoTop = MathMax(d.ssa, d.ssb);
   double kumoBot = MathMin(d.ssa, d.ssb);

   if(dir == 1) {
      if(price <= d.ssb) return DCA_KUMO_DEEP;
      if(price <= kumoBot) return DCA_KUMO;
      if(price <= d.kijun) return DCA_KIJUN;
      if(price <= d.tenkan) return DCA_TENKAN;
   }
   else if(dir == -1) {
      if(price >= d.ssb) return DCA_KUMO_DEEP;
      if(price >= kumoTop) return DCA_KUMO;
      if(price >= d.kijun) return DCA_KIJUN;
      if(price >= d.tenkan) return DCA_TENKAN;
   }

   return DCA_NONE;
}
