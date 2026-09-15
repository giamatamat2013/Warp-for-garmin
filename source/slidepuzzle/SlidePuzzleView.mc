import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

(:touchGames)
class SlidePuzzleView extends WatchUi.View {

    private const BLANK = 0;
    private const SHUFFLE_MOVES = 150;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;

    private var _n as Number = 4;
    private var _cells as Array<Number>;
    private var _moves as Number = 0;
    private var _solved as Boolean = false;

    function initialize() {
        View.initialize();
        _cells = [];
        shuffle();
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        var boardSize = BoardMetrics.squareBoardSize(_width, _height, 16);
        _cellSize = boardSize / _n;
        boardSize = _cellSize * _n;
        _boardLeft = (_width - boardSize) / 2;
        _boardTop = (_height - boardSize) / 2;
    }

    function setBoardSize(n as Number) as Void {
        _n = n;
        if (_cellSize > 0) {
            var boardSize = BoardMetrics.squareBoardSize(_width, _height, 16);
            _cellSize = boardSize / _n;
            boardSize = _cellSize * _n;
            _boardLeft = (_width - boardSize) / 2;
            _boardTop = (_height - boardSize) / 2;
        }
        shuffle();
    }

    private function shuffle() as Void {
        var total = _n * _n;
        _cells = new [total];
        var i = 0;
        while (i < total - 1) {
            _cells[i] = i + 1;
            i++;
        }
        _cells[total - 1] = BLANK;

        var blankIdx = total - 1;
        var moveCount = 0;
        while (moveCount < SHUFFLE_MOVES) {
            var neighbors = neighborIndices(blankIdx);
            var pick = neighbors[(Math.rand() % neighbors.size()).abs()];
            _cells[blankIdx] = _cells[pick];
            _cells[pick] = BLANK;
            blankIdx = pick;
            moveCount++;
        }

        _moves = 0;
        _solved = false;
        WatchUi.requestUpdate();
    }

    private function neighborIndices(idx as Number) as Array<Number> {
        var row = idx / _n;
        var col = idx % _n;
        var result = [] as Array<Number>;
        if (row > 0) { result.add(idx - _n); }
        if (row < _n - 1) { result.add(idx + _n); }
        if (col > 0) { result.add(idx - 1); }
        if (col < _n - 1) { result.add(idx + 1); }
        return result;
    }

    private function blankIndex() as Number {
        var i = 0;
        while (i < _cells.size()) {
            if (_cells[i] == BLANK) {
                return i;
            }
            i++;
        }
        return -1;
    }

    private function checkSolved() as Boolean {
        var i = 0;
        while (i < _cells.size() - 1) {
            if (_cells[i] != i + 1) {
                return false;
            }
            i++;
        }
        return _cells[_cells.size() - 1] == BLANK;
    }

    function handleTap(x as Number, y as Number) as Void {
        if (_solved) {
            shuffle();
            return;
        }
        if (x < _boardLeft || y < _boardTop) {
            return;
        }
        var col = (x - _boardLeft) / _cellSize;
        var row = (y - _boardTop) / _cellSize;
        if (col < 0 || col >= _n || row < 0 || row >= _n) {
            return;
        }
        var idx = row * _n + col;
        if (_cells[idx] == BLANK) {
            return;
        }

        var blankIdx = blankIndex();
        var neighbors = neighborIndices(blankIdx);
        var adjacent = false;
        var i = 0;
        while (i < neighbors.size()) {
            if (neighbors[i] == idx) {
                adjacent = true;
            }
            i++;
        }
        if (!adjacent) {
            return;
        }

        _cells[blankIdx] = _cells[idx];
        _cells[idx] = BLANK;
        _moves++;

        if (checkSolved()) {
            _solved = true;
            HighScores.submitFastest("slidepuzzle_best", _moves);
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var label = "Tap to slide";
        if (_solved) {
            label = "Solved in " + _moves + " moves!";
        }
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var numberFont = (_cellSize >= 40) ? Graphics.FONT_MEDIUM : Graphics.FONT_SMALL;
        var gap = 2;

        var r = 0;
        while (r < _n) {
            var c = 0;
            while (c < _n) {
                var idx = r * _n + c;
                var value = _cells[idx];
                if (value != BLANK) {
                    var left = _boardLeft + c * _cellSize;
                    var top = _boardTop + r * _cellSize;
                    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                    dc.fillRoundedRectangle(left + gap, top + gap, _cellSize - gap * 2, _cellSize - gap * 2, 4);
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(left + _cellSize / 2, top + _cellSize / 2 - _cellSize / 4, numberFont, value.toString(), Graphics.TEXT_JUSTIFY_CENTER);
                }
                c++;
            }
            r++;
        }
    }

}
