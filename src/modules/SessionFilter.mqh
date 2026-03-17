//+------------------------------------------------------------------+
//| SessionFilter.mqh - Session & Time Management                    |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

class C_Session {
private:
   int ParseHour(string s, bool start) {
      string parts[];
      if(StringSplit(s, '-', parts) == 2) {
         string hm[];
         if(StringSplit(start ? parts[0] : parts[1], ':', hm) == 2)
            return (int)StringToInteger(hm[0]);
      }
      return 0;
   }
public:
   bool CanTrade() {
      if(!InpUseTimeFilter) return true;
      MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
      if(InpCloseOnFriday && dt.day_of_week == 5 && dt.hour >= InpFridayCloseHour) return false;

      bool ok = false;
      if(dt.hour >= ParseHour(InpTokyo,true) && dt.hour < ParseHour(InpTokyo,false)) ok = true;
      if(dt.hour >= ParseHour(InpLondon,true) && dt.hour < ParseHour(InpLondon,false)) ok = true;
      if(dt.hour >= ParseHour(InpNewYork,true) && dt.hour < ParseHour(InpNewYork,false)) ok = true;
      return ok;
   }

   bool IsFridayClose() {
      if(!InpCloseOnFriday) return false;
      MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
      return (dt.day_of_week == 5 && dt.hour >= InpFridayCloseHour);
   }

   bool IsNewsTime() {
      if(!InpUseNewsFilter) return false;
      datetime now = TimeCurrent();
      MqlCalendarValue v[];
      if(!CalendarValueHistory(v, now - InpNewsMinutes*60, now + InpNewsMinutes*60)) return false;
      string b = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
      string q = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
      if(b == "") { b = StringSubstr(_Symbol, 0, 3); q = StringSubstr(_Symbol, 3, 3); }
      for(int i = 0; i < ArraySize(v); i++) {
         MqlCalendarEvent e; MqlCalendarCountry c;
         if(CalendarEventById(v[i].event_id, e) && CalendarCountryById(e.country_id, c))
            if(e.importance == CALENDAR_IMPORTANCE_HIGH && (c.currency == b || c.currency == q))
               return true;
      }
      return false;
   }
};

C_Session m_session;

// Friday Close: Đóng sạch trước weekend
void ManageFridayClose() {
   if(!m_session.IsFridayClose()) return;
   int c = CountPositions();
   if(c > 0) {
      double profit = GetBasketProfit();
      CloseAllPositions();
      if(profit > 0) { g_cycleWins++; g_cycleProfit += profit; }
      PrintFormat("FRIDAY CLOSE: %d pos | P/L: %.2f USD | Cycles: %d | Total: +%.2f",
         c, profit, g_cycleWins, g_cycleProfit);
      g_direction = 0; g_dcaLevel = 0; g_lastDCATime = 0; g_lastPyramidTime = 0;
   }
}
