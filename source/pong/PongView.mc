import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.System;
import Toybox.Math;
import Toybox.Lang;

class PongView extends WatchUi.View {

    private const PADDLE_HEIGHT = 36;
    private const PADDLE_WIDTH = 6;
    private const PADDLE_MARGIN = 8;

    private var _aiSpeed as Float = 3.5;
    private var _ballSpeed as Float = 3.0;
    private var _aiAccuracy as Float = 0.75;
    private var _speedMultiplier as Float = 1.0;
    private var _aiTargetOffset as Float = 0.0;
    private var _aiDecided as Boolean = false;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _isRound as Boolean = false;
    private var _centerX as Float = 0.0;
    private var _centerY as Float = 0.0;
    private var _radius as Float = 0.0;

    private var _aiX as Float = 0.0;
    private var _playerX as Float = 0.0;

    private var _ballX as Float = 0.0;
    private var _ballY as Float = 0.0;
    private var _ballVelX as Float = 3.0;
    private var _ballVelY as Float = 2.0;

    private var _playerY as Float = 0.0;
    private var _aiY as Float = 0.0;

    private var _playerScore as Number = 0;
    private var _aiScore as Number = 0;

    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _centerX = _width / 2.0;
        _centerY = _height / 2.0;
        _radius = (_width < _height ? _width : _height) / 2.0;
        _isRound = (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND);

        _aiX = PADDLE_MARGIN + PADDLE_WIDTH / 2.0;
        _playerX = _width - PADDLE_MARGIN - PADDLE_WIDTH / 2.0;

        _playerY = _centerY;
        _aiY = _centerY;
        resetBall();
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

    private function clampToPlayfield(y as Float, x as Float) as Float {
        var half = PADDLE_HEIGHT / 2.0;
        var range = verticalHalfRangeAt(x);
        var minY = _centerY - range + half;
        var maxY = _centerY + range - half;
        if (minY > maxY) {
            return _centerY;
        }
        if (y < minY) { return minY; }
        if (y > maxY) { return maxY; }
        return y;
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
        updateGame();
        WatchUi.requestUpdate();
    }

    function getHeight() as Number {
        return _height;
    }

    function setDifficulty(aiSpeed as Float, ballSpeed as Float, aiAccuracy as Float) as Void {
        _aiSpeed = aiSpeed;
        _ballSpeed = ballSpeed;
        _aiAccuracy = aiAccuracy;
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
    }

    function setPlayerY(y as Number) as Void {
        _playerY = clampToPlayfield(y.toFloat(), _playerX);
    }

    function resetGame() as Void {
        _playerScore = 0;
        _aiScore = 0;
        _playerY = _centerY;
        _aiY = _centerY;
        resetBall();
    }

    function movePlayer(dy as Number) as Void {
        _playerY = clampToPlayfield(_playerY + dy, _playerX);
    }

    // Random float in [min, max), used to keep ball trajectories from
    // settling into a repeating loop.
    private function randomFloat(min as Float, max as Float) as Float {
        var r = (Math.rand() % 10000).abs() / 10000.0;
        return min + (max - min) * r;
    }

    private function resetBall() as Void {
        _ballX = _centerX;
        _ballY = _centerY;
        var speed = _ballSpeed * _speedMultiplier;
        _ballVelX = (_ballVelX > 0) ? -speed : speed;
        var angleFactor = randomFloat(0.35, 0.85);
        _ballVelY = (Math.rand() % 2 == 0) ? speed * angleFactor : -speed * angleFactor;
    }

    // Nudges the ball's vertical velocity by a small random amount on every
    // paddle hit, clamped so it never goes fully flat or fully vertical.
    private function deflectBall() as Void {
        _ballVelY += randomFloat(-0.9, 0.9);
        var maxVelY = _ballVelX.abs() * 1.3;
        var minVelY = _ballVelX.abs() * 0.2;
        if (_ballVelY.abs() > maxVelY) {
            _ballVelY = (_ballVelY > 0) ? maxVelY : -maxVelY;
        } else if (_ballVelY.abs() < minVelY) {
            _ballVelY = (_ballVelY >= 0) ? minVelY : -minVelY;
        }
    }

    private function updateGame() as Void {
        var half = PADDLE_HEIGHT / 2.0;

        _ballX += _ballVelX;
        _ballY += _ballVelY;

        var ballRange = verticalHalfRangeAt(_ballX);
        var ballTop = _centerY - ballRange;
        var ballBottom = _centerY + ballRange;
        if (_ballY <= ballTop) {
            _ballY = ballTop;
            _ballVelY = -_ballVelY;
        } else if (_ballY >= ballBottom) {
            _ballY = ballBottom;
            _ballVelY = -_ballVelY;
        }

        // AI paddle tracks the ball, but only "decides" where to move once
        // per approach (when the ball turns toward it) rather than every
        // tick. Below-perfect accuracy adds a persistent aim error for that
        // approach, so a low-accuracy AI can genuinely misjudge and miss
        // instead of the error averaging out over the rally.
        if (_ballVelX < 0) {
            if (!_aiDecided) {
                var maxOffset = (1.0 - _aiAccuracy) * PADDLE_HEIGHT * 3.0;
                _aiTargetOffset = randomFloat(-maxOffset, maxOffset);
                _aiDecided = true;
            }
        } else {
            _aiDecided = false;
        }
        var aiTarget = _ballY + _aiTargetOffset;
        var aiSpeed = _aiSpeed * _speedMultiplier;
        if (_aiY < aiTarget) {
            _aiY += aiSpeed;
        } else if (_aiY > aiTarget) {
            _aiY -= aiSpeed;
        }
        _aiY = clampToPlayfield(_aiY, _aiX);

        // AI paddle (left) collision
        if (_ballX <= PADDLE_MARGIN + PADDLE_WIDTH && _ballVelX < 0) {
            if (_ballY >= _aiY - half && _ballY <= _aiY + half) {
                _ballVelX = -_ballVelX;
                deflectBall();
            }
        }

        // Player paddle (right) collision
        if (_ballX >= _playerX - PADDLE_WIDTH / 2.0 && _ballVelX > 0) {
            if (_ballY >= _playerY - half && _ballY <= _playerY + half) {
                _ballVelX = -_ballVelX;
                deflectBall();
            }
        }

        if (_ballX < 0) {
            _aiScore += 1;
            resetBall();
        } else if (_ballX > _width) {
            _playerScore += 1;
            resetBall();
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, _aiScore.toString() + " : " + _playerScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        var half = (PADDLE_HEIGHT / 2).toNumber();
        dc.fillRectangle(_aiX.toNumber() - PADDLE_WIDTH / 2, _aiY.toNumber() - half, PADDLE_WIDTH, PADDLE_HEIGHT);
        dc.fillRectangle(_playerX.toNumber() - PADDLE_WIDTH / 2, _playerY.toNumber() - half, PADDLE_WIDTH, PADDLE_HEIGHT);

        dc.fillCircle(_ballX.toNumber(), _ballY.toNumber(), 4);
    }

}
