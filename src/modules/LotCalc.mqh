//+------------------------------------------------------------------+
//| LotCalc.mqh - Dynamic Lot Sizing & SR Level Helpers             |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

double GetZScore(int period, ENUM_TIMEFRAMES tf) {
   double close[];
   if(CopyClose(_Symbol, tf, 0, period, close) < period) return 0;

   double mean = 0;
   for(int i=0; i<period; i++) mean += close[i];
   mean /= period;

   double variance = 0;
   for(int i=0; i<period; i++) variance += MathPow(close[i] - mean, 2);
   variance /= period;

   double stdDev = MathSqrt(variance);
   if(stdDev == 0) return 0;

   return (close[period-1] - mean) / stdDev;
}

// Parse "0.02,0.03,0.05" -> double array
int ParseDoubleList(string str, double &arr[]) {
   string parts[];
   int count = StringSplit(str, StringGetCharacter(",",0), parts);
   ArrayResize(arr, count);
   for(int i=0; i<count; i++) {
      StringTrimLeft(parts[i]); StringTrimRight(parts[i]);
      arr[i] = StringToDouble(parts[i]);
   }
   return count;
}

// Tính Lot động để kéo TP về mức hòa vốn 1 rổ hoặc hòa vốn tổng (Total BE)
double CalculateRecoveryLot(bool isTrim, double srLevel, double tpPips) {
   double vSelf = GetTotalLots(isTrim);

   int mainCount = CountPositions(0, false);
   int trimCount = CountPositions(0, true);
   bool useHedgeMerge = (InpHedgeMergeVolume && mainCount > 0 && trimCount > 0);

   if(useHedgeMerge && ArraySize(g_trimDcaTP) > 0) {
      tpPips = g_trimDcaTP[0];
   }

   double tpDistPrice = tpPips * g_point * g_p2p;

   // Ngăn chặn tính Lot Recovery quá sớm
   if(useHedgeMerge) {
      int totalPos = mainCount + trimCount;
      if(totalPos < InpTrimBEAfterDCA - 1) return 0.0;
   } else if(InpEnableTrimTotalBE && trimCount > 0) {
      int totalPos = mainCount + trimCount;
      if(totalPos < InpBEAfterDCA - 1) return 0.0;
   } else {
      int posCount = (isTrim ? trimCount : mainCount);
      int threshold = isTrim ? InpTrimBEAfterDCA : InpBEAfterDCA;
      if(InpHedgeMergeVolume) threshold = InpTrimBEAfterDCA;
      if(posCount < threshold - 1) return 0.0;
   }

   if(!InpEnableTrimTotalBE && !useHedgeMerge) {
      // Rổ nào tính rổ đó (Basic recovery)
      if(vSelf == 0) return 0;
      double avgSelf = GetAvgPrice(isTrim);
      int dirSelf = isTrim ? g_trimDirection : g_direction;
      if(dirSelf == 0) return 0;

      double recovery = 0;
      if(dirSelf == 1) recovery = (avgSelf - srLevel - tpDistPrice) * vSelf / tpDistPrice;
      else recovery = (srLevel - avgSelf - tpDistPrice) * vSelf / tpDistPrice;
      return MathMax(0.0, recovery);
   }

   // Total Breakeven Logic (Cầu hòa chung 2 rổ)
   double vOther = GetTotalLots(!isTrim);
   if(vOther == 0) {
      if(vSelf == 0) return 0;
      double avgSelf = GetAvgPrice(isTrim);
      int dirSelf = isTrim ? g_trimDirection : g_direction;
      if(dirSelf == 0) return 0;

      double recovery = 0;
      if(dirSelf == 1) recovery = (avgSelf - srLevel - tpDistPrice) * vSelf / tpDistPrice;
      else recovery = (srLevel - avgSelf - tpDistPrice) * vSelf / tpDistPrice;
      return MathMax(0.0, recovery);
   }

   // Có cả 2 rổ -> Giải phương trình bậc 2 tìm Lot X
   double avgSelf  = GetAvgPrice(isTrim);
   double avgOther = GetAvgPrice(!isTrim);
   int dirSelf = isTrim ? g_trimDirection : g_direction;
   if(dirSelf == 0) return 0;

   double A = tpDistPrice;
   double B = 2.0 * vSelf * tpDistPrice - vOther * dirSelf * (srLevel + dirSelf * tpDistPrice - avgOther);
   double C = vSelf * vSelf * tpDistPrice - vSelf * vOther * dirSelf * (avgSelf + dirSelf * tpDistPrice - avgOther);

   if(C >= 0) return 0.0;

   double delta = B * B - 4.0 * A * C;
   if(delta < 0) return 0.0;

   double x = (-B + MathSqrt(delta)) / (2.0 * A);
   return MathMax(0.0, x);
}

// Quét các mức Kijun/SSB đi ngang trong quá khứ làm S/R tĩnh
int GetHistoricalSRLevels(C_Ichimoku &ichi, double refPrice, int dir, double &outLevels[], int maxLevels=20) {
   double rawLevels[];
   int rawCount = 0;

   for(int i = 1; i <= 300; i++) {
      S_IchiData d1, d2, d3, d4;
      if(!ichi.Get(i, d1) || !ichi.Get(i+1, d2) || !ichi.Get(i+2, d3) || !ichi.Get(i+3, d4)) break;

      if(d1.kijun == d2.kijun && d2.kijun == d3.kijun && d3.kijun == d4.kijun) {
         ArrayResize(rawLevels, rawCount+1);
         rawLevels[rawCount++] = d1.kijun;
      }

      if(d1.ssb == d2.ssb && d2.ssb == d3.ssb && d3.ssb == d4.ssb) {
         ArrayResize(rawLevels, rawCount+1);
         rawLevels[rawCount++] = d1.ssb;
      }
   }

   double validLevels[];
   int validCount = 0;

   for(int i=0; i<rawCount; i++) {
      double lvl = rawLevels[i];

      double minGap = InpMinDCAGap * g_point * g_p2p;
      if(dir == 1 && lvl > refPrice - minGap) continue;
      if(dir == -1 && lvl < refPrice + minGap) continue;
 
      bool isDup = false;
      for(int j=0; j<validCount; j++) {
         if(MathAbs(validLevels[j] - lvl) < 3.0 * g_point * g_p2p) {
            isDup = true; break;
         }
      }

      if(!isDup) {
         ArrayResize(validLevels, validCount+1);
         validLevels[validCount++] = lvl;
      }
   }

   ArraySort(validLevels);
   if(dir == 1) {
      for(int i=0; i<validCount/2; i++) {
         double temp = validLevels[i];
         validLevels[i] = validLevels[validCount - 1 - i];
         validLevels[validCount - 1 - i] = temp;
      }
   }

   int copied = MathMin(validCount, maxLevels);
   ArrayResize(outLevels, copied);
   for(int i=0; i<copied; i++) outLevels[i] = validLevels[i];

   return copied;
}
