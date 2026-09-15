import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

(:touchGames)
class CheckersView extends WatchUi.View {

    private const EMPTY = 0;
    private const PLAYER = 1;
    private const PLAYER_KING = 2;
    private const AI = 3;
    private const AI_KING = 4;

    private const SIZE = 8;

    private const SKILL_EASY = 0;
    private const SKILL_NORMAL = 1;
    private const SKILL_HARD = 2;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;

    private var _cells as Array<Number>;
    private var _turn as Number = PLAYER;
    private var _gameOver as Boolean = false;
    private var _winnerText as String = "";
    private var _aiSkill as Number = SKILL_NORMAL;

    private var _selected as Number = -1;
    private var _mustContinueFrom as Number = -1;
    private var _destinations as Array<Number> = [];

    function initialize() {
        View.initialize();
        _cells = [];
        resetCells();
    }

    private function resetCells() as Void {
        _cells = [];
        var i = 0;
        while (i < SIZE * SIZE) {
            _cells.add(EMPTY);
            i++;
        }
        var row = 0;
        while (row < SIZE) {
            var col = 0;
            while (col < SIZE) {
                if ((row + col) % 2 == 1) {
                    if (row < 3) {
                        _cells[row * SIZE + col] = AI;
                    } else if (row > 4) {
                        _cells[row * SIZE + col] = PLAYER;
                    }
                }
                col++;
            }
            row++;
        }
        _turn = PLAYER;
        _gameOver = false;
        _selected = -1;
        _mustContinueFrom = -1;
        _destinations = [];
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

    private function isPlayerPiece(v as Number) as Boolean {
        return v == PLAYER || v == PLAYER_KING;
    }

    private function isAiPiece(v as Number) as Boolean {
        return v == AI || v == AI_KING;
    }

    private function isKing(v as Number) as Boolean {
        return v == PLAYER_KING || v == AI_KING;
    }

    private function ownedBy(v as Number, side as Number) as Boolean {
        return side == PLAYER ? isPlayerPiece(v) : isAiPiece(v);
    }

    // Returns forward-move row deltas for a piece (kings move both ways).
    private function rowDeltas(v as Number) as Array<Number> {
        if (isKing(v)) {
            return [-1, 1];
        }
        return isPlayerPiece(v) ? [-1] : [1];
    }

    // A move is {to, over}; `over` is -1 for a simple step, else the captured index.
    private function capturesFor(idx as Number) as Array<Array<Number> > {
        var moves = [] as Array<Array<Number> >;
        var v = _cells[idx];
        if (v == EMPTY) {
            return moves;
        }
        var side = isPlayerPiece(v) ? PLAYER : AI;
        var row = idx / SIZE;
        var col = idx % SIZE;
        var drs = rowDeltas(v);
        var dcs = [-1, 1];
        var i = 0;
        while (i < drs.size()) {
            var j = 0;
            while (j < dcs.size()) {
                var dr = drs[i];
                var dc = dcs[j];
                var midR = row + dr;
                var midC = col + dc;
                var landR = row + dr * 2;
                var landC = col + dc * 2;
                if (midR >= 0 && midR < SIZE && midC >= 0 && midC < SIZE &&
                    landR >= 0 && landR < SIZE && landC >= 0 && landC < SIZE) {
                    var midIdx = midR * SIZE + midC;
                    var landIdx = landR * SIZE + landC;
                    if (ownedBy(_cells[midIdx], otherSide(side)) && _cells[landIdx] == EMPTY) {
                        moves.add([landIdx, midIdx]);
                    }
                }
                j++;
            }
            i++;
        }
        return moves;
    }

    private function simpleMovesFor(idx as Number) as Array<Array<Number> > {
        var moves = [] as Array<Array<Number> >;
        var v = _cells[idx];
        if (v == EMPTY) {
            return moves;
        }
        var row = idx / SIZE;
        var col = idx % SIZE;
        var drs = rowDeltas(v);
        var dcs = [-1, 1];
        var i = 0;
        while (i < drs.size()) {
            var j = 0;
            while (j < dcs.size()) {
                var r = row + drs[i];
                var c = col + dcs[j];
                if (r >= 0 && r < SIZE && c >= 0 && c < SIZE && _cells[r * SIZE + c] == EMPTY) {
                    moves.add([r * SIZE + c, -1]);
                }
                j++;
            }
            i++;
        }
        return moves;
    }

    private function otherSide(side as Number) as Number {
        return side == PLAYER ? AI : PLAYER;
    }

    private function anyCaptureAvailable(side as Number) as Boolean {
        var i = 0;
        while (i < _cells.size()) {
            if (ownedBy(_cells[i], side) && capturesFor(i).size() > 0) {
                return true;
            }
            i++;
        }
        return false;
    }

    // Legal moves for one piece, honoring the forced-capture rule for its side.
    // Scans the whole board for a capture elsewhere, so avoid calling this in
    // a per-cell loop - use legalMovesForFlag with a precomputed flag instead.
    private function legalMovesFor(idx as Number) as Array<Array<Number> > {
        var v = _cells[idx];
        if (v == EMPTY) {
            return [] as Array<Array<Number> >;
        }
        var side = isPlayerPiece(v) ? PLAYER : AI;
        return legalMovesForFlag(idx, anyCaptureAvailable(side));
    }

    private function legalMovesForFlag(idx as Number, mustCapture as Boolean) as Array<Array<Number> > {
        var v = _cells[idx];
        if (v == EMPTY) {
            return [] as Array<Array<Number> >;
        }
        var captures = capturesFor(idx);
        if (captures.size() > 0 || mustCapture) {
            return captures;
        }
        return simpleMovesFor(idx);
    }

    private function applyMove(idx as Number, move as Array<Number>) as Number {
        var to = move[0];
        var over = move[1];
        var v = _cells[idx];
        _cells[idx] = EMPTY;
        if (over != -1) {
            _cells[over] = EMPTY;
        }
        var row = to / SIZE;
        if (v == PLAYER && row == 0) {
            v = PLAYER_KING;
        } else if (v == AI && row == SIZE - 1) {
            v = AI_KING;
        }
        _cells[to] = v;
        return to;
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

        if (_mustContinueFrom != -1) {
            tryMove(_mustContinueFrom, idx);
            return;
        }

        if (_selected == -1) {
            if (isPlayerPiece(_cells[idx]) && legalMovesFor(idx).size() > 0) {
                selectPiece(idx);
            }
            return;
        }

        if (idx == _selected) {
            _selected = -1;
            _destinations = [];
            WatchUi.requestUpdate();
            return;
        }

        if (isPlayerPiece(_cells[idx]) && legalMovesFor(idx).size() > 0) {
            selectPiece(idx);
            return;
        }

        tryMove(_selected, idx);
    }

    private function selectPiece(idx as Number) as Void {
        _selected = idx;
        var moves = legalMovesFor(idx);
        _destinations = [];
        var i = 0;
        while (i < moves.size()) {
            _destinations.add(moves[i][0]);
            i++;
        }
        WatchUi.requestUpdate();
    }

    private function tryMove(fromIdx as Number, toIdx as Number) as Void {
        var moves = legalMovesFor(fromIdx);
        var chosen = null;
        var i = 0;
        while (i < moves.size()) {
            if (moves[i][0] == toIdx) {
                chosen = moves[i];
            }
            i++;
        }
        if (chosen == null) {
            return;
        }

        var wasCapture = chosen[1] != -1;
        var newIdx = applyMove(fromIdx, chosen);

        if (wasCapture && capturesFor(newIdx).size() > 0) {
            _mustContinueFrom = newIdx;
            selectPiece(newIdx);
            return;
        }

        _selected = -1;
        _destinations = [];
        _mustContinueFrom = -1;
        endTurn();
    }

    private function endTurn() as Void {
        if (checkGameOver()) {
            WatchUi.requestUpdate();
            return;
        }
        _turn = AI;
        aiTurn();
        if (!checkGameOver()) {
            _turn = PLAYER;
        }
        WatchUi.requestUpdate();
    }

    private function aiTurn() as Void {
        var current = -1;
        var mustCapture = false;
        while (true) {
            var moves;
            var candidates = [] as Array<Number>;
            if (current == -1) {
                mustCapture = anyCaptureAvailable(AI);
                var i = 0;
                while (i < _cells.size()) {
                    if (isAiPiece(_cells[i]) && legalMovesForFlag(i, mustCapture).size() > 0) {
                        candidates.add(i);
                    }
                    i++;
                }
                if (candidates.size() == 0) {
                    return;
                }
                current = pickAiPiece(candidates);
            }

            moves = legalMovesForFlag(current, mustCapture);
            if (moves.size() == 0) {
                return;
            }
            var move = pickAiMove(current, moves);
            var wasCapture = move[1] != -1;
            var newIdx = applyMove(current, move);

            if (wasCapture && capturesFor(newIdx).size() > 0) {
                current = newIdx;
                continue;
            }
            return;
        }
    }

    private function pickAiPiece(candidates as Array<Number>) as Number {
        if (_aiSkill == SKILL_EASY && (Math.rand() % 10).abs() < 6) {
            return candidates[(Math.rand() % candidates.size()).abs()];
        }
        var best = candidates[0];
        var bestScore = pieceScore(best);
        var i = 1;
        while (i < candidates.size()) {
            var score = pieceScore(candidates[i]);
            if (score > bestScore) {
                bestScore = score;
                best = candidates[i];
            }
            i++;
        }
        return best;
    }

    private function pieceScore(idx as Number) as Number {
        var moves = legalMovesFor(idx);
        var score = 0;
        var i = 0;
        while (i < moves.size()) {
            if (moves[i][1] != -1) {
                score += 5;
            }
            i++;
        }
        if (isKing(_cells[idx])) {
            score += 2;
        }
        return score;
    }

    private function pickAiMove(idx as Number, moves as Array<Array<Number> > ) as Array<Number> {
        if (_aiSkill == SKILL_EASY && (Math.rand() % 10).abs() < 6) {
            return moves[(Math.rand() % moves.size()).abs()];
        }
        var best = moves[0];
        var bestScore = moveScore(idx, best);
        var i = 1;
        while (i < moves.size()) {
            var score = moveScore(idx, moves[i]);
            if (score > bestScore) {
                bestScore = score;
                best = moves[i];
            }
            i++;
        }
        return best;
    }

    private function moveScore(idx as Number, move as Array<Number>) as Number {
        var score = 0;
        if (move[1] != -1) {
            score += 10;
        }
        var toRow = move[0] / SIZE;
        if (!isKing(_cells[idx]) && toRow == SIZE - 1) {
            score += 6;
        }
        if (_aiSkill == SKILL_HARD) {
            // Slight preference for staying off the edge columns (harder to trap).
            var col = move[0] % SIZE;
            if (col > 0 && col < SIZE - 1) {
                score += 1;
            }
        }
        return score;
    }

    private function countPieces(side as Number) as Number {
        var count = 0;
        var i = 0;
        while (i < _cells.size()) {
            if (ownedBy(_cells[i], side)) {
                count++;
            }
            i++;
        }
        return count;
    }

    private function hasAnyMove(side as Number) as Boolean {
        var mustCapture = anyCaptureAvailable(side);
        var i = 0;
        while (i < _cells.size()) {
            if (ownedBy(_cells[i], side) && legalMovesForFlag(i, mustCapture).size() > 0) {
                return true;
            }
            i++;
        }
        return false;
    }

    private function checkGameOver() as Boolean {
        if (countPieces(AI) == 0 || !hasAnyMove(AI)) {
            _gameOver = true;
            _winnerText = "You Win!";
            return true;
        }
        if (countPieces(PLAYER) == 0 || !hasAnyMove(PLAYER)) {
            _gameOver = true;
            _winnerText = "AI Wins";
            return true;
        }
        return false;
    }

    function isGameOver() as Boolean {
        return _gameOver;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var label;
        if (_gameOver) {
            label = _winnerText;
        } else {
            label = "You: " + countPieces(PLAYER) + "  AI: " + countPieces(AI);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var row = 0;
        while (row < SIZE) {
            var col = 0;
            while (col < SIZE) {
                var idx = row * SIZE + col;
                var cx = _boardLeft + col * _cellSize;
                var cy = _boardTop + row * _cellSize;
                var dark = (row + col) % 2 == 1;
                if (idx == _selected) {
                    dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
                } else if (dark) {
                    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                }
                dc.fillRectangle(cx, cy, _cellSize, _cellSize);
                col++;
            }
            row++;
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(_boardLeft, _boardTop, _cellSize * SIZE, _cellSize * SIZE);

        var radius = _cellSize / 2 - 3;
        var i = 0;
        while (i < _destinations.size()) {
            var dIdx = _destinations[i];
            var dcx = _boardLeft + (dIdx % SIZE) * _cellSize + _cellSize / 2;
            var dcy = _boardTop + (dIdx / SIZE) * _cellSize + _cellSize / 2;
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(dcx, dcy, 3);
            i++;
        }

        var r = 0;
        while (r < SIZE) {
            var c = 0;
            while (c < SIZE) {
                var v = _cells[r * SIZE + c];
                if (v != EMPTY) {
                    var pcx = _boardLeft + c * _cellSize + _cellSize / 2;
                    var pcy = _boardTop + r * _cellSize + _cellSize / 2;
                    dc.setColor(isPlayerPiece(v) ? Graphics.COLOR_BLUE : Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(pcx, pcy, radius);
                    if (isKing(v)) {
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                        dc.drawCircle(pcx, pcy, radius - 3);
                    }
                }
                c++;
            }
            r++;
        }
    }
}
