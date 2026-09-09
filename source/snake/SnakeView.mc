import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Math;

class SnakeView extends WatchUi.View {

    private const GRID_SIZE = 12;
    private const DIR_UP = 0;
    private const DIR_DOWN = 1;
    private const DIR_LEFT = 2;
    private const DIR_RIGHT = 3;

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
    private var _gameOver as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _body = [];
        _food = [0, 0];
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        var boardSize = BoardMetrics.squareBoardSize(_width, _height, 16);
        _cellSize = boardSize / GRID_SIZE;
        boardSize = _cellSize * GRID_SIZE;
        _boardLeft = (_width - boardSize) / 2;
        _boardTop = (_height - boardSize) / 2;
        resetGame();
    }

    function resetGame() as Void {
        var mid = GRID_SIZE / 2;
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
            var r = (Math.rand() % GRID_SIZE).abs();
            var c = (Math.rand() % GRID_SIZE).abs();
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
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), 160, true);
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

        if (r < 0 || r >= GRID_SIZE || c < 0 || c >= GRID_SIZE) {
            _gameOver = true;
            return;
        }

        var ateFood = (r == _food[0] && c == _food[1]);

        // Growing keeps the tail in place; otherwise the tail moves with it,
        // so the cell it's vacating is not itself a collision.
        var bodyToCheck = ateFood ? _body : _body.slice(1, null) as Array<Array<Number> >;
        if (occupiesCellIn(bodyToCheck, r, c)) {
            _gameOver = true;
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
        var label = _gameOver ? "Game Over  " + _score.toString() : "Score: " + _score.toString();
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        dc.fillRectangle(_boardLeft + _food[1] * _cellSize, _boardTop + _food[0] * _cellSize, _cellSize, _cellSize);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        var i = 0;
        while (i < _body.size()) {
            var seg = _body[i];
            dc.fillRectangle(_boardLeft + seg[1] * _cellSize, _boardTop + seg[0] * _cellSize, _cellSize - 1, _cellSize - 1);
            i++;
        }
    }

}
