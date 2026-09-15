import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

(:touchGames)
class MemoryMatchView extends WatchUi.View {

    private const BEST_KEY = "memorymatch_best";
    private const COLS = 4;
    private const CARD_COLORS = [
        Graphics.COLOR_RED, Graphics.COLOR_BLUE, Graphics.COLOR_GREEN,
        Graphics.COLOR_YELLOW, Graphics.COLOR_ORANGE, Graphics.COLOR_PURPLE,
        Graphics.COLOR_PINK, Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_BLUE,
        Graphics.COLOR_LT_GRAY, Graphics.COLOR_WHITE, Graphics.COLOR_DK_RED
    ];

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;
    private var _rows as Number = 0;

    private var _pairs as Number = 6;
    private var _values as Array<Number>;
    private var _revealed as Array<Boolean>;
    private var _matched as Array<Boolean>;
    private var _pending as Array<Number>;
    private var _moves as Number = 0;
    private var _won as Boolean = false;
    private var _best as Number?;

    function initialize() {
        View.initialize();
        _values = [];
        _revealed = [];
        _matched = [];
        _pending = [];
        _best = HighScores.getRaw(BEST_KEY);
        resetCards();
    }

    private function resetCards() as Void {
        var total = _pairs * 2;
        _values = [];
        var i = 0;
        while (i < _pairs) {
            _values.add(i);
            _values.add(i);
            i++;
        }
        i = total - 1;
        while (i > 0) {
            var j = (Math.rand() % (i + 1)).abs();
            var tmp = _values[i];
            _values[i] = _values[j];
            _values[j] = tmp;
            i--;
        }
        _revealed = new Array<Boolean>[total];
        _matched = new Array<Boolean>[total];
        i = 0;
        while (i < total) {
            _revealed[i] = false;
            _matched[i] = false;
            i++;
        }
        _pending = [];
        _moves = 0;
        _won = false;
        _rows = (total + COLS - 1) / COLS;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        layoutBoard();
    }

    private function layoutBoard() as Void {
        var boardSize = BoardMetrics.squareBoardSize(_width, _height, 16);
        _cellSize = boardSize / COLS;
        _boardLeft = (_width - _cellSize * COLS) / 2;
        _boardTop = (_height - _cellSize * _rows) / 2;
    }

    function setDifficulty(pairs as Number) as Void {
        _pairs = pairs;
        resetGame();
    }

    function resetGame() as Void {
        resetCards();
        if (_width > 0) {
            layoutBoard();
        }
        WatchUi.requestUpdate();
    }

    function handleTap(x as Number, y as Number) as Void {
        if (_won) {
            resetGame();
            return;
        }
        if (x < _boardLeft || y < _boardTop) {
            return;
        }
        var col = (x - _boardLeft) / _cellSize;
        var row = (y - _boardTop) / _cellSize;
        if (col < 0 || col >= COLS || row < 0 || row >= _rows) {
            return;
        }
        var idx = row * COLS + col;
        if (idx >= _values.size()) {
            return;
        }

        if (_pending.size() == 2) {
            hidePending();
        }
        if (_matched[idx] || _revealed[idx]) {
            return;
        }

        _revealed[idx] = true;
        _pending.add(idx);
        if (_pending.size() == 2) {
            _moves++;
            var a = _pending[0];
            var b = _pending[1];
            if (_values[a] == _values[b]) {
                _matched[a] = true;
                _matched[b] = true;
                _pending = [];
                checkWin();
            }
        }
        WatchUi.requestUpdate();
    }

    private function hidePending() as Void {
        var i = 0;
        while (i < _pending.size()) {
            _revealed[_pending[i]] = false;
            i++;
        }
        _pending = [];
    }

    private function checkWin() as Void {
        var i = 0;
        while (i < _matched.size()) {
            if (!_matched[i]) {
                return;
            }
            i++;
        }
        _won = true;
        HighScores.submitFastest(BEST_KEY, _moves);
        _best = HighScores.getRaw(BEST_KEY);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var label = "Moves: " + _moves.toString();
        if (_won) {
            label = "Solved in " + _moves.toString() + " moves!";
        } else if (_best != null) {
            label += "  Best:" + (_best as Number).toString();
        }
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var i = 0;
        while (i < _values.size()) {
            var row = i / COLS;
            var col = i % COLS;
            var cx = _boardLeft + col * _cellSize;
            var cy = _boardTop + row * _cellSize;
            var pad = 2;
            if (_matched[i] || _revealed[i]) {
                var color = CARD_COLORS[_values[i] % CARD_COLORS.size()];
                dc.setColor(color, color);
                dc.fillRoundedRectangle(cx + pad, cy + pad, _cellSize - pad * 2, _cellSize - pad * 2, 4);
                if (_matched[i]) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.drawRoundedRectangle(cx + pad, cy + pad, _cellSize - pad * 2, _cellSize - pad * 2, 4);
                }
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx + _cellSize / 2, cy + _cellSize / 2 - _cellSize / 4, Graphics.FONT_SMALL, _values[i].toString(), Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRoundedRectangle(cx + pad, cy + pad, _cellSize - pad * 2, _cellSize - pad * 2, 4);
            }
            i++;
        }
    }

}
