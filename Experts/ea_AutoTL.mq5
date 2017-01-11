//+------------------------------------------------------------------+
//|                                                    ea_AutoTL.mq5 |
//| ea_AutoTL v1.00                           Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#include <ExpertAdvisor2010.mqh>

input double Risk=0.1; // Risk
input double InpSL        =  4.1; // Stop Loss distance
input double InpTP        = 8; // Take Profit distance
input double InpTS        =  4.0; // Trailing Stop distance
input double InpBE        =  2; // Brake Even distance
input int    HourStart =   8; // Hour of trade start
input int    HourEnd   =  16; // Hour of trade end
input int    PositionExpire=40; // Position Expire
input string desc1="1--------- AutoTL  ------------";
input int InpFastPeriod=25;           // Fast Period
input int InpHiLoPeriod=70;           // HiLo Period
input string desc2="2.--------- TimeFrames -------------";
input ENUM_TIMEFRAMES InpTF1=PERIOD_M5; // Bars period
input ENUM_TIMEFRAMES InpTF2=PERIOD_H1;// GannSwing Period
input ENUM_TIMEFRAMES InpTF3=PERIOD_H4; // AutoTL TF
//---
class CMyEA : public CExpertAdvisor
  {
protected:
   double            m_risk;          // size of risk
   int               m_sl;            // Stop Loss
   int               m_tp;            // Take Profit
   int               m_ts;            // Trailing Stop
   int               m_be;            // Brake Even
   long              m_expire_sec;    // expire sec 
   int               m_hourStart;     // Hour of trade start
   int               m_hourEnd;       // Hour of trade end
   int               m_tl_handle;     // atl Handle
   int               m_atr_handle;    // atl Handle
   int               m_trend_handle;  // trend Handle
   int               m_gann_handle;   // mom Handle
   int               m_buy_sig;
   int               m_sell_sig;

public:
   void              CMyEA();
   void             ~CMyEA();
   virtual bool      Init(string smb,ENUM_TIMEFRAMES tf); // initialization
   virtual bool      Main();                              // main function
   virtual void      OpenPosition(long dir);              // open position on signal
   virtual void      ClosePosition(long dir);             // close position on signal
  };
//------------------------------------------------------------------	CMyEA
void CMyEA::CMyEA() { }
//------------------------------------------------------------------	~CMyEA
void CMyEA::~CMyEA()
  {
   IndicatorRelease(m_tl_handle);
   IndicatorRelease(m_atr_handle);
   IndicatorRelease(m_gann_handle);
  }
//------------------------------------------------------------------	Init
bool CMyEA::Init(string smb,ENUM_TIMEFRAMES tf)
  {
   if(!CExpertAdvisor::Init(0,smb,tf)) return(false);                                // initialize parent class

//---
   m_risk=Risk;
   m_expire_sec=PeriodSeconds(InpTF2)*PositionExpire;
   m_hourStart=HourStart;
   m_hourEnd=HourEnd;
//---

   m_tl_handle=iCustom(NULL,InpTF3,"SimpleAutoTL_v2_2",InpFastPeriod,InpHiLoPeriod,0.6,true,500,clrDodgerBlue,1,true);

   m_atr_handle=iCustom(m_smb,InpTF2,"LasyATR",50);
   m_gann_handle=iCustom(m_smb,InpTF2,"GannSwingBars",2);

   if(m_atr_handle==INVALID_HANDLE
      || m_gann_handle==INVALID_HANDLE
      || m_atr_handle==INVALID_HANDLE) return(false);              // if there is an error, then exit

   m_bInit=true;
   return(true);                                                       // trade allowed
  }
