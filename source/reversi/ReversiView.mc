import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

(:touchGames)
class ReversiView extends WatchUi.View {

    private const EMPTY = 0;
    private const PLAYER = 1;
    private const AI = 2;

    private const SIZE = 8;

    // AI strength: 0 = mostly random, 1 = greedy + corner bonus,
    // 2 = greedy + corner bonus, avoiding handing the opponent a corner.
    private const SKILL_EASY = 0;
    private const SKILL_NORMAL = 1;
    private const SKILL_HARD = 2;

    private const DIRECTIONS = [
        [-1, -1], [-1, 0], [-1, 1],
        [0, -1], [0, 1],
        [1, -1], [1, 0], [1, 1]
    ];

    private const CORNERS = [0, 7, 56, 63];

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;

    private var _cells as Array<Number>;
    private var _turn as Number = PLAYER;
    private var _gameOver as Boolean = false;
    private var _aiSkill as Number = SKILL_NORMAL;

    function initialize() {
        View.initialize();
        _cells = [];
        resetCells();
    }

    private function resetCells() as Void {
        _cells = new [SIZE * SIZE];
        var i = 0;
        while (i < _cells.size()) {
            _cells[i] = EMPTY;
            i++;
        }
        _cells[3 * SIZE + 3] = PLAYER;
        _cells[4 * SIZE + 4] = PLAYER;
        _cells[3 * SIZE + 4] = AI;
        _cells[4 * SIZE + 3] = AI;
        _turn = PLAYER;
        _gameOver = false;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        var boardSize = BoardMetrics.squareBoardSize(_width, _height, 16);
        _cellSize = boardSize / SIZE;
        boardSize = _cellSize * SIZE;
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
        if (_gameOver) {
            resetGame();
            return;
        }
        if (_turn != PLAYER) {
            return;
        }
        if (x < _boardLeft || y < _boardTop) {
            return;
        }
        var col = (x - _boardLeft) / _cellSize;
        var row = (y - _boardTop) / _cellSize;
        if (col < 0 || col >= SIZE || row < 0 || row >= SIZE) {
            return;
        }
        var idx = row * SIZE + col;
        var flips = flipsFor(_cells, PLAYER, idx);
        if (flips.size() == 0) {
            return;
        }

        applyMove(_cells, PLAYER, idx, flips);
        advanceTurn();
        WatchUi.requestUpdate();
    }

    // After a move, hand the turn to the other side, skipping a side with no
    // legal moves; the game ends only when neither side can move.
    private function advanceTurn() as Void {
        _turn = AI;
        while (true) {
            if (getLegalMoves(_cells, _turn).size() > 0) {
                if (_turn == AI) {
                    aiMove();
                    _turn = PLAYER;
                } else {
                    return;
                }
            } else if (getLegalMoves(_cells, otherPlayer(_turn)).size() > 0) {
                _turn = otherPlayer(_turn);
            } else {
                _gameOver = true;
                return;
            }
        }
    }

    private function otherPlayer(player as Number) as Number {
        return (player == PLAYER) ? AI : PLAYER;
    }

    private function aiMove() as Void {
        var moves = getLegalMoves(_cells, AI);
        if (moves.size() == 0) {
            return;
        }

        if (_aiSkill == SKILL_EASY && (Math.rand() % 10).abs() < 7) {
            var idx = moves[(Math.rand() % moves.size()).abs()];
            applyMove(_cells, AI, idx, flipsFor(_cells, AI, idx));
            return;
        }

        var best = bestGreedyMove(moves);
        if (_aiSkill == SKILL_HARD) {
            var safe = safestMove(moves, best);
            if (safe != -1) {
                best = safe;
            }
        }
        applyMove(_cells, AI, best, flipsFor(_cells, AI, best));
    }

    private function bestGreedyMove(moves as Array<Number>) as Number {
        var best = moves[0];
        var bestScore = moveScore(best);
        var i = 1;
        while (i < moves.size()) {
            var score = moveScore(moves[i]);
            if (score > bestScore) {
                bestScore = score;
                best = moves[i];
            }
            i++;
        }
        return best;
    }

    private function moveScore(idx as Number) as Number {
        var score = flipsFor(_cells, AI, idx).size();
        if (CORNERS.indexOf(idx) != -1) {
            score += 20;
        }
        return score;
    }

