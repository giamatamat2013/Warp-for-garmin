import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Math;

// Gravity Flip: side-scrolling platformer runner.
// Gravity constantly pulls player up or down. Tap / Enter flips gravity.
// Player must land on platforms and avoid falling off top or bottom bounds.
class GravityFlipView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "gravityflip_high";
    private const BASE_SPEED = 2.4;
    private const GRAVITY_ACCEL = 0.55;
    private const MAX_FALL_SPEED = 6.0;
    private const PLAYER_SIZE = 12;

    private var _width as Number = 0;
    private var _height as Number = 0;

    private var _playerX as Float = 0.0;
    private var _playerY as Float = 0.0;
    private var _vy as Float = 0.0;
    private var _gravityDown as Boolean = true;

    // Platforms: rects [x, y, w, h]
    private var _platX as Array<Float>;
    private var _platY as Array<Float>;
    private var _platW as Array<Float>;
    private var _platH as Array<Float>;

    private var _speed as Float = BASE_SPEED;
    private var _speedMultiplier as Float = 1.0;
    private var _spawnCooldown as Number = 0;

    private var _score as Number = 0;
    private var _highScore as Number = 0;
    private var _gameOver as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _platX = [];
        _platY = [];
        _platW = [];
        _platH = [];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function setSpeedMultiplier(multiplier as Float) as Void {
        _speedMultiplier = multiplier;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _playerX = _width * 0.22;
        resetGame();
    }

    function resetGame() as Void {
        _gravityDown = true;
        _playerY = _height / 2.0;
        _vy = 0.0;
        _speed = BASE_SPEED * _speedMultiplier;
        _score = 0;
        _gameOver = false;
        _spawnCooldown = 0;

        _platX = [];
        _platY = [];
        _platW = [];
        _platH = [];

        // Initial starting platform under the player
        _platX.add(10.0);
        _platY.add(_height / 2.0 + PLAYER_SIZE);
        _platW.add(_width * 0.7);
        _platH.add(10.0);

        // A couple ahead
        spawnPlatform(_width * 0.85);

        WatchUi.requestUpdate();
    }

    function flipGravity() as Void {
        if (_gameOver) {
            resetGame();
            return;
        }
        _gravityDown = !_gravityDown;
        // give a slight initial push in the new gravity direction if standing on a platform
        _vy = _gravityDown ? 1.0 : -1.0;
    }

    function isGameOver() as Boolean {
        return _gameOver;
    }

    private function spawnPlatform(startX as Float) as Void {
        var pw = 45.0 + (Math.rand() % 45).abs();
        var py = 25.0 + (Math.rand() % (_height - 60)).abs();
        _platX.add(startX);
        _platY.add(py.toFloat());
        _platW.add(pw);
        _platH.add(10.0);
        _spawnCooldown = (24 + (Math.rand() % 20).abs());
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

    private function updateGame() as Void {
        // Accelerate
        if (_speed < 6.0 * _speedMultiplier) {
            _speed += 0.0015;
        }

        // Apply gravity
        if (_gravityDown) {
            _vy += GRAVITY_ACCEL;
            if (_vy > MAX_FALL_SPEED) { _vy = MAX_FALL_SPEED; }
        } else {
            _vy -= GRAVITY_ACCEL;
            if (_vy < -MAX_FALL_SPEED) { _vy = -MAX_FALL_SPEED; }
        }

        _playerY += _vy;

        // Scroll platforms
        var keptX = [] as Array<Float>;
        var keptY = [] as Array<Float>;
        var keptW = [] as Array<Float>;
        var keptH = [] as Array<Float>;

        var i = 0;
        while (i < _platX.size()) {
            var px = _platX[i] - _speed;
            var py = _platY[i];
            var pw = _platW[i];
            var ph = _platH[i];

            // Platform collision
            // Check if player lands on top of platform (gravity down)
            if (_gravityDown && _vy >= 0) {
                if (_playerX + PLAYER_SIZE > px && _playerX < px + pw) {
                    var playerBottom = _playerY + PLAYER_SIZE;
                    if (playerBottom >= py && playerBottom <= py + ph + _vy + 3.0) {
                        _playerY = py - PLAYER_SIZE;
                        _vy = 0.0;
                    }
                }
            } else if (!_gravityDown && _vy <= 0) {
                // Check if player lands on bottom of platform (gravity up)
                if (_playerX + PLAYER_SIZE > px && _playerX < px + pw) {
                    var playerTop = _playerY;
                    if (playerTop <= py + ph && playerTop >= py - (-_vy + 3.0)) {
                        _playerY = py + ph;
                        _vy = 0.0;
                    }
                }
            }

            if (px + pw > 0) {
                keptX.add(px);
                keptY.add(py);
                keptW.add(pw);
                keptH.add(ph);
            }
            i++;
        }
        _platX = keptX;
        _platY = keptY;
        _platW = keptW;
        _platH = keptH;

        // Spawning new platforms
        _spawnCooldown -= 1;
        if (_spawnCooldown <= 0) {
            spawnPlatform(_width.toFloat() + 10.0);
        }

        // Check death bounds
        if (_playerY < -PLAYER_SIZE || _playerY > _height) {
            markGameOver();
            return;
        }

        _score += 1;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Platforms
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
        var i = 0;
        while (i < _platX.size()) {
            dc.fillRoundedRectangle(_platX[i].toNumber(), _platY[i].toNumber(), _platW[i].toNumber(), _platH[i].toNumber(), 3);
            i++;
        }

        // Player
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        dc.fillRoundedRectangle(_playerX.toNumber(), _playerY.toNumber(), PLAYER_SIZE, PLAYER_SIZE, 2);

        // Arrow indicator inside player
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var cx = _playerX.toNumber() + PLAYER_SIZE / 2;
        var cy = _playerY.toNumber() + PLAYER_SIZE / 2;
        if (_gravityDown) {
            dc.fillPolygon([
                [cx, cy + 3],
                [cx - 3, cy - 2],
                [cx + 3, cy - 2]
            ] as Array<[Numeric, Numeric]>);
        } else {
            dc.fillPolygon([
                [cx, cy - 3],
                [cx - 3, cy + 2],
                [cx + 3, cy + 2]
            ] as Array<[Numeric, Numeric]>);
        }

        // HUD / Game Over
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_gameOver) {
            dc.drawText(_width / 2, _height / 2 - 10, Graphics.FONT_SMALL, "Game Over", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_width / 2, _height / 2 + 10, Graphics.FONT_TINY, "Score: " + _score.toString() + "  Best: " + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(_width / 2, 2, Graphics.FONT_XTINY, _score.toString() + "  Best:" + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
