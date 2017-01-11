//+------------------------------------------------------------------+
//|                                            SimpleAutoTL_v2_2.mq5 |
//| Simple Auto TL v2.2                       Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "2.2"

#property indicator_chart_window
#property indicator_buffers 11
#property indicator_plots   2

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrMagenta
#property indicator_width1  1

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrMagenta
#property indicator_width2  1
#include <Arrays\ArrayInt.mqh>
int WinNo=ChartWindowFind();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int InpFastPeriod=20;           // Fast Period
input int InpHiLoPeriod=50;           // HiLo Period
input double InpSize=1.0;             // Threshold
input bool InpShowHistory=true;       // Show History
input int InpMaxBars=1000;            // MaxBars
input color InpColor=clrDodgerBlue;    // Line Color
input int InpLineWidth=1;    // Line Width
input bool InpShowSign=true;           // Show Sign
double InpXSize=0.3;   //   X Size

int UP_SIG=0;
int DN_SIG=1;
int UP_X1=2;
int UP_X2=3;
int UP_Y1=4;
int UP_Y2=5;
int DN_X1=6;
int DN_X2=7;
int DN_Y1=8;
int DN_Y2=9;
int UP_ID=10;
int DN_ID=11;

CArrayInt *HighCache[];
CArrayInt *LowCache[];
double wk[][12];
double HI[];
double LO[];
double HI2[];
double LO2[];
double LATR[];

