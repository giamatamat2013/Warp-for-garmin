import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Math;

// Word Rush: spell as many valid 3 and 4-letter words as possible before time runs out!
// Tap letter tiles in sequence, then tap SUBMIT.
class WordRushView extends WatchUi.View {

    private const HIGH_SCORE_KEY = "wordrush_high";
    private const ROUND_SECONDS = 60;

    private var _width as Number = 0;
    private var _height as Number = 0;

    // Available letter sets: 4 letters each with many anagrams
    private const LETTER_SETS = [
        ["S", "T", "A", "R"],
        ["P", "L", "A", "Y"],
        ["G", "A", "M", "E"],
        ["T", "I", "M", "E"],
        ["W", "O", "R", "D"],
        ["B", "E", "A", "T"],
        ["F", "A", "S", "T"],
        ["C", "A", "R", "T"],
        ["S", "H", "I", "P"],
        ["C", "O", "D", "E"],
        ["F", "I", "R", "E"],
        ["B", "O", "A", "T"],
        ["B", "I", "R", "D"],
        ["W", "I", "N", "D"],
        ["F", "I", "S", "H"],
        ["R", "O", "C", "K"],
        ["R", "O", "A", "D"],
        ["L", "O", "V", "E"],
        ["G", "O", "A", "L"],
        ["H", "O", "M", "E"],
        ["K", "I", "N", "G"],
        ["S", "O", "N", "G"],
        ["R", "A", "C", "E"],
        ["P", "A", "T", "H"],
        ["T", "E", "A", "M"],
        ["P", "L", "A", "N"],
        ["G", "O", "L", "D"],
        ["W", "A", "R", "P"],
        ["C", "A", "R", "E"],
        ["L", "E", "A", "P"],
        ["P", "O", "S", "T"],
        ["S", "P", "O", "T"],
        ["S", "T", "O", "P"],
        ["T", "A", "P", "E"],
        ["P", "E", "A", "K"],
        ["R", "A", "T", "E"]
    ] as Array<Array<String> >;

