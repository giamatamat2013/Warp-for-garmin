import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Timer;

(:bigGames)
class ChessView extends WatchUi.View {

    private const EMPTY = 0;
    private const PAWN = 1;
    private const KNIGHT = 2;
    private const BISHOP = 3;
    private const ROOK = 4;
    private const QUEEN = 5;
    private const KING = 6;

    private const WHITE = 1;   // player
    private const BLACK = -1;  // AI

    private const SIZE = 8;

    private const SKILL_EASY = 0;
    private const SKILL_NORMAL = 1;
    private const SKILL_HARD = 2;

    private const FLAG_NONE = 0;
    private const FLAG_DOUBLE_PUSH = 1;
    private const FLAG_EN_PASSANT = 2;
    private const FLAG_CASTLE_KING = 3;
    private const FLAG_CASTLE_QUEEN = 4;
    private const FLAG_PROMOTION = 5;

    private const ROOK_DIRS = [[-1, 0], [1, 0], [0, -1], [0, 1]];
    private const BISHOP_DIRS = [[-1, -1], [-1, 1], [1, -1], [1, 1]];
    private const QUEEN_DIRS = [[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]];
    private const KNIGHT_OFFSETS = [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]];
    private const BACK_RANK = [ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK];

    private const WHITE_ROOK_A_HOME = 56;
    private const WHITE_ROOK_H_HOME = 63;
    private const BLACK_ROOK_A_HOME = 0;
    private const BLACK_ROOK_H_HOME = 7;

    // Piece silhouettes on a 40x40 grid, one char per value (char code - 48):
    //   P n x1 y1 ..  filled polygon with outline
    //   C x y r       filled circle with outline
    //   E x y r       small circle in the outline color (eye)
    //   L x1 y1 x2 y2 thick line in the outline color
    // Index 0 is the shared base, then PAWN..KING.
    private const SHAPES = [
        "P48TPTNO:O",
        "P4>OJOGDADCD?6",
        "P:<ONONFJ<D5B:<<8B:FBDEC=1",
        "P7>OJOHFJ?D7>?@FCD53LF<BB",
        "P4<OLOJ@>@P<:@N@N7J7J;F;F7B7B;>;>7:7",
        "P9<OLOJFP:HBD8@B8:>FC892CD72CP92",
        "P9<OLOJFO>H<D@@<9>>FLD1D;L@5H5"
    ];

    // AI thinking runs a little per timer tick: Connect IQ's watchdog kills
    // any single event that executes too much, and a full move search in the
    // tap handler was enough to trip it.
    private const AI_IDLE = 0;
    private const AI_GATHER = 1;
    private const AI_SCORE = 2;
    private const TICK_MS = 30;
    private const MATE_SCORE = 100000;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _boardLeft as Number = 0;
    private var _boardTop as Number = 0;
    private var _cellSize as Number = 0;

    private var _cells as Array<Number>;
    private var _turn as Number = WHITE;
    private var _gameOver as Boolean = false;
    private var _winnerText as String = "";
    private var _aiSkill as Number = SKILL_NORMAL;

    private var _whiteKingMoved as Boolean = false;
    private var _whiteRookAMoved as Boolean = false;
    private var _whiteRookHMoved as Boolean = false;
    private var _blackKingMoved as Boolean = false;
    private var _blackRookAMoved as Boolean = false;
    private var _blackRookHMoved as Boolean = false;
    private var _enPassantCol as Number = -1;
    private var _whiteKingIdx as Number = 60;
    private var _blackKingIdx as Number = 4;

    private var _selected as Number = -1;
    private var _destinations as Array<Number> = [];
    private var _lastFrom as Number = -1;
    private var _lastTo as Number = -1;
    private var _cursor as Number = -1;

    private var _timer as Timer.Timer?;
    private var _aiPhase as Number = AI_IDLE;
    private var _aiScanIdx as Number = 0;
    private var _aiCandidates as Array<Array<Number> > = [];
    private var _aiBestMove as Array<Number>?;
    private var _aiBestScore as Number = 0;

    private var _shapeBytes as Array<Array<Number> > = [];

    function initialize() {
        View.initialize();
        _cells = [];
        var i = 0;
        while (i < SHAPES.size()) {
            _shapeBytes.add((SHAPES[i] as String).toUtf8Array());
            i++;
        }
        resetCells();
    }

    private function resetCells() as Void {
        _cells = [];
        var i = 0;
        while (i < SIZE * SIZE) {
            _cells.add(EMPTY);
            i++;
        }
        var col = 0;
        while (col < SIZE) {
            _cells[7 * SIZE + col] = BACK_RANK[col] * WHITE;
            _cells[6 * SIZE + col] = PAWN * WHITE;
            _cells[1 * SIZE + col] = PAWN * BLACK;
            _cells[0 * SIZE + col] = BACK_RANK[col] * BLACK;
            col++;
        }
        _turn = WHITE;
        _gameOver = false;
        _winnerText = "";
        _whiteKingMoved = false;
        _whiteRookAMoved = false;
        _whiteRookHMoved = false;
        _blackKingMoved = false;
        _blackRookAMoved = false;
        _blackRookHMoved = false;
        _enPassantCol = -1;
        _whiteKingIdx = 60;
        _blackKingIdx = 4;
        _selected = -1;
        _destinations = [];
        _lastFrom = -1;
        _lastTo = -1;
        _cursor = -1;
        _aiPhase = AI_IDLE;
        _aiCandidates = [];
        _aiBestMove = null;
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

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), TICK_MS, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function setDifficulty(skill as Number) as Void {
        _aiSkill = skill;
        resetGame();
    }

    function resetGame() as Void {
        resetCells();
        WatchUi.requestUpdate();
    }

    function isGameOver() as Boolean {
        return _gameOver;
    }

    private function pieceType(v as Number) as Number {
        return v < 0 ? -v : v;
    }

    private function pieceSide(v as Number) as Number {
        return v > 0 ? WHITE : (v < 0 ? BLACK : 0);
    }

    private function otherSide(side as Number) as Number {
        return side == WHITE ? BLACK : WHITE;
    }

    private function inBounds(row as Number, col as Number) as Boolean {
        return row >= 0 && row < SIZE && col >= 0 && col < SIZE;
    }

    // --- Pseudo-legal move generation (king safety checked in legalMovesFor) ---

    private function pseudoMovesFor(idx as Number) as Array<Array<Number> > {
        var v = _cells[idx];
        var moves = [] as Array<Array<Number> >;
        if (v == EMPTY) {
            return moves;
        }
        var side = pieceSide(v);
        var type = pieceType(v);
        var row = idx / SIZE;
        var col = idx % SIZE;

        if (type == PAWN) {
            addPawnMoves(moves, idx, row, col, side);
        } else if (type == KNIGHT) {
            addOffsetMoves(moves, idx, row, col, side, KNIGHT_OFFSETS);
        } else if (type == BISHOP) {
            addSlidingMoves(moves, idx, row, col, side, BISHOP_DIRS);
        } else if (type == ROOK) {
            addSlidingMoves(moves, idx, row, col, side, ROOK_DIRS);
        } else if (type == QUEEN) {
            addSlidingMoves(moves, idx, row, col, side, QUEEN_DIRS);
        } else if (type == KING) {
            addOffsetMoves(moves, idx, row, col, side, QUEEN_DIRS);
            addCastlingMoves(moves, idx, side);
        }
        return moves;
    }

    private function addPawnMoves(moves as Array<Array<Number> >, idx as Number, row as Number, col as Number, side as Number) as Void {
        var dir = (side == WHITE) ? -1 : 1;
        var startRow = (side == WHITE) ? 6 : 1;
        var promoRow = (side == WHITE) ? 0 : 7;

        var r1 = row + dir;
        if (inBounds(r1, col) && _cells[r1 * SIZE + col] == EMPTY) {
            moves.add([idx, r1 * SIZE + col, (r1 == promoRow) ? FLAG_PROMOTION : FLAG_NONE]);
            var r2 = row + dir * 2;
            if (row == startRow && _cells[r2 * SIZE + col] == EMPTY) {
                moves.add([idx, r2 * SIZE + col, FLAG_DOUBLE_PUSH]);
            }
        }

        var k = 0;
        while (k < 2) {
            var r = row + dir;
            var c = col + ((k == 0) ? -1 : 1);
            if (inBounds(r, c)) {
                var targetIdx = r * SIZE + c;
                var tv = _cells[targetIdx];
                if (tv != EMPTY && pieceSide(tv) != side) {
                    moves.add([idx, targetIdx, (r == promoRow) ? FLAG_PROMOTION : FLAG_NONE]);
                } else if (tv == EMPTY && _enPassantCol == c && row == ((side == WHITE) ? 3 : 4)) {
                    moves.add([idx, targetIdx, FLAG_EN_PASSANT]);
                }
            }
            k++;
        }
    }

    private function addOffsetMoves(moves as Array<Array<Number> >, idx as Number, row as Number, col as Number, side as Number, offsets as Array<Array<Number> >) as Void {
        var i = 0;
        while (i < offsets.size()) {
            var r = row + offsets[i][0];
            var c = col + offsets[i][1];
            if (inBounds(r, c)) {
                var tv = _cells[r * SIZE + c];
                if (tv == EMPTY || pieceSide(tv) != side) {
                    moves.add([idx, r * SIZE + c, FLAG_NONE]);
                }
            }
            i++;
        }
    }

    private function addSlidingMoves(moves as Array<Array<Number> >, idx as Number, row as Number, col as Number, side as Number, dirs as Array<Array<Number> >) as Void {
        var i = 0;
        while (i < dirs.size()) {
            var r = row + dirs[i][0];
            var c = col + dirs[i][1];
            while (inBounds(r, c)) {
                var tv = _cells[r * SIZE + c];
                if (tv == EMPTY) {
                    moves.add([idx, r * SIZE + c, FLAG_NONE]);
                } else {
                    if (pieceSide(tv) != side) {
                        moves.add([idx, r * SIZE + c, FLAG_NONE]);
                    }
                    break;
                }
                r += dirs[i][0];
                c += dirs[i][1];
            }
            i++;
        }
    }

    private function addCastlingMoves(moves as Array<Array<Number> >, idx as Number, side as Number) as Void {
        var kingMoved = (side == WHITE) ? _whiteKingMoved : _blackKingMoved;
        if (kingMoved || isSquareAttacked(idx, otherSide(side))) {
            return;
        }
        var enemy = otherSide(side);
        var rookHMoved = (side == WHITE) ? _whiteRookHMoved : _blackRookHMoved;
        if (!rookHMoved && _cells[idx + 1] == EMPTY && _cells[idx + 2] == EMPTY &&
            !isSquareAttacked(idx + 1, enemy) && !isSquareAttacked(idx + 2, enemy)) {
            moves.add([idx, idx + 2, FLAG_CASTLE_KING]);
        }
        var rookAMoved = (side == WHITE) ? _whiteRookAMoved : _blackRookAMoved;
        if (!rookAMoved && _cells[idx - 1] == EMPTY && _cells[idx - 2] == EMPTY && _cells[idx - 3] == EMPTY &&
            !isSquareAttacked(idx - 1, enemy) && !isSquareAttacked(idx - 2, enemy)) {
            moves.add([idx, idx - 2, FLAG_CASTLE_QUEEN]);
        }
    }

    // --- Attack detection ---

    private function isSquareAttacked(idx as Number, bySide as Number) as Boolean {
        var row = idx / SIZE;
        var col = idx % SIZE;

        var attackerRow = row - ((bySide == WHITE) ? -1 : 1);
        if (attackerRow >= 0 && attackerRow < SIZE) {
            var pawn = PAWN * bySide;
            if (col > 0 && _cells[attackerRow * SIZE + col - 1] == pawn) {
                return true;
            }
            if (col < SIZE - 1 && _cells[attackerRow * SIZE + col + 1] == pawn) {
                return true;
            }
        }

        var knight = KNIGHT * bySide;
        var king = KING * bySide;
        var i = 0;
        while (i < 8) {
            var r = row + KNIGHT_OFFSETS[i][0];
            var c = col + KNIGHT_OFFSETS[i][1];
            if (r >= 0 && r < SIZE && c >= 0 && c < SIZE && _cells[r * SIZE + c] == knight) {
                return true;
            }
            r = row + QUEEN_DIRS[i][0];
            c = col + QUEEN_DIRS[i][1];
            if (r >= 0 && r < SIZE && c >= 0 && c < SIZE && _cells[r * SIZE + c] == king) {
                return true;
            }
            i++;
        }

        var queen = QUEEN * bySide;
        i = 0;
        while (i < 8) {
            var dr = QUEEN_DIRS[i][0];
            var dc = QUEEN_DIRS[i][1];
            var slider = (i < 4) ? ROOK * bySide : BISHOP * bySide;
            var r = row + dr;
            var c = col + dc;
            while (r >= 0 && r < SIZE && c >= 0 && c < SIZE) {
                var tv = _cells[r * SIZE + c];
                if (tv != EMPTY) {
                    if (tv == slider || tv == queen) {
                        return true;
                    }
                    break;
                }
                r += dr;
                c += dc;
            }
            i++;
        }
        return false;
    }

    private function isKingInCheck(side as Number) as Boolean {
        return isSquareAttacked((side == WHITE) ? _whiteKingIdx : _blackKingIdx, otherSide(side));
    }

    // --- Move simulation (mutate then revert, no board copies) ---

    private function applyMoveRaw(m as Array<Number>) as Array<Number> {
        var from = m[0];
        var to = m[1];
        var flag = m[2];
        var v = _cells[from];
        var captured = _cells[to];
        var epIdx = -1;
        var epVal = EMPTY;
        var rookFrom = -1;
        var rookTo = -1;
        var rookVal = EMPTY;
        var prevKingIdx = -1;

        if (v == KING) {
            prevKingIdx = _whiteKingIdx;
            _whiteKingIdx = to;
        } else if (v == -KING) {
            prevKingIdx = _blackKingIdx;
            _blackKingIdx = to;
        }

        _cells[from] = EMPTY;
        if (flag == FLAG_EN_PASSANT) {
            epIdx = from - (from % SIZE) + (to % SIZE);
            epVal = _cells[epIdx];
            _cells[epIdx] = EMPTY;
        }
        _cells[to] = (flag == FLAG_PROMOTION) ? (QUEEN * pieceSide(v)) : v;
        if (flag == FLAG_CASTLE_KING) {
            rookFrom = from + 3;
            rookTo = from + 1;
        } else if (flag == FLAG_CASTLE_QUEEN) {
            rookFrom = from - 4;
            rookTo = from - 1;
        }
        if (rookFrom != -1) {
            rookVal = _cells[rookFrom];
            _cells[rookTo] = rookVal;
            _cells[rookFrom] = EMPTY;
        }

        return [from, to, v, captured, flag, epIdx, epVal, rookFrom, rookTo, rookVal, prevKingIdx];
    }

    private function undoMoveRaw(u as Array<Number>) as Void {
        var v = u[2];
        _cells[u[0]] = v;
        _cells[u[1]] = u[3];
        if (u[5] != -1) {
            _cells[u[5]] = u[6];
        }
        if (u[7] != -1) {
            _cells[u[8]] = EMPTY;
            _cells[u[7]] = u[9];
        }
        if (v == KING) {
            _whiteKingIdx = u[10];
        } else if (v == -KING) {
            _blackKingIdx = u[10];
        }
    }

    private function legalMovesFor(idx as Number) as Array<Array<Number> > {
        var v = _cells[idx];
        var legal = [] as Array<Array<Number> >;
        if (v == EMPTY) {
            return legal;
        }
        var side = pieceSide(v);
        var pseudo = pseudoMovesFor(idx);
        var i = 0;
        while (i < pseudo.size()) {
            var u = applyMoveRaw(pseudo[i]);
            if (!isKingInCheck(side)) {
                legal.add(pseudo[i]);
            }
            undoMoveRaw(u);
            i++;
        }
        return legal;
    }

    private function hasAnyLegalMove(side as Number) as Boolean {
        var i = 0;
        while (i < _cells.size()) {
            if (pieceSide(_cells[i]) == side && legalMovesFor(i).size() > 0) {
                return true;
            }
            i++;
        }
        return false;
    }

    // Applies a move permanently: updates castling rights and en passant state.
    private function makeRealMove(m as Array<Number>) as Void {
        var from = m[0];
        var to = m[1];
        var v = _cells[from];

        applyMoveRaw(m);

        if (v == KING) {
            _whiteKingMoved = true;
        } else if (v == -KING) {
            _blackKingMoved = true;
        }
        if (from == WHITE_ROOK_A_HOME || to == WHITE_ROOK_A_HOME) {
            _whiteRookAMoved = true;
        }
        if (from == WHITE_ROOK_H_HOME || to == WHITE_ROOK_H_HOME) {
            _whiteRookHMoved = true;
        }
        if (from == BLACK_ROOK_A_HOME || to == BLACK_ROOK_A_HOME) {
            _blackRookAMoved = true;
        }
        if (from == BLACK_ROOK_H_HOME || to == BLACK_ROOK_H_HOME) {
            _blackRookHMoved = true;
        }

        _enPassantCol = (m[2] == FLAG_DOUBLE_PUSH) ? (to % SIZE) : -1;
        _lastFrom = from;
        _lastTo = to;
    }

    // --- Touch handling ---

    function handleTap(x as Number, y as Number) as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        if (_turn != WHITE || _cellSize == 0) {
            return;
        }
        if (x < _boardLeft || y < _boardTop) {
            return;
        }
        var col = (x - _boardLeft) / _cellSize;
        var row = (y - _boardTop) / _cellSize;
        if (col >= SIZE || row >= SIZE) {
            return;
        }
        var idx = row * SIZE + col;
        _cursor = -1;

        if (idx == _selected) {
            clearSelection();
            return;
        }

        if (pieceSide(_cells[idx]) == WHITE) {
            selectPiece(idx);
            return;
        }

        if (_selected != -1) {
            tryMove(idx);
        }
    }

    // --- Button handling: UP/DOWN cycle, ENTER confirms, BACK cancels ---
    //
    // With no piece selected the cursor steps through pieces that can move;
    // with one selected it steps through that piece's destinations.

    function cycleCursor(dir as Number) as Void {
        if (_gameOver || _turn != WHITE) {
            return;
        }
        if (_selected != -1) {
            var n = _destinations.size();
            var pos = _destinations.indexOf(_cursor);
            if (pos < 0) {
                pos = (dir > 0) ? -1 : 0;
            }
            _cursor = _destinations[(pos + dir + n) % n];
        } else {
            var start = (_cursor == -1) ? ((dir > 0) ? -1 : 0) : _cursor;
            var k = 1;
            while (k <= 64) {
                var idx = ((start + dir * k) % 64 + 64) % 64;
                if (pieceSide(_cells[idx]) == WHITE && legalMovesFor(idx).size() > 0) {
                    _cursor = idx;
                    break;
                }
                k++;
            }
        }
        WatchUi.requestUpdate();
    }

    function confirmCursor() as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        if (_turn != WHITE) {
            return;
        }
        if (_cursor == -1) {
            cycleCursor(1);
        } else if (_selected == -1) {
            selectPiece(_cursor);
            if (_selected != -1) {
                _cursor = _destinations[0];
            }
        } else {
            tryMove(_cursor);
        }
    }

    // Returns false when there is nothing to cancel, so BACK can leave the game.
    function cancelSelection() as Boolean {
        if (_selected == -1) {
            return false;
        }
        _cursor = _selected;
        clearSelection();
        return true;
    }

    private function clearSelection() as Void {
        _selected = -1;
        _destinations = [];
        WatchUi.requestUpdate();
    }

    private function selectPiece(idx as Number) as Void {
        var moves = legalMovesFor(idx);
        if (moves.size() == 0) {
            clearSelection();
            return;
        }
        _selected = idx;
        _destinations = [];
        var i = 0;
        while (i < moves.size()) {
            _destinations.add(moves[i][1]);
            i++;
        }
        WatchUi.requestUpdate();
    }

    private function tryMove(toIdx as Number) as Void {
        if (_destinations.indexOf(toIdx) < 0) {
            clearSelection();
            return;
        }
        var moves = legalMovesFor(_selected);
        var i = 0;
        while (i < moves.size()) {
            if (moves[i][1] == toIdx) {
                makeRealMove(moves[i]);
                _selected = -1;
                _destinations = [];
                if (!checkGameOver(BLACK)) {
                    startAiTurn();
                }
                WatchUi.requestUpdate();
                return;
            }
            i++;
        }
    }

    // Ends the game if `sideToMove` has no legal move (checkmate if in check, else stalemate).
    private function checkGameOver(sideToMove as Number) as Boolean {
        if (hasAnyLegalMove(sideToMove)) {
            return false;
        }
        _gameOver = true;
        if (isKingInCheck(sideToMove)) {
            _winnerText = (sideToMove == BLACK) ? "Checkmate! You win" : "Checkmate! AI wins";
        } else {
            _winnerText = "Stalemate - Draw";
        }
        return true;
    }

    // --- AI ---

    private function startAiTurn() as Void {
        _turn = BLACK;
        _aiPhase = AI_GATHER;
        _aiScanIdx = 0;
        _aiCandidates = [];
        _aiBestMove = null;
        _aiBestScore = 0;
    }

    function onTimerTick() as Void {
        if (_aiPhase == AI_GATHER) {
            gatherStep();
        } else if (_aiPhase == AI_SCORE) {
            scoreStep();
        }
    }

    // Collects legal moves from at most one AI piece per tick.
    private function gatherStep() as Void {
        while (_aiScanIdx < _cells.size()) {
            var idx = _aiScanIdx;
            _aiScanIdx++;
            if (pieceSide(_cells[idx]) == BLACK) {
                _aiCandidates.addAll(legalMovesFor(idx));
                return;
            }
        }

        if (_aiCandidates.size() == 0) {
            _aiPhase = AI_IDLE;
            return;
        }
        if (_aiSkill == SKILL_EASY && (Math.rand() % 2) == 0) {
            finishAiTurn(_aiCandidates[(Math.rand() % _aiCandidates.size()).abs()]);
            return;
        }
        _aiPhase = AI_SCORE;
        _aiScanIdx = 0;
    }

    // Scores one candidate per tick.
    private function scoreStep() as Void {
        var m = _aiCandidates[_aiScanIdx];
        var score = moveScore(m);
        if (_aiBestMove == null || score > _aiBestScore ||
            (score == _aiBestScore && (Math.rand() % 3) == 0)) {
            _aiBestMove = m;
            _aiBestScore = score;
        }
        _aiScanIdx++;
        if (_aiScanIdx >= _aiCandidates.size()) {
            finishAiTurn(_aiBestMove as Array<Number>);
        }
    }

    private function finishAiTurn(m as Array<Number>) as Void {
        makeRealMove(m);
        _aiPhase = AI_IDLE;
        _aiCandidates = [];
        _aiBestMove = null;
        if (!checkGameOver(WHITE)) {
            _turn = WHITE;
        }
        WatchUi.requestUpdate();
    }

    private function pieceValue(type as Number) as Number {
        if (type == PAWN) {
            return 10;
        } else if (type == KNIGHT || type == BISHOP) {
            return 30;
        } else if (type == ROOK) {
            return 50;
        } else if (type == QUEEN) {
            return 90;
        }
        return 0;
    }

    // Development/centralization nudge for the piece landing on (row, col).
    private function positionalBonus(type as Number, row as Number, col as Number) as Number {
        var center = 6 - (row * 2 - 7).abs() / 2 - (col * 2 - 7).abs() / 2;
        if (type == PAWN) {
            return (row - 1) + ((col == 3 || col == 4) ? 2 : 0);
        } else if (type == KNIGHT || type == BISHOP) {
            return center;
        } else if (type == QUEEN) {
            return center / 2;
        } else if (type == KING) {
            return -center;
        }
        return 0;
    }

    // Score for Black making move m: material won, minus the best exchange
    // White gets in reply (a capture counts only for what it nets after
    // Black's recapture), plus checks, mate, and positional nudges.
    private function moveScore(m as Array<Number>) as Number {
        var from = m[0];
        var to = m[1];
        var flag = m[2];
        var movedType = pieceType(_cells[from]);
        var score = 0;

        if (flag == FLAG_EN_PASSANT) {
            score += pieceValue(PAWN);
        } else {
            score += pieceValue(pieceType(_cells[to]));
        }
        if (flag == FLAG_PROMOTION) {
            score += pieceValue(QUEEN) - pieceValue(PAWN);
        }
        if (flag == FLAG_CASTLE_KING || flag == FLAG_CASTLE_QUEEN) {
            score += 15;
        }
        var posWeight = (_aiSkill == SKILL_HARD) ? 2 : 1;
        score += positionalBonus(movedType, to / SIZE, to % SIZE) * posWeight;
        score -= positionalBonus(movedType, from / SIZE, from % SIZE) * posWeight;

        var u = applyMoveRaw(m);
        if (isKingInCheck(WHITE)) {
            if (!hasAnyLegalMove(WHITE)) {
                undoMoveRaw(u);
                return MATE_SCORE;
            }
            score += 5;
        }
        score -= bestWhiteReply();
        undoMoveRaw(u);
        return score;
    }

    // Best material White can net with one capture, assuming Black recaptures
    // whenever the capturing piece lands on a defended square.
    private function bestWhiteReply() as Number {
        var best = 0;
        var i = 0;
        while (i < _cells.size()) {
            var v = _cells[i];
            if (v > 0) {
                var moves = pseudoMovesFor(i);
                var j = 0;
                while (j < moves.size()) {
                    var to = moves[j][1];
                    var victim = _cells[to];
                    if (victim < 0 && victim != -KING) {
                        var gain = pieceValue(-victim);
                        if (gain > best) {
                            var u = applyMoveRaw(moves[j]);
                            if (!isKingInCheck(WHITE)) {
                                if (isSquareAttacked(to, BLACK)) {
                                    gain -= pieceValue(pieceType(v));
                                }
                                if (gain > best) {
                                    best = gain;
                                }
                            }
                            undoMoveRaw(u);
                        }
                    }
                    j++;
                }
            }
            i++;
        }
        return best;
    }

    // --- Drawing ---

    private function drawShape(dc as Dc, shape as Array<Number>, left as Number, top as Number, fill as Number, outline as Number) as Void {
        var s = _cellSize;
        var p = 0;
        var n = shape.size();
        while (p < n) {
            var op = shape[p];
            if (op == 80) { // 'P'
                var count = shape[p + 1] - 48;
                var pts = [];
                var k = 0;
                while (k < count) {
                    pts.add([left + (shape[p + 2 + k * 2] - 48) * s / 40, top + (shape[p + 3 + k * 2] - 48) * s / 40]);
                    k++;
                }
                dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
                dc.fillPolygon(pts);
                dc.setColor(outline, Graphics.COLOR_TRANSPARENT);
                k = 0;
                while (k < count) {
                    var a = pts[k] as Array<Number>;
                    var b = pts[(k + 1) % count] as Array<Number>;
                    dc.drawLine(a[0], a[1], b[0], b[1]);
                    k++;
                }
                p += 2 + count * 2;
            } else if (op == 76) { // 'L'
                dc.setColor(outline, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(s > 24 ? 3 : 2);
                dc.drawLine(left + (shape[p + 1] - 48) * s / 40, top + (shape[p + 2] - 48) * s / 40,
                    left + (shape[p + 3] - 48) * s / 40, top + (shape[p + 4] - 48) * s / 40);
                dc.setPenWidth(1);
                p += 5;
            } else {
                var cx = left + (shape[p + 1] - 48) * s / 40;
                var cy = top + (shape[p + 2] - 48) * s / 40;
                var r = (shape[p + 3] - 48) * s / 40;
                if (r < 1) {
                    r = 1;
                }
                if (op == 67) { // 'C'
                    dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(cx, cy, r);
                    dc.setColor(outline, Graphics.COLOR_TRANSPARENT);
                    dc.drawCircle(cx, cy, r);
                } else { // 'E'
                    dc.setColor(outline, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(cx, cy, r);
                }
                p += 4;
            }
        }
    }

    private function drawPiece(dc as Dc, v as Number, left as Number, top as Number) as Void {
        var fill = (v > 0) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var outline = (v > 0) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        drawShape(dc, _shapeBytes[0], left, top, fill, outline);
        drawShape(dc, _shapeBytes[pieceType(v)], left, top, fill, outline);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var checkedKingIdx = -1;
        if (!_gameOver && isKingInCheck(_turn)) {
            checkedKingIdx = (_turn == WHITE) ? _whiteKingIdx : _blackKingIdx;
        }

        var label;
        if (_gameOver) {
            label = _winnerText;
        } else if (_turn == BLACK) {
            label = "AI thinking...";
        } else if (checkedKingIdx != -1) {
            label = "Check!";
        } else {
            label = "Your move";
        }
        var labelY = _boardTop - Graphics.getFontHeight(Graphics.FONT_XTINY) - 1;
        if (labelY < 0) {
            labelY = 0;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_width / 2, labelY, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var row = 0;
        while (row < SIZE) {
            var col = 0;
            while (col < SIZE) {
                var idx = row * SIZE + col;
                var x = _boardLeft + col * _cellSize;
                var y = _boardTop + row * _cellSize;
                var color;
                if (idx == _selected) {
                    color = Graphics.COLOR_BLUE;
                } else if (idx == checkedKingIdx) {
                    color = Graphics.COLOR_RED;
                } else if (idx == _lastFrom || idx == _lastTo) {
                    color = ((row + col) % 2 == 1) ? 0xAAAA00 : 0xFFFF55;
                } else {
                    color = ((row + col) % 2 == 1) ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
                }
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x, y, _cellSize, _cellSize);
                var v = _cells[idx];
                if (v != EMPTY) {
                    drawPiece(dc, v, x, y);
                }
                col++;
            }
            row++;
        }

        var dot = _cellSize / 7;
        if (dot < 2) {
            dot = 2;
        }
        var i = 0;
        while (i < _destinations.size()) {
            var d = _destinations[i];
            var cx = _boardLeft + (d % SIZE) * _cellSize + _cellSize / 2;
            var cy = _boardTop + (d / SIZE) * _cellSize + _cellSize / 2;
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            if (_cells[d] != EMPTY) {
                dc.setPenWidth(2);
                dc.drawCircle(cx, cy, _cellSize / 2 - 1);
                dc.setPenWidth(1);
            } else {
                dc.fillCircle(cx, cy, dot);
            }
            i++;
        }

        if (_cursor != -1 && !_gameOver) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            dc.drawRectangle(_boardLeft + (_cursor % SIZE) * _cellSize + 1, _boardTop + (_cursor / SIZE) * _cellSize + 1, _cellSize - 2, _cellSize - 2);
            dc.setPenWidth(1);
        }
    }
}