double UPPER_X[];
double LOWER_X[];
double UPPER[];
double LOWER[];
double UP[];
double DN[];
int LAtrPeriod=100;
double LAtrAlpha=2.0/(LAtrPeriod+1.0);
int LineNo=0;
double xFactor;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectDeleteByName("AutoTL");
   if(InpShowSign)
   {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_ARROW);
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_ARROW);
   }
   else
   {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
   }
   SetIndexBuffer(0,UP,INDICATOR_DATA);
   SetIndexBuffer(1,DN,INDICATOR_DATA);
   SetIndexBuffer(2,LATR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,HI,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,LO,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,UPPER_X,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,LOWER_X,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,HI2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,LO2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,UPPER,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,LOWER,INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(0,PLOT_ARROW,158);
   PlotIndexSetInteger(1,PLOT_ARROW,158);
 

   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDeleteByName("AutoTL");
   int sz1=ArraySize(HighCache);
   for(int i=0;i<sz1;i++) delete HighCache[i];
   int sz2=ArraySize(LowCache);
   for(int i=0;i<sz2;i++) delete LowCache[i];
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
//      if(InpShowHistory) ObjectDeleteByBarNo("AutoTL",fmax(0,rates_total-InpMaxBars));

      UPPER[i]=EMPTY_VALUE;
      LOWER[i]=EMPTY_VALUE;
      UPPER_X[i]=EMPTY_VALUE;
      LOWER_X[i]=EMPTY_VALUE;
      HI[i]=EMPTY_VALUE;
      LO[i]=EMPTY_VALUE;
      UP[i]=EMPTY_VALUE;
      DN[i]=EMPTY_VALUE;

      LATR[i]=EMPTY_VALUE;
      if(i==rates_total-1)continue;

      //----
      double atr0 = (i==0) ? high[i]-low[i] : MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      double atr1 = (i==0) ? atr0 : LATR[i-1];
      atr0=fmax(atr1*0.667,fmin(atr0,atr1*1.333));
      LATR[i]=LAtrAlpha*atr0+(1.0-LAtrAlpha)*atr1;

      //---
      if(ArrayRange(wk,0)!=rates_total) ArrayResize(wk,rates_total);

      if(ArraySize(HighCache)!=rates_total) ArrayResize(HighCache,rates_total);
      if(ArraySize(LowCache)!=rates_total) ArrayResize(LowCache,rates_total);
      if(HighCache[i]==NULL)HighCache[i]=new CArrayInt();
      if(LowCache[i]==NULL)LowCache[i]=new CArrayInt();
      if(i>0)
        {
         HighCache[i].AssignArray(HighCache[i-1]);
         LowCache[i].AssignArray(LowCache[i-1]);
        }
      //----
      double size=InpSize*LATR[i];
      if(i<=fmax(InpHiLoPeriod,InpFastPeriod)+1)continue;
      //---
      HI[i]=high[ArrayMaximum(high,i-(InpHiLoPeriod-1),InpHiLoPeriod)];
      LO[i]=low[ArrayMinimum(low,i-(InpHiLoPeriod-1),InpHiLoPeriod)];
      HI2[i]=high[ArrayMaximum(high,i-(InpFastPeriod-1),InpFastPeriod)];
      LO2[i]=low[ArrayMinimum(low,i-(InpFastPeriod-1),InpFastPeriod)];
      if(HI[i-1]==EMPTY_VALUE)continue;
      UPPER[i]=(HI[i]>HI[i-1])? HI[i]:UPPER[i-1];
      LOWER[i]=(LO[i]<LO[i-1])? LO[i]:LOWER[i-1];
      UPPER_X[i]=(HI[i]>HI[i-1])? i:UPPER_X[i-1];
      LOWER_X[i]=(LO[i]<LO[i-1])? i:LOWER_X[i-1];
      //---
      if(HI[i]>HI[i-1]) HighCache[i].Clear();
      HighCache[i].Add(i);
      //---
      if(LO[i]<LO[i-1]) LowCache[i].Clear();
      LowCache[i].Add(i);
      //---
      if(i<rates_total-InpMaxBars)continue;
      //---   
      wk[i][UP_ID]=wk[i-1][UP_ID];
      wk[i][DN_ID]=wk[i-1][DN_ID];
      wk[i][UP_SIG]=wk[i-1][UP_SIG];
      wk[i][DN_SIG]=wk[i-1][DN_SIG];
      wk[i][UP_X1]=wk[i-1][UP_X1];
      wk[i][UP_Y1]=wk[i-1][UP_Y1];
      wk[i][UP_X2]=wk[i-1][UP_X2];
      wk[i][UP_Y2]=wk[i-1][UP_Y2];

      wk[i][DN_X1]=wk[i-1][DN_X1];
      wk[i][DN_Y1]=wk[i-1][DN_Y1];
      wk[i][DN_X2]=wk[i-1][DN_X2];
      wk[i][DN_Y2]=wk[i-1][DN_Y2];
      //---
      xFactor=LATR[i]*InpXSize;
      if(i-LOWER_X[i]>=InpFastPeriod)
        {
         if(HI2[i]==high[i])
           {
            double lower[][2];
            //update
            convex_lower(lower,low,LowCache[i]);

            int sz=int(ArraySize(lower)*0.5);
            if(sz>1)
              {
               //---
               LowCache[i].Clear();
               for(int j=0;j<sz;j++) LowCache[i].Add((int)lower[j][0]);
               //---
               double best_d=0;
               int best=0;
               for(int j=0;j<sz-1;j++)
                 {
                  double d=dimension_up(lower[j][0],lower[j][1],lower[j+1][0],lower[j+1][1],LOWER[i],i,xFactor);
                  if(d>best_d) {  best=j; best_d=d; }
                 }
               if(best_d>0)
                 {
                  wk[i][UP_X1]=lower[best][0];
                  wk[i][UP_Y1]=lower[best][1];
                  wk[i][UP_X2]=lower[best+1][0];
                  wk[i][UP_Y2]=lower[best+1][1];
                  wk[i][UP_SIG]=1;
                  wk[i][UP_ID]=wk[i][UP_X2];
                  double y2=upTL(i);
                  int n=(InpShowHistory)? (int)wk[i][UP_X2] : 1;
                  drawTrend(1,n,InpColor,(int)wk[i][UP_X1],wk[i][UP_Y1],i,y2,time,STYLE_SOLID,InpLineWidth,false);
                  DN[i]=y2;
                 }
              }
           }
        }

      if(i-UPPER_X[i]>=InpFastPeriod)
        {
         if(LO2[i]==low[i])
           {
            double upper[][2];

            // update tl
            convex_upper(upper,high,HighCache[i]);
            int sz=int(ArraySize(upper)*0.5);
            if(sz>1)
              {
               //---
               HighCache[i].Clear();
               for(int j=0;j<sz;j++)HighCache[i].Add((int)upper[j][0]);

               //---
               double best_d=0;
               int best=0;
               for(int j=0;j<sz-1;j++)
                 {
                  double d=dimension_dn(upper[j][0],upper[j][1],upper[j+1][0],upper[j+1][1],UPPER[i],i,xFactor);
                  if(d>best_d) {  best=j;best_d=d;   }
                 }
               if(best_d>0)
                 {
                  wk[i][DN_X1]=upper[best][0];
                  wk[i][DN_Y1]=upper[best][1];
                  wk[i][DN_X2]=upper[best+1][0];
                  wk[i][DN_Y2]=upper[best+1][1];
                  wk[i][DN_SIG]=1;
                  wk[i][DN_ID]=wk[i][DN_X2];
                  double y2=dnTL(i);

                  int n=(InpShowHistory)?  (int)wk[i][DN_X2] : 2;
                  drawTrend(1,n,InpColor,(int)wk[i][DN_X1],wk[i][DN_Y1],i,y2,time,STYLE_SOLID,InpLineWidth,false);
                  UP[i]=y2;
                 }

              }
           }
        }
      //---
      if(wk[i][UP_X1]>0 && wk[i][UP_X1]<i && wk[i][UP_SIG]>=1)
        {
         double tl=upTL(i);
         if(close[i]<tl)
           {
            wk[i][UP_SIG]=2;
           }

         int n=(InpShowHistory)?(int)wk[i][UP_ID]: 1;
         drawTrend(1,n,InpColor,(int)wk[i][UP_X1],wk[i][UP_Y1],i,tl,time,STYLE_SOLID,InpLineWidth,false);
         DN[i]=tl;
         if(close[i]<tl-LATR[i]*InpSize)
           {
            wk[i][UP_SIG]=0;
           }

        }
      if(wk[i][DN_X1]>0 && wk[i][DN_X1]<i && wk[i][DN_SIG]>=1)
        {
         double tl=dnTL(i);
         if(close[i]>tl)
           {
            wk[i][DN_SIG]=2;
           }
         int n=(InpShowHistory)?(int)wk[i][DN_ID]: 2;
         drawTrend(1,n,InpColor,(int)wk[i][DN_X1],wk[i][DN_Y1],i,tl,time,STYLE_SOLID,InpLineWidth,false);
         UP[i]=tl;
         if(close[i]>tl+LATR[i]*InpSize)
           {
            wk[i][DN_SIG]=0;
           }

        }

      //---

     }

