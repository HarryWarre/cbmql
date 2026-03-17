//+------------------------------------------------------------------+
//| ProfitRecycler.mqh - Recycle old profits to kill current losers  |
//| Phoenix V3 - Ichimoku Trend DCA Bot                              |
//+------------------------------------------------------------------+

void ManageProfitRecycler() {
   if(!InpEnableRecycler) return;

   // 1. Cập nhật danh sách lợi nhuận từ lịch sử
   UpdateProfitList();

   int currentCount = ArraySize(g_profitList);
   if(currentCount < InpRecyclerLookback) return;

   // 2. Tính tổng lợi nhuận và trung bình
   double totalProfit = 0;
   for(int i=0; i<currentCount; i++) totalProfit += g_profitList[i];
   double avgProfit = totalProfit / currentCount;

   // 3. Tìm lệnh đang lỗ nặng nhất
   double worstLoss = 0;
   ulong worstTicket = GetWorstPositionTicket(worstLoss);

   if(worstTicket == 0 || worstLoss >= 0) return;

   // 4. Kiểm tra điều kiện "Tái chế"
   // Điều kiện: Tổng lãi (10 lệnh) > |Lỗ lệnh tệ nhất| 
   // VÀ Lỗ lệnh đó > Trung bình lãi (để đảm bảo lệnh đủ "xứng đáng" để diệt)
   if(totalProfit > MathAbs(worstLoss) && MathAbs(worstLoss) > avgProfit) {
      if(m_trade.PositionClose(worstTicket)) {
         PrintFormat("PROFIT RECYCLER: Closed worst loser #%d (%.2f USD) using total profit %.2f USD of last %d deals.",
            worstTicket, worstLoss, totalProfit, currentCount);
         
         if(InpRecyclerReset) {
            ArrayFree(g_profitList);
            Print("PROFIT RECYCLER: Profit list reset.");
         }
      }
   }
}

void UpdateProfitList() {
   // Quét lịch sử để tìm các lệnh đóng mới (DEAL_ENTRY_OUT / DEAL_ENTRY_INOUT)
   if(!HistorySelect(0, TimeCurrent())) return;

   int totalDeals = HistoryDealsTotal();
   for(int i=0; i<totalDeals; i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= g_lastRecycleTicket) continue;

      long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
      string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
      if(magic != InpMagicNumber || symbol != _Symbol) continue;

      long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT) {
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT) + 
                         HistoryDealGetDouble(ticket, DEAL_SWAP) + 
                         HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         
         // Chỉ tính các lệnh có lãi (hoặc tất cả? User nói "lợi nhuận 10 lệnh gần nhất")
         // Thường thì recycler dùng lệnh lãi để diệt lệnh lỗ. Nếu lệnh chốt cũ cũng lỗ thì sẽ khó recycler.
         // Giả định: Lấy 10 lệnh gần nhất bất kể lãi lỗ.
         
         AddProfitToFIFO(profit);
         g_lastRecycleTicket = ticket;
      }
   }
}

void AddProfitToFIFO(double profit) {
   int size = ArraySize(g_profitList);
   if(size < InpRecyclerLookback) {
      ArrayResize(g_profitList, size + 1);
      g_profitList[size] = profit;
   } else {
      // FIFO: Shift left
      for(int i=0; i<size-1; i++) g_profitList[i] = g_profitList[i+1];
      g_profitList[size-1] = profit;
   }
}
