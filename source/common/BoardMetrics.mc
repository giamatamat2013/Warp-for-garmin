import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// Shared sizing helper for games that draw a square board. On round screens
// a square's corners reach farther from the center than its edges, so the
// board must shrink to the circle's inscribed square (side = radius*sqrt(2))
// to stay clear of the bezel; rectangular screens just get a flat margin.
module BoardMetrics {

    function isRoundScreen() as Boolean {
        return (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND);
    }

    function squareBoardSize(width as Number, height as Number, marginPx as Number) as Number {
        var minDim = (width < height ? width : height);
        if (isRoundScreen()) {
            return (minDim / 2.0 * Math.sqrt(2.0) * 0.94).toNumber();
        }
        return minDim - marginPx;
    }

}