    // 1-ply danger check: among the legal moves, prefer one that does not let
    // the player take a corner on their very next turn, if such a move exists.
    private function safestMove(moves as Array<Number>, fallback as Number) as Number {
        var best = -1;
        var bestScore = -1;
        var i = 0;
        while (i < moves.size()) {
            var idx = moves[i];
            var testCells = _cells.slice(0, null) as Array<Number>;
            applyMove(testCells, AI, idx, flipsFor(testCells, AI, idx));
            if (!opponentCanTakeCorner(testCells)) {
                var score = moveScore(idx);
                if (score > bestScore) {
                    bestScore = score;
                    best = idx;
                }
            }
            i++;
        }
        return best;
    }

    private function opponentCanTakeCorner(cells as Array<Number>) as Boolean {
        var i = 0;
        while (i < CORNERS.size()) {
            if (cells[CORNERS[i]] == EMPTY && flipsFor(cells, PLAYER, CORNERS[i]).size() > 0) {
                return true;
            }
            i++;
        }
        return false;
    }

    private function getLegalMoves(cells as Array<Number>, player as Number) as Array<Number> {
        var moves = [] as Array<Number>;
        var i = 0;
        while (i < cells.size()) {
            if (cells[i] == EMPTY && flipsFor(cells, player, i).size() > 0) {
                moves.add(i);
            }
            i++;
        }
        return moves;
    }

    private function flipsFor(cells as Array<Number>, player as Number, idx as Number) as Array<Number> {
        var flips = [] as Array<Number>;
        if (cells[idx] != EMPTY) {
            return flips;
        }
        var opponent = otherPlayer(player);
        var row = idx / SIZE;
        var col = idx % SIZE;
        var d = 0;
        while (d < DIRECTIONS.size()) {
            var dr = DIRECTIONS[d][0];
            var dc = DIRECTIONS[d][1];
            var r = row + dr;
            var c = col + dc;
            var line = [] as Array<Number>;
            while (r >= 0 && r < SIZE && c >= 0 && c < SIZE && cells[r * SIZE + c] == opponent) {
                line.add(r * SIZE + c);
                r += dr;
                c += dc;
            }
            if (line.size() > 0 && r >= 0 && r < SIZE && c >= 0 && c < SIZE && cells[r * SIZE + c] == player) {
                flips.addAll(line);
            }
            d++;
        }
        return flips;
    }

    private function applyMove(cells as Array<Number>, player as Number, idx as Number, flips as Array<Number>) as Void {
        cells[idx] = player;
        var i = 0;
        while (i < flips.size()) {
            cells[flips[i]] = player;
            i++;
        }
    }

    private function countDiscs(player as Number) as Number {
        var count = 0;
        var i = 0;
        while (i < _cells.size()) {
            if (_cells[i] == player) {
                count++;
            }
            i++;
        }
        return count;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var playerCount = countDiscs(PLAYER);
        var aiCount = countDiscs(AI);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var label;
        if (_gameOver) {
            if (playerCount > aiCount) {
                label = "You Win!";
            } else if (aiCount > playerCount) {
                label = "AI Wins";
            } else {
                label = "Draw";
            }
        } else {
            label = "You: " + playerCount + "  AI: " + aiCount;
        }
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var i = 0;
        while (i <= SIZE) {
            dc.drawLine(_boardLeft + i * _cellSize, _boardTop, _boardLeft + i * _cellSize, _boardTop + _cellSize * SIZE);
            dc.drawLine(_boardLeft, _boardTop + i * _cellSize, _boardLeft + _cellSize * SIZE, _boardTop + i * _cellSize);
            i++;
        }

        var radius = _cellSize / 2 - 2;
        var r = 0;
        while (r < SIZE) {
            var c = 0;
            while (c < SIZE) {
                var idx = r * SIZE + c;
                var cx = _boardLeft + c * _cellSize + _cellSize / 2;
                var cy = _boardTop + r * _cellSize + _cellSize / 2;
                if (_cells[idx] == PLAYER) {
                    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(cx, cy, radius);
                } else if (_cells[idx] == AI) {
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(cx, cy, radius);
                }
                c++;
            }
            r++;
        }
    }

}
