import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.System;
import Toybox.Math;
import Toybox.Lang;

class DinoView extends WatchUi.View {

    private const GRAVITY = 0.9;
    private const JUMP_VELOCITY = -11.0;
    private const DINO_SIZE = 14;
    private const OBSTACLE_WIDTH = 10;
    private const OBSTACLE_MIN_HEIGHT = 14;
    private const OBSTACLE_MAX_HEIGHT = 30;
    private const BASE_SPEED = 3.5;
    private const MAX_SPEED = 8.0;

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

    private var _speed as Float = BASE_SPEED;
    private var _score as Number = 0;
    private var _gameOver as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _obstacleX = [];
        _obstacleHeight = [];
        _obstaclePassed = [];
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
        _speed = BASE_SPEED;
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

    private function spawnObstacle() as Void {
        var height = OBSTACLE_MIN_HEIGHT + (Math.rand() % (OBSTACLE_MAX_HEIGHT - OBSTACLE_MIN_HEIGHT)).abs();
        _obstacleX.add(_width.toFloat() + 20.0);
        _obstacleHeight.add(height);
        _obstaclePassed.add(false);
        _spawnCooldown = 40 + (Math.rand() % 40).abs();
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

        if (_speed < MAX_SPEED) {
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
                    _gameOver = true;
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

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, _groundY.toNumber(), _width, _groundY.toNumber());

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        var i = 0;
        while (i < _obstacleX.size()) {
            var ox = _obstacleX[i].toNumber();
            var oh = _obstacleHeight[i];
            dc.fillRectangle(ox, (_groundY - oh).toNumber(), OBSTACLE_WIDTH, oh);
            i++;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(_dinoX.toNumber(), _dinoY.toNumber(), DINO_SIZE, DINO_SIZE);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_gameOver) {
            dc.drawText(_width / 2, _height / 2 - 10, Graphics.FONT_SMALL, "Game Over", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_width / 2, _height / 2 + 10, Graphics.FONT_TINY, "Score: " + _score.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(_width / 2, 2, Graphics.FONT_TINY, _score.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