    // Dictionary of common 3- and 4-letter words
    private const DICTIONARY = [
        "ACE", "ACT", "AGE", "AGO", "AIM", "AIR", "ALL", "AND", "ANY", "APE", "APT", "ARC", "ARE", "ARK", "ARM", "ART", "ASH", "ASK", "ATE", "AWE",
        "BAD", "BAG", "BAN", "BAR", "BAT", "BAY", "BED", "BEE", "BEG", "BET", "BID", "BIG", "BIN", "BIT", "BOA", "BOB", "BOG", "BOW", "BOX", "BOY", "BUD", "BUG", "BUS", "BUT", "BUY", "BYE",
        "CAB", "CAM", "CAN", "CAP", "CAR", "CAT", "COB", "COD", "COG", "CON", "COO", "COP", "COT", "COW", "CRY", "CUB", "CUP", "CUR", "CUT",
        "DAB", "DAM", "DAY", "DEN", "DEW", "DID", "DIE", "DIG", "DIM", "DIN", "DIP", "DOE", "DOG", "DOT", "DRY", "DUB", "DUE", "DUG", "DYE",
        "EAR", "EAT", "EGG", "EGO", "ELF", "ELM", "EMU", "END", "ERA", "EVE", "EYE",
        "FAN", "FAR", "FAT", "FED", "FEE", "FEW", "FIG", "FIN", "FIR", "FIT", "FIX", "FLY", "FOE", "FOG", "FOR", "FOX", "FRY", "FUN", "FUR",
        "GAG", "GAP", "GAS", "GEL", "GEM", "GET", "GIG", "GIN", "GLAD", "GNU", "GOD", "GOT", "GUM", "GUN", "GUT", "GUY", "GYM",
        "HAD", "HAM", "HAS", "HAT", "HAY", "HEM", "HEN", "HER", "HEW", "HEX", "HID", "HIM", "HIP", "HIS", "HIT", "HOG", "HOP", "HOT", "HOW", "HUB", "HUG", "HUM", "HUT",
        "ICE", "ICY", "ILL", "INK", "INN", "ION", "IRE", "IVY",
        "JAM", "JAR", "JAW", "JAY", "JET", "JIG", "JOB", "JOG", "JOY", "JUG", "JUT",
        "KEG", "KEY", "KID", "KIN", "KIT",
        "LAB", "LAD", "LAP", "LAW", "LAY", "LED", "LEG", "LET", "LID", "LIE", "LIP", "LIT", "LOG", "LOT", "LOW",
        "MAD", "MAN", "MAP", "MAT", "MAY", "MEN", "MET", "MID", "MIX", "MOP", "MUD", "MUG",
        "NAG", "NAP", "NET", "NEW", "NIP", "NOD", "NOR", "NOT", "NOW", "NUT",
        "OAK", "OAR", "OAT", "ODD", "OFF", "OFT", "OIL", "OLD", "ONE", "OPT", "ORE", "OUR", "OUT", "OWL", "OWN",
        "PAD", "PAN", "PAR", "PAT", "PAW", "PAY", "PEA", "PEG", "PEN", "PER", "PET", "PEW", "PIE", "PIG", "PIN", "PIT", "PLY", "POD", "POP", "POT", "PRO", "PUB", "PUP", "PUT",
        "RAG", "RAM", "RAN", "RAP", "RAT", "RAW", "RAY", "RED", "RIB", "RID", "RIG", "RIM", "RIP", "ROB", "ROD", "ROE", "ROT", "ROW", "RUB", "RUG", "RUN", "RUT", "RYE",
        "SAC", "SAD", "SAG", "SAP", "SAT", "SAW", "SAY", "SEA", "SEE", "SET", "SEW", "SHE", "SHY", "SIN", "SIP", "SIR", "SIT", "SIX", "SKI", "SKY", "SLY", "SOB", "SOD", "SON", "SOP", "SOW", "SOY", "SPA", "SPY", "SUM", "SUN",
        "TAB", "TAG", "TAN", "TAP", "TAR", "TEA", "TED", "TEN", "THE", "TIE", "TIN", "TIP", "TOE", "TON", "TOO", "TOP", "TOW", "TOY", "TRY", "TUB", "TUG", "TWO",
        "URN", "USE",
        "VAN", "VAT", "VET", "VIA", "VIE", "VOW",
        "WAR", "WAS", "WAX", "WAY", "WEB", "WED", "WET", "WHO", "WHY", "WIG", "WIN", "WIT", "WOE", "WON", "WOW",
        "YAK", "YAM", "YAP", "YAW", "YEA", "YES", "YET", "YEW", "YON", "YOU",
        "ZIP", "ZOO",
        // 4-letter words
        "ACRE", "AIDE", "ALLY", "ALSO", "ARCH", "AREA", "ARMY", "ARTS", "AUNT", "AWAY",
        "BABY", "BACK", "BAIT", "BAKE", "BALL", "BAND", "BANK", "BARE", "BARK", "BARN", "BASE", "BATH", "BEAK", "BEAM", "BEAN", "BEAR", "BEAT", "BEEF", "BEER", "BELL", "BELT", "BEND", "BEST", "BILL", "BIND", "BIRD", "BITE", "BLOW", "BLUE", "BOAT", "BODY", "BOIL", "BOLD", "BOMB", "BOND", "BONE", "BOOK", "BOOM", "BOOT", "BORE", "BORN", "BOSS", "BOTH", "BOWL", "BULK", "BURN", "BUSH", "BUSY",
        "CAFE", "CAGE", "CAKE", "CALL", "CALM", "CAMP", "CANE", "CAPE", "CARD", "CARE", "CART", "CASE", "CASH", "CAST", "CAVE", "CELL", "CHEF", "CITY", "CLAP", "CLAW", "CLAY", "CLIP", "CLUB", "COAL", "COAT", "CODE", "COIN", "COLD", "COME", "COOK", "COOL", "COPE", "COPY", "CORD", "CORE", "CORN", "COST", "CRAB", "CREW", "CROP", "CROW", "CUBE", "CURE", "CURL",
        "DARK", "DART", "DASH", "DATE", "DAWN", "DEAD", "DEAL", "DEAR", "DECK", "DEED", "DEEP", "DEER", "DESK", "DIAL", "DIRT", "DISC", "DISH", "DISK", "DIVE", "DOCK", "DOOR", "DOSE", "DOWN", "DRAW", "DROP", "DRUM", "DUCK", "DUST", "DUTY",
        "EACH", "EARN", "EAST", "EASY", "EDGE", "ELSE", "ENVY", "EVEN", "EVER", "EVIL", "EXAM", "EXIT", "EYES",
        "FACE", "FACT", "FADE", "FAIL", "FAIR", "FALL", "FAME", "FARM", "FAST", "FATE", "FEAR", "FEAT", "FEED", "FEEL", "FEET", "FILL", "FILM", "FIND", "FINE", "FIRE", "FIRM", "FISH", "FIST", "FLAG", "FLAT", "FLAW", "FLEA", "FLEW", "FLIP", "FLOW", "FOAM", "FOIL", "FOLD", "FOLK", "FOOD", "FOOL", "FOOT", "FORD", "FORK", "FORM", "FORT", "FOUL", "FOUR", "FOWL", "FREE", "FROG", "FROM", "FUEL", "FULL", "FUME", "FUND", "FURY", "FUSE",
        "GAIN", "GAME", "GANG", "GATE", "GEAR", "GIFT", "GIRL", "GIVE", "GLAD", "GLOW", "GOAL", "GOAT", "GOLD", "GOLF", "GOOD", "GRAB", "GRAY", "GREW", "GRID", "GRIN", "GRIP", "GROW", "GULF",
        "HAIR", "HALF", "HALL", "HALT", "HAND", "HANG", "HARD", "HARE", "HARM", "HATE", "HAVE", "HAWK", "HEAD", "HEAL", "HEAP", "HEAR", "HEAT", "HEEL", "HEIR", "HELD", "HELL", "HELP", "HERB", "HERD", "HERO", "HIDE", "HIGH", "HIKE", "HILL", "HINT", "HIRE", "HOLD", "HOLE", "HOLY", "HOME", "HOOK", "HOPE", "HORN", "HOSE", "HOST", "HOUR", "HUGE", "HUNT", "HURT",
        "ICON", "IDEA", "IDLE", "INCH", "INTO", "IRON", "ITEM",
        "JAZZ", "JEAN", "JOIN", "JOKE", "JUMP", "JUNE", "JURY", "JUST",
        "KEEN", "KEEP", "KICK", "KILL", "KIND", "KING", "KISS", "KITE", "KNEE", "KNOT", "KNOW",
        "LACE", "LACK", "LADY", "LAID", "LAKE", "LAMB", "LAMP", "LAND", "LANE", "LAST", "LATE", "LEAD", "LEAF", "LEAK", "LEAN", "LEAP", "LEFT", "LEND", "LENS", "LESS", "LIAR", "LICK", "LIFE", "LIFT", "LIKE", "LIME", "LINE", "LINK", "LION", "LIPS", "LIST", "LIVE", "LOAD", "LOAF", "LOAN", "LOCK", "LOGO", "LONG", "LOOK", "LOOP", "LORD", "LOSE", "LOSS", "LOST", "LOUD", "LOVE", "LUCK", "LUMP", "LUNG",
        "MADE", "MAID", "MAIL", "MAIN", "MAKE", "MALE", "MALL", "MANE", "MANY", "MARK", "MARS", "MASK", "MASS", "MAST", "MATE", "MATH", "MAZE", "MEAL", "MEAN", "MEAT", "MEET", "MELT", "MEND", "MENU", "MESS", "MILE", "MILK", "MIND", "MINE", "MINT", "MISS", "MIST", "MOOD", "MOON", "MORE", "MOSS", "MOST", "MOTH", "MOVE", "MUCH", "MULE", "MUST", "MUTE",
        "NAIL", "NAME", "NEAR", "NEAT", "NECK", "NEED", "NEST", "NEWS", "NEXT", "NICE", "NINE", "NODE", "NOON", "NOSE", "NOTE",
        "OAKS", "OATH", "OBEY", "ODDS", "OGRE", "OILS", "OKAY", "OMIT", "ONCE", "ONES", "ONLY", "ONTO", "OPEN", "ORAL", "ORES", "OVAL", "OVEN", "OVER", "OWLS", "OWNS",
        "PACE", "PACK", "PAGE", "PAID", "PAIN", "PAIR", "PALE", "PALM", "PANT", "PARK", "PART", "PASS", "PAST", "PATH", "PEAK", "PEAR", "PEEL", "PEER", "PEST", "PICK", "PILE", "PILL", "PINE", "PINK", "PIPE", "PITY", "PLAN", "PLAY", "PLOT", "PLUG", "POEM", "POET", "POLE", "POLL", "POND", "POOL", "POOR", "POPE", "PORK", "PORT", "POSE", "POST", "POUR", "PRAY", "PURE", "PUSH",
        "QUIT", "QUIZ",
        "RACE", "RACK", "RAFT", "RAGE", "RAID", "RAIL", "RAIN", "RANK", "RARE", "RATE", "READ", "REAL", "REAP", "REAR", "REED", "REEF", "REST", "RICE", "RICH", "RIDE", "RING", "RIOT", "RIPE", "RISE", "RISK", "ROAD", "ROAR", "ROBE", "ROCK", "RODE", "ROLE", "ROLL", "ROOF", "ROOM", "ROOT", "ROPE", "ROSE", "RUSH", "RUST",
        "SAFE", "SAGE", "SAID", "SAIL", "SAKE", "SALE", "SALT", "SAME", "SAND", "SAVE", "SEAL", "SEAM", "SEAT", "SEED", "SEEK", "SEEM", "SEEN", "SELF", "SELL", "SEND", "SHED", "SHIP", "SHOE", "SHOP", "SHOT", "SHOW", "SHUT", "SICK", "SIDE", "SIGN", "SILK", "SING", "SINK", "SITE", "SIZE", "SKIN", "SKIP", "SLAP", "SLID", "SLIM", "SLIP", "SLOW", "SNAP", "SNOW", "SOAK", "SOAP", "SOAR", "SOCK", "SOFA", "SOIL", "SOLD", "SOLE", "SOLO", "SOME", "SONG", "SOON", "SORE", "SOUL", "SOUP", "SPAN", "SPIN", "SPIT", "SPOT", "STAR", "STAY", "STEM", "STEP", "STIR", "STOP", "SUCH", "SUIT", "SURE", "SURF", "SWAN", "SWIM",
        "TAIL", "TAKE", "TALE", "TALK", "TALL", "TANK", "TAPE", "TASK", "TEAM", "TEAR", "TELL", "TENT", "TERM", "TEST", "TEXT", "THAT", "THEM", "THEN", "THEY", "THIN", "THIS", "THOU", "TICK", "TIDE", "TIDY", "TIED", "TILE", "TILL", "TIME", "TINY", "TIRE", "TOAD", "TOLL", "TONE", "TOOK", "TOOL", "TOPS", "TORE", "TORN", "TOSS", "TOUR", "TOWN", "TRAP", "TRAY", "TREE", "TRIP", "TRUE", "TUBE", "TUNE", "TURN", "TWIN", "TYPE",
        "UNIT", "UPON", "URGE", "USED", "USER",
        "VAIN", "VALE", "VARY", "VAST", "VEIL", "VEIN", "VENT", "VERY", "VEST", "VETO", "VICE", "VIEW", "VINE", "VOLE", "VOTE",
        "WAGE", "WAIT", "WAKE", "WALK", "WALL", "WANT", "WARD", "WARM", "WARN", "WARP", "WARS", "WASH", "WASP", "WAVE", "WEAK", "WEAR", "WEED", "WEEK", "WELL", "WENT", "WEST", "WHAT", "WHEN", "WHOM", "WIDE", "WIFE", "WILD", "WILL", "WIND", "WINE", "WING", "WINK", "WIPE", "WIRE", "WISE", "WISH", "WITH", "WOLF", "WOOD", "WOOL", "WORD", "WORE", "WORK", "WORM", "WORN", "WRAP",
        "YARD", "YARN", "YEAR", "YELL", "YOGA", "YOKE", "YOUR",
        "ZEAL", "ZERO", "ZINC", "ZONE"
    ] as Array<String>;

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
        var idx = (Math.rand() % LETTER_SETS.size()).abs();
        _currentLetters = LETTER_SETS[idx];
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
        var i = 0;
        while (i < DICTIONARY.size()) {
            if (DICTIONARY[i].equals(word)) {
                return true;
            }
            i++;
        }
        return false;
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), 1000, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
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
