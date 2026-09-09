import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Math;

class SimonView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "simon_high";
    private const STATE_SHOWING = 0;
    private const STATE_WAITING = 1;
    private const STATE_GAME_OVER = 2;

    private const BASE_SHOW_ON_MS = 450;
    private const BASE_SHOW_OFF_MS = 200;
    private const TICK_MS = 30;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _boardSize as Number = 0;

    private var _sequence as Array<Number>;
    private var _state as Number = STATE_SHOWING;
    private var _showStep as Number = 0;
    private var _showElapsed as Number = 0;
    private var _showingOn as Boolean = false;
    private var _activeQuadrant as Number = -1;
    private var _inputIndex as Number = 0;
    private var _timer as Timer.Timer?;

    private var _speedMultiplier as Float = 1.0;
    private var _startLength as Number = 1;
    private var _strikesAllowed as Number = 0;
    private var _strikesUsed as Number = 0;
    private var _highScore as Number = 0;

    function initialize() {
        View.initialize();
        _sequence = [];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _boardSize = BoardMetrics.squareBoardSize(_width, _height, 16);
        _boardLeft = (_width - _boardSize) / 2;
        _boardTop = (_height - _boardSize) / 2;
        resetGame();
    }

    // startLength: how many steps the sequence begins with (harder skips the
    // warm-up). strikesAllowed: wrong taps tolerated before game over.
    function setDifficulty(startLength as Number, strikesAllowed as Number) as Void {
        _startLength = startLength;
        _strikesAllowed = strikesAllowed;
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
    }

    function resetGame() as Void {
        _sequence = [];
        _strikesUsed = 0;
        var i = 0;
        while (i < _startLength) {
            addStep();
            i++;
        }
        startShowing();
        WatchUi.requestUpdate();
    }

    private function addStep() as Void {
        _sequence.add((Math.rand() % 4).abs());
    }

    private function startShowing() as Void {
        _state = STATE_SHOWING;
        _showStep = 0;
        _showElapsed = 0;
        _showingOn = true;
        _activeQuadrant = _sequence[0];
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), TICK_MS, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTimerTick() as Void {
        if (_state == STATE_SHOWING) {
            updateShowing();
            WatchUi.requestUpdate();
        }
    }

    private function updateShowing() as Void {
        _showElapsed += TICK_MS;
        if (_showingOn) {
            if (_showElapsed >= BASE_SHOW_ON_MS / _speedMultiplier) {
                _showingOn = false;
                _showElapsed = 0;
                _activeQuadrant = -1;
            }
        } else {
            if (_showElapsed >= BASE_SHOW_OFF_MS / _speedMultiplier) {
                _showStep += 1;
                if (_showStep >= _sequence.size()) {
                    _state = STATE_WAITING;
                    _inputIndex = 0;
                    _activeQuadrant = -1;
                    return;
                }
                _showingOn = true;
                _showElapsed = 0;
                _activeQuadrant = _sequence[_showStep];
            }
        }
    }

    function handleTap(x as Number, y as Number) as Void {
        if (_state == STATE_GAME_OVER) {
            resetGame();
            return;
        }
        if (_state != STATE_WAITING) {
            return;
        }
        if (x < _boardLeft || y < _boardTop || x >= _boardLeft + _boardSize || y >= _boardTop + _boardSize) {
            return;
        }
        var half = _boardSize / 2;
        var col = (x - _boardLeft) / half;
        var row = (y - _boardTop) / half;
        var quadrant = row * 2 + col;

        if (quadrant == _sequence[_inputIndex]) {
            _activeQuadrant = quadrant;
            _inputIndex += 1;
            if (_inputIndex >= _sequence.size()) {
                addStep();
                startShowing();
            }
        } else if (_strikesUsed < _strikesAllowed) {
            // A tolerated mistake replays the same sequence rather than
            // ending the game outright.
            _strikesUsed += 1;
            _activeQuadrant = -1;
            startShowing();
        } else {
            _state = STATE_GAME_OVER;
            _activeQuadrant = -1;
            HighScores.submit(HIGH_SCORE_KEY, _sequence.size() - 1);
            _highScore = HighScores.get(HIGH_SCORE_KEY);
        }
        WatchUi.requestUpdate();
    }

    private function quadrantColor(q as Number) as Number {
        if (q == 0) { return Graphics.COLOR_RED; }
        if (q == 1) { return Graphics.COLOR_GREEN; }
        if (q == 2) { return Graphics.COLOR_BLUE; }
        return Graphics.COLOR_YELLOW;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var roundNum = _sequence.size() - 1;
        var label = (_state == STATE_GAME_OVER) ? "Game Over  " + roundNum.toString() + "  Best:" + _highScore.toString() : "Score: " + roundNum.toString() + "  Best:" + _highScore.toString();
        dc.drawText(_width / 2, 2, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var half = _boardSize / 2;
        var q = 0;
        while (q < 4) {
            var col = q % 2;
            var row = q / 2;
            var x = _boardLeft + col * half;
            var y = _boardTop + row * half;
            var baseColor = quadrantColor(q);
            dc.setColor(baseColor, baseColor);
            dc.fillRectangle(x + 2, y + 2, half - 4, half - 4);
            if (q == _activeQuadrant) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(x + 2, y + 2, half - 4, half - 4);
                dc.drawRectangle(x + 3, y + 3, half - 6, half - 6);
            }
            q++;
        }
    }

}
