//+------------------------------------------------------------------+
//| Sakata.mqh - Japanese Candle Pattern Detection (Ch.1 Extension)  |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

class C_Sakata {
private:
   double O[], H[], L[], C[];
   double Body(int i)    { return MathAbs(O[i]-C[i]); }
   double UShadow(int i) { return H[i] - MathMax(O[i],C[i]); }
   double LShadow(int i) { return MathMin(O[i],C[i]) - L[i]; }
   bool   Bull(int i)    { return C[i] > O[i]; }
   bool   Bear(int i)    { return C[i] < O[i]; }
public:
   C_Sakata() {
      ArrayResize(O,5); ArrayResize(H,5); ArrayResize(L,5); ArrayResize(C,5);
      ArraySetAsSeries(O,true); ArraySetAsSeries(H,true);
      ArraySetAsSeries(L,true); ArraySetAsSeries(C,true);
   }

   ENUM_SAKATA Detect(ENUM_TIMEFRAMES tf) {
      if(CopyOpen(_Symbol,tf,1,5,O)<5) return SAK_NONE;
      if(CopyHigh(_Symbol,tf,1,5,H)<5) return SAK_NONE;
      if(CopyLow(_Symbol,tf,1,5,L)<5)  return SAK_NONE;
      if(CopyClose(_Symbol,tf,1,5,C)<5) return SAK_NONE;

      double b0=Body(0), b1=Body(1), b2=Body(2);
      double avg = (b0+b1+b2)/3.0;

      if(b0 <= (H[0]-L[0])*0.05) return SAK_DOJI;
      if(Bull(0) && Bear(1) && C[0]>O[1] && O[0]<C[1]) return SAK_BULL_ENGULF;
      if(Bear(0) && Bull(1) && C[0]<O[1] && O[0]>C[1]) return SAK_BEAR_ENGULF;
      if(Bull(0) && b1<avg*0.3 && Bear(2) && b0>avg*1.5 && C[0]>(O[2]+C[2])/2) return SAK_MORNING;
      if(Bear(0) && b1<avg*0.3 && Bull(2) && b0>avg*1.5 && C[0]<(O[2]+C[2])/2) return SAK_EVENING;
      if(b0>0 && LShadow(0)>b0*2 && UShadow(0)<b0*0.2) return SAK_HAMMER;
      if(b0>0 && UShadow(0)>b0*2 && LShadow(0)<b0*0.2) return SAK_SHOOTING;
      if(Bull(0)&&Bull(1)&&Bull(2) && C[0]>H[1] && C[1]>H[2]) return SAK_3SOLDIERS;
      if(Bear(0)&&Bear(1)&&Bear(2) && C[0]<L[1] && C[1]<L[2]) return SAK_3CROWS;
      if(Bull(0) && b0>avg*2 && UShadow(0)<b0*0.05 && LShadow(0)<b0*0.05) return SAK_MARUBOZU_B;
      if(Bear(0) && b0>avg*2 && UShadow(0)<b0*0.05 && LShadow(0)<b0*0.05) return SAK_MARUBOZU_S;
      return SAK_NONE;
   }

   int Score(ENUM_SAKATA p) {
      switch(p) {
         case SAK_3SOLDIERS:   return 150;  case SAK_3CROWS:      return -150;
         case SAK_MORNING:     return 120;  case SAK_EVENING:     return -120;
         case SAK_BULL_ENGULF: return 100;  case SAK_BEAR_ENGULF: return -100;
         case SAK_MARUBOZU_B:  return 80;   case SAK_MARUBOZU_S:  return -80;
         case SAK_HAMMER:      return 60;   case SAK_SHOOTING:    return -60;
         default: return 0;
      }
   }
};

C_Sakata m_sakata;
