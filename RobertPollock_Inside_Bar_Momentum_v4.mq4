//+------------------------------------------------------------------+
//|                      RobertPollock_InsideBarMomentumStrategy.mq4 |
//|                                                   Robert Pollock |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Robert Pollock"
#property link        "https://www.babypips.com/trading/forex-inside-bar-20170113"
#property description "Based on the strategy by Robopip which searches for inside bar formations"
#property description "ie dual candlestick patterns in which the second bar is completely"
#property description "contained by the high and low of the first bar - see link."
#property version     "1.00"
#property strict



int MagicNumber;

// signal definitions
#define BUY 0
#define SELL 1

// lot risk settings

extern int  RiskPercent = 1;

//Move To Break Even
extern bool UseMoveToBreakEven = true;
extern int  WhenToMoveToBE = 100;
extern int  PipsToLockIn=5;





//Global internal variables
double pips;
double FirstCandleHigh,FirstCandleLow, SecondCandleHigh, SecondCandleLow;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
  {
//---
   double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   if (ticksize == 0.00001 || ticksize == 0.001)
	pips = ticksize*10;
	else pips =ticksize;
	MagicNumber = getMagicNumber();


//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
   if(OpenOrdersThisPair(Symbol())>0)   
      {
         if(UseMoveToBreakEven) MoveToBreakEven();
      }

   if(IsNewCandle()) CheckForInsideBar();
  }
  
  
//--- CHECK FOR NEW CANDLE FUNCTION

bool IsNewCandle() 
{
 static int BarsOnChart =0;
 if(Bars ==BarsOnChart)return(false);
 BarsOnChart =Bars;
 return(true);
}  
  
//--- CHECK FOR INSIDE BAR

void CheckForInsideBar()
   {
   FirstCandleHigh = iHigh(NULL,240,2); // this symbol, four hour time frame
   FirstCandleLow = iLow(NULL,240,2);
   SecondCandleHigh = iHigh(NULL,240,1);
   SecondCandleLow = iLow(NULL,240,1);
   double FirstCandleOpen = iOpen(NULL,240,2);
   double FirstCandleClose = iClose(NULL,240,2);
   
   //if first candle bullish and second candle is contained by first candle
   if(FirstCandleClose>FirstCandleOpen && SecondCandleHigh<FirstCandleHigh && SecondCandleLow>FirstCandleLow)SendOrder(BUY);
   //if first candle bearish and second candle contained by first candle
   if(FirstCandleClose<FirstCandleOpen && SecondCandleHigh<FirstCandleHigh && SecondCandleLow>FirstCandleLow)SendOrder(SELL);
   }      
   
//--- ORDER PROCESSING

void SendOrder (int direction)  
   { 
   // close any previous insidebar positions before proceeding
   if(OpenOrdersThisPair(Symbol())>0)CloseAll(); 
   
   double FirstCandleRange = iHigh(NULL,240,2)-iLow(NULL,240,2);
   double TenPercent = FirstCandleRange*0.1;
   double TwentyPercent = FirstCandleRange*0.2;
   double FortyPercent = FirstCandleRange*0.4;
   double EightyPercent = FirstCandleRange*0.8;
   
   if(direction==BUY)
      {
      double BuyEntry = FirstCandleHigh+TenPercent;
      double BuySL = FirstCandleHigh-FortyPercent;
      double BuyTP = FirstCandleHigh+EightyPercent;
      
      double BuyPipsToStopLoss = ND(BuyEntry-BuySL)*1000;
      Print("pips to sl is",BuyPipsToStopLoss);
      double lotstest = CalculateLotSize(BuyPipsToStopLoss);
      Print(lotstest);
      
      int BuyTicket = OrderSend(Symbol(),OP_BUYSTOP,CalculateLotSize(BuyPipsToStopLoss),ND(BuyEntry),3,ND(BuySL),ND(BuyTP) , "Buy" ,MagicNumber,0,Green); // ordersend function returns a number. we assign that number as 'ticket'. If function sends back -1 there has been an error.
      if (BuyTicket>0)
        {
        if(OrderSelect(BuyTicket,SELECT_BY_TICKET,MODE_TRADES))
            {
            Print ("Buy order opened");
            bool res = SendNotification("Inside Bar Momentum Strategy - Buy order opened \n"
                                         +"Order #" +string(BuyTicket) +"\n"
                                         +"Open Price: " + string(OrderOpenPrice())  + "\n"
                                         +"StopLoss: "   + string(OrderStopLoss())   + "\n"
                                         +"TakeProfit: " + string(OrderTakeProfit()) + "\n"
                                        );
            if(res == false)
               {
               Alert("Error sending email");
               }                
            
            
            }
        }    
      else Print("Error opening BUY order: ", GetLastError());
      }
      
   if(direction==SELL)
      {
      double SellEntry = FirstCandleLow-TenPercent;
      double SellSL = FirstCandleLow+FortyPercent;
      double SellTP = FirstCandleLow-EightyPercent;
      
      double SellPipsToStopLoss = ND(SellSL -SellEntry)*1000;
     
         int SellTicket = OrderSend(Symbol(),OP_SELLSTOP,CalculateLotSize(SellPipsToStopLoss),ND(SellEntry),3,ND(SellSL), ND(SellTP),NULL,MagicNumber,0,Red);
         if (SellTicket>0) 
            {
            if(OrderSelect(SellTicket,SELECT_BY_TICKET,MODE_TRADES))
            {
            
             Print ("Sell order opened"); 
            
             bool res = SendNotification("Inside Bar Momentum Strategy - Sell order opened \n"
                                         +"Order #" +string(SellTicket) +"\n"
                                         +"Open Price: " + string(OrderOpenPrice())  + "\n"
                                         +"StopLoss: "   + string(OrderStopLoss())   + "\n"
                                         +"TakeProfit: " + string(OrderTakeProfit()) + "\n"
                                        );
            if(res == false)
               {
               Alert("Error sending email");
               }                                      
            }                   
            }
            else Print ("Error opening SELL order: ", GetLastError());        
       }
    }
   

