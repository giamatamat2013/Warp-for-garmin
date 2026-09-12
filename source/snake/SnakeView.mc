import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Math;

class SnakeView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "snake_high";
    private const BASE_TICK_MS = 240;
    private const DIR_UP = 0;
    private const DIR_DOWN = 1;
    private const DIR_LEFT = 2;
    private const DIR_RIGHT = 3;

    private var _gridSize as Number = 12;
    private var _speedMultiplier as Float = 1.0;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;

    private var _body as Array<Array<Number> >;
    private var _direction as Number = DIR_RIGHT;
    private var _pendingDirection as Number = DIR_RIGHT;
    private var _food as Array<Number>;
    private var _score as Number = 0;
    private var _highScore as Number = 0;
    private var _gameOver as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _body = [];
        _food = [0, 0];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        layoutBoard();
        resetGame();
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

    // Callback target for NumberKeypadDelegate — see item_grid_custom in
    // SnakeMenuDelegate.
    function onCustomBoardSize(value as Number) as Void {
        setBoardSize(value);
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
        restartTimer();
    }

    function resetGame() as Void {
        var mid = _gridSize / 2;
        _body = [[mid, mid - 1], [mid, mid], [mid, mid + 1]] as Array<Array<Number> >;
        _direction = DIR_RIGHT;
        _pendingDirection = DIR_RIGHT;
        _score = 0;
        _gameOver = false;
        spawnFood();
        WatchUi.requestUpdate();
    }

    private function spawnFood() as Void {
        while (true) {
            var r = (Math.rand() % _gridSize).abs();
            var c = (Math.rand() % _gridSize).abs();
            if (!occupiesCellIn(_body, r, c)) {
                _food = [r, c];
                return;
            }
        }
    }

    function setDirection(dir as Number) as Void {
        // Disallow reversing directly into the body.
        if (dir == DIR_UP && _direction == DIR_DOWN) { return; }
        if (dir == DIR_DOWN && _direction == DIR_UP) { return; }
        if (dir == DIR_LEFT && _direction == DIR_RIGHT) { return; }
        if (dir == DIR_RIGHT && _direction == DIR_LEFT) { return; }
        _pendingDirection = dir;
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
        var interval = (BASE_TICK_MS / _speedMultiplier).toNumber();
        _timer.start(method(:onTimerTick), interval, true);
    }

    function onTimerTick() as Void {
        if (!_gameOver) {
            updateGame();
        }
        WatchUi.requestUpdate();
    }

    private function updateGame() as Void {
        _direction = _pendingDirection;
        var head = _body[_body.size() - 1];
        var r = head[0];
        var c = head[1];
        if (_direction == DIR_UP) {
            r -= 1;
        } else if (_direction == DIR_DOWN) {
            r += 1;
        } else if (_direction == DIR_LEFT) {
            c -= 1;
        } else {
            c += 1;
        }

        if (r < 0 || r >= _gridSize || c < 0 || c >= _gridSize) {
            markGameOver();
            return;
        }

        var ateFood = (r == _food[0] && c == _food[1]);

        // Growing keeps the tail in place; otherwise the tail moves with it,
        // so the cell it's vacating is not itself a collision.
        var bodyToCheck = ateFood ? _body : _body.slice(1, null) as Array<Array<Number> >;
        if (occupiesCellIn(bodyToCheck, r, c)) {
            markGameOver();
            return;
        }

        if (!ateFood) {
            _body = _body.slice(1, null) as Array<Array<Number> >;
        }
        _body.add([r, c]);

        if (ateFood) {
            _score += 1;
            spawnFood();
        }
    }

    private function markGameOver() as Void {
        _gameOver = true;
        HighScores.submit(HIGH_SCORE_KEY, _score);
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    private function occupiesCellIn(body as Array<Array<Number> >, r as Number, c as Number) as Boolean {
        var i = 0;
        while (i < body.size()) {
            if (body[i][0] == r && body[i][1] == c) {
                return true;
            }
            i++;
        }
        return false;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var label = _gameOver ? "Game Over  " + _score.toString() + "  Best:" + _highScore.toString() : "Score: " + _score.toString() + "  Best:" + _highScore.toString();
        dc.drawText(_width / 2, 2, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var boardSize = _cellSize * _gridSize;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(_boardLeft, _boardTop, boardSize, boardSize);

        drawApple(dc);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        var i = 0;
        while (i < _body.size()) {
            var seg = _body[i];
            dc.fillRectangle(_boardLeft + seg[1] * _cellSize, _boardTop + seg[0] * _cellSize, _cellSize - 1, _cellSize - 1);
            i++;
        }

        drawFace(dc);
    }

    // A round red apple with a small stem and leaf, instead of a plain square.
    private function drawApple(dc as Dc) as Void {
        var cx = _boardLeft + _food[1] * _cellSize + _cellSize / 2;
        var cy = _boardTop + _food[0] * _cellSize + _cellSize / 2;
        var r = _cellSize / 2;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        dc.fillCircle(cx, cy, r);
        // A small light patch gives the apple a bit of shine/roundness.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - r / 3, cy - r / 3, (r / 4).toNumber() > 0 ? r / 4 : 1);

        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, cy - r, cx, cy - r - 2);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [cx, cy - r - 1],
            [cx + r / 2, cy - r - 2],
            [cx + 1, cy - r]
        ] as Array<[Numeric, Numeric]>);
    }

    // A pair of eyes on the head cell, shifted toward whichever direction
    // the snake is currently moving so it visibly "looks" that way.
    private function drawFace(dc as Dc) as Void {
        var head = _body[_body.size() - 1];
        var cx = _boardLeft + head[1] * _cellSize + _cellSize / 2;
        var cy = _boardTop + head[0] * _cellSize + _cellSize / 2;
        var forward = _cellSize / 4;
        var side = _cellSize / 4;
        var eye1x = cx;
        var eye1y = cy;
        var eye2x = cx;
        var eye2y = cy;
        if (_direction == DIR_RIGHT) {
            eye1x = cx + forward; eye1y = cy - side;
            eye2x = cx + forward; eye2y = cy + side;
        } else if (_direction == DIR_LEFT) {
            eye1x = cx - forward; eye1y = cy - side;
            eye2x = cx - forward; eye2y = cy + side;
        } else if (_direction == DIR_UP) {
            eye1x = cx - side; eye1y = cy - forward;
            eye2x = cx + side; eye2y = cy - forward;
        } else {
            eye1x = cx - side; eye1y = cy + forward;
            eye2x = cx + side; eye2y = cy + forward;
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(eye1x, eye1y, 1);
        dc.fillCircle(eye2x, eye2y, 1);
    }

}
