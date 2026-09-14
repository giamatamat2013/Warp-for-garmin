import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.Math;

// Tilt Maze: roll a ball through a procedurally generated maze using tilt.
// Reaching the exit (bottom-right) advances to the next level.
class TiltMazeView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "tiltmaze_high";
    private const BASE_TICK_MS = 33;
    private const TILT_ACCEL = 700.0;
    private const DAMPING = 0.90;

    private var _gridSize as Number = 9;
    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _boardSize as Number = 0;
    private var _cellSize as Float = 0.0;
    private var _ballRadius as Float = 0.0;

    // Maze walls: true = wall present
    private var _wallsH as Array<Boolean>; // size (N-1)*N
    private var _wallsV as Array<Boolean>; // size N*(N-1)

    // Ball physics
    private var _ballX as Float = 0.0;
    private var _ballY as Float = 0.0;
    private var _vx as Float = 0.0;
    private var _vy as Float = 0.0;

    private var _accelX as Number = 0;
    private var _accelY as Number = 0;
    private var _calX as Number = 0;
    private var _calY as Number = 0;

    private var _level as Number = 1;
    private var _highScore as Number = 0;
    private var _levelWon as Boolean = false;
    private var _winTimer as Number = 0;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _wallsH = [];
        _wallsV = [];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _boardSize = BoardMetrics.squareBoardSize(_width, _height, 18);
        _boardLeft = (_width - _boardSize) / 2;
        _boardTop = (_height - _boardSize) / 2 + 6;
        _cellSize = _boardSize.toFloat() / _gridSize.toFloat();
        _ballRadius = _cellSize * 0.32;
        resetGame();
    }

    function setGridSize(size as Number) as Void {
        _gridSize = size;
        if (_width > 0) {
            _cellSize = _boardSize.toFloat() / _gridSize.toFloat();
            _ballRadius = _cellSize * 0.32;
        }
        _level = 1;
        resetGame();
    }

    function resetGame() as Void {
        generateMaze();
        resetBall();
        calibrate();
        WatchUi.requestUpdate();
    }

    private function resetBall() as Void {
        _ballX = _boardLeft + _cellSize / 2.0;
        _ballY = _boardTop + _cellSize / 2.0;
        _vx = 0.0;
        _vy = 0.0;
        _levelWon = false;
        _winTimer = 0;
    }

    private function calibrate() as Void {
        _calX = _accelX;
        _calY = _accelY;
    }

    function onSensorInfo(info as Sensor.Info) as Void {
        var accel = info.accel;
        if (accel != null) {
            _accelX = accel[0];
            _accelY = accel[1];
        }
    }

    function nudge(dx as Float, dy as Float) as Void {
        _vx += dx;
        _vy += dy;
    }

    private function generateMaze() as Void {
        var n = _gridSize;
        var hSize = (n - 1) * n;
        var vSize = n * (n - 1);
        _wallsH = [] as Array<Boolean>;
        _wallsV = [] as Array<Boolean>;

        var i = 0;
        while (i < hSize) {
            _wallsH.add(true);
            i++;
        }
        i = 0;
        while (i < vSize) {
            _wallsV.add(true);
            i++;
        }

        var totalCells = n * n;
        var visited = [] as Array<Boolean>;
        i = 0;
        while (i < totalCells) {
            visited.add(false);
            i++;
        }

        var stack = [] as Array<Number>;
        stack.add(0);
        visited[0] = true;

        while (stack.size() > 0) {
            var curr = stack[stack.size() - 1];
            var cr = (curr / n).toNumber();
            var cc = curr % n;

            // Find unvisited neighbors
            var unvisited = [] as Array<Number>; // stores direction: 0=up, 1=down, 2=left, 3=right
            if (cr > 0 && !visited[(cr - 1) * n + cc]) { unvisited.add(0); }
            if (cr < n - 1 && !visited[(cr + 1) * n + cc]) { unvisited.add(1); }
            if (cc > 0 && !visited[cr * n + (cc - 1)]) { unvisited.add(2); }
            if (cc < n - 1 && !visited[cr * n + (cc + 1)]) { unvisited.add(3); }

            if (unvisited.size() > 0) {
                var pick = (Math.rand() % unvisited.size()).abs();
                var dir = unvisited[pick];
                var nextR = cr;
                var nextC = cc;

                if (dir == 0) { // UP
                    nextR = cr - 1;
                    _wallsH[nextR * n + cc] = false;
                } else if (dir == 1) { // DOWN
                    nextR = cr + 1;
                    _wallsH[cr * n + cc] = false;
                } else if (dir == 2) { // LEFT
                    nextC = cc - 1;
                    _wallsV[cr * (n - 1) + nextC] = false;
                } else if (dir == 3) { // RIGHT
                    nextC = cc + 1;
                    _wallsV[cr * (n - 1) + cc] = false;
                }

                var nextIdx = nextR * n + nextC;
                visited[nextIdx] = true;
                stack.add(nextIdx);
            } else {
                stack = stack.slice(0, stack.size() - 1) as Array<Number>;
            }
        }
    }

    function onShow() as Void {
        try {
            Sensor.enableSensorEvents(method(:onSensorInfo));
        } catch (e) {
            // Non-accelerometer fallback
        }
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), BASE_TICK_MS, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        Sensor.enableSensorEvents(null);
    }

    function onTimerTick() as Void {
        if (_levelWon) {
            _winTimer += 1;
            if (_winTimer > 40) {
                _level += 1;
                generateMaze();
                resetBall();
            }
        } else {
            updateGame();
        }
        WatchUi.requestUpdate();
    }

    private function updateGame() as Void {
        var dt = BASE_TICK_MS / 1000.0;
        var tiltX = TiltSensor.normalize(_accelX, _calX);
        var tiltY = TiltSensor.normalize(_accelY, _calY);

        _vx += tiltX * TILT_ACCEL * dt;
        _vy -= tiltY * TILT_ACCEL * dt;
        _vx *= DAMPING;
        _vy *= DAMPING;

        var prevX = _ballX;
        var prevY = _ballY;

        _ballX += _vx * dt;
        _ballY += _vy * dt;

        // Outer board bounds
        var minX = _boardLeft + _ballRadius;
        var maxX = _boardLeft + _boardSize - _ballRadius;
        var minY = _boardTop + _ballRadius;
        var maxY = _boardTop + _boardSize - _ballRadius;

        if (_ballX < minX) { _ballX = minX; _vx = 0.0; }
        if (_ballX > maxX) { _ballX = maxX; _vx = 0.0; }
        if (_ballY < minY) { _ballY = minY; _vy = 0.0; }
        if (_ballY > maxY) { _ballY = maxY; _vy = 0.0; }

        // Collision with inner walls
        var n = _gridSize;
        var r = ((prevY - _boardTop) / _cellSize).toNumber();
        var c = ((prevX - _boardLeft) / _cellSize).toNumber();
        if (r < 0) { r = 0; }
        if (r >= n) { r = n - 1; }
        if (c < 0) { c = 0; }
        if (c >= n) { c = n - 1; }

        // Check 4 boundaries of current cell (r, c)
        // Top boundary: wall between r-1 and r (if r > 0)
        if (r > 0 && _wallsH[(r - 1) * n + c]) {
            var wy = _boardTop + r * _cellSize;
            if (_ballY - _ballRadius < wy) {
                _ballY = wy + _ballRadius;
                _vy = 0.0;
            }
        }
        // Bottom boundary: wall between r and r+1 (if r < n-1)
        if (r < n - 1 && _wallsH[r * n + c]) {
            var wy = _boardTop + (r + 1) * _cellSize;
            if (_ballY + _ballRadius > wy) {
                _ballY = wy - _ballRadius;
                _vy = 0.0;
            }
        }
        // Left boundary: wall between c-1 and c (if c > 0)
        if (c > 0 && _wallsV[r * (n - 1) + (c - 1)]) {
            var wx = _boardLeft + c * _cellSize;
            if (_ballX - _ballRadius < wx) {
                _ballX = wx + _ballRadius;
                _vx = 0.0;
            }
        }
        // Right boundary: wall between c and c+1 (if c < n-1)
        if (c < n - 1 && _wallsV[r * (n - 1) + c]) {
            var wx = _boardLeft + (c + 1) * _cellSize;
            if (_ballX + _ballRadius > wx) {
                _ballX = wx - _ballRadius;
                _vx = 0.0;
            }
        }

        // Check if reached exit: bottom-right cell
        var exitX = _boardLeft + (n - 0.5) * _cellSize;
        var exitY = _boardTop + (n - 0.5) * _cellSize;
        var dx = _ballX - exitX;
        var dy = _ballY - exitY;
        if (Math.sqrt(dx * dx + dy * dy) < _cellSize * 0.45) {
            _levelWon = true;
            HighScores.submit(HIGH_SCORE_KEY, _level);
            _highScore = HighScores.get(HIGH_SCORE_KEY);
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Top HUD
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_width / 2, 2, Graphics.FONT_XTINY, "Level: " + _level.toString() + "  Best: " + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        var n = _gridSize;

        // Draw exit goal (green/red marker)
        var exitCellX = (_boardLeft + (n - 1) * _cellSize).toNumber();
        var exitCellY = (_boardTop + (n - 1) * _cellSize).toNumber();
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
        dc.fillRectangle(exitCellX + 1, exitCellY + 1, (_cellSize - 2).toNumber(), (_cellSize - 2).toNumber());

        // Draw walls
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        // Outer border
        dc.drawRectangle(_boardLeft, _boardTop, _boardSize, _boardSize);

        // Horizontal walls
        var r = 0;
        while (r < n - 1) {
            var c = 0;
            while (c < n) {
                if (_wallsH[r * n + c]) {
                    var x1 = (_boardLeft + c * _cellSize).toNumber();
                    var x2 = (_boardLeft + (c + 1) * _cellSize).toNumber();
                    var y = (_boardTop + (r + 1) * _cellSize).toNumber();
                    dc.drawLine(x1, y, x2, y);
                }
                c++;
            }
            r++;
        }

        // Vertical walls
        r = 0;
        while (r < n) {
            var c = 0;
            while (c < n - 1) {
                if (_wallsV[r * (n - 1) + c]) {
                    var x = (_boardLeft + (c + 1) * _cellSize).toNumber();
                    var y1 = (_boardTop + r * _cellSize).toNumber();
                    var y2 = (_boardTop + (r + 1) * _cellSize).toNumber();
                    dc.drawLine(x, y1, x, y2);
                }
                c++;
            }
            r++;
        }

        // Draw Ball
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        dc.fillCircle(_ballX.toNumber(), _ballY.toNumber(), _ballRadius.toNumber());

        // Level Won overlay
        if (_levelWon) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_width / 2, _height / 2 - 10, Graphics.FONT_SMALL, "Level Complete!", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
