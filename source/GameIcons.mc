import Toybox.Graphics;
import Toybox.Lang;

// Small vector-style icons for the main menu, one per game. Connect IQ has
// no SVG renderer, so each icon is built from basic Graphics primitives
// (rectangles, circles, polygons) inside an x,y,size bounding box - this is
// the closest equivalent to an "SVG icon" the platform supports.
//
// Add a game here: give it a case in draw() below, plus a private drawer
// function that fills roughly the box [x, y, x+s, y+s].
module GameIcons {

    function draw(dc as Graphics.Dc, id as Symbol, x as Number, y as Number, s as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        if (id == :item_pong) {
            drawPong(dc, x, y, s, color);
        } else if (id == :item_2048) {
            draw2048(dc, x, y, s, color);
        } else if (id == :item_flappy) {
            drawFlappy(dc, x, y, s, color);
        } else if (id == :item_snake) {
            drawSnake(dc, x, y, s, color);
        } else if (id == :item_breakout) {
            drawBreakout(dc, x, y, s, color);
        } else if (id == :item_tictactoe) {
            drawTicTacToe(dc, x, y, s, color);
        } else if (id == :item_simon) {
            drawSimon(dc, x, y, s, color);
        } else if (id == :item_dino) {
            drawDino(dc, x, y, s, color);
        } else if (id == :item_tetris) {
            drawTetris(dc, x, y, s, color);
        } else if (id == :item_balanceball) {
            drawBalanceBall(dc, x, y, s, color);
        } else if (id == :item_maze) {
            drawMaze(dc, x, y, s, color);
        } else if (id == :item_racing) {
            drawRacing(dc, x, y, s, color);
        } else if (id == :item_draw) {
            drawPencil(dc, x, y, s, color);
        }
    }

    function drawPong(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        var pw = (s * 0.14).toNumber();
        var ph = (s * 0.42).toNumber();
        dc.fillRectangle(x + (s * 0.06).toNumber(), y + (s * 0.29).toNumber(), pw, ph);
        dc.fillRectangle(x + (s * 0.80).toNumber(), y + (s * 0.29).toNumber(), pw, ph);
        dc.fillCircle(x + (s * 0.5).toNumber(), y + (s * 0.5).toNumber(), (s * 0.08).toNumber());
    }

    function draw2048(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        var g = (s * 0.06).toNumber();
        var cell = ((s - g * 3) / 2).toNumber();
        var sizes = [cell, (cell * 0.75).toNumber(), (cell * 0.55).toNumber(), cell];
        var i = 0;
        for (var row = 0; row < 2; row++) {
            for (var col = 0; col < 2; col++) {
                var cs = sizes[i];
                var cx = x + g + col * (cell + g) + (cell - cs) / 2;
                var cy = y + g + row * (cell + g) + (cell - cs) / 2;
                dc.drawRectangle(cx, cy, cs, cs);
                i++;
            }
        }
    }

    function drawFlappy(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        var pipeW = (s * 0.22).toNumber();
        dc.fillRectangle(x + (s * 0.10).toNumber(), y, pipeW, (s * 0.32).toNumber());
        dc.fillRectangle(x + (s * 0.10).toNumber(), y + (s * 0.68).toNumber(), pipeW, (s * 0.32).toNumber());
        dc.fillCircle(x + (s * 0.66).toNumber(), y + (s * 0.46).toNumber(), (s * 0.18).toNumber());
        dc.fillPolygon([
            [x + (s * 0.82).toNumber(), y + (s * 0.40).toNumber()],
            [x + (s * 0.98).toNumber(), y + (s * 0.46).toNumber()],
            [x + (s * 0.82).toNumber(), y + (s * 0.54).toNumber()]
        ]);
    }

