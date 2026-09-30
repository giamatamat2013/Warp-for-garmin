import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;

// DVD logo screensaver: the logo drifts around a frame, changes colour on
// every bounce, and the goal is to catch it kissing a corner. A bounce that
// lands within CORNER_SLACK pixels of the other wall counts as a corner hit.
(:extendedCode)
class DvdView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "dvd_high";
    private const CORNER_SLACK = 4.0;
    private const BASE_VX = 1.7;
    private const BASE_VY = 1.1;
    private const FLASH_TICKS = 40;
    private const COLORS = [Graphics.COLOR_RED, Graphics.COLOR_ORANGE, Graphics.COLOR_YELLOW,
        Graphics.COLOR_GREEN, Graphics.COLOR_BLUE, Graphics.COLOR_PINK] as Array<Number>;

    private var _width as Number = 0;
    private var _height as Number = 0;
    // The play frame. On round screens it is the square inscribed in the
    // bezel so all four corners are actually visible.
    private var _minX as Float = 0.0;
    private var _maxX as Float = 0.0;
    private var _minY as Float = 0.0;
    private var _maxY as Float = 0.0;
    private var _logoW as Float = 0.0;
    private var _logoH as Float = 0.0;

    private var _x as Float = 0.0;
    private var _y as Float = 0.0;
    private var _dirX as Number = 1;
    private var _dirY as Number = 1;
    private var _speedMultiplier as Float = 1.0;

    private var _colorIndex as Number = 0;
    private var _corners as Number = 0;
    private var _best as Number = 0;
    private var _flash as Number = 0;
    private var _paused as Boolean = false;

    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _best = HighScores.get(HIGH_SCORE_KEY);
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        if (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {
            var half = _width * 0.35;
            _minX = _width / 2.0 - half;
            _maxX = _width / 2.0 + half;
            _minY = _height / 2.0 - half;
            _maxY = _height / 2.0 + half;
        } else {
            _minX = 6.0;
            _maxX = _width - 6.0;
            _minY = 28.0;
            _maxY = _height - 6.0;
        }
        _logoW = (_maxX - _minX) * 0.32;
        _logoH = _logoW * 0.5;
        resetGame();
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), 33, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTimerTick() as Void {
        if (!_paused) {
            step();
        }
        WatchUi.requestUpdate();
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
    }

    function togglePause() as Void {
        _paused = !_paused;
    }

    function resetGame() as Void {
        _x = _minX + (_maxX - _minX - _logoW) * 0.3;
        _y = _minY + (_maxY - _minY - _logoH) * 0.4;
        _dirX = 1;
        _dirY = 1;
        _colorIndex = 0;
        _corners = 0;
        _flash = 0;
    }

    private function step() as Void {
        _x += _dirX * BASE_VX * _speedMultiplier;
        _y += _dirY * BASE_VY * _speedMultiplier;

        var hitX = false;
        var hitY = false;
        if (_x <= _minX) {
            _x = _minX;
            _dirX = 1;
            hitX = true;
        } else if (_x + _logoW >= _maxX) {
            _x = _maxX - _logoW;
            _dirX = -1;
            hitX = true;
        }
        if (_y <= _minY) {
            _y = _minY;
            _dirY = 1;
            hitY = true;
        } else if (_y + _logoH >= _maxY) {
            _y = _maxY - _logoH;
            _dirY = -1;
            hitY = true;
        }

        if (_flash > 0) {
            _flash -= 1;
        }
        if (!hitX && !hitY) {
            return;
        }
        _colorIndex = (_colorIndex + 1) % COLORS.size();
        if ((hitX && hitY) ||
            (hitX && nearWall(_y - _minY, _maxY - _y - _logoH)) ||
            (hitY && nearWall(_x - _minX, _maxX - _x - _logoW))) {
            _corners += 1;
            _flash = FLASH_TICKS;
            if (HighScores.submit(HIGH_SCORE_KEY, _corners)) {
                _best = _corners;
            }
        }
    }

    private function nearWall(gapA as Float, gapB as Float) as Boolean {
        var slack = CORNER_SLACK * _speedMultiplier;
        return gapA <= slack || gapB <= slack;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var flashing = _flash > 0;
        dc.setPenWidth(2);
        dc.setColor(flashing && (_flash / 4) % 2 == 0 ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(_minX.toNumber(), _minY.toNumber(), (_maxX - _minX).toNumber(), (_maxY - _minY).toNumber());

        dc.setColor(COLORS[_colorIndex] as Number, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(_x.toNumber(), _y.toNumber(), _logoW.toNumber(), _logoH.toNumber(), 5);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText((_x + _logoW / 2).toNumber(), (_y + _logoH / 2).toNumber(), Graphics.FONT_XTINY, "DVD",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var title = flashing ? "CORNER!" : "Corners " + _corners + "  Best " + _best;
        dc.drawText(_width / 2, (_minY - 24).toNumber(), Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_CENTER);
        if (_paused) {
            dc.drawText(_width / 2, ((_minY + _maxY) / 2).toNumber(), Graphics.FONT_SMALL, "Paused",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

}
