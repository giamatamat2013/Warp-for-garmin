import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

(:touchGames)
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

    // Move flags.
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

    private var _selected as Number = -1;
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
        _selected = -1;
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

    // --- Pseudo-legal move generation (does not yet check king safety) ---

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
            var dcCol = (k == 0) ? -1 : 1;
            var r = row + dir;
            var c = col + dcCol;
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
        var rookHMoved = (side == WHITE) ? _whiteRookHMoved : _blackRookHMoved;
        if (!rookHMoved && _cells[idx + 1] == EMPTY && _cells[idx + 2] == EMPTY &&
            !isSquareAttacked(idx + 1, otherSide(side)) && !isSquareAttacked(idx + 2, otherSide(side))) {
            moves.add([idx, idx + 2, FLAG_CASTLE_KING]);
        }
        var rookAMoved = (side == WHITE) ? _whiteRookAMoved : _blackRookAMoved;
        if (!rookAMoved && _cells[idx - 1] == EMPTY && _cells[idx - 2] == EMPTY && _cells[idx - 3] == EMPTY &&
            !isSquareAttacked(idx - 1, otherSide(side)) && !isSquareAttacked(idx - 2, otherSide(side))) {
            moves.add([idx, idx - 2, FLAG_CASTLE_QUEEN]);
        }
    }

    // --- Attack detection ---

    private function isSquareAttacked(idx as Number, bySide as Number) as Boolean {
        var row = idx / SIZE;
        var col = idx % SIZE;

        // Pawns: a pawn of bySide one row behind (from its own forward direction) attacks diagonally.
        var pawnDir = (bySide == WHITE) ? -1 : 1;
        var attackerRow = row - pawnDir;
        var k = 0;
        while (k < 2) {
            var c = col + ((k == 0) ? -1 : 1);
            if (inBounds(attackerRow, c) && _cells[attackerRow * SIZE + c] == PAWN * bySide) {
                return true;
            }
            k++;
        }

        var i = 0;
        while (i < KNIGHT_OFFSETS.size()) {
            var r = row + KNIGHT_OFFSETS[i][0];
            var c2 = col + KNIGHT_OFFSETS[i][1];
            if (inBounds(r, c2) && _cells[r * SIZE + c2] == KNIGHT * bySide) {
                return true;
            }
            i++;
        }

        i = 0;
        while (i < QUEEN_DIRS.size()) {
            var r = row + QUEEN_DIRS[i][0];
            var c3 = col + QUEEN_DIRS[i][1];
            if (inBounds(r, c3) && _cells[r * SIZE + c3] == KING * bySide) {
                return true;
            }
            i++;
        }

        i = 0;
        while (i < ROOK_DIRS.size()) {
            var r = row + ROOK_DIRS[i][0];
            var c4 = col + ROOK_DIRS[i][1];
            while (inBounds(r, c4)) {
                var tv = _cells[r * SIZE + c4];
                if (tv != EMPTY) {
                    if (pieceSide(tv) == bySide && (pieceType(tv) == ROOK || pieceType(tv) == QUEEN)) {
                        return true;
                    }
                    break;
                }
                r += ROOK_DIRS[i][0];
                c4 += ROOK_DIRS[i][1];
            }
            i++;
        }

        i = 0;
        while (i < BISHOP_DIRS.size()) {
            var r = row + BISHOP_DIRS[i][0];
            var c5 = col + BISHOP_DIRS[i][1];
            while (inBounds(r, c5)) {
                var tv = _cells[r * SIZE + c5];
                if (tv != EMPTY) {
                    if (pieceSide(tv) == bySide && (pieceType(tv) == BISHOP || pieceType(tv) == QUEEN)) {
                        return true;
                    }
                    break;
                }
                r += BISHOP_DIRS[i][0];
                c5 += BISHOP_DIRS[i][1];
            }
            i++;
        }

        return false;
    }

    private function findKing(side as Number) as Number {
        var target = KING * side;
        var i = 0;
        while (i < _cells.size()) {
            if (_cells[i] == target) {
                return i;
            }
            i++;
        }
        return -1;
    }

    private function isKingInCheck(side as Number) as Boolean {
        var kingIdx = findKing(side);
        if (kingIdx == -1) {
            return false;
        }
        return isSquareAttacked(kingIdx, otherSide(side));
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
            rookVal = _cells[rookFrom];
            _cells[rookTo] = rookVal;
            _cells[rookFrom] = EMPTY;
        } else if (flag == FLAG_CASTLE_QUEEN) {
            rookFrom = from - 4;
            rookTo = from - 1;
            rookVal = _cells[rookFrom];
            _cells[rookTo] = rookVal;
            _cells[rookFrom] = EMPTY;
        }

        return [from, to, v, captured, flag, epIdx, epVal, rookFrom, rookTo, rookVal];
    }

    private function undoMoveRaw(u as Array<Number>) as Void {
        var from = u[0];
        var to = u[1];
        var v = u[2];
        var captured = u[3];
        var flag = u[4];
        var epIdx = u[5];
        var epVal = u[6];
        var rookFrom = u[7];
        var rookTo = u[8];
        var rookVal = u[9];

        _cells[from] = v;
        _cells[to] = captured;
        if (flag == FLAG_EN_PASSANT) {
            _cells[epIdx] = epVal;
        }
        if (flag == FLAG_CASTLE_KING || flag == FLAG_CASTLE_QUEEN) {
            _cells[rookTo] = EMPTY;
            _cells[rookFrom] = rookVal;
        }
    }

    // Legal moves for one piece: pseudo-legal moves that don't leave the mover's own king in check.
    private function legalMovesFor(idx as Number) as Array<Array<Number> > {
        var v = _cells[idx];
        if (v == EMPTY) {
            return [] as Array<Array<Number> >;
        }
        var side = pieceSide(v);
        var pseudo = pseudoMovesFor(idx);
        var legal = [] as Array<Array<Number> >;
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
        var flag = m[2];
        var side = pieceSide(_cells[from]);
        var type = pieceType(_cells[from]);

        applyMoveRaw(m);

        if (type == KING) {
            if (side == WHITE) {
                _whiteKingMoved = true;
            } else {
                _blackKingMoved = true;
            }
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

        _enPassantCol = (flag == FLAG_DOUBLE_PUSH) ? (to % SIZE) : -1;
    }

    // --- Touch handling ---

    function handleTap(x as Number, y as Number) as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        if (_turn != WHITE) {
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

        if (_selected == -1) {
            if (pieceSide(_cells[idx]) == WHITE && legalMovesFor(idx).size() > 0) {
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

        if (pieceSide(_cells[idx]) == WHITE && legalMovesFor(idx).size() > 0) {
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
            _destinations.add(moves[i][1]);
            i++;
        }
        WatchUi.requestUpdate();
    }

    private function tryMove(fromIdx as Number, toIdx as Number) as Void {
        var moves = legalMovesFor(fromIdx);
        var chosen = null;
        var i = 0;
        while (i < moves.size()) {
            if (moves[i][1] == toIdx) {
                chosen = moves[i];
            }
            i++;
        }
        if (chosen == null) {
            return;
        }

        makeRealMove(chosen);
        _selected = -1;
        _destinations = [];
        endTurn();
    }

    private function endTurn() as Void {
        if (checkGameOver(BLACK)) {
            WatchUi.requestUpdate();
            return;
        }
        _turn = BLACK;
        aiTurn();
        if (!checkGameOver(WHITE)) {
            _turn = WHITE;
        }
        WatchUi.requestUpdate();
    }

    // Ends the game if `sideToMove` has no legal move (checkmate if in check, else stalemate).
    private function checkGameOver(sideToMove as Number) as Boolean {
        if (hasAnyLegalMove(sideToMove)) {
            return false;
        }
        _gameOver = true;
        if (isKingInCheck(sideToMove)) {
            _winnerText = (sideToMove == BLACK) ? "Checkmate - You Win!" : "Checkmate - AI Wins";
        } else {
            _winnerText = "Stalemate - Draw";
        }
        return true;
    }

    // --- AI: single-ply greedy search with a cheap "don't hang the piece" safety check. ---

    private function pieceValue(type as Number) as Number {
        if (type == PAWN) {
            return 1;
        } else if (type == KNIGHT || type == BISHOP) {
            return 3;
        } else if (type == ROOK) {
            return 5;
        } else if (type == QUEEN) {
            return 9;
        }
        return 0;
    }

    private function aiTurn() as Void {
        var candidates = [] as Array<Array<Number> >;
        var i = 0;
        while (i < _cells.size()) {
            if (pieceSide(_cells[i]) == BLACK) {
                var moves = legalMovesFor(i);
                var j = 0;
                while (j < moves.size()) {
                    candidates.add(moves[j]);
                    j++;
                }
            }
            i++;
        }
        if (candidates.size() == 0) {
            return;
        }

        var move;
        if (_aiSkill == SKILL_EASY && (Math.rand() % 10).abs() < 6) {
            move = candidates[(Math.rand() % candidates.size()).abs()];
        } else {
            move = candidates[0];
            var bestScore = moveScore(move);
            var k = 1;
            while (k < candidates.size()) {
                var score = moveScore(candidates[k]);
                if (score > bestScore) {
                    bestScore = score;
                    move = candidates[k];
                }
                k++;
            }
        }

        makeRealMove(move);
    }

    private function moveScore(m as Array<Number>) as Number {
        var from = m[0];
        var to = m[1];
        var flag = m[2];
        var movedType = pieceType(_cells[from]);
        var capturedVal = _cells[to];
        var score = 0;

        if (flag == FLAG_EN_PASSANT) {
            score += pieceValue(PAWN) * 10;
        } else if (capturedVal != EMPTY) {
            score += pieceValue(pieceType(capturedVal)) * 10;
        }
        if (flag == FLAG_PROMOTION) {
            score += pieceValue(QUEEN) * 10;
        }

        var u = applyMoveRaw(m);
        if (isSquareAttacked(to, WHITE)) {
            score -= pieceValue(movedType) * 9;
        }
        if (_aiSkill == SKILL_HARD && isKingInCheck(WHITE)) {
            score += 4;
        }
        undoMoveRaw(u);

        return score;
    }

    // --- Drawing ---

    private function pieceLetter(type as Number) as String {
        if (type == PAWN) {
            return "P";
        } else if (type == KNIGHT) {
            return "N";
        } else if (type == BISHOP) {
            return "B";
        } else if (type == ROOK) {
            return "R";
        } else if (type == QUEEN) {
            return "Q";
        }
        return "K";
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var label;
        if (_gameOver) {
            label = _winnerText;
        } else if (isKingInCheck(_turn)) {
            label = (_turn == WHITE) ? "Check!" : "AI in check";
        } else {
            label = (_turn == WHITE) ? "Your move" : "AI thinking";
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_width / 2, 2, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var checkedKingIdx = -1;
        if (!_gameOver && isKingInCheck(_turn)) {
            checkedKingIdx = findKing(_turn);
        }

        var row = 0;
        while (row < SIZE) {
            var col = 0;
            while (col < SIZE) {
                var idx = row * SIZE + col;
                var cx = _boardLeft + col * _cellSize;
                var cy = _boardTop + row * _cellSize;
                if (idx == _selected) {
                    dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
                } else if (idx == checkedKingIdx) {
                    dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
                } else if ((row + col) % 2 == 1) {
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

        var i = 0;
        while (i < _destinations.size()) {
            var dIdx = _destinations[i];
            var dcx = _boardLeft + (dIdx % SIZE) * _cellSize + _cellSize / 2;
            var dcy = _boardTop + (dIdx / SIZE) * _cellSize + _cellSize / 2;
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(dcx, dcy, 3);
            i++;
        }

        var font = (_cellSize >= 24) ? Graphics.FONT_SMALL : Graphics.FONT_XTINY;
        var r = 0;
        while (r < SIZE) {
            var c = 0;
            while (c < SIZE) {
                var v = _cells[r * SIZE + c];
                if (v != EMPTY) {
                    var pcx = _boardLeft + c * _cellSize + _cellSize / 2;
                    var pcy = _boardTop + r * _cellSize + _cellSize / 2;
                    dc.setColor(pieceSide(v) == WHITE ? Graphics.COLOR_BLUE : Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(pcx, pcy, font, pieceLetter(pieceType(v)), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
                c++;
            }
            r++;
        }
    }
}
