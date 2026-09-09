import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.System;
import Toybox.Math;
import Toybox.Lang;

class FlappyView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "flappy_high";

    private const GRAVITY = 0.5;
    private const FLAP_VELOCITY = -6.0;
    private const BIRD_RADIUS = 7;
    private const PIPE_WIDTH = 16;
    private const PIPE_SPACING = 120;
    private const BASE_PIPE_SPEED = 2.5;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _isRound as Boolean = false;
    private var _centerX as Float = 0.0;
    private var _centerY as Float = 0.0;
    private var _radius as Float = 0.0;

    private var _birdX as Float = 0.0;
    private var _birdY as Float = 0.0;
    private var _birdVelY as Float = 0.0;
    private var _baseGapHeight as Float = 70.0;
    private var _gapHeight as Float = 70.0;
    private var _gapMultiplier as Float = 1.0;
    private var _speedMultiplier as Float = 1.0;

    private var _pipeX as Array<Float>;
    private var _pipeGapY as Array<Float>;
    private var _pipePassed as Array<Boolean>;

    private var _score as Number = 0;
    private var _highScore as Number = 0;
    private var _gameOver as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _pipeX = [];
        _pipeGapY = [];
        _pipePassed = [];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _centerX = _width / 2.0;
        _centerY = _height / 2.0;
        _radius = (_width < _height ? _width : _height) / 2.0;
        _isRound = (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND);
        _birdX = _width * 0.3;
        var corridor = verticalHalfRangeAt(_birdX) * 2.0;
        _baseGapHeight = corridor * 0.5;
        _gapHeight = _baseGapHeight * _gapMultiplier;
        resetGame();
    }

    function setDifficulty(gapMultiplier as Float) as Void {
        _gapMultiplier = gapMultiplier;
        _gapHeight = _baseGapHeight * _gapMultiplier;
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
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
        _birdY = _centerY;
        _birdVelY = 0.0;
        _pipeX = [];
        _pipeGapY = [];
        _pipePassed = [];
        _score = 0;
        _gameOver = false;
        spawnPipe(_width.toFloat() + 40.0);
    }

    private function markGameOver() as Void {
        _gameOver = true;
        HighScores.submit(HIGH_SCORE_KEY, _score);
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    private function spawnPipe(x as Float) as Void {
        var range = verticalHalfRangeAt(_birdX);
        var minGapY = _centerY - range + _gapHeight / 2.0 + 6.0;
        var maxGapY = _centerY + range - _gapHeight / 2.0 - 6.0;
        var gapY = _centerY;
        if (maxGapY > minGapY) {
            var r = (Math.rand() % 10000).abs() / 10000.0;
            gapY = minGapY + (maxGapY - minGapY) * r;
        }
        _pipeX.add(x);
        _pipeGapY.add(gapY);
        _pipePassed.add(false);
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

    function flap() as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        _birdVelY = FLAP_VELOCITY;
    }

    private function updateGame() as Void {
        _birdVelY += GRAVITY;
        _birdY += _birdVelY;

        var range = verticalHalfRangeAt(_birdX);
        var top = _centerY - range;
        var bottom = _centerY + range;
        if (_birdY - BIRD_RADIUS <= top || _birdY + BIRD_RADIUS >= bottom) {
            markGameOver();
            return;
        }

        var pipeSpeed = BASE_PIPE_SPEED * _speedMultiplier;
        var i = 0;
        while (i < _pipeX.size()) {
            _pipeX[i] = _pipeX[i] - pipeSpeed;
            i++;
        }

        // Spawn a new pipe once the last one has cleared enough space.
        if (_pipeX.size() == 0 || _pipeX[_pipeX.size() - 1] <= _width - PIPE_SPACING) {
            spawnPipe(_width.toFloat() + PIPE_WIDTH);
        }

        // Drop pipes that have scrolled fully off-screen, scoring passed ones.
        var kept = [] as Array<Float>;
        var keptGap = [] as Array<Float>;
        var keptPassed = [] as Array<Boolean>;
        i = 0;
        while (i < _pipeX.size()) {
            var px = _pipeX[i];
            var gapY = _pipeGapY[i];
            var passed = _pipePassed[i];

            if (!passed && px + PIPE_WIDTH < _birdX) {
                passed = true;
                _score += 1;
            }

            if (_birdX + BIRD_RADIUS > px && _birdX - BIRD_RADIUS < px + PIPE_WIDTH) {
                if (_birdY - BIRD_RADIUS < gapY - _gapHeight / 2.0 || _birdY + BIRD_RADIUS > gapY + _gapHeight / 2.0) {
                    markGameOver();
                }
            }

            if (px + PIPE_WIDTH >= 0) {
                kept.add(px);
                keptGap.add(gapY);
                keptPassed.add(passed);
            }
            i++;
        }
        _pipeX = kept;
        _pipeGapY = keptGap;
        _pipePassed = keptPassed;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        var i = 0;
        while (i < _pipeX.size()) {
            var px = _pipeX[i].toNumber();
            var gapY = _pipeGapY[i];
            var range = verticalHalfRangeAt(_pipeX[i]);
            var top = (_centerY - range).toNumber();
            var bottom = (_centerY + range).toNumber();
            var gapTop = (gapY - _gapHeight / 2.0).toNumber();
            var gapBottom = (gapY + _gapHeight / 2.0).toNumber();
            dc.fillRectangle(px, top, PIPE_WIDTH, gapTop - top);
            dc.fillRectangle(px, gapBottom, PIPE_WIDTH, bottom - gapBottom);
            i++;
        }

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_birdX.toNumber(), _birdY.toNumber(), BIRD_RADIUS);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_gameOver) {
            dc.drawText(_width / 2, _height / 2 - 10, Graphics.FONT_SMALL, "Game Over", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_width / 2, _height / 2 + 10, Graphics.FONT_TINY, "Score: " + _score.toString() + "  Best: " + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(_width / 2, 2, Graphics.FONT_TINY, _score.toString() + "  Best:" + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
