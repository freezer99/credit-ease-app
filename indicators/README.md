# BoomCrashSpike (MQL5)

Custom indicator for Boom/Crash indices that detects spike candles and pre-signals using RSI, EMA, Bollinger Bands and ATR confluences.

## Installation (MetaTrader 5)

1. In MT5, go to: File → Open Data Folder.
2. Navigate to `MQL5/Indicators/`.
3. Copy `BoomCrashSpike.mq5` from this repo into that folder.
4. In MT5, open the Navigator (Ctrl+N), right-click Indicators → Refresh, or open `BoomCrashSpike.mq5` in MetaEditor and press Compile (F7).
5. Attach `BoomCrashSpike` to a Boom or Crash chart.

## Inputs

- RestrictToSymbolType: Only show Up signals on Boom and Down signals on Crash when enabled.
- LookbackBars: Max bars processed each tick.
- EnablePreSignals/EnableSpikeSignals: Toggle pre-signal and spike arrows.
- RSIPeriod/Overbought/Oversold: RSI settings.
- FastMAPeriod/SlowMAPeriod: EMA settings for confluence and slope.
- BBPeriod/BBDeviation: Bollinger Bands settings for extremes.
- ATRPeriod/WickAtrMultiplier/BodyToRangeMax: Spike detection thresholds.
- AlertPopups/AlertPush/AlertSound: Alert preferences and sound file.

## Usage tips

- Timeframes: M1–M5 commonly used for Boom/Crash spikes.
- Consider combining pre-signals with price action or higher timeframe trend for confirmation.
- Default parameters are conservative; tune for your broker/instrument behavior.

## Notes

- This is an indicator, not an EA. It does not place trades.
- Alerts occur on the just-closed bar to reduce repainting.
- Works best on symbols containing "Boom" or "Crash" in their names.