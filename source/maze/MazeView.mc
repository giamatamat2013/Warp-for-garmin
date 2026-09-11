import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.Math;

// Tilt the watch to roll the ball through the maze to the green goal cell.
// No score, no timer, no difficulty - just get there, then reset for a new
// maze. Movement is continuous physics (like BalanceBallView), not a
// grid-cell hop, so the ball actually rolls down corridors and bounces off
// walls the way a real ball would.
class MazeView extends WatchUi.View {

    private const GRID_SIZE = 9;
    private const BASE_TICK_MS = 50;
    private const TILT_ACCEL = 900.0; // px/s^2 at full tilt deflection
    private const DAMPING = 0.985;
    // Capped so a single tick's movement can't cross more than one cell,
    // which is what keeps the per-axis wall walk in moveX/moveY correct.
    private const MAX_SPEED = 350.0; // px/s

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Float = 0.0;
    private var _boardTop as Float = 0.0;
    private var _cellSize as Float = 0.0;
    private var _ballRadius as Float = 6.0;

    private var _wallRight as Array<Array<Boolean> >;
    private var _wallDown as Array<Array<Boolean> >;

    private var _ballX as Float = 0.0;
    private var _ballY as Float = 0.0;
    private var _vx as Float = 0.0;
    private var _vy as Float = 0.0;
    private var _goalX as Float = 0.0;
    private var _goalY as Float = 0.0;

    private var _accelX as Number = 0;
    private var _accelY as Number = 0;
    private var _calX as Number = 0;
    private var _calY as Number = 0;

