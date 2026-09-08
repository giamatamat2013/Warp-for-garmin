import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

class Game2048View extends WatchUi.View {

    private const GRID_SIZE = 4;

    private var _grid as Array<Array<Number> >;
    private var _score as Number = 0;
    private var _gameOver as Boolean = false;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;
    private var _cellGap as Number = 4;

    function initialize() {
        View.initialize();
        _grid = newEmptyGrid();
        spawnRandomTile();
        spawnRandomTile();
    }

    private function newEmptyGrid() as Array<Array<Number> > {
        var grid = [] as Array<Array<Number> >;
        for (var r = 0; r < GRID_SIZE; r++) {
            grid.add([0, 0, 0, 0]);
        }
        return grid;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        var minDim = (_width < _height ? _width : _height);
        var isRound = (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND);

        var boardSize;
        if (isRound) {
            // A square board's corners sit farther from the center than its
            // edges, so it must shrink to the circle's inscribed square
            // (side = radius * sqrt(2)) to stay clear of the round bezel.
            boardSize = (minDim / 2.0 * Math.sqrt(2.0) * 0.94).toNumber();
        } else {
            boardSize = minDim - 16;
        }

        _cellSize = (boardSize - _cellGap * (GRID_SIZE + 1)) / GRID_SIZE;
        boardSize = _cellSize * GRID_SIZE + _cellGap * (GRID_SIZE + 1);
        _boardTop = (_height - boardSize) / 2;
        if (_boardTop < 24) {
            _boardTop = 24;
        }
    }

    function resetGame() as Void {
        _grid = newEmptyGrid();
        _score = 0;
        _gameOver = false;
        spawnRandomTile();
        spawnRandomTile();
        WatchUi.requestUpdate();
    }

    function handleSwipe(direction as WatchUi.SwipeDirection) as Void {
        if (_gameOver) {
            return;
        }
        var before = flatten();
        if (direction == WatchUi.SWIPE_LEFT) {
            moveLeft();
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            moveRight();
        } else if (direction == WatchUi.SWIPE_UP) {
            moveUp();
        } else if (direction == WatchUi.SWIPE_DOWN) {
            moveDown();
        } else {
            return;
        }
        var after = flatten();
        if (!arraysEqual(before, after)) {
            spawnRandomTile();
            if (isGameOver()) {
                _gameOver = true;
            }
        }
        WatchUi.requestUpdate();
    }

    private function flatten() as Array<Number> {
        var out = [] as Array<Number>;
        for (var r = 0; r < GRID_SIZE; r++) {
            for (var c = 0; c < GRID_SIZE; c++) {
                out.add(_grid[r][c]);
            }
        }
        return out;
    }

