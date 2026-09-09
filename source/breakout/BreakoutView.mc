import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Math;

class BreakoutView extends WatchUi.View {

    private const ROWS = 5;
    private const COLS = 6;
    private const PADDLE_HEIGHT = 6;
    private const BALL_RADIUS = 4;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _boardSize as Number = 0;
    private var _brickW as Number = 0;
    private var _brickH as Number = 10;
    private var _paddleWidth as Number = 0;

    private var _bricks as Array<Array<Boolean> >;
    private var _paddleX as Float = 0.0;
    private var _ballX as Float = 0.0;
    private var _ballY as Float = 0.0;
    private var _ballVelX as Float = 2.2;
    private var _ballVelY as Float = -2.2;
    private var _score as Number = 0;
    private var _lives as Number = 3;
    private var _gameOver as Boolean = false;
    private var _won as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _bricks = [];
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _boardSize = BoardMetrics.squareBoardSize(_width, _height, 16);
        _boardLeft = (_width - _boardSize) / 2;
        _boardTop = (_height - _boardSize) / 2;
        _brickW = _boardSize / COLS;
        _paddleWidth = _boardSize / 5;
        resetGame();
    }

    function resetGame() as Void {
        _bricks = [];
        var r = 0;
        while (r < ROWS) {
            var row = [] as Array<Boolean>;
            var c = 0;
            while (c < COLS) {
                row.add(true);
                c++;
            }
            _bricks.add(row);
            r++;
        }
        _paddleX = _boardLeft + (_boardSize - _paddleWidth) / 2.0;
        _score = 0;
        _lives = 3;
        _gameOver = false;
        _won = false;
        resetBall();
        WatchUi.requestUpdate();
    }

    private function randomFloat(min as Float, max as Float) as Float {
        var rnd = (Math.rand() % 10000).abs() / 10000.0;
        return min + (max - min) * rnd;
    }

    private function resetBall() as Void {
        _ballX = _boardLeft + _boardSize / 2.0;
        _ballY = _boardTop + _boardSize * 0.7;
        _ballVelX = randomFloat(-1.5, 1.5);
        _ballVelY = -2.5;
    }

    function movePaddle(dx as Float) as Void {
        setPaddleLeft(_paddleX + dx);
    }

    function setPaddleCenterX(centerX as Number) as Void {
        setPaddleLeft(centerX - _paddleWidth / 2.0);
    }

    private function setPaddleLeft(x as Float) as Void {
        var min = _boardLeft.toFloat();
        var max = (_boardLeft + _boardSize - _paddleWidth).toFloat();
        if (x < min) { x = min; }
        if (x > max) { x = max; }
        _paddleX = x;
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), 25, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTimerTick() as Void {
        if (!_gameOver && !_won) {
            updateGame();
        }
        WatchUi.requestUpdate();
    }

    private function updateGame() as Void {
        _ballX += _ballVelX;
        _ballY += _ballVelY;

        if (_ballX - BALL_RADIUS <= _boardLeft) {
            _ballX = (_boardLeft + BALL_RADIUS).toFloat();
            _ballVelX = -_ballVelX;
        } else if (_ballX + BALL_RADIUS >= _boardLeft + _boardSize) {
            _ballX = (_boardLeft + _boardSize - BALL_RADIUS).toFloat();
            _ballVelX = -_ballVelX;
        }
        if (_ballY - BALL_RADIUS <= _boardTop) {
            _ballY = (_boardTop + BALL_RADIUS).toFloat();
            _ballVelY = -_ballVelY;
        }

        // Paddle collision
        var paddleY = _boardTop + _boardSize - PADDLE_HEIGHT - 2;
        if (_ballY + BALL_RADIUS >= paddleY && _ballY + BALL_RADIUS <= paddleY + PADDLE_HEIGHT + 4 && _ballVelY > 0) {
            if (_ballX >= _paddleX - BALL_RADIUS && _ballX <= _paddleX + _paddleWidth + BALL_RADIUS) {
                _ballVelY = -_ballVelY.abs();
                // Deflect based on where it hit the paddle, plus a small random nudge.
                var hitPos = (_ballX - _paddleX) / _paddleWidth - 0.5;
                _ballVelX = hitPos * 5.0 + randomFloat(-0.3, 0.3);
            }
        }

        // Brick collision (cell the ball currently occupies)
        var row = ((_ballY - _boardTop) / _brickH).toNumber();
        var col = ((_ballX - _boardLeft) / _brickW).toNumber();
        if (row >= 0 && row < ROWS && col >= 0 && col < COLS && _bricks[row][col]) {
            _bricks[row][col] = false;
            _ballVelY = -_ballVelY;
            _score += 1;
            if (allBricksCleared()) {
                _won = true;
            }
        }

        if (_ballY - BALL_RADIUS > _boardTop + _boardSize) {
            _lives -= 1;
            if (_lives <= 0) {
                _gameOver = true;
            } else {
                resetBall();
            }
        }
    }

    private function allBricksCleared() as Boolean {
        var r = 0;
        while (r < ROWS) {
            var c = 0;
            while (c < COLS) {
                if (_bricks[r][c]) {
                    return false;
                }
                c++;
            }
            r++;
        }
        return true;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, "Score:" + _score.toString() + "  Lives:" + _lives.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        var colors = [Graphics.COLOR_RED, Graphics.COLOR_ORANGE, Graphics.COLOR_YELLOW, Graphics.COLOR_GREEN, Graphics.COLOR_BLUE] as Array<Number>;
        var r = 0;
        while (r < ROWS) {
            var c = 0;
            while (c < COLS) {
                if (_bricks[r][c]) {
                    var color = colors[r % colors.size()];
                    dc.setColor(color, color);
                    dc.fillRectangle(_boardLeft + c * _brickW + 1, _boardTop + r * _brickH + 1, _brickW - 2, _brickH - 2);
                }
                c++;
            }
            r++;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        var paddleY = _boardTop + _boardSize - PADDLE_HEIGHT - 2;
        dc.fillRectangle(_paddleX.toNumber(), paddleY, _paddleWidth, PADDLE_HEIGHT);

        dc.fillCircle(_ballX.toNumber(), _ballY.toNumber(), BALL_RADIUS);

        if (_gameOver || _won) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var msg = _won ? "You Win!" : "Game Over";
            dc.drawText(_width / 2, _height / 2, Graphics.FONT_SMALL, msg, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
