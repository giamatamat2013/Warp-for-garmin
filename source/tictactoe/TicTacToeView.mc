import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

class TicTacToeView extends WatchUi.View {

    private const EMPTY = 0;
    private const PLAYER = 1;
    private const AI = 2;

    // AI strength: 0 = mostly random, 1 = win/block/center/corner
    // heuristic, 2 = heuristic plus fork-blocking.
    private const SKILL_EASY = 0;
    private const SKILL_NORMAL = 1;
    private const SKILL_HARD = 2;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;

    private var _cells as Array<Number>;
    private var _winner as Number = EMPTY;
    private var _draw as Boolean = false;
    private var _winLines as Array<Array<Number> >;
    private var _aiSkill as Number = SKILL_NORMAL;

    function initialize() {
        View.initialize();
        _winLines = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8],
            [0, 3, 6], [1, 4, 7], [2, 5, 8],
            [0, 4, 8], [2, 4, 6]
        ];
        _cells = [];
        resetCells();
    }

    private function resetCells() as Void {
        _cells = [EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY];
        _winner = EMPTY;
        _draw = false;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        var boardSize = BoardMetrics.squareBoardSize(_width, _height, 16);
        _cellSize = boardSize / 3;
        boardSize = _cellSize * 3;
        _boardLeft = (_width - boardSize) / 2;
        _boardTop = (_height - boardSize) / 2;
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
        if (x < _boardLeft || y < _boardTop) {
            return;
        }
        var col = (x - _boardLeft) / _cellSize;
        var row = (y - _boardTop) / _cellSize;
        if (col < 0 || col > 2 || row < 0 || row > 2) {
            return;
        }
        var idx = row * 3 + col;
        if (_cells[idx] != EMPTY) {
            return;
        }

        _cells[idx] = PLAYER;
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

    private function aiMove() as Void {
        if (_aiSkill == SKILL_EASY && (Math.rand() % 10).abs() < 7) {
            var randomMove = pickRandomEmpty();
            if (randomMove != -1) {
                _cells[randomMove] = AI;
                return;
            }
        }

        var move = findWinningMove(AI);
        if (move == -1) {
            move = findWinningMove(PLAYER);
        }
        if (move == -1 && _aiSkill == SKILL_HARD) {
            move = findForkBlock();
        }
        if (move == -1 && _cells[4] == EMPTY) {
            move = 4;
        }
        if (move == -1) {
            var corners = [0, 2, 6, 8];
            var i = 0;
            while (i < corners.size()) {
                if (_cells[corners[i]] == EMPTY) {
                    move = corners[i];
                    i = corners.size();
                } else {
                    i++;
                }
            }
        }
        if (move == -1) {
            var i2 = 0;
            while (i2 < _cells.size()) {
                if (_cells[i2] == EMPTY) {
                    move = i2;
                    i2 = _cells.size();
                } else {
                    i2++;
                }
            }
        }
        if (move != -1) {
            _cells[move] = AI;
        }
    }

    private function pickRandomEmpty() as Number {
        var empty = [] as Array<Number>;
        var i = 0;
        while (i < _cells.size()) {
            if (_cells[i] == EMPTY) {
                empty.add(i);
            }
            i++;
        }
        if (empty.size() == 0) {
            return -1;
        }
        return empty[(Math.rand() % empty.size()).abs()];
    }

    // A cell that, if the player took it, would complete two lines at once
    // (an unblockable fork) — the AI should occupy it first.
    private function findForkBlock() as Number {
        var i = 0;
        while (i < _cells.size()) {
            if (_cells[i] == EMPTY) {
                var testCells = _cells.slice(0, null) as Array<Number>;
                testCells[i] = PLAYER;
                if (countTwoInLine(testCells, PLAYER) >= 2) {
                    return i;
                }
            }
            i++;
        }
        return -1;
    }

    private function countTwoInLine(cells as Array<Number>, player as Number) as Number {
        var count = 0;
        var i = 0;
        while (i < _winLines.size()) {
            var line = _winLines[i];
            var playerCount = 0;
            var emptyCount = 0;
            var j = 0;
            while (j < line.size()) {
                var v = cells[line[j]];
                if (v == player) {
                    playerCount++;
                } else if (v == EMPTY) {
                    emptyCount++;
                }
                j++;
            }
            if (playerCount == 2 && emptyCount == 1) {
                count++;
            }
            i++;
        }
        return count;
    }

    private function findWinningMove(player as Number) as Number {
        var i = 0;
        while (i < _winLines.size()) {
            var line = _winLines[i];
            var a = _cells[line[0]];
            var b = _cells[line[1]];
            var c = _cells[line[2]];
            if (a == player && b == player && c == EMPTY) { return line[2]; }
            if (a == player && c == player && b == EMPTY) { return line[1]; }
            if (b == player && c == player && a == EMPTY) { return line[0]; }
            i++;
        }
        return -1;
    }

    private function checkWinner(player as Number) as Boolean {
        var i = 0;
        while (i < _winLines.size()) {
            var line = _winLines[i];
            if (_cells[line[0]] == player && _cells[line[1]] == player && _cells[line[2]] == player) {
                return true;
            }
            i++;
        }
        return false;
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
        var label = "Tap to play";
        if (_winner == PLAYER) {
            label = "You Win!";
        } else if (_winner == AI) {
            label = "AI Wins";
        } else if (_draw) {
            label = "Draw";
        }
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var i = 1;
        while (i < 3) {
            dc.drawLine(_boardLeft + i * _cellSize, _boardTop, _boardLeft + i * _cellSize, _boardTop + _cellSize * 3);
            dc.drawLine(_boardLeft, _boardTop + i * _cellSize, _boardLeft + _cellSize * 3, _boardTop + i * _cellSize);
            i++;
        }

        var r = 0;
        while (r < 3) {
            var c = 0;
            while (c < 3) {
                var idx = r * 3 + c;
                var cx = _boardLeft + c * _cellSize + _cellSize / 2;
                var cy = _boardTop + r * _cellSize + _cellSize / 2;
                if (_cells[idx] == PLAYER) {
                    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(cx, cy - _cellSize / 4, Graphics.FONT_MEDIUM, "X", Graphics.TEXT_JUSTIFY_CENTER);
                } else if (_cells[idx] == AI) {
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(cx, cy - _cellSize / 4, Graphics.FONT_MEDIUM, "O", Graphics.TEXT_JUSTIFY_CENTER);
                }
                c++;
            }
            r++;
        }
    }

}