    private function arraysEqual(a as Array<Number>, b as Array<Number>) as Boolean {
        for (var i = 0; i < a.size(); i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }

    // Slides non-zero values together and merges equal adjacent pairs, in
    // order, padding the result back out to GRID_SIZE with zeros.
    private function processLine(line as Array<Number>) as Array<Number> {
        var vals = [] as Array<Number>;
        for (var i = 0; i < line.size(); i++) {
            if (line[i] != 0) {
                vals.add(line[i]);
            }
        }
        var merged = [] as Array<Number>;
        var i = 0;
        while (i < vals.size()) {
            if (i + 1 < vals.size() && vals[i] == vals[i + 1]) {
                var v = vals[i] * 2;
                merged.add(v);
                _score += v;
                i += 2;
            } else {
                merged.add(vals[i]);
                i += 1;
            }
        }
        while (merged.size() < GRID_SIZE) {
            merged.add(0);
        }
        return merged;
    }

    private function reversed(line as Array<Number>) as Array<Number> {
        var out = [] as Array<Number>;
        for (var i = line.size() - 1; i >= 0; i--) {
            out.add(line[i]);
        }
        return out;
    }

    private function moveLeft() as Void {
        for (var r = 0; r < GRID_SIZE; r++) {
            _grid[r] = processLine(_grid[r]);
        }
    }

    private function moveRight() as Void {
        for (var r = 0; r < GRID_SIZE; r++) {
            _grid[r] = reversed(processLine(reversed(_grid[r])));
        }
    }

    private function getCol(c as Number) as Array<Number> {
        var col = [] as Array<Number>;
        for (var r = 0; r < GRID_SIZE; r++) {
            col.add(_grid[r][c]);
        }
        return col;
    }

    private function setCol(c as Number, col as Array<Number>) as Void {
        for (var r = 0; r < GRID_SIZE; r++) {
            _grid[r][c] = col[r];
        }
    }

    private function moveUp() as Void {
        for (var c = 0; c < GRID_SIZE; c++) {
            setCol(c, processLine(getCol(c)));
        }
    }

    private function moveDown() as Void {
        for (var c = 0; c < GRID_SIZE; c++) {
            setCol(c, reversed(processLine(reversed(getCol(c)))));
        }
    }

    private function spawnRandomTile() as Void {
        var empty = [] as Array<[Number, Number]>;
        for (var r = 0; r < GRID_SIZE; r++) {
            for (var c = 0; c < GRID_SIZE; c++) {
                if (_grid[r][c] == 0) {
                    empty.add([r, c]);
                }
            }
        }
        if (empty.size() == 0) {
            return;
        }
        var pick = empty[(Math.rand() % empty.size()).abs()];
        var value = ((Math.rand() % 10).abs() == 0) ? 4 : 2;
        _grid[pick[0]][pick[1]] = value;
    }

    private function isGameOver() as Boolean {
        for (var r = 0; r < GRID_SIZE; r++) {
            for (var c = 0; c < GRID_SIZE; c++) {
                if (_grid[r][c] == 0) {
                    return false;
                }
                if (c + 1 < GRID_SIZE && _grid[r][c] == _grid[r][c + 1]) {
                    return false;
                }
                if (r + 1 < GRID_SIZE && _grid[r][c] == _grid[r + 1][c]) {
                    return false;
                }
            }
        }
        return true;
    }

    private function tileColor(v as Number) as Number {
        if (v <= 0) { return Graphics.COLOR_LT_GRAY; }
        if (v == 2) { return Graphics.COLOR_WHITE; }
        if (v == 4) { return Graphics.COLOR_YELLOW; }
        if (v == 8) { return Graphics.COLOR_ORANGE; }
        if (v == 16) { return Graphics.COLOR_DK_RED; }
        if (v == 32) { return Graphics.COLOR_RED; }
        if (v == 64) { return Graphics.COLOR_PURPLE; }
        if (v == 128) { return Graphics.COLOR_PINK; }
        if (v == 256) { return Graphics.COLOR_DK_BLUE; }
        if (v == 512) { return Graphics.COLOR_BLUE; }
        if (v == 1024) { return Graphics.COLOR_DK_GREEN; }
        return Graphics.COLOR_GREEN;
    }

    private function textColor(v as Number) as Number {
        return (v > 0 && v <= 4) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var label = _gameOver ? "Game Over  " + _score.toString() : "Score: " + _score.toString();
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        for (var r = 0; r < GRID_SIZE; r++) {
            for (var c = 0; c < GRID_SIZE; c++) {
                var x = (_width - (_cellSize * GRID_SIZE + _cellGap * (GRID_SIZE + 1))) / 2 + _cellGap + c * (_cellSize + _cellGap);
                var y = _boardTop + _cellGap + r * (_cellSize + _cellGap);
                var v = _grid[r][c];
                dc.setColor(tileColor(v), tileColor(v));
                dc.fillRoundedRectangle(x, y, _cellSize, _cellSize, 4);
                if (v > 0) {
                    dc.setColor(textColor(v), Graphics.COLOR_TRANSPARENT);
                    dc.drawText(x + _cellSize / 2, y + _cellSize / 2 - 8, Graphics.FONT_TINY, v.toString(), Graphics.TEXT_JUSTIFY_CENTER);
                }
            }
        }
    }

}