    function drawSnake(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        var c = (s * 0.16).toNumber();
        var pts = [
            [x + (s * 0.08).toNumber(), y + (s * 0.70).toNumber()],
            [x + (s * 0.32).toNumber(), y + (s * 0.70).toNumber()],
            [x + (s * 0.32).toNumber(), y + (s * 0.38).toNumber()],
            [x + (s * 0.56).toNumber(), y + (s * 0.38).toNumber()],
            [x + (s * 0.56).toNumber(), y + (s * 0.70).toNumber()],
            [x + (s * 0.86).toNumber(), y + (s * 0.70).toNumber()]
        ];
        var i = 0;
        while (i < pts.size()) {
            dc.fillRoundedRectangle(pts[i][0] - c / 2, pts[i][1] - c / 2, c, c, 2);
            i++;
        }
        dc.fillCircle(x + (s * 0.90).toNumber(), y + (s * 0.28).toNumber(), (s * 0.10).toNumber());
    }

    function drawBreakout(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        var bw = (s * 0.26).toNumber();
        var bh = (s * 0.12).toNumber();
        var gap = (s * 0.04).toNumber();
        for (var row = 0; row < 2; row++) {
            for (var col = 0; col < 3; col++) {
                dc.fillRectangle(x + col * (bw + gap) + (s * 0.03).toNumber(), y + row * (bh + gap) + (s * 0.06).toNumber(), bw, bh);
            }
        }
        dc.fillCircle(x + (s * 0.5).toNumber(), y + (s * 0.62).toNumber(), (s * 0.07).toNumber());
        dc.fillRectangle(x + (s * 0.30).toNumber(), y + (s * 0.86).toNumber(), (s * 0.40).toNumber(), (s * 0.08).toNumber());
    }

    function drawTicTacToe(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        var m1 = x + (s * 0.34).toNumber();
        var m2 = x + (s * 0.66).toNumber();
        dc.drawLine(m1, y + (s * 0.06).toNumber(), m1, y + (s * 0.94).toNumber());
        dc.drawLine(m2, y + (s * 0.06).toNumber(), m2, y + (s * 0.94).toNumber());
        var l1 = y + (s * 0.34).toNumber();
        var l2 = y + (s * 0.66).toNumber();
        dc.drawLine(x + (s * 0.06).toNumber(), l1, x + (s * 0.94).toNumber(), l1);
        dc.drawLine(x + (s * 0.06).toNumber(), l2, x + (s * 0.94).toNumber(), l2);
        // X in top-left cell
        dc.drawLine(x + (s * 0.10).toNumber(), y + (s * 0.10).toNumber(), m1 - (s * 0.04).toNumber(), l1 - (s * 0.04).toNumber());
        dc.drawLine(m1 - (s * 0.04).toNumber(), y + (s * 0.10).toNumber(), x + (s * 0.10).toNumber(), l1 - (s * 0.04).toNumber());
        // O in bottom-right cell
        dc.drawCircle((m2 + x + (s * 0.94).toNumber()) / 2, (l2 + y + (s * 0.94).toNumber()) / 2, (s * 0.12).toNumber());
    }

    function drawSimon(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        var r = (s * 0.20).toNumber();
        var cx = x + (s * 0.5).toNumber();
        var cy = y + (s * 0.5).toNumber();
        var offs = [[-1, -1], [1, -1], [-1, 1], [1, 1]];
        var i = 0;
        while (i < offs.size()) {
            dc.fillCircle(cx + offs[i][0] * r, cy + offs[i][1] * r, r - 2);
            i++;
        }
    }

    function drawDino(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        dc.fillRectangle(x + (s * 0.20).toNumber(), y + (s * 0.30).toNumber(), (s * 0.42).toNumber(), (s * 0.32).toNumber());
        dc.fillRectangle(x + (s * 0.50).toNumber(), y + (s * 0.10).toNumber(), (s * 0.26).toNumber(), (s * 0.26).toNumber());
        dc.fillRectangle(x + (s * 0.26).toNumber(), y + (s * 0.62).toNumber(), (s * 0.12).toNumber(), (s * 0.26).toNumber());
        dc.fillRectangle(x + (s * 0.48).toNumber(), y + (s * 0.62).toNumber(), (s * 0.12).toNumber(), (s * 0.26).toNumber());
        dc.fillPolygon([
            [x + (s * 0.20).toNumber(), y + (s * 0.36).toNumber()],
            [x + (s * 0.04).toNumber(), y + (s * 0.30).toNumber()],
            [x + (s * 0.20).toNumber(), y + (s * 0.48).toNumber()]
        ]);
    }

