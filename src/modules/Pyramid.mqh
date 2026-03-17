//+------------------------------------------------------------------+
//| Pyramid.mqh - Pyramid DCA (Trend-Following Volume Addition)      |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

void ManagePyramidDCA() {
   if(!InpEnablePyramid) return;
   if(g_direction == 0) return;
   if(g_dcaLevel < 1) return;

   // Không Pyramid khi đang có lệnh TRIM/HEDGE
   if(CountPositions(0, true) > 0) return;

   long periodSec = PeriodSeconds(InpBaseTF);
   if(periodSec > 0 && (TimeCurrent() - g_lastPyramidTime) < InpDCACooldownBars * periodSec) return;

   double lastPrice = GetExtremeEntryPrice(false);
   double ask = m_symbol.Ask();
   double bid = m_symbol.Bid();
   double price = (g_direction == 1) ? ask : bid;

   if(g_direction == 1 && price <= lastPrice) return;
   if(g_direction == -1 && price >= lastPrice) return;

   double initPrice = GetInitialEntryPrice(false);
   if(initPrice <= 0) return;

   double srLevels[];
   int numLevels = GetHistoricalSRLevels(m_ichiBase, initPrice, -g_direction, srLevels, 50);

   bool touched = false;
   double srLevel = 0;
   string srName = "";

   for(int i = 0; i < numLevels; i++) {
      double lvl = srLevels[i];
      if(g_direction == 1 && lvl <= lastPrice) continue;
      if(g_direction == -1 && lvl >= lastPrice) continue;

      double gap = MathAbs(lvl - lastPrice) / (g_point * g_p2p);
      if(gap < InpMinPyramidGap) continue;

      if(g_direction == 1 && price >= lvl) {
         touched = true; srLevel = lvl; srName = "PYR_SR" + IntegerToString(i+1);
      }
      if(g_direction == -1 && price <= lvl) {
         touched = true; srLevel = lvl; srName = "PYR_SR" + IntegerToString(i+1);
      }
      break;
   }

   if(!touched) {
      double gap = MathAbs(price - lastPrice) / (g_point * g_p2p);
      if(gap >= InpMinPyramidGap) {
         if(g_direction == 1 && price > lastPrice) {
            touched = true; srLevel = price; srName = "PYR_GAP";
         }
         if(g_direction == -1 && price < lastPrice) {
            touched = true; srLevel = price; srName = "PYR_GAP";
         }
      }
   }

   if(touched) {
      double vol = AdjustLots(InpEntryLot);
      double tpPips = (ArraySize(g_dcaTP) > 0) ? g_dcaTP[0] : 10;
      double tpDist = tpPips * g_point * g_p2p;
      string comment = "PX PYRAMID " + ((g_direction==1)?"BUY":"SELL");

      double sharedTP = (g_direction == 1) ? ask + tpDist : bid - tpDist;

      bool ok = false;
      if(g_direction == 1) ok = m_trade.Buy(vol, _Symbol, ask, GetPropFirmSL(1, ask), sharedTP, comment);
      else ok = m_trade.Sell(vol, _Symbol, bid, GetPropFirmSL(-1, bid), sharedTP, comment);

      if(ok) {
         g_lastPyramidTime = TimeCurrent();
         for(int i=0; i<PositionsTotal(); i++) {
            ulong tk = PositionGetTicket(i);
            if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
               if(StringFind(PositionGetString(POSITION_COMMENT), "TRIM") < 0) {
                  double sl = PositionGetDouble(POSITION_SL);
                  double tp = PositionGetDouble(POSITION_TP);
                  if(MathAbs(tp - sharedTP) > 0.00001) {
                     m_trade.PositionModify(tk, sl, sharedTP);
                  }
               }
            }
         }
         PrintFormat("PYRAMID DCA [%s]: %.3f lot @ %.5f | Set TP: %.5f (%.0f pips L0)",
            (g_direction==1)?"BUY":"SELL", vol, price, sharedTP, tpPips);
      }
   }
}

void ManagePyramidTrailing() {
   if(!InpPyramidTrailingKijun || !InpEnablePyramid) return;
   if(!InpPropFirmMode) return;
   if(g_direction == 0) return;

   S_IchiData d;
   if(!m_ichiBase.Get(0, d)) return;
   double kijun = d.kijun;

   double minGap = MathMax(m_symbol.StopsLevel() * g_point, (m_symbol.Ask() - m_symbol.Bid()) * 2.0);

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         string comment = PositionGetString(POSITION_COMMENT);
         if(StringFind(comment, "PYRAMID") >= 0) {
            double sl = PositionGetDouble(POSITION_SL);
            double tp = PositionGetDouble(POSITION_TP);

            if(g_direction == 1) {
               if(kijun < m_symbol.Bid() - minGap) {
                  if(sl == 0.0 || kijun > sl) {
                     m_trade.PositionModify(tk, kijun, tp);
                  }
               }
            } else if(g_direction == -1) {
               if(kijun > m_symbol.Ask() + minGap) {
                  if(sl == 0.0 || kijun < sl) {
                     m_trade.PositionModify(tk, kijun, tp);
                  }
               }
            }
         }
      }
   }
}
