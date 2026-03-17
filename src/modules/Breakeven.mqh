//+------------------------------------------------------------------+
//| Breakeven.mqh - Breakeven Management                             |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

bool ManageBreakeven() {
   if(!InpEnableBE) return false;

   int mainCount = CountPositions(0, false);
   int trimCount = CountPositions(0, true);
   int totalCount = mainCount + trimCount;

   if(totalCount == 0) return false;

   // Có lệnh TRIM/HEDGE đang mở -> Dùng Total BE (gộp cả 2 rổ)
   if(trimCount > 0) {
      int threshold = InpBEAfterDCA;
      if(InpHedgeMergeVolume) threshold = InpTrimBEAfterDCA;

      if(totalCount < threshold) return false;

      double profit = GetBasketProfit(false) + GetBasketProfit(true);
      if(profit > 0) {
         double lots = GetTotalLots(false) + GetTotalLots(true);
         double pipValue = m_symbol.TickValue() * g_p2p;

         double targetProfit = InpBEPips * pipValue * lots;
         if(InpHedgeMergeVolume) targetProfit = InpTrimBEPips * pipValue * lots;

         if(profit >= targetProfit) {
            CloseAllPositions();
            g_cycleWins++;
            g_cycleProfit += profit;
            PrintFormat("BE TOTAL #%d: %.2f USD | %d pos (Main:%d + Trim:%d) | %.2f lot | Total: +%.2f",
               g_cycleWins, profit, totalCount, mainCount, trimCount, lots, g_cycleProfit);

            g_direction=0; g_dcaLevel=0; g_lastDCATime=0; g_lastPyramidTime=0;
            g_trimActive=false; g_trimDirection=0; g_trimDcaLevel=0; g_lastTrimTime=0;
            return true;
         }
      }
      return false;
   }

   // Chỉ có rổ chính -> Breakeven riêng lẻ
   if(g_dcaLevel < InpBEAfterDCA) return false;

   double profit = GetBasketProfit(false);
   double lots = GetTotalLots(false);
   double pipValue = m_symbol.TickValue() * g_p2p;
   double targetProfit = InpBEPips * pipValue * lots;
   
   if(profit >= targetProfit) {
      CloseBasket(false);
      g_cycleWins++;
      g_cycleProfit += profit;
      
      double realPips = (lots > 0 && pipValue > 0) ? profit / (lots * pipValue) : 0;
      
      PrintFormat("BE MAIN #%d: %.1f pips (%.2f USD) | L%d | %d pos %.2f lot | Total: +%.2f",
         g_cycleWins, realPips, profit, g_dcaLevel, mainCount, lots, g_cycleProfit);
      g_direction=0; g_dcaLevel=0; g_lastDCATime=0; g_lastPyramidTime=0;
      return true;
   }
   return false;
}

bool ManageTrimBreakeven() {
   if(!InpEnableTrim) return false;
   if(g_trimDcaLevel < InpTrimBEAfterDCA) return false;

   double profit = GetBasketProfit(true);
   double lots = GetTotalLots(true);
   double pipValue = m_symbol.TickValue() * g_p2p;
   double targetProfit = InpTrimBEPips * pipValue * lots;
   
   if(profit >= targetProfit) {
      int count = CountPositions(0, true);
      CloseBasket(true);
      g_cycleProfit += profit;
      
      double realPips = (lots > 0 && pipValue > 0) ? profit / (lots * pipValue) : 0;
      
      PrintFormat("BE TRIM: %.1f pips (%.2f USD) | L%d | %d pos %.2f lot | Total: +%.2f",
         realPips, profit, g_trimDcaLevel, count, lots, g_cycleProfit);
      g_trimActive = false; g_trimDirection = 0; g_trimDcaLevel = 0; g_lastTrimTime = 0;
      return true;
   }
   return false;
}
