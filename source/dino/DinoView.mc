import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.System;
import Toybox.Math;
import Toybox.Lang;

class DinoView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "dino_high";
    private const GRAVITY = 0.9;
    private const JUMP_VELOCITY = -11.0;
    private const DINO_SIZE = 14;
    private const OBSTACLE_WIDTH = 10;
    private const OBSTACLE_MIN_HEIGHT = 14;
    private const OBSTACLE_MAX_HEIGHT = 30;
    private const BASE_SPEED = 3.5;
    private const BASE_MAX_SPEED = 8.0;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _isRound as Boolean = false;
    private var _centerX as Float = 0.0;
    private var _centerY as Float = 0.0;
    private var _radius as Float = 0.0;

    private var _dinoX as Float = 0.0;
    private var _groundY as Float = 0.0;
    private var _dinoY as Float = 0.0;
    private var _dinoVelY as Float = 0.0;
    private var _isJumping as Boolean = false;

    private var _obstacleX as Array<Float>;
    private var _obstacleHeight as Array<Number>;
    private var _obstaclePassed as Array<Boolean>;
    private var _spawnCooldown as Number = 0;
    private var _spawnGapMultiplier as Float = 1.0;
    private var _heightMultiplier as Float = 1.0;
    private var _speedMultiplier as Float = 1.0;

    private var _speed as Float = BASE_SPEED;
    private var _score as Number = 0;
    private var _highScore as Number = 0;
    private var _gameOver as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _obstacleX = [];
        _obstacleHeight = [];
        _obstaclePassed = [];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function setSpawnFrequency(spawnGapMultiplier as Float) as Void {
        _spawnGapMultiplier = spawnGapMultiplier;
    }

    function setCactusHeight(heightMultiplier as Float) as Void {
        _heightMultiplier = heightMultiplier;
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _centerX = _width / 2.0;
        _centerY = _height / 2.0;
        _radius = (_width < _height ? _width : _height) / 2.0;
        _isRound = (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND);
        _dinoX = _width * 0.2;
        _groundY = _centerY + verticalHalfRangeAt(_dinoX) - 4.0;
        resetGame();
    }

    // Half the vertical space available at horizontal position x, accounting
    // for the round bezel (full center-to-edge height on rectangular screens).
    private function verticalHalfRangeAt(x as Float) as Float {
        if (!_isRound) {
            return _centerY;
        }
        var dx = x - _centerX;
        var distSq = _radius * _radius - dx * dx;
        if (distSq <= 0) {
            return 0.0;
        }
        return Math.sqrt(distSq).toFloat();
    }

    function resetGame() as Void {
        _dinoY = _groundY - DINO_SIZE;
        _dinoVelY = 0.0;
        _isJumping = false;
        _obstacleX = [];
        _obstacleHeight = [];
        _obstaclePassed = [];
        _spawnCooldown = 30;
        _speed = BASE_SPEED * _speedMultiplier;
        _score = 0;
        _gameOver = false;
        WatchUi.requestUpdate();
    }

    function jump() as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        if (!_isJumping) {
            _dinoVelY = JUMP_VELOCITY;
            _isJumping = true;
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

    private function spawnObstacle() as Void {
        var minH = (OBSTACLE_MIN_HEIGHT * _heightMultiplier).toNumber();
        var maxH = (OBSTACLE_MAX_HEIGHT * _heightMultiplier).toNumber();
        if (maxH <= minH) {
            maxH = minH + 1;
        }
        var height = minH + (Math.rand() % (maxH - minH)).abs();
        _obstacleX.add(_width.toFloat() + 20.0);
        _obstacleHeight.add(height);
        _obstaclePassed.add(false);
        _spawnCooldown = (( 40 + (Math.rand() % 40).abs()) * _spawnGapMultiplier).toNumber();
    }

    private function updateGame() as Void {
        if (_isJumping) {
            _dinoVelY += GRAVITY;
            _dinoY += _dinoVelY;
            if (_dinoY >= _groundY - DINO_SIZE) {
                _dinoY = _groundY - DINO_SIZE;
                _dinoVelY = 0.0;
                _isJumping = false;
            }
        }

        var maxSpeed = BASE_MAX_SPEED * _speedMultiplier;
        if (_speed < maxSpeed) {
            _speed += 0.0025;
        }

        _spawnCooldown -= 1;
        if (_spawnCooldown <= 0) {
            spawnObstacle();
        }

        var kept = [] as Array<Float>;
        var keptHeight = [] as Array<Number>;
        var keptPassed = [] as Array<Boolean>;
        var i = 0;
        while (i < _obstacleX.size()) {
            var ox = _obstacleX[i] - _speed;
            var oh = _obstacleHeight[i];
            var passed = _obstaclePassed[i];

            if (!passed && ox + OBSTACLE_WIDTH < _dinoX) {
                passed = true;
                _score += 1;
            }

            if (_dinoX + DINO_SIZE > ox && _dinoX < ox + OBSTACLE_WIDTH) {
                if (_dinoY + DINO_SIZE > _groundY - oh) {
                    markGameOver();
                }
            }

            if (ox + OBSTACLE_WIDTH >= 0) {
                kept.add(ox);
                keptHeight.add(oh);
                keptPassed.add(passed);
            }
            i++;
        }
        _obstacleX = kept;
        _obstacleHeight = keptHeight;
        _obstaclePassed = keptPassed;
    }

    // A small T-rex silhouette instead of a plain square: body, head with an
    // eye, a stubby arm, a running leg, and a tail trailing behind.
    private function drawDino(dc as Dc) as Void {
        var x = _dinoX.toNumber();
        var y = _dinoY.toNumber();
        var s = DINO_SIZE;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        // Body/torso.
        dc.fillRectangle(x + s / 4, y + s / 3, s * 3 / 4, s * 2 / 3);
        // Head, sitting a bit above and ahead of the torso.
        dc.fillRectangle(x + s / 2, y, s / 2, s / 2);
        // Tail trailing off the back.
        dc.fillPolygon([
            [x + s / 4, y + s / 2],
            [x, y + s / 2 - 2],
            [x + s / 4, y + s / 2 + 3]
        ] as Array<[Numeric, Numeric]>);
        // Leg.
        dc.fillRectangle(x + s / 2, y + s, s / 4, s / 4);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x + s * 7 / 8, y + s / 5, 1);
    }

    // A saguaro-style cactus: a central trunk with two arms, instead of a
    // plain green rectangle.
    private function drawCactus(dc as Dc, ox as Number, topY as Number, oh as Number) as Void {
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        var trunkW = OBSTACLE_WIDTH / 2;
        var trunkX = ox + (OBSTACLE_WIDTH - trunkW) / 2;
        dc.fillRectangle(trunkX, topY, trunkW, oh);

        var armY = topY + oh / 3;
        var armH = oh / 3;
        var armW = OBSTACLE_WIDTH / 4;
        if (armW < 2) {
            armW = 2;
        }
        // Left arm: sticks out then turns upward.
        dc.fillRectangle(ox, armY + armH / 2, trunkX - ox, armW);
        dc.fillRectangle(ox, armY - armH / 2, armW, armH);
        // Right arm, mirrored.
        var rightArmX = trunkX + trunkW;
        dc.fillRectangle(rightArmX, armY + armH / 2, ox + OBSTACLE_WIDTH - rightArmX, armW);
        dc.fillRectangle(ox + OBSTACLE_WIDTH - armW, armY - armH / 2, armW, armH);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, _groundY.toNumber(), _width, _groundY.toNumber());

        var i = 0;
        while (i < _obstacleX.size()) {
            var ox = _obstacleX[i].toNumber();
            var oh = _obstacleHeight[i];
            drawCactus(dc, ox, (_groundY - oh).toNumber(), oh);
            i++;
        }

        drawDino(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_gameOver) {
            dc.drawText(_width / 2, _height / 2 - 10, Graphics.FONT_SMALL, "Game Over", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_width / 2, _height / 2 + 10, Graphics.FONT_TINY, "Score: " + _score.toString() + "  Best: " + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(_width / 2, 2, Graphics.FONT_TINY, _score.toString() + "  Best:" + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
