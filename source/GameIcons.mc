import Toybox.Graphics;
import Toybox.Lang;

// Small vector-style icons for the main menu, one per game. Connect IQ has
// no SVG renderer, so each icon is a list of basic Graphics primitives
// inside an x,y,size bounding box.
//
// Icons are stored as compact drawing-command strings instead of code: on
// 96KB devices the old per-icon drawer functions cost ~9KB of app memory.
// Coordinates are absolute pixels for the menu's 38px icon box.
//
// Format: a command letter followed by its arguments, each argument one
// character whose value is (char code - 48), so '0' = 0, '9' = 9, ':' = 10,
// 'A' = 17, 'V' = 38. x/y arguments are offsets from the icon's top-left.
//   R x y w h    fillRectangle          r x y w h   drawRectangle
//   Q x y w h rad fillRoundedRectangle
//   C x y rad    fillCircle             c x y rad   drawCircle
//   L x1 y1 x2 y2 drawLine
//   P n x1 y1 .. fillPolygon with n points
//   K black      G dark gray            W back to the icon color
//
// Add a game here: insert its string in ICONS at the same index as in Games.IDS.
module GameIcons {

    // One string per game, in the same order as Games.IDS.
    const ICONS = [
        "P56Q;FJ7O<?KP36Q;F<M",  // draw
        "R1294R;294RE294R1794R;794RE794CCG2R;P?3",  // breakout
        "Q86D=3L=6;3LG6I3R8C43RHC43KC>;2CF;2WQ;L?42RAI33",  // invaders
        "Q;3?N4GC:93CK93C:L3CKL3",  // racing
        "R35N4R3KN4R>>88L8<8ILM<MI",  // gravityflip
        "C:84CL<6P4CC;PCMJP",  // asteroid
        "r33NOC=<3CH<3CCB3L9M@KLLMEK",  // pinball
        "R=;99RF;99R4D99R=D99",  // tetris
        "r22@@rF4<<r6H88rDD@@",  // 2048
        "r22@@rD2@@r2D@@rDD@@L5:>:LG:P:L5L>LLGLPL",  // wordrush
        "R308<R3I8<CIA6P3O?UAOD",  // flappy
        "R7;?<RC399R9G49RBG49P37=1;7B",  // dino
        "r33NNL3=F=L?=?HL?HRHC983",  // tiltmaze
        "R2;5?RN;5?CCC3",  // pong
        "Q0G662Q9G662Q9;662QB;662QBG662QMG662CR:3",  // snake
        "C<<5CJ<5C<J5CJJ5",  // simon
        "L4JQEP3?GFFCPCC=5",  // balanceball
        "L<2<SLI2ISL2<S<L2ISIL33;;L;33;cNN4"  // tictactoe
    ];

    // Draws game index's icon with its top-left at x,y.
    function draw(dc as Graphics.Dc, game as Number, x as Number, y as Number, color as Number) as Void {
        var d = (ICONS[game] as String).toUtf8Array();
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        var p = 0;
        var n = d.size();
        while (p < n) {
            var op = d[p];
            if (op == 75) { // 'K'
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                p += 1;
            } else if (op == 71) { // 'G'
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                p += 1;
            } else if (op == 87) { // 'W'
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                p += 1;
            } else if (op == 80) { // 'P'
                var count = d[p + 1] - 48;
                var pts = [];
                for (var k = 0; k < count; k++) {
                    pts.add([x + d[p + 2 + k * 2] - 48, y + d[p + 3 + k * 2] - 48]);
                }
                dc.fillPolygon(pts);
                p += 2 + count * 2;
            } else {
                var a = x + d[p + 1] - 48;
                var b = y + d[p + 2] - 48;
                var c = d[p + 3] - 48;
                if (op == 67) { // 'C'
                    dc.fillCircle(a, b, c);
                    p += 4;
                } else if (op == 99) { // 'c'
                    dc.drawCircle(a, b, c);
                    p += 4;
                } else {
                    var e = d[p + 4] - 48;
                    if (op == 82) { // 'R'
                        dc.fillRectangle(a, b, c, e);
                    } else if (op == 114) { // 'r'
                        dc.drawRectangle(a, b, c, e);
                    } else if (op == 76) { // 'L'
                        dc.drawLine(a, b, x + c, y + e);
                    } else if (op == 81) { // 'Q'
                        dc.fillRoundedRectangle(a, b, c, e, d[p + 5] - 48);
                        p += 1;
                    }
                    p += 5;
                }
            }
        }
    }

}
