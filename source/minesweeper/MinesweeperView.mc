import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

(:touchGames)
class MinesweeperView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "minesweeper_best";
    private const MINE_DENSITY_PCT = 15;

    private var _gridSize as Number = 8;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;

    private var _mines as Array<Boolean>;
    private var _revealed as Array<Boolean>;
    private var _counts as Array<Number>;
    private var _minesPlaced as Boolean = false;
    private var _mineCount as Number = 0;

    private var _gameOver as Boolean = false;
    private var _won as Boolean = false;
    private var _startTimeMs as Number = 0;
    private var _elapsedMs as Number = 0;
    private var _bestMs as Number?;

    function initialize() {
        View.initialize();
        _mines = [];
        _revealed = [];
        _counts = [];
        _bestMs = HighScores.getRaw(HIGH_SCORE_KEY);
        resetCells();
    }

    private function resetCells() as Void {
        var total = _gridSize * _gridSize;
        _mines = [] as Array<Boolean>;
        _revealed = [] as Array<Boolean>;
        _counts = [] as Array<Number>;
        var i = 0;
        while (i < total) {
            _mines.add(false);
            _revealed.add(false);
            _counts.add(0);
            i++;
        }
        _minesPlaced = false;
        _mineCount = 0;
        _gameOver = false;
        _won = false;
        _startTimeMs = System.getTimer();
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        layoutBoard();
    }

    private function layoutBoard() as Void {
        var boardSize = BoardMetrics.squareBoardSize(_width, _height, 16);
        _cellSize = boardSize / _gridSize;
        boardSize = _cellSize * _gridSize;
        _boardLeft = (_width - boardSize) / 2;
        _boardTop = (_height - boardSize) / 2;
    }

    function setBoardSize(gridSize as Number) as Void {
        _gridSize = gridSize;
        if (_width > 0) {
            layoutBoard();
        }
        resetGame();
    }

    function resetGame() as Void {
        resetCells();
        WatchUi.requestUpdate();
    }

    function handleTap(x as Number, y as Number) as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        if (x < _boardLeft || y < _boardTop) {
            return;
        }
        var col = (x - _boardLeft) / _cellSize;
        var row = (y - _boardTop) / _cellSize;
        if (col < 0 || col >= _gridSize || row < 0 || row >= _gridSize) {
            return;
        }
        var idx = row * _gridSize + col;
        if (_revealed[idx]) {
            return;
        }

        if (!_minesPlaced) {
            placeMines(idx);
            computeCounts();
            _minesPlaced = true;
            _startTimeMs = System.getTimer();
        }

        if (_mines[idx]) {
            _revealed[idx] = true;
            revealAllMines();
            _gameOver = true;
            _won = false;
            WatchUi.requestUpdate();
            return;
        }

        floodReveal(idx);

        if (checkWin()) {
            _gameOver = true;
            _won = true;
            _elapsedMs = System.getTimer() - _startTimeMs;
            HighScores.submitFastest(HIGH_SCORE_KEY, _elapsedMs);
            _bestMs = HighScores.getRaw(HIGH_SCORE_KEY);
        }
        WatchUi.requestUpdate();
    }

    // Mines are placed only after the first tap, excluding that cell and its
    // immediate neighbors, so the first reveal is always safe.
    private function placeMines(safeIdx as Number) as Void {
        var n = _gridSize;
        var total = n * n;
        var safeRow = safeIdx / n;
        var safeCol = safeIdx % n;
        var excluded = [] as Array<Boolean>;
        var i = 0;
        while (i < total) {
            excluded.add(false);
            i++;
        }
        var dr = -1;
        while (dr <= 1) {
            var dc2 = -1;
            while (dc2 <= 1) {
                var r = safeRow + dr;
                var c = safeCol + dc2;
                if (r >= 0 && r < n && c >= 0 && c < n) {
                    excluded[r * n + c] = true;
                }
                dc2++;
            }
            dr++;
        }

        _mineCount = total * MINE_DENSITY_PCT / 100;
        if (_mineCount < 1) {
            _mineCount = 1;
        }

        var placed = 0;
        var guard = 0;
        while (placed < _mineCount && guard < total * 50) {
            var idx = (Math.rand() % total).abs();
            guard++;
            if (excluded[idx] || _mines[idx]) {
                continue;
            }
            _mines[idx] = true;
            placed++;
        }
    }

    private function computeCounts() as Void {
        var n = _gridSize;
        var r = 0;
        while (r < n) {
            var c = 0;
            while (c < n) {
                if (!_mines[r * n + c]) {
                    _counts[r * n + c] = countNeighborMines(r, c);
                }
                c++;
            }
            r++;
        }
    }

    private function countNeighborMines(row as Number, col as Number) as Number {
        var n = _gridSize;
        var count = 0;
        var dr = -1;
        while (dr <= 1) {
            var dc2 = -1;
            while (dc2 <= 1) {
                if (!(dr == 0 && dc2 == 0)) {
                    var r = row + dr;
                    var c = col + dc2;
                    if (r >= 0 && r < n && c >= 0 && c < n && _mines[r * n + c]) {
                        count++;
                    }
                }
                dc2++;
            }
            dr++;
        }
        return count;
    }

    // Explicit stack-based flood fill (no recursion) so revealing a large
    // open area can't grow the call stack on embedded hardware.
    private function floodReveal(startIdx as Number) as Void {
        var n = _gridSize;
        var stack = [] as Array<Number>;
        stack.add(startIdx);
        while (stack.size() > 0) {
            var idx = stack[stack.size() - 1];
            stack = stack.slice(0, stack.size() - 1) as Array<Number>;
            if (_revealed[idx] || _mines[idx]) {
                continue;
            }
            _revealed[idx] = true;
            if (_counts[idx] == 0) {
                var row = idx / n;
                var col = idx % n;
                var dr = -1;
                while (dr <= 1) {
                    var dc2 = -1;
                    while (dc2 <= 1) {
                        if (!(dr == 0 && dc2 == 0)) {
                            var r = row + dr;
                            var c = col + dc2;
                            if (r >= 0 && r < n && c >= 0 && c < n) {
                                var nIdx = r * n + c;
                                if (!_revealed[nIdx] && !_mines[nIdx]) {
                                    stack.add(nIdx);
                                }
                            }
                        }
                        dc2++;
                    }
                    dr++;
                }
            }
        }
    }

    private function revealAllMines() as Void {
        var i = 0;
        while (i < _mines.size()) {
            if (_mines[i]) {
                _revealed[i] = true;
            }
            i++;
        }
    }

    private function checkWin() as Boolean {
        var total = _gridSize * _gridSize;
        var i = 0;
        while (i < total) {
            if (!_mines[i] && !_revealed[i]) {
                return false;
            }
            i++;
        }
        return true;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var label = "Tap to play";
        if (_gameOver) {
            if (_won) {
                label = "Cleared! Time: " + (_elapsedMs / 1000).toString() + "s";
            } else {
                label = "Boom! Game Over";
            }
        }
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var n = _gridSize;
        var r = 0;
        while (r < n) {
            var c = 0;
            while (c < n) {
                drawCell(dc, r, c);
                c++;
            }
            r++;
        }
    }

    private function drawCell(dc as Dc, row as Number, col as Number) as Void {
        var idx = row * _gridSize + col;
        var x = _boardLeft + col * _cellSize;
        var y = _boardTop + row * _cellSize;

        if (!_revealed[idx]) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.fillRectangle(x + 1, y + 1, _cellSize - 1, _cellSize - 1);
            return;
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, _cellSize, _cellSize);

        if (_mines[idx]) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
            dc.fillCircle(x + _cellSize / 2, y + _cellSize / 2, _cellSize / 3);
            return;
        }

        var count = _counts[idx];
        if (count > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x + _cellSize / 2, y + _cellSize / 2 - _cellSize / 4, Graphics.FONT_XTINY, count.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
