//+------------------------------------------------------------------+
//| PositionUtils.mqh - Position Tracking Helpers                    |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

int CountPositions(int dir=0, bool isTrim=false) {
   int c = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      bool isTrimPos = (StringFind(PositionGetString(POSITION_COMMENT), "TRIM") >= 0);
      if(isTrimPos != isTrim) continue;

      if(dir==0) { c++; continue; }
      if(dir==1 && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) c++;
      if(dir==-1 && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) c++;
   }
   return c;
}

double GetBasketProfit(bool isTrim=false) {
   double total = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      bool isTrimPos = (StringFind(PositionGetString(POSITION_COMMENT), "TRIM") >= 0);
      if(isTrimPos != isTrim) continue;

      total += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + PositionGetDouble(POSITION_COMMISSION);
   }
   return total;
}

double GetTotalLots(bool isTrim=false) {
   double total = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      bool isTrimPos = (StringFind(PositionGetString(POSITION_COMMENT), "TRIM") >= 0);
      if(isTrimPos != isTrim) continue;

      total += PositionGetDouble(POSITION_VOLUME);
   }
   return total;
}

double GetLastEntryPrice(bool isTrim=false) {
   double p = 0; datetime t = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      bool isTrimPos = (StringFind(PositionGetString(POSITION_COMMENT), "TRIM") >= 0);
      if(isTrimPos != isTrim) continue;

      datetime tt = (datetime)PositionGetInteger(POSITION_TIME);
      if(tt > t) { t = tt; p = PositionGetDouble(POSITION_PRICE_OPEN); }
   }
   return p;
}

double GetExtremeEntryPrice(bool isTrim=false) {
   double extreme = 0;
   int dir = isTrim ? g_trimDirection : g_direction;
   for(int i=0; i<PositionsTotal(); i++) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      bool isTrimPos = (StringFind(PositionGetString(POSITION_COMMENT), "TRIM") >= 0);
      if(isTrimPos != isTrim) continue;

      double p = PositionGetDouble(POSITION_PRICE_OPEN);
      if(extreme == 0) { extreme = p; continue; }

      if(dir == 1 && p > extreme) extreme = p;
      if(dir == -1 && p < extreme) extreme = p;
   }
   return extreme;
}

// Giá trung bình gia quyền (weighted average price)
double GetAvgPrice(bool isTrim=false) {
   double totalCost = 0, totalVol = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      bool isTrimPos = (StringFind(PositionGetString(POSITION_COMMENT), "TRIM") >= 0);
      if(isTrimPos != isTrim) continue;

      double v = PositionGetDouble(POSITION_VOLUME);
      double p = PositionGetDouble(POSITION_PRICE_OPEN);
      totalCost += p * v;
      totalVol  += v;
   }
   return (totalVol > 0) ? totalCost / totalVol : 0;
}

// Lấy giá Entry ban đầu của rổ
double GetInitialEntryPrice(bool isTrim=false) {
   for(int i=0; i<PositionsTotal(); i++) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC)==InpMagicNumber && PositionGetString(POSITION_SYMBOL)==_Symbol) {
         string comment = PositionGetString(POSITION_COMMENT);
         bool isTrimPos = (StringFind(comment, "TRIM") >= 0);
         if(isTrimPos != isTrim) continue;

         if(StringFind(comment, isTrim ? "TRIM ENTRY" : "ENTRY") >= 0) {
            return PositionGetDouble(POSITION_PRICE_OPEN);
         }
      }
   }
   return GetAvgPrice(isTrim); // Fallback
}

void CloseBasket(bool isTrim) {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC)==InpMagicNumber && PositionGetString(POSITION_SYMBOL)==_Symbol) {
         bool isTrimPos = (StringFind(PositionGetString(POSITION_COMMENT), "TRIM") >= 0);
         if(isTrimPos == isTrim) m_trade.PositionClose(tk);
      }
   }
}

void CloseAllPositions() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC)==InpMagicNumber && PositionGetString(POSITION_SYMBOL)==_Symbol)
         m_trade.PositionClose(tk);
   }
}

double AdjustLots(double vol) {
   double mn = m_symbol.LotsMin(), mx = m_symbol.LotsMax(), st = m_symbol.LotsStep();
   vol = MathMax(mn, MathMin(mx, vol));
   return MathRound(vol / st) * st;
}

// Tìm ticket của lệnh đang lỗ nặng nhất
ulong GetWorstPositionTicket(double &outLoss) {
   ulong worstTicket = 0;
   outLoss = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      ulong tk = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      
      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + PositionGetDouble(POSITION_COMMISSION);
      if(profit < outLoss) {
         outLoss = profit;
         worstTicket = tk;
      }
   }
   return worstTicket;
}
