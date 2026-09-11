import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.Math;

// Keep the ball on the watch face. Tilting the watch (read from the
// accelerometer) rolls the ball downhill just like a real ball on an
// unlevel surface; it "falls off" and ends the round once it reaches the
// edge of the board.
class BalanceBallView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "balanceball_best_ms";
    private const BASE_TICK_MS = 50;
    private const TILT_ACCEL = 900.0; // px/s^2 at full tilt deflection
    private const DAMPING = 0.985;

    private var _boundaryFraction as Float = 0.72;
    private var _speedMultiplier as Float = 1.0;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _centerX as Float = 0.0;
    private var _centerY as Float = 0.0;
    private var _boundaryRadius as Float = 0.0;
    private var _ballRadius as Float = 8.0;

    private var _ballX as Float = 0.0;
    private var _ballY as Float = 0.0;
    private var _vx as Float = 0.0;
    private var _vy as Float = 0.0;

    private var _accelX as Number = 0;
    private var _accelY as Number = 0;
    private var _calX as Number = 0;
    private var _calY as Number = 0;

    private var _elapsedMs as Number = 0;
    private var _highScoreMs as Number = 0;
    private var _fallen as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _highScoreMs = HighScores.get(HIGH_SCORE_KEY);
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _centerX = _width / 2.0;
        _centerY = _height / 2.0;
        _ballRadius = (_width < _height ? _width : _height) * 0.045;
        layoutBoundary();
        resetGame();
    }

    private function layoutBoundary() as Void {
        var minDim = (_width < _height ? _width : _height);
        _boundaryRadius = minDim / 2.0 * _boundaryFraction;
    }

    function setDifficulty(boundaryFraction as Float) as Void {
        _boundaryFraction = boundaryFraction;
        if (_width > 0) {
            layoutBoundary();
        }
        resetGame();
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
    }

    function resetGame() as Void {
        _ballX = _centerX;
        _ballY = _centerY;
        _vx = 0.0;
        _vy = 0.0;
        _elapsedMs = 0;
        _fallen = false;
        calibrate();
        WatchUi.requestUpdate();
    }

    // Captures the current tilt as "flat" so the ball doesn't roll just
    // because the watch happens to be worn at a slight natural angle.
    private function calibrate() as Void {
        _calX = _accelX;
        _calY = _accelY;
    }

    function onSensorInfo(info as Sensor.Info) as Void {
        var accel = info.accel;
        if (accel != null) {
            _accelX = accel[0];
            _accelY = accel[1];
        }
    }

    // Fallback control for devices/simulators without live accelerometer
    // input: each press nudges the ball like a firm tilt in that direction.
    function nudge(dx as Float, dy as Float) as Void {
        _vx += dx;
        _vy += dy;
    }

    function onShow() as Void {
        try {
            Sensor.enableSensorEvents(method(:onSensorInfo));
        } catch (e) {
            // No accelerometer available; the key-nudge fallback still works.
        }
        restartTimer();
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        Sensor.enableSensorEvents(null);
    }

    private function restartTimer() as Void {
        if (_timer != null) {
            _timer.stop();
        }
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), BASE_TICK_MS, true);
    }

    function onTimerTick() as Void {
        if (!_fallen) {
            updateGame();
        }
        WatchUi.requestUpdate();
    }

    private function updateGame() as Void {
        var dt = BASE_TICK_MS / 1000.0;
        var tiltX = TiltSensor.normalize(_accelX, _calX);
        var tiltY = TiltSensor.normalize(_accelY, _calY);

        // Y is inverted: tilting the top of the watch down (positive accel Y)
        // should roll the ball up the screen (negative Dc y), not down.
        _vx += tiltX * TILT_ACCEL * _speedMultiplier * dt;
        _vy -= tiltY * TILT_ACCEL * _speedMultiplier * dt;
        _vx *= DAMPING;
        _vy *= DAMPING;

        _ballX += _vx * dt;
        _ballY += _vy * dt;

        var dx = _ballX - _centerX;
        var dy = _ballY - _centerY;
        var dist = Math.sqrt(dx * dx + dy * dy);
        if (dist > _boundaryRadius - _ballRadius) {
            markFallen();
            return;
        }

        _elapsedMs += BASE_TICK_MS;
    }

    private function markFallen() as Void {
        _fallen = true;
        HighScores.submit(HIGH_SCORE_KEY, _elapsedMs);
        _highScoreMs = HighScores.get(HIGH_SCORE_KEY);
    }

    private function formatSeconds(ms as Number) as String {
        var tenths = (ms / 100) % 10;
        var secs = ms / 1000;
        return secs.toString() + "." + tenths.toString() + "s";
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(_centerX, _centerY, _boundaryRadius);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var label = _fallen
            ? "Fell! " + formatSeconds(_elapsedMs) + "  Best:" + formatSeconds(_highScoreMs)
            : formatSeconds(_elapsedMs) + "  Best:" + formatSeconds(_highScoreMs);
        dc.drawText(_centerX, 2, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var ballColor = _fallen ? Graphics.COLOR_RED : Graphics.COLOR_BLUE;
        dc.setColor(ballColor, ballColor);
        dc.fillCircle(_ballX, _ballY, _ballRadius);
    }

}
