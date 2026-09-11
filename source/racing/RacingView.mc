import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Math;
import Toybox.Lang;

// Endless three-lane racer: switch lanes to avoid the bot cars coming down
// the road. Score is how many you dodge; the road speeds up over time, same
// ramp-up feel as Dino's obstacle speed.
class RacingView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "racing_high";
    private const LANES = 3;
    private const CAR_WIDTH = 16;
    private const CAR_HEIGHT = 20;
    private const LANE_EASE = 0.4;
    private const BASE_SPEED = 2.5;
    private const BASE_MAX_SPEED = 6.5;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _roadLeft as Float = 0.0;
    private var _laneWidth as Float = 0.0;
    private var _roadTop as Float = 0.0;
    private var _roadBottom as Float = 0.0;
    private var _playerY as Float = 0.0;

    private var _laneIndex as Number = 1;
    private var _carX as Float = 0.0;

    private var _botLane as Array<Number>;
    private var _botY as Array<Float>;
    private var _botPassed as Array<Boolean>;
    private var _spawnCooldown as Number = 0;
    private var _spawnGapMultiplier as Float = 1.0;
    private var _speedMultiplier as Float = 1.0;

    private var _speed as Float = BASE_SPEED;
    private var _score as Number = 0;
    private var _highScore as Number = 0;
    private var _gameOver as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _botLane = [];
        _botY = [];
        _botPassed = [];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function setDifficulty(spawnGapMultiplier as Float) as Void {
        _spawnGapMultiplier = spawnGapMultiplier;
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        var roadWidth = _width * 0.62;
        _roadLeft = (_width - roadWidth) / 2.0;
        _laneWidth = roadWidth / LANES;
        _roadTop = 18.0;
        _roadBottom = _height - 6.0;
        _playerY = _roadBottom - CAR_HEIGHT - 4.0;
        resetGame();
    }

    private function laneCenterX(lane as Number) as Float {
        return _roadLeft + _laneWidth * (lane + 0.5);
    }

    function resetGame() as Void {
        _laneIndex = 1;
        _carX = laneCenterX(_laneIndex);
        _botLane = [];
        _botY = [];
        _botPassed = [];
        _spawnCooldown = 30;
        _speed = BASE_SPEED * _speedMultiplier;
        _score = 0;
        _gameOver = false;
        WatchUi.requestUpdate();
    }

    // Also doubles as the game-over restart, same as Dino's jump().
    function moveLane(dir as Number) as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        _laneIndex += dir;
        if (_laneIndex < 0) {
            _laneIndex = 0;
        } else if (_laneIndex >= LANES) {
            _laneIndex = LANES - 1;
        }
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

    private function spawnBot() as Void {
        _botLane.add((Math.rand() % LANES).abs());
        _botY.add(_roadTop - CAR_HEIGHT);
        _botPassed.add(false);
        _spawnCooldown = ((40 + (Math.rand() % 40).abs()) * _spawnGapMultiplier).toNumber();
    }

    private function updateGame() as Void {
        var targetX = laneCenterX(_laneIndex);
        _carX += (targetX - _carX) * LANE_EASE;

        var maxSpeed = BASE_MAX_SPEED * _speedMultiplier;
        if (_speed < maxSpeed) {
            _speed += 0.002;
        }

        _spawnCooldown -= 1;
        if (_spawnCooldown <= 0) {
            spawnBot();
        }

        var keptLane = [] as Array<Number>;
        var keptY = [] as Array<Float>;
        var keptPassed = [] as Array<Boolean>;
        var i = 0;
        while (i < _botY.size()) {
            var by = _botY[i] + _speed;
            var lane = _botLane[i];
            var passed = _botPassed[i];

            if (!passed && by > _playerY + CAR_HEIGHT) {
                passed = true;
                _score += 1;
            }

            var bx = laneCenterX(lane);
            var xOverlap = (_carX - CAR_WIDTH / 2.0 < bx + CAR_WIDTH / 2.0) && (_carX + CAR_WIDTH / 2.0 > bx - CAR_WIDTH / 2.0);
            var yOverlap = (by < _playerY + CAR_HEIGHT) && (by + CAR_HEIGHT > _playerY);
            if (xOverlap && yOverlap) {
                markGameOver();
            }

            if (by < _roadBottom + CAR_HEIGHT) {
                keptLane.add(lane);
                keptY.add(by);
                keptPassed.add(passed);
            }
            i++;
        }
        _botLane = keptLane;
        _botY = keptY;
        _botPassed = keptPassed;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var roadWidth = _laneWidth * LANES;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        dc.fillRectangle(_roadLeft, _roadTop, roadWidth, _roadBottom - _roadTop);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var lane;
        for (lane = 1; lane < LANES; lane++) {
            var x = (_roadLeft + _laneWidth * lane).toNumber();
            dc.drawLine(x, _roadTop.toNumber(), x, _roadBottom.toNumber());
        }

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        var i = 0;
        while (i < _botY.size()) {
            var bx = laneCenterX(_botLane[i]);
            dc.fillRectangle(bx - CAR_WIDTH / 2.0, _botY[i], CAR_WIDTH, CAR_HEIGHT);
            i++;
        }

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        dc.fillRectangle(_carX - CAR_WIDTH / 2.0, _playerY, CAR_WIDTH, CAR_HEIGHT);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_gameOver) {
            dc.drawText(_width / 2, _height / 2 - 10, Graphics.FONT_SMALL, "Crashed!", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_width / 2, _height / 2 + 10, Graphics.FONT_TINY, "Score: " + _score.toString() + "  Best: " + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(_width / 2, 2, Graphics.FONT_TINY, _score.toString() + "  Best:" + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
