//+------------------------------------------------------------------+
//| MergedTP.mqh - Merged TP (Close basket at target DCA level TP)  |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

void UpdateMergedTP(bool isTrim) {
   bool enabled = isTrim ? InpEnableTrimMTP : InpEnableMergedTP;
   int targetLevel = isTrim ? InpTrimMTPLevel : InpMergedTPLevel;
   string prefix = isTrim ? "PX TRIM DCA" : "PX DCA";
   int activeLevel = isTrim ? g_trimDcaLevel : g_dcaLevel;
   int dir = isTrim ? g_trimDirection : g_direction;

   if(!enabled) return;
   if(activeLevel < targetLevel) return;
   if(CountPositions(0, isTrim) < 2) return;

   // Lấy TP pips của level chỉ định
   double tpPips = 0;
   if(isTrim) {
      int tpIdx = targetLevel - 1;
      if(tpIdx >= ArraySize(g_trimDcaTP)) return;
      tpPips = g_trimDcaTP[tpIdx];
   } else {
      int tpIdx = targetLevel - 1;
      if(tpIdx >= ArraySize(g_dcaTP)) return;
      tpPips = g_dcaTP[tpIdx];
   }

   string targetComment = prefix + IntegerToString(targetLevel);
   double refPrice = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      bool isTrimPos = (StringFind(PositionGetString(POSITION_COMMENT), "TRIM") >= 0);
      if(isTrimPos == isTrim && PositionGetString(POSITION_COMMENT) == targetComment) {
         refPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         break;
      }
   }
   if(refPrice <= 0) return;

   double tpDist = tpPips * g_point * g_p2p;
   double mergedTP = 0;
   if(dir == 1) mergedTP = refPrice + tpDist;
   else if(dir == -1) mergedTP = refPrice - tpDist;
   else return;

   double price = (dir == 1) ? m_symbol.Bid() : m_symbol.Ask();
   bool tpHit = (dir == 1 && price >= mergedTP) || (dir == -1 && price <= mergedTP);

   if(tpHit) {
      double profit = GetBasketProfit(isTrim);

      if(InpHedgeType != HEDGE_NONE) {
         profit = GetBasketProfit(false) + GetBasketProfit(true);
         CloseAllPositions();
         g_cycleWins++;
         g_cycleProfit += profit;
         PrintFormat("HEDGE TP [%s] L%d: %.2f USD | Total: +%.2f", isTrim?"TRIM":"MAIN", targetLevel, profit, g_cycleProfit);
         g_direction=0; g_dcaLevel=0; g_lastDCATime=0; g_lastPyramidTime=0;
         g_trimActive=false; g_trimDirection=0; g_trimDcaLevel=0; g_lastTrimTime = 0;
      } else {
         int count = CountPositions(0, isTrim);
         CloseBasket(isTrim);
         g_cycleProfit += profit;

         if(!isTrim) {
            g_cycleWins++;
            PrintFormat("MERGED TP MAIN L%d #%d: %.2f USD | %d pos | Total: +%.2f", targetLevel, g_cycleWins, profit, count, g_cycleProfit);
            g_direction=0; g_dcaLevel=0; g_lastDCATime=0; g_lastPyramidTime=0;
         } else {
            PrintFormat("MERGED TP TRIM L%d: %.2f USD | %d pos | Total: +%.2f", targetLevel, profit, count, g_cycleProfit);
            g_trimActive=false; g_trimDirection=0; g_trimDcaLevel=0; g_lastTrimTime=0;
         }
      }
   }
}
