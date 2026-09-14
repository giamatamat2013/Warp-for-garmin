import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Math;

// Space Invaders: defend Earth from marching alien invaders!
// Move cannon with LEFT/RIGHT or drag, press ENTER or tap to fire missiles.
// Invaders march horizontally, drop down on edges, and drop bombs.
class InvadersView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "invaders_high";
    private const ROWS = 3;
    private const COLS = 5;
    private const CANNON_W = 16;
    private const CANNON_H = 10;
    private const ALIEN_W = 12;
    private const ALIEN_H = 8;
    private const ALIEN_GAP_X = 8;
    private const ALIEN_GAP_Y = 8;

    private var _width as Number = 0;
    private var _height as Number = 0;

    // Cannon
    private var _cannonX as Float = 0.0;
    private var _cannonY as Float = 0.0;
    private var _bulletX as Float = 0.0;
    private var _bulletY as Float = 0.0;
    private var _bulletActive as Boolean = false;

    // Invaders grid
    private var _aliensAlive as Array<Array<Boolean> >;
    private var _alienGridX as Float = 0.0;
    private var _alienGridY as Float = 0.0;
    private var _alienDir as Float = 1.0;
    private var _alienStepTimer as Number = 0;
    private var _alienAnimFrame as Boolean = false;

    // Enemy bombs
    private var _bombX as Array<Float>;
    private var _bombY as Array<Float>;
    private var _bombCooldown as Number = 0;

    // Bunkers: 3 defensive shelters
    private var _bunkerX as Array<Number>;
    private var _bunkerY as Number = 0;
    private var _bunkerHealth as Array<Number>; // 4 health stages each

    // Game stats
    private var _score as Number = 0;
    private var _highScore as Number = 0;
    private var _lives as Number = 3;
    private var _wave as Number = 1;
    private var _gameOver as Boolean = false;
    private var _speedMultiplier as Float = 1.0;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _aliensAlive = [];
        _bombX = [];
        _bombY = [];
        _bunkerX = [];
        _bunkerHealth = [];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _cannonY = (_height - 24).toFloat();
        layoutBunkers();
        resetGame();
    }

    private function layoutBunkers() as Void {
        _bunkerX = [];
        _bunkerHealth = [];
        _bunkerY = (_height - 44).toNumber();
        var cx = _width / 2;
        var spread = (_width * 0.28).toNumber();
        _bunkerX.add(cx - spread);
        _bunkerX.add(cx);
        _bunkerX.add(cx + spread);
        _bunkerHealth.add(4);
        _bunkerHealth.add(4);
        _bunkerHealth.add(4);
    }

    function resetGame() as Void {
        _score = 0;
        _lives = 3;
        _wave = 1;
        _gameOver = false;
        _bulletActive = false;
        _cannonX = (_width / 2.0) - (CANNON_W / 2.0);
        _bombX = [];
        _bombY = [];
        layoutBunkers();
        initWave();
        WatchUi.requestUpdate();
    }

    private function initWave() as Void {
        _aliensAlive = [];
        var r = 0;
        while (r < ROWS) {
            var row = [] as Array<Boolean>;
            var c = 0;
            while (c < COLS) {
                row.add(true);
                c++;
            }
            _aliensAlive.add(row);
            r++;
        }
        _alienGridX = (_width - (COLS * (ALIEN_W + ALIEN_GAP_X))) / 2.0;
        _alienGridY = 22.0 + (_wave - 1) * 4.0;
        if (_alienGridY > 50.0) { _alienGridY = 50.0; }
        _alienDir = 1.0;
        _alienStepTimer = 0;
        _bombCooldown = 30;
    }

    function moveCannon(dx as Float) as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        setCannonCenterX((_cannonX + CANNON_W / 2.0 + dx).toNumber());
    }

    function setCannonCenterX(cx as Number) as Void {
        var x = cx - CANNON_W / 2.0;
        var minX = 6.0;
        var maxX = (_width - CANNON_W - 6).toFloat();
        if (x < minX) { x = minX; }
        if (x > maxX) { x = maxX; }
        _cannonX = x;
    }

    function fireBullet() as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        if (!_bulletActive) {
            _bulletX = _cannonX + CANNON_W / 2.0;
            _bulletY = _cannonY - 3.0;
            _bulletActive = true;
        }
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), 33, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTimerTick() as Void {
        if (!_gameOver) {
            updateGame();
        }
        WatchUi.requestUpdate();
    }

    private function markGameOver() as Void {
        _gameOver = true;
        HighScores.submit(HIGH_SCORE_KEY, _score);
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    private function countAliveAliens() as Number {
        var count = 0;
        var r = 0;
        while (r < ROWS) {
            var c = 0;
            while (c < COLS) {
                if (_aliensAlive[r][c]) { count++; }
                c++;
            }
            r++;
        }
        return count;
    }

    private function updateGame() as Void {
        var remaining = countAliveAliens();
        if (remaining == 0) {
            _score += 100 * _wave;
            _wave += 1;
            initWave();
            return;
        }

        // Alien movement
        var stepInterval = ((remaining * 1.5 + 4) / _speedMultiplier).toNumber();
        if (stepInterval < 1) { stepInterval = 1; }
        _alienStepTimer += 1;
        if (_alienStepTimer >= stepInterval) {
            _alienStepTimer = 0;
            _alienAnimFrame = !_alienAnimFrame;

            // Check grid bounds
            var minCol = COLS;
            var maxCol = -1;
            var maxRow = -1;
            var r = 0;
            while (r < ROWS) {
                var c = 0;
                while (c < COLS) {
                    if (_aliensAlive[r][c]) {
                        if (c < minCol) { minCol = c; }
                        if (c > maxCol) { maxCol = c; }
                        if (r > maxRow) { maxRow = r; }
                    }
                    c++;
                }
                r++;
            }

            var leftX = _alienGridX + minCol * (ALIEN_W + ALIEN_GAP_X);
            var rightX = _alienGridX + maxCol * (ALIEN_W + ALIEN_GAP_X) + ALIEN_W;
            var bottomY = _alienGridY + maxRow * (ALIEN_H + ALIEN_GAP_Y) + ALIEN_H;

            if (bottomY >= _cannonY) {
                markGameOver();
                return;
            }

            if (_alienDir > 0 && rightX >= _width - 8) {
                _alienDir = -1.0;
                _alienGridY += 8.0;
            } else if (_alienDir < 0 && leftX <= 8) {
                _alienDir = 1.0;
                _alienGridY += 8.0;
            } else {
                _alienGridX += _alienDir * (4.0 + (15 - remaining) * 0.4);
            }
        }

        // Player bullet
        if (_bulletActive) {
            _bulletY -= 7.0;
            if (_bulletY < 12) {
                _bulletActive = false;
            } else {
                // Check bullet vs aliens
                var r2 = 0;
                while (r2 < ROWS && _bulletActive) {
                    var c2 = 0;
                    while (c2 < COLS && _bulletActive) {
                        if (_aliensAlive[r2][c2]) {
                            var ax = _alienGridX + c2 * (ALIEN_W + ALIEN_GAP_X);
                            var ay = _alienGridY + r2 * (ALIEN_H + ALIEN_GAP_Y);
                            if (_bulletX >= ax && _bulletX <= ax + ALIEN_W && _bulletY >= ay && _bulletY <= ay + ALIEN_H) {
                                _aliensAlive[r2][c2] = false;
                                _bulletActive = false;
                                var pts = (ROWS - r2) * 10;
                                _score += pts;
                            }
                        }
                        c2++;
                    }
                    r2++;
                }

                // Check bullet vs bunkers
                if (_bulletActive) {
                    var bi = 0;
                    while (bi < _bunkerX.size()) {
                        if (_bunkerHealth[bi] > 0) {
                            var bx = _bunkerX[bi];
                            if (_bulletX >= bx - 8 && _bulletX <= bx + 8 && _bulletY >= _bunkerY && _bulletY <= _bunkerY + 8) {
                                _bunkerHealth[bi] -= 1;
                                _bulletActive = false;
                                break;
                            }
                        }
                        bi++;
                    }
                }
            }
        }

        // Alien bomb drops
        _bombCooldown -= 1;
        if (_bombCooldown <= 0 && _bombX.size() < 3) {
            // Pick a random alive bottom alien to drop bomb
            var aliveCols = [] as Array<Number>;
            var col = 0;
            while (col < COLS) {
                var row = ROWS - 1;
                while (row >= 0) {
                    if (_aliensAlive[row][col]) {
                        aliveCols.add(col);
                        break;
                    }
                    row--;
                }
                col++;
            }

            if (aliveCols.size() > 0) {
                var pick = aliveCols[(Math.rand() % aliveCols.size()).abs()];
                var bottomRow = 0;
                var row2 = ROWS - 1;
                while (row2 >= 0) {
                    if (_aliensAlive[row2][pick]) {
                        bottomRow = row2;
                        break;
                    }
                    row2--;
                }
                var dropX = _alienGridX + pick * (ALIEN_W + ALIEN_GAP_X) + ALIEN_W / 2.0;
                var dropY = _alienGridY + bottomRow * (ALIEN_H + ALIEN_GAP_Y) + ALIEN_H;
                _bombX.add(dropX);
                _bombY.add(dropY);
            }
            _bombCooldown = 25 + (Math.rand() % 35).abs();
        }

        // Update bombs
        var keptBX = [] as Array<Float>;
        var keptBY = [] as Array<Float>;
        var i = 0;
        while (i < _bombX.size()) {
            var by = _bombY[i] + 3.2;
            var bx = _bombX[i];
            var hit = false;

            // Check bunker collision
            var bki = 0;
            while (bki < _bunkerX.size()) {
                if (_bunkerHealth[bki] > 0) {
                    var bkx = _bunkerX[bki];
                    if (bx >= bkx - 8 && bx <= bkx + 8 && by >= _bunkerY && by <= _bunkerY + 8) {
                        _bunkerHealth[bki] -= 1;
                        hit = true;
                        break;
                    }
                }
                bki++;
            }

            // Check cannon collision
            if (!hit && bx >= _cannonX && bx <= _cannonX + CANNON_W && by >= _cannonY && by <= _cannonY + CANNON_H) {
                hit = true;
                _lives -= 1;
                if (_lives <= 0) {
                    markGameOver();
                    return;
                } else {
                    _cannonX = (_width / 2.0) - (CANNON_W / 2.0);
                }
            }

            if (!hit && by < _height) {
                keptBX.add(bx);
                keptBY.add(by);
            }
            i++;
        }
        _bombX = keptBX;
        _bombY = keptBY;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // HUD
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var hud = "Scr:" + _score.toString() + " L:" + _lives.toString() + " W:" + _wave.toString() + " Bst:" + _highScore.toString();
        dc.drawText(_width / 2, 2, Graphics.FONT_XTINY, hud, Graphics.TEXT_JUSTIFY_CENTER);

        // Draw Invaders
        var r = 0;
        while (r < ROWS) {
            var c = 0;
            while (c < COLS) {
                if (_aliensAlive[r][c]) {
                    var ax = (_alienGridX + c * (ALIEN_W + ALIEN_GAP_X)).toNumber();
                    var ay = (_alienGridY + r * (ALIEN_H + ALIEN_GAP_Y)).toNumber();

                    if (r == 0) {
                        // Top row: Yellow squid
                        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_YELLOW);
                        dc.fillRectangle(ax + 2, ay, ALIEN_W - 4, ALIEN_H);
                        dc.fillCircle(ax + ALIEN_W / 2, ay + 2, ALIEN_W / 3);
                    } else if (r == 1) {
                        // Middle row: Cyan/Blue crab
                        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
                        dc.fillRoundedRectangle(ax, ay + 1, ALIEN_W, ALIEN_H - 2, 2);
                        dc.fillRectangle(_alienAnimFrame ? ax : ax + 2, ay + ALIEN_H - 2, 2, 2);
                        dc.fillRectangle(_alienAnimFrame ? ax + ALIEN_W - 2 : ax + ALIEN_W - 4, ay + ALIEN_H - 2, 2, 2);
                    } else {
                        // Bottom row: Green octopus
                        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
                        dc.fillRoundedRectangle(ax + 1, ay, ALIEN_W - 2, ALIEN_H, 3);
                    }
                    // Eyes
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                    dc.fillCircle(ax + 3, ay + 3, 1);
                    dc.fillCircle(ax + ALIEN_W - 3, ay + 3, 1);
                }
                c++;
            }
            r++;
        }

        // Draw Bunkers
        var bi = 0;
        while (bi < _bunkerX.size()) {
            var hp = _bunkerHealth[bi];
            if (hp > 0) {
                var bx = _bunkerX[bi];
                var color = (hp >= 3) ? Graphics.COLOR_DK_GREEN : ((hp == 2) ? Graphics.COLOR_ORANGE : Graphics.COLOR_RED);
                dc.setColor(color, color);
                dc.fillRoundedRectangle(bx - 8, _bunkerY, 16, 7, 2);
            }
            bi++;
        }

        // Draw Player Bullet
        if (_bulletActive) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillRectangle(_bulletX.toNumber() - 1, _bulletY.toNumber(), 2, 5);
        }

        // Draw Alien Bombs
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        var i = 0;
        while (i < _bombX.size()) {
            dc.fillRectangle(_bombX[i].toNumber() - 1, _bombY[i].toNumber(), 2, 4);
            i++;
        }

        // Draw Cannon
        var cx = _cannonX.toNumber();
        var cy = _cannonY.toNumber();
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        dc.fillRoundedRectangle(cx, cy + 3, CANNON_W, CANNON_H - 3, 2);
        dc.fillRectangle(cx + CANNON_W / 2 - 1, cy, 3, 4);

        // Game Over overlay
        if (_gameOver) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_width / 2, _height / 2 - 10, Graphics.FONT_SMALL, "Game Over", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_width / 2, _height / 2 + 10, Graphics.FONT_TINY, "Score: " + _score.toString() + "  Best: " + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}

