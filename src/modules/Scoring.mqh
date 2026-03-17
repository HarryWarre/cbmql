//+------------------------------------------------------------------+
//| Scoring.mqh - Matrix Scoring (Confirmation Layer)                |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//| Tổng hợp tất cả module Ichimoku thành điểm -1000 tới +1000     |
//+------------------------------------------------------------------+

void UpdateMatrixScore() {
   double price = m_symbol.Bid();
   S_IchiData d;
   if(!m_ichiBase.Get(0, d)) return;

   int bS = 0, sS = 0; // Buy/Sell scores

   // Han-ne Equilibrium (Ch.4-6): Giá vs Kijun
   if(price > d.kijun) bS += 200; else sS -= 200;

   // Overextended check (Ch.5)
   if(IsOverextended(m_ichiBase, price, 45)) {
      if(price > d.tenkan) bS -= 100; else sS += 100;
   }

   // Range punishment (Ch.8)
   if(IsKijunFlat(m_ichiBase, InpKijunFlatBars)) {
      bS /= 2; sS /= 2;
   }

   // Authentic Cross (Ch.7)
   int slope = KijunSlope(m_ichiBase);
   if(d.tenkan > d.kijun) {
      if(slope >= 0) bS += 250; else bS -= 125;
   } else if(d.tenkan < d.kijun) {
      if(slope <= 0) sS -= 250; else sS += 125;
   }

   // Chikou Momentum (Ch.14)
   double cMom = ChikouMomentum(m_ichiBase, InpBaseTF);
   if(cMom > 10.0) bS += 150; else if(cMom < -10.0) sS -= 150;

   // Kumo strength (Ch.12)
   double kThick = m_ichiBase.KumoThick(d);
   double kumoTop = MathMax(d.ssa, d.ssb);
   double kumoBot = MathMin(d.ssa, d.ssb);
   if(price > kumoTop && kThick >= InpMinKumoThick) bS += 300;
   else if(price < kumoBot && kThick >= InpMinKumoThick) sS -= 300;

   // MTF Alignment (Ch.15)
   if(InpMTFMode == MTF_TRIPLE) {
      S_IchiData mid, hgh;
      if(m_ichiMid.Get(0, mid) && m_ichiHigh.Get(0, hgh)) {
         if(price > mid.tenkan && price > hgh.tenkan) bS += 100;
         if(price < mid.tenkan && price < hgh.tenkan) sS -= 100;
      }
   }

   // Sakata Patterns
   int sakScore = m_sakata.Score(m_sakata.Detect(InpBaseTF));
   if(sakScore > 0) bS += sakScore; else sS += sakScore;

   g_scoreBuy  = MathMax(0, bS);
   g_scoreSell = MathMin(0, sS);
   g_scoreNet  = bS + sS;
}
