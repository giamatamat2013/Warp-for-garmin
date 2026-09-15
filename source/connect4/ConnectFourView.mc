import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

(:touchGames)
class ConnectFourView extends WatchUi.View {

    private const EMPTY = 0;
    private const PLAYER = 1;
    private const AI = 2;

    private const COLS = 7;
    private const ROWS = 6;

    private const SKILL_EASY = 0;
    private const SKILL_NORMAL = 1;
    private const SKILL_HARD = 2;

    private const DIRS = [[1, 0], [0, 1], [1, 1], [1, -1]];

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;

    private var _cells as Array<Number>;
    private var _winner as Number = EMPTY;
    private var _draw as Boolean = false;
    private var _aiSkill as Number = SKILL_NORMAL;

    function initialize() {
        View.initialize();
        _cells = [];
        resetCells();
    }

    private function resetCells() as Void {
        _cells = new [COLS * ROWS];
        var i = 0;
        while (i < _cells.size()) {
            _cells[i] = EMPTY;
            i++;
        }
        _winner = EMPTY;
        _draw = false;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        var side = BoardMetrics.squareBoardSize(_width, _height, 16);
        _cellSize = side / COLS;
        _boardLeft = (_width - _cellSize * COLS) / 2;
        _boardTop = (_height - _cellSize * ROWS) / 2;
    }

    function setDifficulty(skill as Number) as Void {
        _aiSkill = skill;
        resetGame();
    }

    function resetGame() as Void {
        resetCells();
        WatchUi.requestUpdate();
    }

    function handleTap(x as Number, y as Number) as Void {
        if (_winner != EMPTY || _draw) {
            resetGame();
            return;
        }
        if (x < _boardLeft || x >= _boardLeft + _cellSize * COLS) {
            return;
        }
        var col = (x - _boardLeft) / _cellSize;
        var row = dropRow(col);
        if (row == -1) {
            return;
        }

        _cells[row * COLS + col] = PLAYER;
        if (checkWinner(PLAYER)) {
            _winner = PLAYER;
            WatchUi.requestUpdate();
            return;
        }
        if (isBoardFull()) {
            _draw = true;
            WatchUi.requestUpdate();
            return;
        }

        aiMove();
        if (checkWinner(AI)) {
            _winner = AI;
        } else if (isBoardFull()) {
            _draw = true;
        }
        WatchUi.requestUpdate();
    }

    private function dropRow(col as Number) as Number {
        var row = ROWS - 1;
        while (row >= 0) {
            if (_cells[row * COLS + col] == EMPTY) {
                return row;
            }
            row--;
        }
        return -1;
    }

    private function validColumns() as Array<Number> {
        var cols = [] as Array<Number>;
        var c = 0;
        while (c < COLS) {
            if (dropRow(c) != -1) {
                cols.add(c);
            }
            c++;
        }
        return cols;
    }

    private function aiMove() as Void {
        var cols = validColumns();
        if (cols.size() == 0) {
            return;
        }

        if (_aiSkill == SKILL_EASY && (Math.rand() % 10).abs() < 7) {
            var winMove = findWinningColumn(AI, cols);
            var col = (winMove != -1) ? winMove : cols[(Math.rand() % cols.size()).abs()];
            _cells[dropRow(col) * COLS + col] = AI;
            return;
        }

        var move = findWinningColumn(AI, cols);
        if (move == -1) {
            move = findWinningColumn(PLAYER, cols);
        }
        if (move == -1 && _aiSkill == SKILL_HARD) {
            move = findSafeCenterColumn(cols);
        }
        if (move == -1) {
            move = closestToCenter(cols);
        }
        _cells[dropRow(move) * COLS + move] = AI;
    }

    private function findWinningColumn(player as Number, cols as Array<Number>) as Number {
        var i = 0;
        while (i < cols.size()) {
            var col = cols[i];
            var row = dropRow(col);
            _cells[row * COLS + col] = player;
            var wins = checkWinner(player);
            _cells[row * COLS + col] = EMPTY;
            if (wins) {
                return col;
            }
            i++;
        }
        return -1;
    }

    // Among columns that don't hand the opponent an immediate winning reply,
    // pick the one closest to the center; if every column loses, fall back to center-ish.
    private function findSafeCenterColumn(cols as Array<Number>) as Number {
        var best = -1;
        var bestDist = COLS;
        var i = 0;
        while (i < cols.size()) {
            var col = cols[i];
            var row = dropRow(col);
            _cells[row * COLS + col] = AI;
            var opponentReply = findWinningColumn(PLAYER, validColumns());
            _cells[row * COLS + col] = EMPTY;
            if (opponentReply == -1) {
                var dist = (col - COLS / 2).abs();
                if (dist < bestDist) {
                    bestDist = dist;
                    best = col;
                }
            }
            i++;
        }
        return best;
    }

    private function closestToCenter(cols as Array<Number>) as Number {
        var best = cols[0];
        var bestDist = (cols[0] - COLS / 2).abs();
        var i = 1;
        while (i < cols.size()) {
            var dist = (cols[i] - COLS / 2).abs();
            if (dist < bestDist) {
                bestDist = dist;
                best = cols[i];
            }
            i++;
        }
        return best;
    }

    private function checkWinner(player as Number) as Boolean {
        var row = 0;
        while (row < ROWS) {
            var col = 0;
            while (col < COLS) {
                if (_cells[row * COLS + col] == player) {
                    var d = 0;
                    while (d < DIRS.size()) {
                        if (countRun(row, col, DIRS[d][0], DIRS[d][1], player) >= 4) {
                            return true;
                        }
                        d++;
                    }
                }
                col++;
            }
            row++;
        }
        return false;
    }

    private function countRun(row as Number, col as Number, dc as Number, dr as Number, player as Number) as Number {
        var count = 0;
        var r = row;
        var c = col;
        while (r >= 0 && r < ROWS && c >= 0 && c < COLS && _cells[r * COLS + c] == player) {
            count++;
            r += dr;
            c += dc;
        }
        return count;
    }

    private function isBoardFull() as Boolean {
        var i = 0;
        while (i < _cells.size()) {
            if (_cells[i] == EMPTY) {
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
        var label = "Tap a column";
        if (_winner == PLAYER) {
            label = "You Win!";
        } else if (_winner == AI) {
            label = "AI Wins";
        } else if (_draw) {
            label = "Draw";
        }
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(_boardLeft, _boardTop, _cellSize * COLS, _cellSize * ROWS);
        var i = 1;
        while (i < COLS) {
            dc.drawLine(_boardLeft + i * _cellSize, _boardTop, _boardLeft + i * _cellSize, _boardTop + _cellSize * ROWS);
            i++;
        }

        var radius = _cellSize / 2 - 3;
        var row = 0;
        while (row < ROWS) {
            var col = 0;
            while (col < COLS) {
                var idx = row * COLS + col;
                var cx = _boardLeft + col * _cellSize + _cellSize / 2;
                var cy = _boardTop + row * _cellSize + _cellSize / 2;
                if (_cells[idx] == PLAYER) {
                    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(cx, cy, radius);
                } else if (_cells[idx] == AI) {
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(cx, cy, radius);
                }
                col++;
            }
            row++;
        }
    }

}
