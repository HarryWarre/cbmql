//+------------------------------------------------------------------+
//| GUI.mqh - Dashboard Rendering                                    |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

class C_GUI {
private:
   string px;

   void Rect(string n, int x, int y, int w, int h, color bg, color border) {
      ObjectCreate(0,n,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,n,OBJPROP_XSIZE,w); ObjectSetInteger(0,n,OBJPROP_YSIZE,h);
      ObjectSetInteger(0,n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,border);
   }

   void Label(string n, string text, int x, int y, color c, int sz) {
      ObjectCreate(0,n,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,n,OBJPROP_COLOR,c); ObjectSetInteger(0,n,OBJPROP_FONTSIZE,sz);
      ObjectSetString(0,n,OBJPROP_FONT,"Consolas"); ObjectSetString(0,n,OBJPROP_TEXT,text);
   }

public:
   C_GUI() { px = "PX3_"; }

   void Init() {
      if(!InpShowGUI) return;
      Rect(px+"BG1", 20, 40, 380, 300, InpGUIBG, C'255,150,0');
      Label(px+"T1", "PHOENIX V3: TREND DCA", 30, 50, C'255,150,0', 10);
      for(int i=0;i<7;i++) Label(px+"L"+IntegerToString(i), "", 30, 82+i*18, InpGUIText, 7);

      Rect(px+"BG2", 410, 40, 480, 300, InpGUIBG, C'0,200,100');
      Label(px+"T2", "DCA STATUS", 420, 50, C'0,200,100', 10);
      for(int i=0;i<7;i++) Label(px+"R"+IntegerToString(i), "", 420, 82+i*18, InpGUIText, 7);
   }

   void Update() {
      if(!InpShowGUI) return;

      string st;
      switch(g_ichiState) {
         case ICHI_STRONG_UP:   st="STRONG UP";   break;
         case ICHI_WEAK_UP:     st="WEAK UP";     break;
         case ICHI_STRONG_DOWN: st="STRONG DOWN"; break;
         case ICHI_WEAK_DOWN:   st="WEAK DOWN";   break;
         default:               st="RANGE";       break;
      }

      ObjectSetString(0,px+"L0",OBJPROP_TEXT,"State : "+st);
      ObjectSetString(0,px+"L1",OBJPROP_TEXT,"Score : "+IntegerToString(g_scoreNet)+" / 1000");
      ObjectSetString(0,px+"L2",OBJPROP_TEXT,"BUY   : +"+IntegerToString(g_scoreBuy));
      ObjectSetString(0,px+"L3",OBJPROP_TEXT,"SELL  : "+IntegerToString(g_scoreSell));
      ObjectSetString(0,px+"L4",OBJPROP_TEXT,"Sakata: "+IntegerToString(m_sakata.Detect(InpBaseTF)));

      double bal=AccountInfoDouble(ACCOUNT_BALANCE), eq=AccountInfoDouble(ACCOUNT_EQUITY);
      double dd = (bal>0) ? (bal-eq)/bal*100 : 0;
      ObjectSetString(0,px+"L5",OBJPROP_TEXT,"DD    : "+DoubleToString(dd,1)+"%");
      ObjectSetString(0,px+"L6",OBJPROP_TEXT,"Equity: "+DoubleToString(eq,2));

      // DCA Panel
      string dir = (g_direction==1)?"BUY":(g_direction==-1)?"SELL":"---";
      ObjectSetString(0,px+"R0",OBJPROP_TEXT,"Dir   : "+dir+" | DCA L"+IntegerToString(g_dcaLevel)+" (no limit)");
      ObjectSetString(0,px+"R1",OBJPROP_TEXT,"Pos   : "+IntegerToString(CountPositions())+" | Lots: "+DoubleToString(GetTotalLots(),2));
      ObjectSetString(0,px+"R2",OBJPROP_TEXT,"P/L   : "+DoubleToString(GetBasketProfit(),2)+" USD | Avg: "+DoubleToString(GetAvgPrice(),5));
      ObjectSetString(0,px+"R3",OBJPROP_TEXT,"BE: "+(InpEnableBE?"ON":"OFF")+" | Trim: "+(g_trimActive?"ACT":"---")+" | MTP "+IntegerToString(InpMergedTPLevel)+"/"+IntegerToString(InpTrimMTPLevel));
      ObjectSetString(0,px+"R4",OBJPROP_TEXT,"Lot   : Entry "+DoubleToString(InpEntryLot,2)+" | DCA max "+DoubleToString(InpDCARiskPct,1)+"%");
      ObjectSetString(0,px+"R5",OBJPROP_TEXT,"Wins  : "+IntegerToString(g_cycleWins)+" | +"+DoubleToString(g_cycleProfit,1)+" USD");
      ObjectSetString(0,px+"R6",OBJPROP_TEXT,"Wins  : "+IntegerToString(g_cycleWins)+" | +"+DoubleToString(g_cycleProfit,1)+" USD");

      ChartRedraw(0);
   }
};

C_GUI m_gui;