    private var _solved as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _wallRight = [];
        _wallDown = [];
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        layoutBoard();
        resetGame();
    }

    private function layoutBoard() as Void {
        var boardSize = BoardMetrics.squareBoardSize(_width, _height, 16);
        _cellSize = boardSize / GRID_SIZE.toFloat();
        _boardLeft = (_width - boardSize) / 2.0;
        _boardTop = (_height - boardSize) / 2.0;
        _ballRadius = _cellSize * 0.28;
    }

    function resetGame() as Void {
        generateMaze();
        _ballX = _boardLeft + _cellSize / 2.0;
        _ballY = _boardTop + _cellSize / 2.0;
        _goalX = _boardLeft + (GRID_SIZE - 0.5) * _cellSize;
        _goalY = _boardTop + (GRID_SIZE - 0.5) * _cellSize;
        _vx = 0.0;
        _vy = 0.0;
        _solved = false;
        calibrate();
        WatchUi.requestUpdate();
    }

    // Captures the current tilt as "flat" so the ball doesn't roll just
    // because the watch happens to be worn at a slight natural angle.
    private function calibrate() as Void {
        _calX = _accelX;
        _calY = _accelY;
    }

    // Recursive-backtracker maze generation: carve a random spanning tree
    // over the grid, leaving exactly one path between any two cells.
    private function generateMaze() as Void {
        var r;
        var c;
        _wallRight = new Array<Array<Boolean> >[GRID_SIZE];
        _wallDown = new Array<Array<Boolean> >[GRID_SIZE];
        var visited = new Array<Array<Boolean> >[GRID_SIZE];
        for (r = 0; r < GRID_SIZE; r++) {
            _wallRight[r] = new Array<Boolean>[GRID_SIZE];
            _wallDown[r] = new Array<Boolean>[GRID_SIZE];
            visited[r] = new Array<Boolean>[GRID_SIZE];
            for (c = 0; c < GRID_SIZE; c++) {
                _wallRight[r][c] = true;
                _wallDown[r][c] = true;
                visited[r][c] = false;
            }
        }

        var stack = [[0, 0]] as Array<Array<Number> >;
        visited[0][0] = true;
        while (stack.size() > 0) {
            var cur = stack[stack.size() - 1];
            var cr = cur[0];
            var cc = cur[1];
            var neighbors = [] as Array<Array<Number> >;
            if (cr > 0 && !visited[cr - 1][cc]) { neighbors.add([cr - 1, cc, 0]); }
            if (cr < GRID_SIZE - 1 && !visited[cr + 1][cc]) { neighbors.add([cr + 1, cc, 1]); }
            if (cc > 0 && !visited[cr][cc - 1]) { neighbors.add([cr, cc - 1, 2]); }
            if (cc < GRID_SIZE - 1 && !visited[cr][cc + 1]) { neighbors.add([cr, cc + 1, 3]); }

            if (neighbors.size() == 0) {
                stack = stack.slice(0, stack.size() - 1) as Array<Array<Number> >;
            } else {
                var pick = neighbors[(Math.rand() % neighbors.size()).abs()];
                var nr = pick[0];
                var nc = pick[1];
                var dir = pick[2];
                if (dir == 0) {
                    _wallDown[nr][nc] = false;
                } else if (dir == 1) {
                    _wallDown[cr][cc] = false;
                } else if (dir == 2) {
                    _wallRight[nr][nc] = false;
                } else {
                    _wallRight[cr][cc] = false;
                }
                visited[nr][nc] = true;
                stack.add([nr, nc]);
            }
        }
    }

    function onSensorInfo(info as Sensor.Info) as Void {
        var accel = info.accel;
        if (accel != null) {
            _accelX = accel[0];
            _accelY = accel[1];
        }
    }

    // Fallback control for devices/simulators without live accelerometer
    // input: each press nudges the ball like a firm tilt in that direction.
    function nudge(dx as Float, dy as Float) as Void {
        _vx += dx;
        _vy += dy;
    }

    function onShow() as Void {
        try {
            Sensor.enableSensorEvents(method(:onSensorInfo));
        } catch (e) {
            // No accelerometer available; the key-nudge fallback still works.
        }
        restartTimer();
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        Sensor.enableSensorEvents(null);
    }

    private function restartTimer() as Void {
        if (_timer != null) {
            _timer.stop();
        }
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), BASE_TICK_MS, true);
    }

    function onTimerTick() as Void {
        if (!_solved) {
            updatePhysics();
        }
        WatchUi.requestUpdate();
    }

    private function updatePhysics() as Void {
        var dt = BASE_TICK_MS / 1000.0;
        var tiltX = TiltSensor.normalize(_accelX, _calX);
        var tiltY = TiltSensor.normalize(_accelY, _calY);

        // Y is inverted: tilting the top of the watch down (positive accel Y)
        // should roll the ball up the screen (negative Dc y), not down.
        _vx += tiltX * TILT_ACCEL * dt;
        _vy -= tiltY * TILT_ACCEL * dt;
        _vx *= DAMPING;
        _vy *= DAMPING;

        if (_vx.abs() > MAX_SPEED) {
            _vx = _vx < 0 ? -MAX_SPEED : MAX_SPEED;
        }
        if (_vy.abs() > MAX_SPEED) {
            _vy = _vy < 0 ? -MAX_SPEED : MAX_SPEED;
        }

        // Resolved one axis at a time by walking the cell boundaries the
        // ball's path actually crosses, stopping at the first closed one.
        // Checking only the ball's final resting position (like a simple
        // overlap test) lets a fast-moving ball land on the far side of a
        // thin wall within a single tick without ever being seen "inside"
        // it - this walks the path instead, so it can't be skipped over.
        moveX(_vx * dt);
        moveY(_vy * dt);

        var dx = _ballX - _goalX;
        var dy = _ballY - _goalY;
        if (Math.sqrt(dx * dx + dy * dy) < _cellSize * 0.35) {
            _solved = true;
            _vx = 0.0;
            _vy = 0.0;
        }
    }

    private function moveX(dx as Float) as Void {
        if (dx == 0.0) {
            return;
        }
        var row = ((_ballY - _boardTop) / _cellSize).toNumber();
        if (row < 0) { row = 0; }
        if (row >= GRID_SIZE) { row = GRID_SIZE - 1; }

        var newX = _ballX + dx;
        var col = ((_ballX - _boardLeft) / _cellSize).toNumber();
        var c;
        if (dx > 0) {
            var targetCol = ((newX + _ballRadius - _boardLeft) / _cellSize).toNumber();
            for (c = col; c <= targetCol && c < GRID_SIZE; c++) {
                var wallX = _boardLeft + (c + 1) * _cellSize;
                if (_wallRight[row][c] && newX + _ballRadius > wallX) {
                    newX = wallX - _ballRadius;
                    _vx = 0.0;
                    break;
                }
            }
        } else {
            var targetCol = ((newX - _ballRadius - _boardLeft) / _cellSize).toNumber();
            for (c = col; c >= targetCol && c >= 0; c--) {
                var wallX = _boardLeft + c * _cellSize;
                var hasWall = (c == 0) || _wallRight[row][c - 1];
                if (hasWall && newX - _ballRadius < wallX) {
                    newX = wallX + _ballRadius;
                    _vx = 0.0;
                    break;
                }
            }
        }
        _ballX = newX;
    }

    private function moveY(dy as Float) as Void {
        if (dy == 0.0) {
            return;
        }
        var col = ((_ballX - _boardLeft) / _cellSize).toNumber();
        if (col < 0) { col = 0; }
        if (col >= GRID_SIZE) { col = GRID_SIZE - 1; }

        var newY = _ballY + dy;
        var row = ((_ballY - _boardTop) / _cellSize).toNumber();
        var r;
        if (dy > 0) {
            var targetRow = ((newY + _ballRadius - _boardTop) / _cellSize).toNumber();
            for (r = row; r <= targetRow && r < GRID_SIZE; r++) {
                var wallY = _boardTop + (r + 1) * _cellSize;
                if (_wallDown[r][col] && newY + _ballRadius > wallY) {
                    newY = wallY - _ballRadius;
                    _vy = 0.0;
                    break;
                }
            }
        } else {
            var targetRow = ((newY - _ballRadius - _boardTop) / _cellSize).toNumber();
            for (r = row; r >= targetRow && r >= 0; r--) {
                var wallY = _boardTop + r * _cellSize;
                var hasWall = (r == 0) || _wallDown[r - 1][col];
                if (hasWall && newY - _ballRadius < wallY) {
                    newY = wallY + _ballRadius;
                    _vy = 0.0;
                    break;
                }
            }
        }
        _ballY = newY;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var label = _solved ? "Finished! Menu for new maze" : "Reach the green cell";
        dc.drawText(_width / 2, 2, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        var r;
        var c;
        for (r = 0; r < GRID_SIZE; r++) {
            for (c = 0; c < GRID_SIZE; c++) {
                var x = _boardLeft + c * _cellSize;
                var y = _boardTop + r * _cellSize;
                if (_wallRight[r][c]) {
                    dc.drawLine(x + _cellSize, y, x + _cellSize, y + _cellSize);
                }
                if (_wallDown[r][c]) {
                    dc.drawLine(x, y + _cellSize, x + _cellSize, y + _cellSize);
                }
            }
        }
        dc.drawRectangle(_boardLeft, _boardTop, _cellSize * GRID_SIZE, _cellSize * GRID_SIZE);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        dc.fillRectangle(_boardLeft + (GRID_SIZE - 1) * _cellSize + 2, _boardTop + (GRID_SIZE - 1) * _cellSize + 2, _cellSize - 3, _cellSize - 3);

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        dc.fillCircle(_ballX, _ballY, _ballRadius);
    }

}
