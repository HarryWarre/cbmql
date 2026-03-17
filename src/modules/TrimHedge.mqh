//+------------------------------------------------------------------+
//| TrimHedge.mqh - Trim/Hedge System (Z-Score + Sanyaku Reversal)  |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

void ManageTrim() {
   if(!InpEnableTrim && !InpEnableHedgeMode) return;

   // Auto-reset nếu lệnh tỉa đã đóng hết
   if(g_trimActive && CountPositions(0, true) == 0) {
      if(InpHedgeType != HEDGE_NONE) {
         CloseAllPositions();
         g_direction = 0; g_dcaLevel = 0; g_lastDCATime = 0; g_lastPyramidTime = 0;
         Print("HEDGE COMPLETED: Closing all positions (Main + Hedge)");
      }
      g_trimActive = false; g_trimDirection = 0; g_trimDcaLevel = 0; g_lastTrimTime = 0;
   }

   int trimCount = CountPositions(0, true);

   // Ưu tiên 1: Hòa vốn Trim
   if(trimCount > 0 && ManageTrimBreakeven()) return;

   double ask = m_symbol.Ask();
   double bid = m_symbol.Bid();

   int tpSize = ArraySize(g_trimDcaTP);
   double tpPips = (tpSize > 0) ? g_trimDcaTP[MathMin(g_trimDcaLevel, tpSize-1)] : 15;

   int mainCount = CountPositions(0, false);

   if(InpHedgeMergeVolume && mainCount > 0 && trimCount > 0 && tpSize > 0) {
      tpPips = g_trimDcaTP[0];
   }

   double tpDist = tpPips * g_point * g_p2p;

   if(!g_trimActive) {
      bool trigger = false;
      double z = 0;
      string triggerSource = "Z-SCORE";

      // 1. Kiểm tra Hedge Mode (Sanyaku Reversal)
      if(InpEnableHedgeMode) {
         if(!IsKijunFlat(m_ichiBase, InpKijunFlatBars) && !m_session.IsNewsTime()) {
            if(InpMTFMode == MTF_TRIPLE) {
               double priceH = iClose(_Symbol, InpHighTF, 1);
               int sanyakuH = SanyakuState(m_ichiHigh, priceH, InpHighTF);
               if(g_direction == 1 && sanyakuH == -1) {
                  g_trimDirection = -1; trigger = true; triggerSource = "HEDGE";
               } else if(g_direction == -1 && sanyakuH == 1) {
                  g_trimDirection = 1; trigger = true; triggerSource = "HEDGE";
               }
            } else {
               double priceB = iClose(_Symbol, InpBaseTF, 1);
               int sanyakuB = SanyakuState(m_ichiBase, priceB, InpBaseTF);
               if(g_direction == 1 && sanyakuB == -1) {
                  g_trimDirection = -1; trigger = true; triggerSource = "HEDGE";
               } else if(g_direction == -1 && sanyakuB == 1) {
                  g_trimDirection = 1; trigger = true; triggerSource = "HEDGE";
               }
            }
         }

         // Lọc mây HighTF
         if(trigger && InpHedgeWaitKumoBreak) {
            S_IchiData hd;
            if(m_ichiHigh.Get(0, hd)) {
               double kumoTop = m_ichiHigh.KumoTop(hd);
               double kumoBot = m_ichiHigh.KumoBottom(hd);
               double curPrice = m_symbol.Bid();
               if(curPrice >= kumoBot && curPrice <= kumoTop) {
                  trigger = false;
               }
            }
         }
      }

      // 2. Chế độ Z-Score
      if(!trigger && InpEnableTrim && g_dcaLevel >= InpTrimAfterDCA) {
         z = GetZScore(InpTrimZPeriod, InpBaseTF);
         if(g_direction == 1 && z >= InpTrimZThreshold) {
            g_trimDirection = -1; trigger = true;
         }
         else if(g_direction == -1 && z <= -InpTrimZThreshold) {
            g_trimDirection = 1; trigger = true;
         }
      }

      // Đảm bảo rổ chính đang LỖ
      if(trigger) {
         double mainAvg = GetAvgPrice(false);
         if(g_direction == 1 && ask >= mainAvg) trigger = false;
         if(g_direction == -1 && bid <= mainAvg) trigger = false;
      }

      if(trigger) {
         double price = (g_trimDirection == 1) ? ask : bid;
         double recoveryLot = CalculateRecoveryLot(true, price, tpPips);
         double initLot = AdjustLots(MathMax(recoveryLot, InpEntryLot));

         if(triggerSource == "HEDGE") {
            if(InpHedgeType == HEDGE_FULL_VOLUME) {
               double totalVolMain = GetTotalLots(false);
               initLot = AdjustLots(totalVolMain);
            }
            else if(InpHedgeType == HEDGE_AUTO_RECOVERY) {
               double vMain = GetTotalLots(false);
               double avgMain = GetAvgPrice(false);
               double tpDistLocal = tpPips * g_point * g_p2p;
               double tpPrice = (g_trimDirection == 1) ? ask + tpDistLocal : bid - tpDistLocal;

               double gapMain = MathAbs(avgMain - tpPrice);
               double distHedge = tpDistLocal;

               if(distHedge > 0) {
                  double recLot = (gapMain * vMain / (g_point * g_p2p) + InpTrimBEPips * vMain) / tpPips;
                  initLot = AdjustLots(recLot);
               }
            }
            if(initLot < InpEntryLot) initLot = InpEntryLot;
         }

         double tp = (g_trimDirection == 1) ? ask + tpDist : bid - tpDist;
         string comment = "PX TRIM ENTRY L1";

         bool ok = false;
         if(g_trimDirection == 1) ok = m_trade.Buy(initLot, _Symbol, ask, GetPropFirmSL(1, ask), tp, comment);
         else ok = m_trade.Sell(initLot, _Symbol, bid, GetPropFirmSL(-1, bid), tp, comment);

         if(ok) {
            g_trimActive = true; g_trimDcaLevel = 1; g_lastTrimTime = TimeCurrent();
            if(triggerSource == "HEDGE") {
               PrintFormat("HEDGE ENTRY [%s]: %.2f lot @ %.5f | TP: %.5f",
                  (g_trimDirection==1)?"BUY":"SELL", initLot, price, tp);
            } else {
               PrintFormat("TRIM ENTRY [%s]: %.2f lot @ %.5f | TP: %.5f (Z=%.2f)",
                  (g_trimDirection==1)?"BUY":"SELL", initLot, price, tp, z);
            }
         }
      }
   }
   else {
      // Đã có lệnh tỉa -> Tự DCA rổ tỉa
      long periodSec = PeriodSeconds(InpBaseTF);
      if(periodSec > 0 && (TimeCurrent() - g_lastTrimTime) < InpDCACooldownBars * periodSec) return;

      double price = iClose(_Symbol, InpBaseTF, 1);

      // HEDGE DCA CONSTRAINT
      if(InpEnableHedgeMode) {
         int sanyaku = SanyakuState(m_ichiBase, price, InpBaseTF);
         if(g_trimDirection == 1 && sanyaku == -1) return;
         if(g_trimDirection == -1 && sanyaku == 1) return;
      }

      double initPrice = GetInitialEntryPrice(true);
      if(initPrice <= 0) return;
      int nextLvl = g_trimDcaLevel;
      int tpSize = ArraySize(g_trimDcaTP);
      int stepSize = ArraySize(g_trimDcaStep);
      
      double tpPips = (tpSize > 0) ? g_trimDcaTP[MathMin(nextLvl, tpSize-1)] : 0;

      double srLevels[];
      int numLevels = GetHistoricalSRLevels(m_ichiBase, initPrice, g_trimDirection, srLevels, 20);

      
      double srLevel = 0; string srName = ""; bool touched = false;
      price = iClose(_Symbol, InpBaseTF, 1);
      double lastPrice = GetLastEntryPrice(true);

      if(nextLvl < numLevels) {
         srLevel = srLevels[nextLvl]; srName = "T_FLAT_SR" + IntegerToString(nextLvl+1);
         if(lastPrice > 0) {
            double gap = MathAbs(price - lastPrice) / (g_point * g_p2p);
            if(gap < InpMinDCAGap) return;
         }
         double prevPrice = iClose(_Symbol, InpBaseTF, 2);
         if(g_trimDirection == 1) touched = (price <= srLevel && prevPrice > srLevel);
         if(g_trimDirection == -1) touched = (price >= srLevel && prevPrice < srLevel);
      } else {
         srLevel = price; srName = "T_GAP_L" + IntegerToString(nextLvl+1);
         if(lastPrice > 0) {
            double gap = MathAbs(price - lastPrice) / (g_point * g_p2p);
            if(gap >= InpMinDCAGap * 2.0) {
               if(g_trimDirection == 1 && price < lastPrice) touched = true;
               if(g_trimDirection == -1 && price > lastPrice) touched = true;
            }
         }
      }

      if(!touched) return;

      double recoveryLot = CalculateRecoveryLot(true, srLevel, tpPips);

      bool forceRecovery = false;
      if(InpEnableHedgeMode && (InpEnableTrimTotalBE || InpHedgeMergeVolume)) {
         int totalPos = CountPositions(0, false) + CountPositions(0, true);
         int forceThreshold = InpHedgeMergeVolume ? InpTrimBEAfterDCA : InpBEAfterDCA;
         if(totalPos >= forceThreshold) forceRecovery = true;
      }

      double minLot = InpEntryLot;
      if(forceRecovery) minLot = recoveryLot;

      double dcaLot = AdjustLots(MathMax(recoveryLot, minLot));

      bool ok = false; string comment = "PX TRIM DCA" + IntegerToString(nextLvl+1);
      if(g_trimDirection == 1) {
         double tp = (tpPips > 0) ? ask + tpDist : 0;
         ok = m_trade.Buy(dcaLot, _Symbol, ask, GetPropFirmSL(1, ask), tp, comment);
      } else if(g_trimDirection == -1) {
         double tp = (tpPips > 0) ? bid - tpDist : 0;
         ok = m_trade.Sell(dcaLot, _Symbol, bid, GetPropFirmSL(-1, bid), tp, comment);
      }

      if(ok) {
         g_trimDcaLevel = nextLvl + 1; g_lastTrimTime = TimeCurrent();
         double newAvg = GetAvgPrice(true);
         double sharedTP = 0;

         if(tpPips > 0) {
            if(g_trimDirection == 1) sharedTP = newAvg + tpDist;
            else if(g_trimDirection == -1) sharedTP = newAvg - tpDist;

            for(int i = 0; i < PositionsTotal(); i++) {
               ulong tk = PositionGetTicket(i);
               if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
                  if(StringFind(PositionGetString(POSITION_COMMENT), "TRIM") >= 0) {
                     double sl = PositionGetDouble(POSITION_SL);
                     double tp = PositionGetDouble(POSITION_TP);
                     if(MathAbs(tp - sharedTP) > 0.00001) {
                        m_trade.PositionModify(tk, sl, sharedTP);
                     }
                  }
               }
            }
         }
         PrintFormat("TRIM DCA L%d [%s]: %.2f lot @ %.5f | TP: %.5f", g_trimDcaLevel, srName, dcaLot, (g_trimDirection==1)?ask:bid, sharedTP);
      }
   }
}
