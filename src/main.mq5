//+------------------------------------------------------------------+
//|                                                   Phoenix_V3.mq5 |
//|               Phoenix V3 - Ichimoku Trend DCA Bot                |
//|                     Copyright 2026, DaiViet                      |
//|                                                                  |
//| Chiến lược: DCA tại các mức Ichimoku (Tenkan/Kijun/Kumo)        |
//| Entry: Sanyaku Kouten/Gyakuten (Ch.3)                            |
//| DCA: Pullback tới các mức Han-ne (Ch.4-6, 10-12)                |
//| Exit: Basket TP - Chốt sạch khi tổng lãi >= Target              |
//| Triết lý: "Luôn tuyến tính dương" - mỗi chu kỳ đều profit.     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, DaiViet"
#property version     "3.00"
#property strict
#property description "Ichimoku Trend DCA - Based on 15 Chapters of Hosoda Theory"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>

// @import "./modules/Defines.mqh"
// @import "./modules/Inputs.mqh"
// @import "./modules/GlobalVars.mqh"
// @import "./modules/Ichimoku.mqh"
// @import "./modules/Sakata.mqh"
// @import "./modules/SessionFilter.mqh"
// @import "./modules/GUI.mqh"
// @import "./modules/Scoring.mqh"
// @import "./modules/PositionUtils.mqh"
// @import "./modules/LotCalc.mqh"
// @import "./modules/PropFirm.mqh"
// @import "./modules/Breakeven.mqh"
// @import "./modules/MergedTP.mqh"
// @import "./modules/TrimHedge.mqh"
// @import "./modules/Pyramid.mqh"
// @import "./modules/HighTFReversal.mqh"
// @import "./modules/DCALogic.mqh"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   Print("=== PHOENIX V3: Ichimoku Trend DCA ===");

   m_trade.SetExpertMagicNumber(InpMagicNumber);
   if(!m_symbol.Name(_Symbol)) return INIT_FAILED;
   m_symbol.RefreshRates();

   g_point = m_symbol.Point();
   g_p2p = (m_symbol.Digits() == 3 || m_symbol.Digits() == 5) ? 10.0 : 1.0;

   // Parse DCA arrays
   int nTP = ParseDoubleList(InpDCATPs, g_dcaTP);
   int nStep = ParseDoubleList(InpDCASteps, g_dcaStep);
   int nTrimTP = ParseDoubleList(InpTrimDCATPs, g_trimDcaTP);
   int nTrimStep = ParseDoubleList(InpTrimDCASteps, g_trimDcaStep);

   Print("DCA Config MAIN: UNLIMITED (Ichimoku S/R + Gap) | Dynamic Lot");
   string lvlName[4] = {"Tenkan","Kijun","KumoTop","KumoBot"};
   for(int i=0; i<nTP; i++) {
      double sVal = (i < nStep) ? g_dcaStep[i] : InpMinDCAGap;
      PrintFormat("  L%d%s: TP %g pips, Step %g pips",
         i+1, (i<4)?" ["+lvlName[i]+"]":" [GAP]", g_dcaTP[i], sVal);
   }
   if(nTP > 0) {
      double lastStep = (nStep > 0) ? g_dcaStep[nStep-1] : InpMinDCAGap;
      PrintFormat("  L%d+: TP %g pips, Step %g pips (last value)", nTP+1, g_dcaTP[nTP-1], lastStep);
   }

   Print("DCA Config TRIM: UNLIMITED (Z-Score Entry + Reverse Ichimoku S/R)");
   for(int i=0; i<nTrimTP; i++) {
      double sVal = (i < nTrimStep) ? g_trimDcaStep[i] : InpMinDCAGap;
      PrintFormat("  TRIM L%d: TP %g pips, Step %g pips", i+1, g_trimDcaTP[i], sVal);
   }
   if(nTrimTP > 0) {
      double lastStep = (nTrimStep > 0) ? g_trimDcaStep[nTrimStep-1] : InpMinDCAGap;
      PrintFormat("  TRIM L%d+: TP %g pips, Step %g pips (last value)", nTrimTP+1, g_trimDcaTP[nTrimTP-1], lastStep);
   }

   Print("Entry: ", InpEntryLot, " lot | DCA cap: ", InpDCARiskPct, "% eq | MinGap: ", InpMinDCAGap, " pips");

   if(!m_ichiBase.Init(_Symbol, InpBaseTF, InpTenkanPeriod, InpKijunPeriod, InpSenkouPeriod))
      return INIT_FAILED;

   m_rsiHandle = iRSI(_Symbol, InpRSITimeframe, InpRSIPeriod, PRICE_CLOSE);
   if(m_rsiHandle == INVALID_HANDLE) {
      Print("Failed to create RSI handle!");
      return INIT_FAILED;
   }

   if(InpMTFMode == MTF_TRIPLE) {
      if(!m_ichiMid.Init(_Symbol, InpMidTF, InpTenkanPeriod, InpKijunPeriod, InpSenkouPeriod)) return INIT_FAILED;
      if(!m_ichiHigh.Init(_Symbol, InpHighTF, InpTenkanPeriod, InpKijunPeriod, InpSenkouPeriod)) return INIT_FAILED;
   }

   m_gui.Init();

   // PropFirm init
   g_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_dayStartBalance = g_initialBalance;
   MqlDateTime dtInit; TimeToStruct(TimeCurrent(), dtInit);
   g_lastDay = dtInit.day;
   g_propFirmLocked = false;

   Print("PHOENIX V3 Ready.");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(m_rsiHandle != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
   ObjectsDeleteAll(0, "PX3_");
   PrintFormat("PHOENIX V3 Stopped. Cycles: %d | Total Profit: +%.2f USD", g_cycleWins, g_cycleProfit);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   // New bar check
   datetime curBar = iTime(_Symbol, InpBaseTF, 0);
   bool newBar = (curBar != g_lastBar);
   if(newBar) g_lastBar = curBar;

   if(InpExecSpeed == EXEC_BAR_CLOSE && !newBar) return;

   m_symbol.RefreshRates();

   // Update analysis
   g_ichiState = GetMarketState(m_ichiBase, m_symbol.Bid(), InpBaseTF);
   UpdateMatrixScore();

   // PropFirm daily/drawdown guard
   if(InpPropFirmMode) {
      MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
      if(dt.day != g_lastDay) {
         g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         g_lastDay = dt.day;
         g_propFirmLocked = false;
      }
      if(ManagePropFirmLimits()) return;
   }

   // Core strategy
   ManageHighTFReversal();
   ManagePyramidTrailing();
   ManageDCA();
   ManageFridayClose();

   // GUI
   m_gui.Update();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {}

//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade() {}

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   return AccountInfoDouble(ACCOUNT_EQUITY) - AccountInfoDouble(ACCOUNT_BALANCE);
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {}