//------------------------------------------------------------------	Main
bool CMyEA::Main() // main function
  {
   if(!CExpertAdvisor::Main()) return(false); // call function of parent class

   if(Bars(m_smb,m_tf)<=100) return(false);   // if there are insufficient number of bars

   if(!CheckNewBar()) return(true);           // check new bar

   double upper[2];
   double lower[2];
   double gann[2];
   double atr[2];
   MqlRates rt[3];

   if(CopyRates(m_smb,InpTF1,0,3,rt)!=3) // Copy price values of last 3 bars to array
     { Print("CopyRates ",m_smb," history is not loaded"); return(WRONG_VALUE); }

   if(CopyBuffer(m_gann_handle,4,1,2,gann)!=2)
     { Print("CopyBuffer Gann - no data"); return(WRONG_VALUE); }

   if(CopyBuffer(m_tl_handle,0,1,2,upper)!=2)
     { Print("CopyBuffer tl - no data 1"); return(WRONG_VALUE); }

   if(CopyBuffer(m_tl_handle,1,1,2,lower)!=2)
     { Print("CopyBuffer tl - no data 1"); return(WRONG_VALUE); }

   if(CopyBuffer(m_atr_handle,0,1,2,atr)!=2)
     { Print("CopyBuffer atr - no data 1"); return(WRONG_VALUE); }
   //---
   m_tp =int(InpTP * atr[1]/m_pnt);
   m_sl =int(InpSL * atr[1]/m_pnt);
   m_ts =int(InpTS * atr[1]/m_pnt);
   m_be =int(InpBE * atr[1]/m_pnt);
   //---
   if(upper[1]!=EMPTY_VALUE)
     {
      if(upper[1]<rt[2].close)
        {
         if(m_buy_sig!=1) m_buy_sig=1;
        }
      if(upper[1]>rt[2].close)
        {
         m_buy_sig=0;
        }
     }
   if(lower[1]!=EMPTY_VALUE)
     {
      if(lower[1]>rt[2].close)
        {
         if(m_sell_sig!=-1) m_sell_sig=-1;
        }
      if(lower[1]<rt[2].close)
        {
         m_sell_sig=0;
        }
     }
   long dir;
   if(PositionSelect(m_smb))
     {
      dir=PositionGetInteger(POSITION_TYPE);

      datetime openTime=(datetime)PositionGetInteger(POSITION_TIME);
      datetime sec=TimeCurrent()-(datetime)m_expire_sec;   
      if(sec>openTime)
        {

         double sl=NormalDbl(PositionGetDouble(POSITION_SL));
         double op=NormalDbl(PositionGetDouble(POSITION_PRICE_OPEN));

         if(dir==ORDER_TYPE_BUY)
           {

            if(m_buy_sig==2 && op-m_sl*m_pnt<sl)
              {
               m_buy_sig=3;
              }
            else
              {
               m_trade.PositionClose(m_smb,1);
               m_buy_sig=0;
              }
           }

         if(dir==ORDER_TYPE_SELL)
           {
            if(m_sell_sig==-2 && op+m_sl*m_pnt>sl)
              {
               m_sell_sig=-3;
              }
            else
              {
               m_trade.PositionClose(m_smb,1);
               m_sell_sig=0;
              }
           }
        }
     }
   else

     {
      if(m_buy_sig==1 && gann[1]==0 && gann[0]==1)
        {
         OpenPosition(ORDER_TYPE_BUY);
         m_buy_sig=2;
         m_sell_sig=0;
        }
      if(m_sell_sig==-1 && gann[1]==1 && gann[0]==0)
        {
         OpenPosition(ORDER_TYPE_SELL);
         m_sell_sig=-2;
         m_buy_sig=0;
        }
     }

   TrailingPosition(ORDER_TYPE_BUY,m_ts);
   TrailingPosition(ORDER_TYPE_SELL,m_ts);
   BEPosition(ORDER_TYPE_BUY,m_be);
   BEPosition(ORDER_TYPE_SELL,m_be);

   return(true);
  }
//------------------------------------------------------------------	OpenPos
void CMyEA::OpenPosition(long dir)
  {
   if(PositionSelect(m_smb)) return;
   double lot=0.1;//CountLotByRisk(m_sl,m_risk,0);
   if(lot<=0) return;
   DealOpen(dir,lot,m_sl,m_tp);
  }
//------------------------------------------------------------------	ClosePos
void CMyEA::ClosePosition(long dir)
  {
   if(!PositionSelect(m_smb)) return;
   if(dir!=PositionGetInteger(POSITION_TYPE)) return;
   m_trade.PositionClose(m_smb,1);
  }
//------------------------------------------------------------------	CheckSignal

CMyEA ea; // class instance
//------------------------------------------------------------------	OnInit
int OnInit()
  {
   ea.Init(Symbol(),Period());   // initialize expert
   return(0);
  }
//------------------------------------------------------------------	OnDeinit
void OnDeinit(const int reason) { }
//------------------------------------------------------------------	OnTick
void OnTick()
  {
   ea.Main(); // process incoming tick
  }
//+------------------------------------------------------------------+
