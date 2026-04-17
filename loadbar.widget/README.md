## CPU load bar for Übersicht

A widget for [Übersicht](http://tracesof.net/uebersicht/) that displays a thin bar on the left side of the screen indicating real CPU usage (user + sys, aggregated across all cores). Under normal load it's almost invisible, but changes color and opacity as load increases. Color and height changes are animated.

It formats its height based on the screen size, so it should work on any size monitor, stretching the full height of the screen at max load.

![](screenshot2.png)

### How it samples

The command uses `top -l 2 -s 1 -n 0` and takes the second sample: a true 1-second delta of `user + sys`, normalized to `0..1` (1.0 = every core saturated). The first sample is discarded because `top`'s first report is cumulative since boot and not meaningful as an instantaneous reading.

```sh
top -l 2 -s 1 -n 0 | awk '/CPU usage/ {gsub("%",""); print ($3+$5)/100}' | tail -1
```

The widget refreshes every 9.5 seconds (`refreshFrequency: 9500`). Each poll spends ~1s mostly sleeping inside `top`, so CPU overhead is negligible.

### Apple Silicon note

On Apple Silicon (M1/M2/M3), `top` aggregates P-cores and E-cores with equal weighting. A workload pinned to P-cores will therefore under-report compared to the true performance impact — but this is still far more representative than `vm.loadavg`, which is the previous data source this widget used.

### Adjusting values

The value passed to the bar is normalized to `0..1`. Thresholds for the color levels can be tweaked in the `update` function:

```coffee
colorclass = switch
  when val > 0.9 then 'urgent'
  when val > 0.75 then 'important'
  when val > 0.5 then 'high'
  when val > 0.25 then 'normal'
  else 'low'
```

### Adjusting colors

The colors for each level can be adjusted in the `style` section:

```
.low::-webkit-progress-value
  background-color: rgba(134, 229, 255, .05)

.normal::-webkit-progress-value
  background-color: rgba(134, 255, 153, .25)

.high::-webkit-progress-value
  background-color: rgba(243, 255, 134, .65)

.important::-webkit-progress-value
  background-color: rgba(185, 134, 255, .75)

.urgent::-webkit-progress-value
  background-color: rgba(255, 71, 71, 1)
```

### Notes

Adjust the refresh rate as desired.
