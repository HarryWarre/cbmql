//+------------------------------------------------------------------+
//| PropFirm.mqh - PropFirm Compliance Guards                        |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

double GetPropFirmSL(int dir, double entryPrice) {
   if(!InpPropFirmMode) return 0;
   double slDist = InpFakeSLPips * g_point * g_p2p;
   double sl = 0;
   if(dir == 1)  sl = entryPrice - slDist;
   if(dir == -1) sl = entryPrice + slDist;
   return NormalizeDouble(sl, (int)m_symbol.Digits());
}

bool ManagePropFirmLimits() {
   if(!InpPropFirmMode) return false;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   // 1. Kiểm tra lỗ trong ngày
   double dailyLoss = g_dayStartBalance - equity;
   double dailyLimit = g_dayStartBalance * InpDailyLossPct / 100.0;
   if(dailyLoss >= dailyLimit) {
      if(!g_propFirmLocked) {
         PrintFormat("PROPFIRM: Daily loss %.2f USD exceeds %.1f%% (%.2f USD). Closing all!",
            dailyLoss, InpDailyLossPct, dailyLimit);
         CloseAllPositions();
         g_direction = 0; g_dcaLevel = 0; g_lastDCATime = 0; g_lastPyramidTime = 0;
         g_trimActive = false; g_trimDirection = 0; g_trimDcaLevel = 0; g_lastTrimTime = 0;
         g_propFirmLocked = true;
      }
      return true;
   }

   // 2. Kiểm tra Max Drawdown từ số dư ban đầu
   double totalLoss = g_initialBalance - equity;
   double ddLimit = g_initialBalance * InpMaxDrawdownPct / 100.0;
   if(totalLoss >= ddLimit) {
      if(!g_propFirmLocked) {
         PrintFormat("PROPFIRM: Drawdown %.2f USD exceeds %.1f%% (%.2f USD). Closing all!",
            totalLoss, InpMaxDrawdownPct, ddLimit);
         CloseAllPositions();
         g_direction = 0; g_dcaLevel = 0; g_lastDCATime = 0; g_lastPyramidTime = 0;
         g_trimActive = false; g_trimDirection = 0; g_trimDcaLevel = 0; g_lastTrimTime = 0;
         g_propFirmLocked = true;
      }
      return true;
   }

   return false;
}
