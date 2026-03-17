//+------------------------------------------------------------------+
//| DCALogic.mqh - Core DCA Strategy Orchestration                   |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

void ManageDCA() {
   int posCount = CountPositions(0, false);

   // Auto-reset nếu MT5 đã tự động đóng hết lệnh chính (VD: hit TP)
   if(posCount == 0 && g_direction != 0) {
      g_direction = 0; g_dcaLevel = 0; g_lastDCATime = 0; g_lastPyramidTime = 0;
      Print("State MAIN reset: no open positions.");
   }

   // STEP 0: HÒA VỐN - Ưu tiên cao nhất
   if(posCount > 0 && ManageBreakeven()) return;

   // STEP 1: GỘP TP
   if(posCount > 0) UpdateMergedTP(false);
   if(CountPositions(0, true) > 0) UpdateMergedTP(true);

   posCount = CountPositions(0, false);
   if(posCount == 0 && g_direction != 0) {
      g_direction = 0; g_dcaLevel = 0; g_lastDCATime = 0; g_lastPyramidTime = 0;
   }

   // STEP 1.5: TỈA LỆNH
   if(posCount > 0) ManageTrim();

   // STEP 1.8: PYRAMID DCA
   if(posCount > 0) ManagePyramidDCA();

   // Session / Spread guard (chỉ ảnh hưởng Entry & DCA mới)
   if(!m_session.CanTrade()) return;
   if((int)m_symbol.Spread() > InpMaxSpread) return;

   S_IchiData d0, d1;
   if(!m_ichiBase.Get(0, d0) || !m_ichiBase.Get(1, d1)) return;

   double price = iClose(_Symbol, InpBaseTF, 1);
   double ask = m_symbol.Ask();
   double bid = m_symbol.Bid();

   // STEP 2: ENTRY - Mở lệnh đầu tiên khi Sanyaku xác nhận
   if(posCount == 0) {
      if(IsKijunFlat(m_ichiBase, InpKijunFlatBars)) return;
      if(m_session.IsNewsTime()) return;

      // Filter High Timeframe Cloud
      if(InpFilterHighKumo && InpMTFMode == MTF_TRIPLE) {
         S_IchiData dHigh;
         if(m_ichiHigh.Get(0, dHigh)) {
            double kumoTopH = MathMax(dHigh.ssa, dHigh.ssb);
            double kumoBotH = MathMin(dHigh.ssa, dHigh.ssb);
            double priceH = iClose(_Symbol, InpHighTF, 1);
            if(priceH >= kumoBotH && priceH <= kumoTopH) return;
         }
      }

      int sanyaku = SanyakuState(m_ichiBase, price, InpBaseTF);

      bool rsiAllowBuy = true;
      bool rsiAllowSell = true;
      if(InpEnableRSIFilter && m_rsiHandle != INVALID_HANDLE) {
         double rsiVal[1];
         if(CopyBuffer(m_rsiHandle, 0, 1, 1, rsiVal) > 0) {
            if(rsiVal[0] > InpRSIOverbought) rsiAllowBuy = false;
            if(rsiVal[0] < InpRSIOversold) rsiAllowSell = false;
         }
      }

      if(sanyaku == 1 && rsiAllowBuy) {
         double entryTPpips = (ArraySize(g_dcaTP) > 0) ? g_dcaTP[0] : 10;
         double vol = AdjustLots(InpEntryLot);
         double entryTP = ask + entryTPpips * g_point * g_p2p;
         if(m_trade.Buy(vol, _Symbol, ask, GetPropFirmSL(1, ask), entryTP, "PX ENTRY BUY")) {
            g_direction = 1; g_dcaLevel = 0; g_lastDCATime = TimeCurrent(); g_lastPyramidTime = TimeCurrent();
            PrintFormat("ENTRY BUY: %.3f lot @ %.5f | TP: %.5f (%.0f pips)", vol, ask, entryTP, entryTPpips);
         }
      }
      else if(sanyaku == -1 && rsiAllowSell) {
         double entryTPpips = (ArraySize(g_dcaTP) > 0) ? g_dcaTP[0] : 10;
         double vol = AdjustLots(InpEntryLot);
         double entryTP = bid - entryTPpips * g_point * g_p2p;
         if(m_trade.Sell(vol, _Symbol, bid, GetPropFirmSL(-1, bid), entryTP, "PX ENTRY SELL")) {
            g_direction = -1; g_dcaLevel = 0; g_lastDCATime = TimeCurrent(); g_lastPyramidTime = TimeCurrent();
            PrintFormat("ENTRY SELL: %.3f lot @ %.5f | TP: %.5f (%.0f pips)", vol, bid, entryTP, entryTPpips);
         }
      }
      return;
   }

   // STEP 3: DCA THEO CẢN TĨNH LỊCH SỬ
   long periodSec = PeriodSeconds(InpBaseTF);
   if(periodSec > 0 && (TimeCurrent() - g_lastDCATime) < InpDCACooldownBars * periodSec) return;

   // HEDGE DCA CONSTRAINT
   if(InpEnableHedgeMode && g_trimActive && CountPositions(0, true) > 0) {
      int sanyaku = SanyakuState(m_ichiBase, price, InpBaseTF);
      if(g_direction == 1 && sanyaku == -1) return;
      if(g_direction == -1 && sanyaku == 1) return;
   }

   double initPrice = GetInitialEntryPrice();
   if(initPrice <= 0) return;

   int tpSize = ArraySize(g_dcaTP);
   int stepSize = ArraySize(g_dcaStep);

   int nextLevel = g_dcaLevel;
   double tpPips = (tpSize > 0) ? g_dcaTP[MathMin(nextLevel, tpSize-1)] : 10;
   double currentStep = (stepSize > 0) ? g_dcaStep[MathMin(nextLevel, stepSize-1)] : InpMinDCAGap;

   double srLevels[];
   int numLevels = GetHistoricalSRLevels(m_ichiBase, initPrice, g_direction, srLevels, 50);

   double srLevel = 0;
   string srName = "";
   bool touched = false;
   double lastPrice = GetLastEntryPrice();

   if(nextLevel < numLevels) {
      srLevel = srLevels[nextLevel];
      srName  = "FLAT_SR" + IntegerToString(nextLevel+1);

      if(lastPrice > 0) {
         double gap = MathAbs(price - lastPrice) / (g_point * g_p2p);
         if(gap < InpMinDCAGap) return;
      }

      double prevPrice = iClose(_Symbol, InpBaseTF, 2);
      if(g_direction == 1) {
         touched = (price <= srLevel && prevPrice > srLevel);
      }
      if(g_direction == -1) {
         touched = (price >= srLevel && prevPrice < srLevel);
      }
   }
   else {
      srLevel = price;
      srName  = "GAP_L" + IntegerToString(nextLevel+1);

      if(lastPrice > 0) {
         double gap = MathAbs(price - lastPrice) / (g_point * g_p2p);
         if(gap >= InpMinDCAGap * 2.0) {
            if(g_direction == 1 && price < lastPrice) touched = true;
            if(g_direction == -1 && price > lastPrice) touched = true;
         }
      }
   }

   if(!touched) return;

   int mainCount = CountPositions(0, false);
   int trimCount = CountPositions(0, true);
   if(InpHedgeMergeVolume && mainCount > 0 && trimCount > 0 && ArraySize(g_trimDcaTP) > 0) {
      tpPips = g_trimDcaTP[0];
   }

   double tpDist = tpPips * g_point * g_p2p;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   double recoveryLot = CalculateRecoveryLot(false, srLevel, tpPips);

   bool forceRecovery = false;
   if(InpEnableHedgeMode && (InpEnableTrimTotalBE || InpHedgeMergeVolume) && g_trimActive) {
      int totalPos = CountPositions(0, false) + CountPositions(0, true);
      int forceThreshold = InpHedgeMergeVolume ? InpTrimBEAfterDCA : InpBEAfterDCA;
      if(totalPos >= forceThreshold) forceRecovery = true;
   }

   double pipValue = m_symbol.TickValue() * g_p2p;

   double minLot = InpEntryLot;
   if(forceRecovery) minLot = recoveryLot;
   if(minLot < m_symbol.LotsMin()) minLot = m_symbol.LotsMin();

   double maxRiskLot = m_symbol.LotsMax();
   if(pipValue > 0 && InpDCARiskPct < 999) {
      maxRiskLot = (equity * InpDCARiskPct / 100.0) / (tpPips * pipValue);
   }
   if(maxRiskLot < m_symbol.LotsMin()) maxRiskLot = m_symbol.LotsMin();

   double dcaLot = AdjustLots(MathMin(MathMax(recoveryLot, minLot), maxRiskLot));

   bool ok = false;
   string comment = "PX DCA" + IntegerToString(nextLevel+1);
   if(g_direction == 1) {
      double tp = (tpPips > 0) ? ask + tpDist : 0;
      ok = m_trade.Buy(dcaLot, _Symbol, ask, GetPropFirmSL(1, ask), tp, comment);
   } else if(g_direction == -1) {
      double tp = (tpPips > 0) ? bid - tpDist : 0;
      ok = m_trade.Sell(dcaLot, _Symbol, bid, GetPropFirmSL(-1, bid), tp, comment);
   }

   if(ok) {
      g_dcaLevel = nextLevel + 1;
      g_lastDCATime = TimeCurrent();
      double newAvg = GetAvgPrice();

      double sharedTP = 0;
      if(tpPips > 0) {
         if(g_direction == 1) sharedTP = newAvg + tpDist;
         else if(g_direction == -1) sharedTP = newAvg - tpDist;

         for(int i = 0; i < PositionsTotal(); i++) {
            ulong tk = PositionGetTicket(i);
            if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
               if(StringFind(PositionGetString(POSITION_COMMENT), "TRIM") >= 0) continue;
               double sl = PositionGetDouble(POSITION_SL);
               double tp = PositionGetDouble(POSITION_TP);
               if(MathAbs(tp - sharedTP) > 0.00001) {
                  m_trade.PositionModify(tk, sl, sharedTP);
               }
            }
         }
      }

      string dir = (g_direction==1) ? "BUY" : "SELL";
      PrintFormat("DCA %s L%d [%s]: %.3f lot @ %.5f | SR: %.5f | TP: %.5f (%.0f pips) | Avg: %.5f | %d pos",
         dir, g_dcaLevel, srName, dcaLot, (g_direction==1)?ask:bid,
         srLevel, sharedTP, tpPips, newAvg, CountPositions());
   }
}