    function drawTetris(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        var c = (s * 0.24).toNumber();
        var g = (s * 0.02).toNumber();
        var cells = [[1, 0], [2, 0], [0, 1], [1, 1]];
        var i = 0;
        while (i < cells.size()) {
            var cx = x + (s * 0.12).toNumber() + cells[i][0] * (c + g);
            var cy = y + (s * 0.30).toNumber() + cells[i][1] * (c + g);
            dc.fillRectangle(cx, cy, c, c);
            i++;
        }
    }

    function drawBalanceBall(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        dc.drawLine(x + (s * 0.12).toNumber(), y + (s * 0.70).toNumber(), x + (s * 0.88).toNumber(), y + (s * 0.56).toNumber());
        dc.fillPolygon([
            [x + (s * 0.42).toNumber(), y + (s * 0.63).toNumber()],
            [x + (s * 0.58).toNumber(), y + (s * 0.60).toNumber()],
            [x + (s * 0.5).toNumber(), y + (s * 0.86).toNumber()]
        ]);
        dc.fillCircle(x + (s * 0.5).toNumber(), y + (s * 0.36).toNumber(), (s * 0.15).toNumber());
    }

    function drawMaze(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        dc.drawRectangle(x + (s * 0.08).toNumber(), y + (s * 0.08).toNumber(), (s * 0.84).toNumber(), (s * 0.84).toNumber());
        dc.drawLine(x + (s * 0.08).toNumber(), y + (s * 0.36).toNumber(), x + (s * 0.62).toNumber(), y + (s * 0.36).toNumber());
        dc.drawLine(x + (s * 0.38).toNumber(), y + (s * 0.36).toNumber(), x + (s * 0.38).toNumber(), y + (s * 0.64).toNumber());
        dc.drawLine(x + (s * 0.38).toNumber(), y + (s * 0.64).toNumber(), x + (s * 0.92).toNumber(), y + (s * 0.64).toNumber());
        dc.drawLine(x + (s * 0.64).toNumber(), y + (s * 0.64).toNumber(), x + (s * 0.64).toNumber(), y + (s * 0.92).toNumber());
    }

    function drawRacing(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        dc.fillRoundedRectangle(x + (s * 0.30).toNumber(), y + (s * 0.10).toNumber(), (s * 0.40).toNumber(), (s * 0.80).toNumber(), 4);
        var wheel = (s * 0.10).toNumber();
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x + (s * 0.28).toNumber(), y + (s * 0.26).toNumber(), wheel);
        dc.fillCircle(x + (s * 0.72).toNumber(), y + (s * 0.26).toNumber(), wheel);
        dc.fillCircle(x + (s * 0.28).toNumber(), y + (s * 0.74).toNumber(), wheel);
        dc.fillCircle(x + (s * 0.72).toNumber(), y + (s * 0.74).toNumber(), wheel);
    }

    function drawPencil(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Number) as Void {
        dc.fillPolygon([
            [x + (s * 0.18).toNumber(), y + (s * 0.88).toNumber()],
            [x + (s * 0.30).toNumber(), y + (s * 0.60).toNumber()],
            [x + (s * 0.70).toNumber(), y + (s * 0.20).toNumber()],
            [x + (s * 0.82).toNumber(), y + (s * 0.32).toNumber()],
            [x + (s * 0.42).toNumber(), y + (s * 0.72).toNumber()]
        ]);
        dc.fillPolygon([
            [x + (s * 0.18).toNumber(), y + (s * 0.88).toNumber()],
            [x + (s * 0.30).toNumber(), y + (s * 0.60).toNumber()],
            [x + (s * 0.34).toNumber(), y + (s * 0.78).toNumber()]
        ]);
    }

}
