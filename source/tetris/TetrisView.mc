import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.System;
import Toybox.Math;
import Toybox.Lang;

class TetrisView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "tetris_high";
    private const DEFAULT_COLS = 9;
    private const BASE_TICK_MS = 500;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;
    private var _cols as Number = DEFAULT_COLS;
    private var _rows as Number = 10;

    private var _board as Array<Array<Number> >;

    private var _pieceType as Number = 0;
    private var _pieceRotation as Number = 0;
    private var _pieceRow as Number = 0;
    private var _pieceCol as Number = 0;
    private var _nextPieceType as Number = 0;

    private var _speedMultiplier as Float = 1.0;
    private var _startLevel as Number = 0;
    private var _level as Number = 0;
    private var _linesCleared as Number = 0;
    private var _score as Number = 0;
    private var _highScore as Number = 0;
    private var _gameOver as Boolean = false;
    private var _timer as Timer.Timer?;

    private var _colors as Array<Number>;

    function initialize() {
        View.initialize();
        _board = [];
        _colors = [
            Graphics.COLOR_BLUE, Graphics.COLOR_YELLOW, Graphics.COLOR_PURPLE,
            Graphics.COLOR_GREEN, Graphics.COLOR_RED, Graphics.COLOR_DK_BLUE,
            Graphics.COLOR_ORANGE
        ];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
        _nextPieceType = (Math.rand() % 7).abs();
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        layoutBoard();
        resetGame();
    }

    private function layoutBoard() as Void {
        var boardWidth = BoardMetrics.squareBoardSize(_width, _height, 16);
        _cellSize = boardWidth / _cols;
        boardWidth = _cellSize * _cols;

        var isRound = BoardMetrics.isRoundScreen();
        var boardHeight = isRound ? (boardWidth * 1.3).toNumber() : (_height - 40);
        _rows = boardHeight / _cellSize;
        boardHeight = _cellSize * _rows;

        _boardLeft = (_width - boardWidth) / 2;
        _boardTop = (_height - boardHeight) / 2;
        if (_boardTop < 24) {
            _boardTop = 24;
        }
    }

    function setBoardSize(cols as Number) as Void {
        _cols = cols;
        if (_width > 0) {
            layoutBoard();
        }
        resetGame();
    }

    // Callback target for NumberKeypadDelegate — see item_grid_custom in
    // TetrisBoardSizeMenuDelegate.
    function onCustomBoardSize(value as Number) as Void {
        setBoardSize(value);
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
        restartTimer();
    }

    function resetGame() as Void {
        _board = [];
        var r = 0;
        while (r < _rows) {
            var row = [] as Array<Number>;
            var c = 0;
            while (c < _cols) {
                row.add(0);
                c++;
            }
            _board.add(row);
            r++;
        }
        _level = _startLevel;
        _linesCleared = 0;
        _score = 0;
        _gameOver = false;
        _nextPieceType = (Math.rand() % 7).abs();
        spawnPiece();
        restartTimer();
        WatchUi.requestUpdate();
    }

    // Returns the 4 [row, col] offsets (within a small bounding box) for the
    // given piece type and rotation. Computed on demand instead of stored in
    // a nested table to keep Monkey C's generic typing simple.
    private function getPieceCells(type as Number, rotation as Number) as Array<Array<Number> > {
        if (type == 0) { // I
            if (rotation % 2 == 0) {
                return [[1, 0], [1, 1], [1, 2], [1, 3]];
            }
            return [[0, 2], [1, 2], [2, 2], [3, 2]];
        } else if (type == 1) { // O
            return [[0, 0], [0, 1], [1, 0], [1, 1]];
        } else if (type == 2) { // T
            var rr = rotation % 4;
            if (rr == 0) { return [[0, 1], [1, 0], [1, 1], [1, 2]]; }
            if (rr == 1) { return [[0, 1], [1, 1], [1, 2], [2, 1]]; }
            if (rr == 2) { return [[1, 0], [1, 1], [1, 2], [2, 1]]; }
            return [[0, 1], [1, 0], [1, 1], [2, 1]];
        } else if (type == 3) { // S
            if (rotation % 2 == 0) {
                return [[0, 1], [0, 2], [1, 0], [1, 1]];
            }
            return [[0, 1], [1, 1], [1, 2], [2, 2]];
        } else if (type == 4) { // Z
            if (rotation % 2 == 0) {
                return [[0, 0], [0, 1], [1, 1], [1, 2]];
            }
            return [[0, 2], [1, 1], [1, 2], [2, 1]];
        } else if (type == 5) { // J
            var rrj = rotation % 4;
            if (rrj == 0) { return [[0, 0], [1, 0], [1, 1], [1, 2]]; }
            if (rrj == 1) { return [[0, 1], [0, 2], [1, 1], [2, 1]]; }
            if (rrj == 2) { return [[1, 0], [1, 1], [1, 2], [2, 2]]; }
            return [[0, 1], [1, 1], [2, 0], [2, 1]];
        }
        // L
        var rrl = rotation % 4;
        if (rrl == 0) { return [[0, 2], [1, 0], [1, 1], [1, 2]]; }
        if (rrl == 1) { return [[0, 1], [1, 1], [2, 1], [2, 2]]; }
        if (rrl == 2) { return [[1, 0], [1, 1], [1, 2], [2, 0]]; }
        return [[0, 0], [0, 1], [1, 1], [2, 1]];
    }

    private function canPlace(type as Number, rotation as Number, row as Number, col as Number) as Boolean {
        var cells = getPieceCells(type, rotation);
        var i = 0;
        while (i < cells.size()) {
            var r = row + cells[i][0];
            var c = col + cells[i][1];
            if (c < 0 || c >= _cols || r >= _rows) {
                return false;
            }
            if (r >= 0 && _board[r][c] != 0) {
                return false;
            }
            i++;
        }
        return true;
    }

    private function spawnPiece() as Void {
        _pieceType = _nextPieceType;
        _nextPieceType = (Math.rand() % 7).abs();
        _pieceRotation = 0;
        _pieceRow = -1;
        _pieceCol = (_cols - 4) / 2;
        if (!canPlace(_pieceType, _pieceRotation, _pieceRow, _pieceCol)) {
            markGameOver();
        }
    }

    private function markGameOver() as Void {
        _gameOver = true;
        HighScores.submit(HIGH_SCORE_KEY, _score);
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function moveLeft() as Void {
        tryMove(0, -1);
    }

    function moveRight() as Void {
        tryMove(0, 1);
    }

    function rotate() as Void {
        if (_gameOver) {
            return;
        }
        var nextRotation = (_pieceRotation + 1) % 4;
        if (canPlace(_pieceType, nextRotation, _pieceRow, _pieceCol)) {
            _pieceRotation = nextRotation;
            WatchUi.requestUpdate();
        }
    }

    private function tryMove(dr as Number, dc as Number) as Void {
        if (_gameOver) {
            return;
        }
        var newRow = _pieceRow + dr;
        var newCol = _pieceCol + dc;
        if (canPlace(_pieceType, _pieceRotation, newRow, newCol)) {
            _pieceRow = newRow;
            _pieceCol = newCol;
            WatchUi.requestUpdate();
        }
    }

    function hardDrop() as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        while (canPlace(_pieceType, _pieceRotation, _pieceRow + 1, _pieceCol)) {
            _pieceRow += 1;
        }
        lockPiece();
        WatchUi.requestUpdate();
    }

    private function lockPiece() as Void {
        var cells = getPieceCells(_pieceType, _pieceRotation);
        var i = 0;
        while (i < cells.size()) {
            var r = _pieceRow + cells[i][0];
            var c = _pieceCol + cells[i][1];
            if (r >= 0) {
                _board[r][c] = _pieceType + 1;
            }
            i++;
        }
        clearLines();
        spawnPiece();
    }

    private function clearLines() as Void {
        var newBoard = [] as Array<Array<Number> >;
        var cleared = 0;
        var r = 0;
        while (r < _rows) {
            var full = true;
            var c = 0;
            while (c < _cols) {
                if (_board[r][c] == 0) {
                    full = false;
                    c = _cols;
                } else {
                    c++;
                }
            }
            if (!full) {
                newBoard.add(_board[r]);
            } else {
                cleared += 1;
            }
            r++;
        }
        if (cleared > 0) {
            var rebuilt = [] as Array<Array<Number> >;
            var j = 0;
            while (j < cleared) {
                var emptyRow2 = [] as Array<Number>;
                var c3 = 0;
                while (c3 < _cols) {
                    emptyRow2.add(0);
                    c3++;
                }
                rebuilt.add(emptyRow2);
                j++;
            }
            var k = 0;
            while (k < newBoard.size()) {
                rebuilt.add(newBoard[k]);
                k++;
            }
            _board = rebuilt;

            var points = [0, 100, 300, 500, 800] as Array<Number>;
            var idx = cleared;
            if (idx > 4) {
                idx = 4;
            }
            _score += points[idx] * (_level + 1);
            _linesCleared += cleared;
            var newLevel = _startLevel + _linesCleared / 10;
            if (newLevel != _level) {
                _level = newLevel;
                restartTimer();
            }
        }
    }

    function onShow() as Void {
        restartTimer();
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    private function restartTimer() as Void {
        if (_timer != null) {
            _timer.stop();
        }
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), tickInterval(), true);
    }

    private function tickInterval() as Number {
        var factor = 1.0;
        var i = 0;
        while (i < _level && factor > 0.15) {
            factor *= 0.88;
            i++;
        }
        var interval = (BASE_TICK_MS * factor / _speedMultiplier).toNumber();
        if (interval < 80) {
            interval = 80;
        }
        return interval;
    }

    function onTimerTick() as Void {
        if (_gameOver) {
            return;
        }
        if (canPlace(_pieceType, _pieceRotation, _pieceRow + 1, _pieceCol)) {
            _pieceRow += 1;
        } else {
            lockPiece();
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var label = _gameOver ? "Game Over  " + _score.toString() + "  Best:" + _highScore.toString() : "Score:" + _score.toString() + " Best:" + _highScore.toString();
        dc.drawText(_width / 2, 2, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        // Locked board
        var r = 0;
        while (r < _rows) {
            var c = 0;
            while (c < _cols) {
                var v = _board[r][c];
                if (v != 0) {
                    var color = _colors[v - 1];
                    dc.setColor(color, color);
                    dc.fillRectangle(_boardLeft + c * _cellSize, _boardTop + r * _cellSize, _cellSize - 1, _cellSize - 1);
                }
                c++;
            }
            r++;
        }

        // Falling piece
        if (!_gameOver) {
            var cells = getPieceCells(_pieceType, _pieceRotation);
            var color = _colors[_pieceType];
            dc.setColor(color, color);
            var i = 0;
            while (i < cells.size()) {
                var pr = _pieceRow + cells[i][0];
                var pc = _pieceCol + cells[i][1];
                if (pr >= 0) {
                    dc.fillRectangle(_boardLeft + pc * _cellSize, _boardTop + pr * _cellSize, _cellSize - 1, _cellSize - 1);
                }
                i++;
            }
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(_boardLeft, _boardTop, _cellSize * _cols, _cellSize * _rows);
    }

}
