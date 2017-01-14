//+------------------------------------------------------------------+
//|                                                      LasyATR.mq5 |
//| LasyATR v1.0                              Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "2.2"

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_type1   DRAW_NONE
#property indicator_color1  clrRed
#property indicator_width1  1

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int InpPeriod=50;           // Period

double LATR[];

double LAtrAlpha=2.0/(InpPeriod+1.0);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,LATR,INDICATOR_DATA);
 
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])

  {

   for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
     {
      //----
      double atr0 = (i==0) ? high[i]-low[i] : MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      double atr1 = (i==0) ? atr0 : LATR[i-1];
      atr0=fmax(atr1*0.667,fmin(atr0,atr1*1.333));
      LATR[i]=LAtrAlpha*atr0+(1.0-LAtrAlpha)*atr1;
     }
   return(rates_total);
   
  }
