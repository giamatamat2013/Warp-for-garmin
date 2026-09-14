import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Math;

// Word Rush: spell as many valid 3 and 4-letter words as possible before time runs out!
// Tap letter tiles in sequence, then tap SUBMIT.
(:touchGames)
class WordRushView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "wordrush_high";
    private const ROUND_SECONDS = 60;

    private var _width as Number = 0;
    private var _height as Number = 0;

    // Letter sets packed 4 chars each: every set has many anagrams
    private const LETTER_SETS = "STARPLAYGAMETIMEWORDBEATFASTCARTSHIPCODEFIREBOATBIRDWINDFISHROCKROADLOVEGOALHOMEKINGSONGRACEPATHTEAMPLANGOLDWARPCARELEAPPOSTSPOTSTOPTAPEPEAKRATE";

    // Space-delimited 3/4-letter word list, loaded from resources only while
    // the game is open so it doesn't count against the app's code memory.
    private var _dict as String? = null;
    private var _currentLetters as Array<String>;
    private var _selectedIndices as Array<Number>;
    private var _foundWords as Array<String>;
    private var _score as Number = 0;
    private var _highScore as Number = 0;
    private var _timeLeft as Number = ROUND_SECONDS;
    private var _gameOver as Boolean = false;
    private var _flashMsg as String = "";
    private var _flashTicks as Number = 0;

    // Tile geometry: 4 letter buttons + Clear + Submit
    private var _tileCX as Array<Number>;
    private var _tileCY as Array<Number>;
    private const TILE_R = 20;

    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _currentLetters = ["W", "A", "R", "P"];
        _selectedIndices = [];
        _foundWords = [];
        _tileCX = [];
        _tileCY = [];
        _highScore = HighScores.get(HIGH_SCORE_KEY);
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        layoutButtons();
        resetGame();
    }

    private function layoutButtons() as Void {
        var cx = _width / 2;
        var cy = (_height * 0.58).toNumber();
        var spread = (_width * 0.26).toNumber();

        _tileCX = [
            cx,              // 0: Top
            cx + spread,     // 1: Right
            cx,              // 2: Bottom
            cx - spread      // 3: Left
        ];
        _tileCY = [
            cy - spread,
            cy,
            cy + spread,
            cy
        ];
    }

    function resetGame() as Void {
        _score = 0;
        _timeLeft = ROUND_SECONDS;
        _gameOver = false;
        _selectedIndices = [];
        _foundWords = [];
        _flashMsg = "";
        _flashTicks = 0;
        pickLetterSet();
        WatchUi.requestUpdate();
    }

    private function pickLetterSet() as Void {
        var start = (Math.rand() % (LETTER_SETS.length() / 4)).abs() * 4;
        _currentLetters = [];
        for (var i = 0; i < 4; i++) {
            _currentLetters.add(LETTER_SETS.substring(start + i, start + i + 1) as String);
        }
        _selectedIndices = [];
    }

    function handleTap(x as Number, y as Number) as Void {
        if (_gameOver) {
            resetGame();
            return;
        }

        // Check 4 letter tiles
        var i = 0;
        while (i < 4) {
            var dx = x - _tileCX[i];
            var dy = y - _tileCY[i];
            if (dx * dx + dy * dy <= TILE_R * TILE_R) {
                // If already selected, do nothing; else add
                if (_selectedIndices.indexOf(i) < 0) {
                    _selectedIndices.add(i);
                    WatchUi.requestUpdate();
                }
                return;
            }
            i++;
        }

        // Check Clear Button (bottom left area)
        if (x < _width * 0.35 && y > _height * 0.80) {
            _selectedIndices = [];
            WatchUi.requestUpdate();
            return;
        }

        // Check Submit Button (bottom right area)
        if (x > _width * 0.65 && y > _height * 0.80) {
            submitWord();
            return;
        }

        // Check Skip Set (top area / tap current word)
        if (y < _height * 0.30) {
            pickLetterSet();
            WatchUi.requestUpdate();
            return;
        }
    }

    private function submitWord() as Void {
        if (_selectedIndices.size() < 3) {
            _selectedIndices = [];
            WatchUi.requestUpdate();
            return;
        }

        var word = "";
        var i = 0;
        while (i < _selectedIndices.size()) {
            word += _currentLetters[_selectedIndices[i]];
            i++;
        }

        if (_foundWords.indexOf(word) >= 0) {
            _flashMsg = "Already Found!";
            _flashTicks = 20;
        } else if (isWordValid(word)) {
            _foundWords.add(word);
            var pts = (word.length() == 4) ? 20 : 10;
            _score += pts;
            _flashMsg = "+" + pts.toString() + " " + word;
            _flashTicks = 20;
            if (_foundWords.size() % 3 == 0) {
                pickLetterSet();
            }
        } else {
            _flashMsg = "Not in list!";
            _flashTicks = 20;
        }

        _selectedIndices = [];
        WatchUi.requestUpdate();
    }

    private function isWordValid(word as String) as Boolean {
        var dict = _dict;
        return dict != null && dict.find(" " + word + " ") != null;
    }

    function onShow() as Void {
        if (_dict == null) {
            _dict = WatchUi.loadResource(Rez.JsonData.WordDict) as String;
        }
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), 1000, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        _dict = null;
    }

    function onTimerTick() as Void {
        if (!_gameOver) {
            _timeLeft -= 1;
            if (_timeLeft <= 0) {
                _gameOver = true;
                HighScores.submit(HIGH_SCORE_KEY, _score);
                _highScore = HighScores.get(HIGH_SCORE_KEY);
            }
        }
        if (_flashTicks > 0) {
            _flashTicks -= 1;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Top HUD
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var hud = "Time: " + _timeLeft.toString() + "s  Score: " + _score.toString();
        dc.drawText(_width / 2, 4, Graphics.FONT_XTINY, hud, Graphics.TEXT_JUSTIFY_CENTER);

        // Word under construction / Flash message
        var msg = "";
        if (_flashTicks > 0) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            msg = _flashMsg;
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var i = 0;
            while (i < _selectedIndices.size()) {
                msg += _currentLetters[_selectedIndices[i]];
                i++;
            }
            if (msg.length() == 0) {
                msg = "_ _ _";
            }
        }
        dc.drawText(_width / 2, (_height * 0.18).toNumber(), Graphics.FONT_MEDIUM, msg, Graphics.TEXT_JUSTIFY_CENTER);

        // Draw 4 Letter tiles
        var li = 0;
        while (li < 4) {
            var tx = _tileCX[li];
            var ty = _tileCY[li];
            var isSel = (_selectedIndices.indexOf(li) >= 0);

            if (isSel) {
                dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_DK_BLUE);
                dc.fillCircle(tx, ty, TILE_R);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(tx, ty, TILE_R);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillCircle(tx, ty, TILE_R);
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(tx, ty, TILE_R);
            }

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(tx, ty - 8, Graphics.FONT_SMALL, _currentLetters[li], Graphics.TEXT_JUSTIFY_CENTER);
            li++;
        }

        // Clear button (bottom left)
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_DK_RED);
        dc.fillRoundedRectangle(8, _height - 28, 48, 22, 4);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(32, _height - 18, Graphics.FONT_XTINY, "CLR", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Submit button (bottom right)
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
        dc.fillRoundedRectangle(_width - 56, _height - 28, 48, 22, 4);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_width - 32, _height - 18, Graphics.FONT_XTINY, "SUB", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Game Over overlay
        if (_gameOver) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.fillRectangle(15, (_height * 0.35).toNumber(), _width - 30, 60);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(15, (_height * 0.35).toNumber(), _width - 30, 60);
            dc.drawText(_width / 2, _height / 2 - 12, Graphics.FONT_SMALL, "Time's Up!", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_width / 2, _height / 2 + 10, Graphics.FONT_XTINY, "Score: " + _score.toString() + "  Best: " + _highScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
