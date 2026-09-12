import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

// Reusable full-screen numeric keypad, styled after a plain phone dial pad:
// 1-9, then DEL / 0 / OK. Push it like any other view; it reports back
// through a Method callback (see NumberKeypadDelegate) instead of the
// caller having to embed keypad drawing/hit-testing into its own view.
class NumberKeypadView extends WatchUi.View {

    // Row-major: 1 2 3 / 4 5 6 / 7 8 9 / DEL 0 OK
    private const KEYS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "DEL", "0", "OK"] as Array<String>;
    private const COLS = 3;
    private const ROWS = 4;
    // Long enough for any board size or similar short numeric entry without
    // the typed value overflowing the header.
    private const MAX_DIGITS = 4;

    private var _title as String;
    private var _minValue as Number;
    private var _maxValue as Number;
    private var _text as String = "";

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _gridLeft as Number = 0;
    private var _gridTop as Number = 0;
    private var _cellW as Number = 0;
    private var _cellH as Number = 0;

    function initialize(title as String, minValue as Number, maxValue as Number, initialValue as Number) {
        View.initialize();
        _title = title;
        _minValue = minValue;
        _maxValue = maxValue;
        _text = initialValue.toString();
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();

        var minDim = (_width < _height ? _width : _height);
        var isRound = (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND);
        // Corners of the grid sit farther from center than its edges, so a
        // round bezel needs a smaller safe area than a rectangular screen.
        var safeSize = isRound ? (minDim * 0.78).toNumber() : minDim;
        var gridW = _width < safeSize ? _width : safeSize;

        var headerH = (_height * 0.22).toNumber();
        var gridH = _height - headerH;

        _cellW = gridW / COLS;
        _cellH = gridH / ROWS;
        _gridLeft = (_width - _cellW * COLS) / 2;
        _gridTop = headerH;
    }

    // Index of the key under (x,y), or null if the tap missed every key.
    function keyAt(x as Number, y as Number) as Number? {
        if (y < _gridTop) {
            return null;
        }
        var col = (x - _gridLeft) / _cellW;
        var row = (y - _gridTop) / _cellH;
        if (col < 0 || col >= COLS || row < 0 || row >= ROWS) {
            return null;
        }
        var idx = row * COLS + col;
        if (idx < 0 || idx >= KEYS.size()) {
            return null;
        }
        return idx;
    }

    // Returns the confirmed value if OK was tapped on a valid in-range
    // number, otherwise null (and the tap is otherwise handled/ignored).
    function pressKey(idx as Number) as Number? {
        var key = KEYS[idx];
        if (key.equals("DEL")) {
            if (_text.length() > 0) {
                _text = _text.substring(0, _text.length() - 1);
            }
        } else if (key.equals("OK")) {
            var value = parsedValue();
            if (value != null) {
                return value;
            }
        } else if (_text.length() < MAX_DIGITS) {
            _text += key;
        }
        WatchUi.requestUpdate();
        return null;
    }

    // Null while the typed text is empty or outside [min,max] — callers
    // treat that as "OK does nothing yet" rather than a hard error state.
    private function parsedValue() as Number? {
        if (_text.length() == 0) {
            return null;
        }
        var value = _text.toNumber();
        if (value == null || value < _minValue || value > _maxValue) {
            return null;
        }
        return value;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, _title, Graphics.TEXT_JUSTIFY_CENTER);
        var shown = _text.length() > 0 ? _text : "_";
        dc.drawText(_width / 2, _gridTop / 2 - 4, Graphics.FONT_MEDIUM, shown, Graphics.TEXT_JUSTIFY_CENTER);

        var okEnabled = parsedValue() != null;
        for (var i = 0; i < KEYS.size(); i++) {
            var row = i / COLS;
            var col = i % COLS;
            var cx = _gridLeft + col * _cellW + _cellW / 2;
            var cy = _gridTop + row * _cellH + _cellH / 2;
            var key = KEYS[i];
            if (key.equals("OK")) {
                dc.setColor(okEnabled ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawText(cx, cy - 8, Graphics.FONT_MEDIUM, key, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
