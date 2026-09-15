import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Math;
import Toybox.Lang;

(:touchGames)
class WhackView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "whack_best";
    private const TICK_MS = 33;
    private const ROUND_TICKS = 30000 / TICK_MS;
    private const BASE_VISIBLE_TICKS = 800 / TICK_MS;
    private const BASE_GAP_MIN_TICKS = 200 / TICK_MS;
    private const BASE_GAP_MAX_TICKS = 500 / TICK_MS;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;

    private var _speedMultiplier as Float = 1.0;
    private var _moleIndex as Number = -1;
    private var _moleVisible as Boolean = false;
    private var _moleCountdown as Number = 0;

    private var _score as Number = 0;
    private var _highScore as Number = 0;
    private var _elapsedTicks as Number = 0;
    private var _roundActive as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        var boardSize = BoardMetrics.squareBoardSize(_width, _height, 16);
        _cellSize = boardSize / 3;
        boardSize = _cellSize * 3;
        _boardLeft = (_width - boardSize) / 2;
        _boardTop = (_height - boardSize) / 2;
    }

    function resetGame() as Void {
        startRound();
    }

    private function startRound() as Void {
        _score = 0;
        _elapsedTicks = 0;
        _moleIndex = -1;
        _moleVisible = false;
        _moleCountdown = randomGapTicks();
        _roundActive = true;
        WatchUi.requestUpdate();
    }

    private function endRound() as Void {
        _roundActive = false;
        _moleVisible = false;
        HighScores.submit(HIGH_SCORE_KEY, _score);
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    private function visibleTicks() as Number {
        var ticks = (BASE_VISIBLE_TICKS / _speedMultiplier).toNumber();
        return ticks < 5 ? 5 : ticks;
    }

    private function randomGapTicks() as Number {
        var minTicks = (BASE_GAP_MIN_TICKS / _speedMultiplier).toNumber();
        var maxTicks = (BASE_GAP_MAX_TICKS / _speedMultiplier).toNumber();
        if (maxTicks <= minTicks) {
            maxTicks = minTicks + 1;
        }
        return minTicks + (Math.rand() % (maxTicks - minTicks)).abs();
    }

    function onShow() as Void {
        if (!_roundActive) {
            startRound();
        }
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
        if (_roundActive) {
            updateGame();
        }
        WatchUi.requestUpdate();
    }

    private function updateGame() as Void {
        _elapsedTicks += 1;
        if (_elapsedTicks >= ROUND_TICKS) {
            endRound();
            return;
        }

        _moleCountdown -= 1;
        if (_moleCountdown <= 0) {
            if (_moleVisible) {
                _moleVisible = false;
                _moleIndex = -1;
                _moleCountdown = randomGapTicks();
            } else {
                _moleIndex = (Math.rand() % 9).abs();
                _moleVisible = true;
                _moleCountdown = visibleTicks();
            }
        }
    }

    function handleTap(x as Number, y as Number) as Void {
        if (!_roundActive) {
            startRound();
            return;
        }
        if (x < _boardLeft || y < _boardTop) {
            return;
        }
        var col = (x - _boardLeft) / _cellSize;
        var row = (y - _boardTop) / _cellSize;
        if (col < 0 || col > 2 || row < 0 || row > 2) {
            return;
        }
        var idx = row * 3 + col;
        if (_moleVisible && idx == _moleIndex) {
            _score += 1;
            _moleVisible = false;
            _moleIndex = -1;
            _moleCountdown = randomGapTicks();
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, "Score: " + _score.toString() + "  Best: " + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        var holeRadius = _cellSize / 2 - 4;
        var r = 0;
        while (r < 3) {
            var c = 0;
            while (c < 3) {
                var idx = r * 3 + c;
                var cx = _boardLeft + c * _cellSize + _cellSize / 2;
                var cy = _boardTop + r * _cellSize + _cellSize / 2;
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(cx, cy, holeRadius);
                if (_moleVisible && idx == _moleIndex) {
                    dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(cx, cy, (holeRadius * 0.6).toNumber());
                }
                c++;
            }
            r++;
        }

        if (!_roundActive) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_width / 2, _height / 2 - 10, Graphics.FONT_SMALL, "Time's Up!", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_width / 2, _height / 2 + 10, Graphics.FONT_TINY, "Score: " + _score.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