//---- CHECK FOR OPEN ORDERS FUNCTION   

int OpenOrdersThisPair(string pair)   // call function with pair. String because Symbol() returns a string
{
int total = 0;      // function always initializes with total as 0         
for (int i =OrdersTotal()-1; i>=0; i--)
{
if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
   {
   if (OrderSymbol()== pair) total ++;
   }
}
return (total);
}
  

//--- EXIT OPEN TRADES

void CloseAll()
   {
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS,MODE_TRADES)==true)
      {
         if(OrderType()==OP_BUYSTOP||OrderType()==OP_SELLSTOP)
         {
             bool closepending=OrderDelete(OrderTicket());
             if(closepending != true)
                  {
                  int err = GetLastError();
                  Print("Last Error = ", err);
                  } 
         }
      else if(OrderType()==OP_BUY|| OrderType()==OP_SELL)
         {   
         if(OrderMagicNumber()==MagicNumber)
            {
            bool closeorder = OrderClose(OrderTicket(),OrderLots(),Bid,3,Pink);
            if(closeorder != true)
                  {
                  int err = GetLastError();
                  Print("Last Error = ", err);
                  } 
            }
          }
        else Print("When selecting a trade, error ", GetLastError()," occurred");       
      }
   }
 }     
      
//---- Normalizing function

double ND(double val)
{
   return(NormalizeDouble(val, Digits));
}      
      
      
//---- Move to breakeven function
    
void MoveToBreakEven()
   {
   for(int b=OrdersTotal()-1;b>=0;b--) // this loop runs for number of orders there are eg 16 orders it will run 16 times
      {
      if (OrderSelect(b,SELECT_BY_POS,MODE_TRADES))//bool true if it can select an order
         {
         if(OrderMagicNumber()== MagicNumber &&  OrderSymbol() == Symbol())  // or could have done if! magic number continue; etc
            {
            if(OrderType()==OP_BUY)
               {
               if(Bid-OrderOpenPrice()> WhenToMoveToBE*pips)
                  {
                  if(OrderOpenPrice()>OrderStopLoss())
                     {
                     bool res = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(PipsToLockIn*pips),OrderTakeProfit(),0,clrNONE);
                     if (res) Print ("Buy order moved to breakeven");
                     }
                  }
                }
            if(OrderType()==OP_SELL)
                {
                if(OrderOpenPrice()-Ask>WhenToMoveToBE*pips)
                  {   
                  if(OrderOpenPrice()<OrderStopLoss())
                     {
                     bool res = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(PipsToLockIn*pips),OrderTakeProfit(),0,clrNONE);
                     if(res)Print ("sell order moved to break even");
                     }
                  }
                }
             }
         }
      }  
   }       
   

//--- LOT SIZE CALCULATION

double CalculateLotSize(double SL){       
   double LotSize=0;
   
   double nTickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
   //If the digits are 3 or 5 we normalize multiplying by 10
   if(Digits==3 || Digits==5){
      nTickValue=nTickValue*10;
   }
   LotSize=(AccountBalance()*RiskPercent/100)/(SL*nTickValue);
   return LotSize;
}   

//+------------------------------------------------------------------+


      

int getMagicNumber() 
{
   int temp;
   if (Symbol()=="EURUSD") temp = 001;
   else if (Symbol()=="GBPUSD") temp = 002;
   else if (Symbol()=="AUDUSD") temp = 003;
   else if (Symbol()=="NZDUSD") temp = 004;
   else if (Symbol()=="USDCHF") temp = 005;
   else if (Symbol()=="USDJPY") temp = 006;
   else if (Symbol()=="USDCAD") temp = 007;
   else if (Symbol()=="XAUUSD") temp = 008;
   else temp = 009;
   temp+=1356; // unique key for this strategy
   return temp;
}