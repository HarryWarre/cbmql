//+------------------------------------------------------------------+
//| HighTFReversal.mqh - High TF Ichimoku Reversal Guard             |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

void ManageHighTFReversal() {
   if(!InpCloseOnHighTFReversal) return;
   if(g_direction == 0 && !g_trimActive) return;

   double price = m_symbol.Bid();
   ENUM_ICHI_STATE highState = GetMarketState(m_ichiHigh, price, InpHighTF);

   bool reverse = false;
   int currentDir = (g_direction != 0) ? g_direction : g_trimDirection;

   if(currentDir == 1 && (highState == ICHI_STRONG_DOWN || highState == ICHI_WEAK_DOWN)) {
      reverse = true;
   } else if(currentDir == -1 && (highState == ICHI_STRONG_UP || highState == ICHI_WEAK_UP)) {
      reverse = true;
   }

   if(reverse) {
      double profit = GetBasketProfit(false) + GetBasketProfit(true);
      PrintFormat("HIGH TF REVERSAL (State: %d) -> Closing all! Profit: %.2f", highState, profit);
      CloseAllPositions();
      g_cycleProfit += profit;
      g_direction = 0; g_dcaLevel = 0; g_lastDCATime = 0; g_lastPyramidTime = 0;
      g_trimActive = false; g_trimDirection = 0; g_trimDcaLevel = 0; g_lastTrimTime = 0;
   }
}