//---   
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrTest(CArrayInt *arr)
  {
   int sz=arr.Total();
   Print("---------------");
   for(int i=0;i<sz;i++)
     {
      Print(arr.At(i));
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double upTL(int bar)
  {
   double x1=wk[bar][UP_X1];
   double x2=wk[bar][UP_X2];
   double y1=wk[bar][UP_Y1];
   double y2=wk[bar][UP_Y2];
   double a= (y2-y1)/(x2-x1);
   double b=y1-a*x1;   //b=y-ax			
   return a*(bar)+b;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double dnTL(int bar)
  {
   double x1=wk[bar][DN_X1];
   double x2=wk[bar][DN_X2];
   double y1=wk[bar][DN_Y1];
   double y2=wk[bar][DN_Y2];

   double a= (y2-y1)/(x2-x1);
   double b=y1-a*x1;   //b=y-ax			
   return a*(bar)+b;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawTrend(int no1,int no2,
               const color clr,const int x0,const double y0,const int x1,const double y1,
               const datetime &time[],const ENUM_LINE_STYLE style,const int width,const bool isRay)
  {

   if(-1<ObjectFind(0,StringFormat("AutoTL_%d_#%d",no1,no2)))
     {
      ObjectMove(0,StringFormat("AutoTL_%d_#%d",no1,no2),0,time[x0],y0);
      ObjectMove(0,StringFormat("AutoTL_%d_#%d",no1,no2),1,time[x1],y1);
     }
   else
     {
      ObjectCreate(0,StringFormat("AutoTL_%d_#%d",no1,no2),OBJ_TREND,WinNo,time[x0],y0,time[x1],y1);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_#%d",no1,no2),OBJPROP_COLOR,clr);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_#%d",no1,no2),OBJPROP_STYLE,style);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_#%d",no1,no2),OBJPROP_WIDTH,width);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_#%d",no1,no2),OBJPROP_RAY_RIGHT,isRay);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDeleteByName(string prefix)
  {
   int total=ObjectsTotal(0),
   length=StringLen(prefix);
   for(int i=total-1; i>=0; i--)
     {
      string objName=ObjectName(0,i);
      if(StringSubstr(objName,0,length)==prefix)
        {
         ObjectDelete(0,objName);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDeleteByBarNo(string prefix,int no)
  {
   int total=ObjectsTotal(0),
   length=StringLen(prefix);
   for(int i=total-1; i>=0; i--)
     {
      string objName=ObjectName(0,i);
      if(StringSubstr(objName,0,length)==prefix)
        {
         string res[];
         StringSplit(objName,'#',res);
         if(ArraySize(res)==2 && int(res[1])<no) ObjectDelete(0,objName);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double dimension_dn(double x1,double y1,double x2,double  y2,double top,double i,double xfacter)
  {
   if(x1>=x2 || y1<=y2)return 0.0;
   double a= (y2-y1)/(x2-x1);
   double b=y1-a*x1;   //b=y-ax
   double x0=(top-b)/a;  //x=(y-b)/a
   double y3 = a*i+b;    //y=ax+b  
   return xfacter*(i-x0)*(top-y3);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double dimension_up(double x1,double y1,double x2,double  y2,double btm,double i,double xfacter)
  {
   if(x1>=x2 || y1>=y2)return 0.0;
   double a= (y2-y1)/(x2-x1);
   double b=y1-a*x1;   //b=y-ax
   double x0=(btm-b)/a;  //x=(y-b)/a
   double y3 = a*i+b;    //y=ax+b  
   return xfacter*(i-x0)*(y3-btm);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void convex_upper(double &upper[][2],const double &high[],CArrayInt *arr)
  {
   int len=arr.Total();

   ArrayResize(upper,len,len);
   int k=0;
   for(int j=0;j<len;j++)
     {

      while(k>=2 && 
            (
            cross(
            upper[k-2][0],upper[k-2][1],
            upper[k-1][0],upper[k-1][1],
            arr.At(j),high[arr.At(j)])
            )>=0)
        {
         k--;
        }

      upper[k][0]= arr.At(j);
      upper[k][1]= high[arr.At(j)];
      k++;
     }
   ArrayResize(upper,k,len);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void convex_lower(double &lower[][2],const double &low[],CArrayInt *arr)
  {
   int len=arr.Total();
   ArrayResize(lower,len,len);
   int k=0;
   for(int j=0;j<len;j++)
     {
      while(k>=2 && 
            (
            cross(
            lower[k-2][0],lower[k-2][1],
            lower[k-1][0],lower[k-1][1],
            arr.At(j),low[arr.At(j)]))<=0)
        {
         k--;
        }

      lower[k][0]= arr.At(j);
      lower[k][1]= low[arr.At(j)];
      k++;
     }
   ArrayResize(lower,k,len);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double cross(const double ox,double oy,
             const double ax,double ay,
             const double bx,double by)
  {
   return ((ax - ox) * (by - oy) - (ay - oy) * (bx - ox));
  }
//+------------------------------------------------------------------+
