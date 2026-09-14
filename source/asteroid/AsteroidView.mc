import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Math;

// Asteroid Dodge: spaceship dodging descending asteroids.
// Steer left/right with keys or drag on touch screens.
// Score increases for each asteroid successfully evaded.
class AsteroidView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "asteroid_high";
    private const SHIP_W = 18;
    private const SHIP_H = 16;
    private const BASE_SPEED = 2.0;
    private const MAX_SPEED = 6.5;

    private var _width as Number = 0;
    private var _height as Number = 0;

    private var _shipX as Float = 0.0;
    private var _shipY as Float = 0.0;

    private var _astX as Array<Float>;
    private var _astY as Array<Float>;
    private var _astR as Array<Number>;
    private var _astPassed as Array<Boolean>;

    private var _speed as Float = BASE_SPEED;
    private var _speedMultiplier as Float = 1.0;
    private var _spawnCooldown as Number = 0;

    private var _score as Number = 0;
    private var _highScore as Number = 0;
    private var _gameOver as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _astX = [];
        _astY = [];
        _astR = [];
        _astPassed = [];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _shipY = (_height - 32).toFloat();
        resetGame();
    }

    function resetGame() as Void {
        _shipX = (_width / 2.0) - (SHIP_W / 2.0);
        _astX = [];
        _astY = [];
        _astR = [];
        _astPassed = [];
        _spawnCooldown = 20;
        _speed = BASE_SPEED * _speedMultiplier;
        _score = 0;
        _gameOver = false;
        WatchUi.requestUpdate();
    }

    function moveShip(dx as Float) as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        setShipCenterX((_shipX + SHIP_W / 2.0 + dx).toNumber());
    }

    function setShipCenterX(cx as Number) as Void {
        var x = cx - SHIP_W / 2.0;
        var minX = 8.0;
        var maxX = (_width - SHIP_W - 8).toFloat();
        if (x < minX) { x = minX; }
        if (x > maxX) { x = maxX; }
        _shipX = x;
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
        if (!_gameOver) {
            updateGame();
        }
        WatchUi.requestUpdate();
    }

    private function markGameOver() as Void {
        _gameOver = true;
        HighScores.submit(HIGH_SCORE_KEY, _score);
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    private function spawnAsteroid() as Void {
        var r = 7 + (Math.rand() % 8).abs();
        var minX = r + 10;
        var maxX = _width - r - 10;
        var span = maxX - minX;
        if (span < 1) { span = 1; }
        var x = minX + (Math.rand() % span).abs();

        _astX.add(x.toFloat());
        _astY.add(-r.toFloat() - 2.0);
        _astR.add(r);
        _astPassed.add(false);

        _spawnCooldown = 20 + (Math.rand() % 25).abs();
    }

    private function updateGame() as Void {
        var maxSpd = MAX_SPEED * _speedMultiplier;
        if (_speed < maxSpd) {
            _speed += 0.002;
        }

        _spawnCooldown -= 1;
        if (_spawnCooldown <= 0 && _astX.size() < 6) {
            spawnAsteroid();
        }

        var keptX = [] as Array<Float>;
        var keptY = [] as Array<Float>;
        var keptR = [] as Array<Number>;
        var keptPassed = [] as Array<Boolean>;

        var shipCX = _shipX + SHIP_W / 2.0;
        var shipCY = _shipY + SHIP_H / 2.0;

        var i = 0;
        while (i < _astX.size()) {
            var ay = _astY[i] + _speed;
            var ax = _astX[i];
            var ar = _astR[i];
            var passed = _astPassed[i];

            if (!passed && ay > _shipY + SHIP_H) {
                passed = true;
                _score += 1;
            }

            // Collision check
            var dx = (shipCX - ax).abs();
            var dy = (shipCY - ay).abs();
            if (dx < (SHIP_W / 2.0 + ar * 0.8) && dy < (SHIP_H / 2.0 + ar * 0.8)) {
                markGameOver();
            }

            if (ay - ar < _height + 10) {
                keptX.add(ax);
                keptY.add(ay);
                keptR.add(ar);
                keptPassed.add(passed);
            }
            i++;
        }
        _astX = keptX;
        _astY = keptY;
        _astR = keptR;
        _astPassed = keptPassed;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Draw asteroids
        var i = 0;
        while (i < _astX.size()) {
            var ax = _astX[i].toNumber();
            var ay = _astY[i].toNumber();
            var ar = _astR[i];

            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.fillCircle(ax, ay, ar);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(ax, ay, ar);
            // small crater
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.fillCircle(ax - ar / 3, ay - ar / 3, ar > 6 ? 2 : 1);
            i++;
        }

        // Draw Ship
        var sx = _shipX.toNumber();
        var sy = _shipY.toNumber();

        // Thruster flame
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_ORANGE);
        dc.fillPolygon([
            [sx + SHIP_W / 2 - 3, sy + SHIP_H],
            [sx + SHIP_W / 2 + 3, sy + SHIP_H],
            [sx + SHIP_W / 2, sy + SHIP_H + 6]
        ] as Array<[Numeric, Numeric]>);

        // Ship body
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        dc.fillPolygon([
            [sx + SHIP_W / 2, sy],
            [sx, sy + SHIP_H],
            [sx + SHIP_W / 2, sy + SHIP_H - 3],
            [sx + SHIP_W, sy + SHIP_H]
        ] as Array<[Numeric, Numeric]>);

        // Cockpit
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillCircle(sx + SHIP_W / 2, sy + SHIP_H / 2, 2);

        // HUD / Game Over
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_gameOver) {
            dc.drawText(_width / 2, _height / 2 - 10, Graphics.FONT_SMALL, "Destroyed!", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_width / 2, _height / 2 + 10, Graphics.FONT_TINY, "Score: " + _score.toString() + "  Best: " + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(_width / 2, 2, Graphics.FONT_XTINY, "Score:" + _score.toString() + "  Best:" + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
