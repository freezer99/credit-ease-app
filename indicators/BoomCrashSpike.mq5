//+------------------------------------------------------------------+
//|                                                    BoomCrashSpike |
//|                        Custom indicator for Boom & Crash indices |
//|  Detects spike candles and pre-signal confluences for Boom/Crash |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

//--- plot 1: Up Pre-Signal
#property indicator_label1  "UpPre"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  DodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot 2: Down Pre-Signal
#property indicator_label2  "DownPre"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  Orange
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot 3: Up Spike
#property indicator_label3  "UpSpike"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  Lime
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot 4: Down Spike
#property indicator_label4  "DownSpike"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  Red
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

//--- inputs: general behavior
input bool   InpRestrictToSymbolType   = true;     // Only Up on Boom and Down on Crash
input int    InpLookbackBars           = 1500;     // Max bars to evaluate each tick
input bool   InpEnablePreSignals       = true;     // Enable pre-signal arrows
input bool   InpEnableSpikeSignals     = true;     // Enable spike detection arrows

//--- inputs: confluence (pre-signal)
input int    InpRSIPeriod              = 14;       // RSI period
input double InpRSIOverbought          = 70.0;     // RSI overbought
input double InpRSIOversold            = 30.0;     // RSI oversold
input int    InpFastMAPeriod           = 10;       // Fast EMA period
input int    InpSlowMAPeriod           = 50;       // Slow EMA period
input int    InpBBPeriod               = 20;       // Bollinger Bands period
input double InpBBDeviation            = 2.0;      // Bollinger Bands deviations
input int    InpConfluenceToPreSignal  = 3;        // Min confluence count to trigger pre-signal (0-4)

//--- inputs: spike detection (candle-based)
input int    InpATRPeriod              = 14;       // ATR period
input double InpWickAtrMultiplier      = 1.6;      // Wick >= ATR * multiplier
input double InpBodyToRangeMax         = 0.35;     // Body <= range * max fraction

//--- inputs: alerts
input bool   InpAlertPopups            = true;     // Popup alerts
input bool   InpAlertPush              = false;    // Push notifications (Terminal must allow)
input bool   InpAlertSound             = false;    // Play sound
input string InpAlertSoundFile         = "alert.wav"; // Sound file name

//--- indicator buffers
double UpPreBuffer[];
double DownPreBuffer[];
double UpSpikeBuffer[];
double DownSpikeBuffer[];

//--- indicator handles
int    rsiHandle   = INVALID_HANDLE;
int    atrHandle   = INVALID_HANDLE;
int    maFastHandle= INVALID_HANDLE;
int    maSlowHandle= INVALID_HANDLE;
int    bbHandle    = INVALID_HANDLE; // 0: upper, 1: middle, 2: lower

//--- alert dedup state
static datetime lastAlertTimeUpPre     = 0;
static datetime lastAlertTimeDownPre   = 0;
static datetime lastAlertTimeUpSpike   = 0;
static datetime lastAlertTimeDownSpike = 0;

//+------------------------------------------------------------------+
//| Utility: lower-cased symbol type checks                         |
//+------------------------------------------------------------------+
bool IsBoomSymbol()
{
	string s = StringToLower(_Symbol);
	return (StringFind(s, "boom") >= 0);
}

bool IsCrashSymbol()
{
	string s = StringToLower(_Symbol);
	return (StringFind(s, "crash") >= 0);
}

