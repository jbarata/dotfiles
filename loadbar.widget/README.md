## CPU load bar for Übersicht

A widget for [Übersicht](http://tracesof.net/uebersicht/) that displays a thin bar on the left side of the screen indicating real CPU usage (user + sys, sampled over 1 second). Under normal CPU load it's almost invisible, but changes color and opacity as the load gets higher. Color and height changes are animated.

It formats its height based on the screen size, so it should work on any size monitor, stretching the full height of the screen at max load.

![](screenshot2.png)

### Adjusting values

The value passed to the bar is normalized to `0..1` (1.0 = all cores saturated). Thresholds for the color levels can be tweaked in the `update` function:

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
