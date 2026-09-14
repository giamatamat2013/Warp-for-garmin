import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Math;

// Pinball: bounce the ball off two flippers to hit bumpers and score.
// LEFT key / left-side tap controls the left flipper; RIGHT key / right-side
// tap controls the right flipper. Ball launches automatically on game start.
class PinballView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "pinball_high";
    private const BALL_RADIUS    = 5;
    private const GRAVITY        = 280.0; // px/s^2
    private const DAMPING        = 0.70;  // velocity retained on wall bounce
    private const FLIPPER_LEN    = 28;    // half-length of each flipper arm
    private const FLIPPER_W      = 4;     // half-thickness drawn
    private const FLIPPER_REST   = 30;    // angle (deg) drooped down from horizontal
    private const FLIPPER_ACTIVE = -20;   // angle (deg) raised up from horizontal

    private var _width  as Number = 0;
    private var _height as Number = 0;

    // Ball state
    private var _bx as Float = 0.0;
    private var _by as Float = 0.0;
    private var _vx as Float = 0.0;
    private var _vy as Float = 0.0;

    // Flippers (symmetric about centre)
    private var _flipperBaseY    as Number = 0;   // Y of flipper pivot
    private var _lFlipX         as Number = 0;   // left flipper pivot X
    private var _rFlipX         as Number = 0;   // right flipper pivot X
    private var _lActive        as Boolean = false;
    private var _rActive        as Boolean = false;
    // Flash ticks for bumpers
    private var _bumperFlash    as Array<Number>;  // countdown ticks each bumper flashes

    // Bumpers: fixed circles
    private var _bumperX as Array<Number>;
    private var _bumperY as Array<Number>;
    private const BUMPER_R = 10;

    private var _score     as Number = 0;
    private var _highScore as Number = 0;
    private var _lives     as Number = 3;
    private var _gameOver  as Boolean = false;
    private var _endTicks  as Number = 0;
    private const END_TICKS = 60; // ~2s at 33ms

    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _bumperX = [];
        _bumperY = [];
        _bumperFlash = [];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function onLayout(dc as Dc) as Void {
        _width  = dc.getWidth();
        _height = dc.getHeight();
        layoutField();
        resetGame();
    }

    private function layoutField() as Void {
        _flipperBaseY = _height - 30;
        var cx = _width / 2;
        _lFlipX = cx - 18;
        _rFlipX = cx + 18;

        // Place 5 bumpers in a roughly pentagonal arrangement in the upper half
        _bumperX = [];
        _bumperY = [];
        _bumperFlash = [];
        var midX = _width / 2;
        var topY = (_height * 0.20).toNumber();
        var r1 = (_width * 0.28).toNumber();
        var r2 = (_width * 0.16).toNumber();
        // Top centre
        _bumperX.add(midX);
        _bumperY.add(topY);
        _bumperFlash.add(0);
        // Upper-left, upper-right
        _bumperX.add(midX - r1);
        _bumperY.add(topY + 30);
        _bumperFlash.add(0);
        _bumperX.add(midX + r1);
        _bumperY.add(topY + 30);
        _bumperFlash.add(0);
        // Lower-left, lower-right
        _bumperX.add(midX - r2);
        _bumperY.add(topY + 72);
        _bumperFlash.add(0);
        _bumperX.add(midX + r2);
        _bumperY.add(topY + 72);
        _bumperFlash.add(0);
    }

    function resetGame() as Void {
        _bx = (_width / 2).toFloat();
        _by = (_height * 0.60).toFloat();
        // Launch with a random slight angle upward
        var rnd = ((Math.rand() % 200).abs() - 100) / 100.0; // -1..1
        _vx = rnd * 40.0;
        _vy = -160.0;
        _lActive = false;
        _rActive = false;
        _score = 0;
        _lives = 3;
        _gameOver = false;
        _endTicks = 0;
        var i = 0;
        while (i < _bumperFlash.size()) {
            _bumperFlash[i] = 0;
            i++;
        }
        WatchUi.requestUpdate();
    }

    function setLeftFlipper(active as Boolean) as Void {
        _lActive = active;
    }

    function setRightFlipper(active as Boolean) as Void {
        _rActive = active;
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
        if (_gameOver) {
            _endTicks += 1;
            if (_endTicks >= END_TICKS) {
                resetGame();
            }
        } else {
            updateGame();
        }
        WatchUi.requestUpdate();
    }

    private function updateGame() as Void {
        var dt = 0.033;
        // Gravity
        _vy += GRAVITY * dt;

        // Move
        _bx += _vx * dt;
        _by += _vy * dt;

        // Tick down flash counters
        var fi = 0;
        while (fi < _bumperFlash.size()) {
            if (_bumperFlash[fi] > 0) { _bumperFlash[fi] -= 1; }
            fi++;
        }

        // Wall collisions
        if (_bx - BALL_RADIUS < 0) {
            _bx = BALL_RADIUS.toFloat();
            _vx = (_vx * -DAMPING).abs();
        } else if (_bx + BALL_RADIUS > _width) {
            _bx = (_width - BALL_RADIUS).toFloat();
            _vx = -(_vx * DAMPING).abs();
        }
        if (_by - BALL_RADIUS < 0) {
            _by = BALL_RADIUS.toFloat();
            _vy = (_vy * -DAMPING).abs();
        }

        // Bumper collisions
        var bi = 0;
        while (bi < _bumperX.size()) {
            var dx = _bx - _bumperX[bi];
            var dy = _by - _bumperY[bi];
            var distSq = dx * dx + dy * dy;
            var minDist = (BALL_RADIUS + BUMPER_R).toFloat();
            if (distSq < minDist * minDist && distSq > 0.01) {
                var dist = Math.sqrt(distSq).toFloat();
                // Push ball out and reflect velocity
                var nx = dx / dist;
                var ny = dy / dist;
                _bx = _bumperX[bi] + nx * minDist;
                _by = _bumperY[bi] + ny * minDist;
                // Reflect velocity with a speed boost (bumpers propel the ball)
                var dot = _vx * nx + _vy * ny;
                _vx = (_vx - 2.0 * dot * nx) * 1.1;
                _vy = (_vy - 2.0 * dot * ny) * 1.1;
                // Cap speed
                var spd = Math.sqrt(_vx * _vx + _vy * _vy).toFloat();
                if (spd > 320.0) {
                    _vx = _vx / spd * 320.0;
                    _vy = _vy / spd * 320.0;
                }
                _score += 10;
                _bumperFlash[bi] = 6;
            }
            bi++;
        }

        // Flipper collisions
        collideFlipper(_lFlipX, _flipperBaseY, _lActive, false);
        collideFlipper(_rFlipX, _flipperBaseY, _rActive, true);

        // Ball fell below flippers
        if (_by - BALL_RADIUS > _height + 5) {
            _lives -= 1;
            if (_lives <= 0) {
                _gameOver = true;
                HighScores.submit(HIGH_SCORE_KEY, _score);
                _highScore = HighScores.get(HIGH_SCORE_KEY);
            } else {
                // Respawn
                _bx = (_width / 2).toFloat();
                _by = (_height * 0.60).toFloat();
                var rnd2 = ((Math.rand() % 200).abs() - 100) / 100.0;
                _vx = rnd2 * 40.0;
                _vy = -160.0;
            }
        }
    }

    // Simple segment-circle collision for each flipper arm.
    // pivotX/Y is the hinge. isRight=true for right flipper (mirrored angle sign).
    private function collideFlipper(pivotX as Number, pivotY as Number, active as Boolean, isRight as Boolean) as Void {
        var angleDeg = active ? FLIPPER_ACTIVE : FLIPPER_REST;
        if (isRight) { angleDeg = -angleDeg; }
        var angleRad = angleDeg * Math.PI / 180.0;
        // Direction vector from pivot toward tip
        var dirX = Math.cos(angleRad).toFloat();
        var dirY = Math.sin(angleRad).toFloat();
        if (!isRight) { dirX = -dirX; } // left flipper extends to the left

        var tipX = pivotX + dirX * FLIPPER_LEN;
        var tipY = pivotY + dirY * FLIPPER_LEN;

        // Closest point on segment [pivot..tip] to ball
        var ax = _bx - pivotX;
        var ay = _by - pivotY;
        var bx2 = tipX - pivotX;
        var by2 = tipY - pivotY;
        var lenSq = bx2 * bx2 + by2 * by2;
        var t = (ax * bx2 + ay * by2) / lenSq;
        if (t < 0.0) { t = 0.0; }
        if (t > 1.0) { t = 1.0; }
        var cx = pivotX + t * bx2;
        var cy = pivotY + t * by2;

        var dx = _bx - cx;
        var dy = _by - cy;
        var distSq = dx * dx + dy * dy;
        var minD = (BALL_RADIUS + FLIPPER_W).toFloat();
        if (distSq < minD * minD && distSq > 0.01 && _vy > 0) {
            var dist = Math.sqrt(distSq).toFloat();
            var nx = dx / dist;
            var ny = dy / dist;
            _bx = cx + nx * minD;
            _by = cy + ny * minD;
            var dot = _vx * nx + _vy * ny;
            _vx = _vx - 2.0 * dot * nx;
            _vy = (_vy - 2.0 * dot * ny) * DAMPING;
            // Active flipper adds upward kick
            if (active) {
                _vy -= 60.0;
            }
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // HUD
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_width / 2, 2, Graphics.FONT_XTINY,
            "Score:" + _score.toString() + " Lives:" + _lives.toString() + " Best:" + _highScore.toString(),
            Graphics.TEXT_JUSTIFY_CENTER);

        // Outer walls
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 0, 0, _height);
        dc.drawLine(_width - 1, 0, _width - 1, _height);

        // Bumpers
        var bi = 0;
        while (bi < _bumperX.size()) {
            if (_bumperFlash[bi] > 0) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_YELLOW);
                dc.fillCircle(_bumperX[bi], _bumperY[bi], BUMPER_R);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(_bumperX[bi], _bumperY[bi], BUMPER_R);
            } else {
                dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_DK_BLUE);
                dc.fillCircle(_bumperX[bi], _bumperY[bi], BUMPER_R);
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(_bumperX[bi], _bumperY[bi], BUMPER_R);
            }
            bi++;
        }

        // Flippers
        drawFlipper(dc, _lFlipX, _flipperBaseY, _lActive, false);
        drawFlipper(dc, _rFlipX, _flipperBaseY, _rActive, true);

        // Ball
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillCircle(_bx.toNumber(), _by.toNumber(), BALL_RADIUS);

        // Game Over overlay
        if (_gameOver) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_width / 2, _height / 2 - 10, Graphics.FONT_SMALL, "Game Over",
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_width / 2, _height / 2 + 10, Graphics.FONT_TINY,
                "Score: " + _score.toString() + "  Best: " + _highScore.toString(),
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function drawFlipper(dc as Graphics.Dc, pivotX as Number, pivotY as Number, active as Boolean, isRight as Boolean) as Void {
        var angleDeg = active ? FLIPPER_ACTIVE : FLIPPER_REST;
        if (isRight) { angleDeg = -angleDeg; }
        var angleRad = angleDeg * Math.PI / 180.0;
        var dirX = Math.cos(angleRad).toFloat();
        var dirY = Math.sin(angleRad).toFloat();
        if (!isRight) { dirX = -dirX; }
        var tipX = (pivotX + dirX * FLIPPER_LEN).toNumber();
        var tipY = (pivotY + dirY * FLIPPER_LEN).toNumber();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(FLIPPER_W * 2);
        dc.drawLine(pivotX, pivotY, tipX, tipY);
        dc.setPenWidth(2);
        dc.fillCircle(pivotX, pivotY, FLIPPER_W);
    }

}