//+------------------------------------------------------------------+
//| Utility: alert helpers                                           |
//+------------------------------------------------------------------+
void FireAlert(const string message)
{
	if(InpAlertPopups)
		Alert(message);
	if(InpAlertPush)
		SendNotification(message);
	if(InpAlertSound && StringLen(InpAlertSoundFile) > 0)
		PlaySound(InpAlertSoundFile);
}

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
	IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
	IndicatorSetString(INDICATOR_SHORTNAME, "BoomCrash Spike & Pre");

	//--- buffers
	SetIndexBuffer(0, UpPreBuffer, INDICATOR_DATA);
	SetIndexBuffer(1, DownPreBuffer, INDICATOR_DATA);
	SetIndexBuffer(2, UpSpikeBuffer, INDICATOR_DATA);
	SetIndexBuffer(3, DownSpikeBuffer, INDICATOR_DATA);

	//--- arrows
	PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_ARROW);
	PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_ARROW);
	PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_ARROW);
	PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_ARROW);
	PlotIndexSetInteger(0, PLOT_ARROW, 233); // up
	PlotIndexSetInteger(1, PLOT_ARROW, 234); // down
	PlotIndexSetInteger(2, PLOT_ARROW, 233); // up
	PlotIndexSetInteger(3, PLOT_ARROW, 234); // down
	PlotIndexSetString(0, PLOT_LABEL, "UpPre");
	PlotIndexSetString(1, PLOT_LABEL, "DownPre");
	PlotIndexSetString(2, PLOT_LABEL, "UpSpike");
	PlotIndexSetString(3, PLOT_LABEL, "DownSpike");
	PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrDodgerBlue);
	PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrOrange);
	PlotIndexSetInteger(2, PLOT_LINE_COLOR, clrLime);
	PlotIndexSetInteger(3, PLOT_LINE_COLOR, clrRed);

	//--- initialize buffers with EMPTY_VALUE
	for(int i = 0; i < 4; i++)
	{
		PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, EMPTY_VALUE);
	}

	//--- indicator handles
	rsiHandle    = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
	atrHandle    = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
	maFastHandle = iMA(_Symbol, PERIOD_CURRENT, InpFastMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
	maSlowHandle = iMA(_Symbol, PERIOD_CURRENT, InpSlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
	bbHandle     = iBands(_Symbol, PERIOD_CURRENT, InpBBPeriod, InpBBDeviation, 0, PRICE_CLOSE);

	if(rsiHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE ||
	   maFastHandle == INVALID_HANDLE || maSlowHandle == INVALID_HANDLE ||
	   bbHandle == INVALID_HANDLE)
	{
		Print("[BoomCrashSpike] Failed to create indicator handles. Error: ", GetLastError());
		return INIT_FAILED;
	}

	return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
	if(rsiHandle    != INVALID_HANDLE) IndicatorRelease(rsiHandle);
	if(atrHandle    != INVALID_HANDLE) IndicatorRelease(atrHandle);
	if(maFastHandle != INVALID_HANDLE) IndicatorRelease(maFastHandle);
	if(maSlowHandle != INVALID_HANDLE) IndicatorRelease(maSlowHandle);
	if(bbHandle     != INVALID_HANDLE) IndicatorRelease(bbHandle);
}

//+------------------------------------------------------------------+
//| Calculation                                                      |
//+------------------------------------------------------------------+
int OnCalculate(
	const int        rates_total,
	const int        prev_calculated,
	const datetime&  time[],
	const double&    open[],
	const double&    high[],
	const double&    low[],
	const double&    close[]
	,
	const long&      tick_volume[],
	const long&      volume[],
	const int&       spread[]
)
{
	int need = MathMax(MathMax(InpRSIPeriod, InpSlowMAPeriod), MathMax(InpBBPeriod, InpATRPeriod)) + 5;
	if(rates_total < need)
		return 0;

	int copyCount = rates_total;
	if(InpLookbackBars > 0)
		copyCount = MathMin(copyCount, InpLookbackBars + 10);

	//--- prepare temp arrays for indicator data
	double rsi[];       ArrayResize(rsi, copyCount);       ArraySetAsSeries(rsi, true);
	double atr[];       ArrayResize(atr, copyCount);       ArraySetAsSeries(atr, true);
	double maFast[];    ArrayResize(maFast, copyCount);    ArraySetAsSeries(maFast, true);
	double maSlow[];    ArrayResize(maSlow, copyCount);    ArraySetAsSeries(maSlow, true);
	double bbUpper[];   ArrayResize(bbUpper, copyCount);   ArraySetAsSeries(bbUpper, true);
	double bbMiddle[];  ArrayResize(bbMiddle, copyCount);  ArraySetAsSeries(bbMiddle, true);
	double bbLower[];   ArrayResize(bbLower, copyCount);   ArraySetAsSeries(bbLower, true);

	int copied;
	copied = CopyBuffer(rsiHandle,    0, 0, copyCount, rsi);      if(copied <= 0) return prev_calculated;
	copied = CopyBuffer(atrHandle,    0, 0, copyCount, atr);      if(copied <= 0) return prev_calculated;
	copied = CopyBuffer(maFastHandle, 0, 0, copyCount, maFast);   if(copied <= 0) return prev_calculated;
	copied = CopyBuffer(maSlowHandle, 0, 0, copyCount, maSlow);   if(copied <= 0) return prev_calculated;
	copied = CopyBuffer(bbHandle,     0, 0, copyCount, bbUpper);  if(copied <= 0) return prev_calculated;
	copied = CopyBuffer(bbHandle,     1, 0, copyCount, bbMiddle); if(copied <= 0) return prev_calculated;
	copied = CopyBuffer(bbHandle,     2, 0, copyCount, bbLower);  if(copied <= 0) return prev_calculated;

	bool boom = IsBoomSymbol();
	bool crash = IsCrashSymbol();

	int start = copyCount - 2; // we need i+1 for slope
	if(start < 1)
		start = 1;

	for(int i = start; i >= 1; i--)
	{
		// reset outputs for this bar first
		UpPreBuffer[i]     = EMPTY_VALUE;
		DownPreBuffer[i]   = EMPTY_VALUE;
		UpSpikeBuffer[i]   = EMPTY_VALUE;
		DownSpikeBuffer[i] = EMPTY_VALUE;

		double body  = MathAbs(close[i] - open[i]);
		double range = high[i] - low[i];
		if(range <= 0.0)
			continue;

		double wickUp   = high[i] - MathMax(open[i], close[i]);
		double wickDown = MathMin(open[i], close[i]) - low[i];
		double atrVal   = atr[i];
		double rsiVal   = rsi[i];
		double maFastNow = maFast[i];
		double maSlowNow = maSlow[i];
		double maFastPrev = maFast[i+1];
		double bbU = bbUpper[i];
		double bbL = bbLower[i];

		//--- pre-signal confluences
		int longConfluence  = 0;
		int shortConfluence = 0;

		bool condRsiLong   = (rsiVal <= InpRSIOversold);
		bool condBbLong    = (close[i] <= bbL || low[i] <= bbL);
		bool condMaLong    = (maFastNow < maSlowNow);
		bool condSlopeDown = (maFastNow < maFastPrev);
		if(condRsiLong)   longConfluence++;
		if(condBbLong)    longConfluence++;
		if(condMaLong)    longConfluence++;
		if(condSlopeDown) longConfluence++;

		bool condRsiShort  = (rsiVal >= InpRSIOverbought);
		bool condBbShort   = (close[i] >= bbU || high[i] >= bbU);
		bool condMaShort   = (maFastNow > maSlowNow);
		bool condSlopeUp   = (maFastNow > maFastPrev);
		if(condRsiShort)  shortConfluence++;
		if(condBbShort)   shortConfluence++;
		if(condMaShort)   shortConfluence++;
		if(condSlopeUp)   shortConfluence++;

		//--- spike detection
		bool condUpWickLarge   = (wickUp   >= InpWickAtrMultiplier * atrVal);
		bool condDownWickLarge = (wickDown >= InpWickAtrMultiplier * atrVal);
		bool condBodySmall     = (body <= InpBodyToRangeMax * range);

		//--- apply symbol restrictions if requested
		bool allowLong  = (!InpRestrictToSymbolType) || boom;
		bool allowShort = (!InpRestrictToSymbolType) || crash;

		//--- pre-signals
		if(InpEnablePreSignals && longConfluence >= InpConfluenceToPreSignal && allowLong)
			UpPreBuffer[i] = low[i];
		if(InpEnablePreSignals && shortConfluence >= InpConfluenceToPreSignal && allowShort)
			DownPreBuffer[i] = high[i];

		//--- spike arrows
		if(InpEnableSpikeSignals && condUpWickLarge && condBodySmall && allowLong)
			UpSpikeBuffer[i] = low[i];
		if(InpEnableSpikeSignals && condDownWickLarge && condBodySmall && allowShort)
			DownSpikeBuffer[i] = high[i];
	}

	//--- alerts for just-closed bar (i == 1)
	if(rates_total >= 2)
	{
		int i = 1;
		bool printed = false;
		string sym = _Symbol;
		string tf  = EnumToString((ENUM_TIMEFRAMES)_Period);

		if(InpEnablePreSignals && UpPreBuffer[i] != EMPTY_VALUE && time[i] != lastAlertTimeUpPre)
		{
			FireAlert(StringFormat("%s %s: Up PRE-SIGNAL", sym, tf));
			lastAlertTimeUpPre = time[i];
			printed = true;
		}
		if(InpEnablePreSignals && DownPreBuffer[i] != EMPTY_VALUE && time[i] != lastAlertTimeDownPre)
		{
			FireAlert(StringFormat("%s %s: Down PRE-SIGNAL", sym, tf));
			lastAlertTimeDownPre = time[i];
			printed = true;
		}
		if(InpEnableSpikeSignals && UpSpikeBuffer[i] != EMPTY_VALUE && time[i] != lastAlertTimeUpSpike)
		{
			FireAlert(StringFormat("%s %s: Up SPIKE detected", sym, tf));
			lastAlertTimeUpSpike = time[i];
			printed = true;
		}
		if(InpEnableSpikeSignals && DownSpikeBuffer[i] != EMPTY_VALUE && time[i] != lastAlertTimeDownSpike)
		{
			FireAlert(StringFormat("%s %s: Down SPIKE detected", sym, tf));
			lastAlertTimeDownSpike = time[i];
			printed = true;
		}
	}

	return rates_total;
}

//+------------------------------------------------------------------+