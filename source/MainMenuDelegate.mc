import Toybox.Lang;
import Toybox.WatchUi;

class CustomMainMenuDelegate extends WatchUi.BehaviorDelegate {

    private var _view as CustomMainMenuView;
    private var _lastDragY as Number = 0;

    function initialize(view as CustomMainMenuView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Add a game here: give it a menu-item in resources/menus/menu.xml, then a
    // case below pushing its View+Delegate. If a game needs a feature not every
    // device has (a higher API level, a touchscreen, ...), hide its menu-item
    // for unsupported devices in Warp_for_garminApp.getInitialView() instead of
    // raising the requirement for everyone.
    function select(id as Symbol) as Void {
        _view.markPlayed(id);
        if (selectTouchGame(id)) {
            return;
        }
        if (selectHeavyGame(id)) {
            return;
        }
        if (id == :item_pong) {
            var view = new PongView();
            WatchUi.pushView(view, new PongDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_flappy) {
            var view = new FlappyView();
            WatchUi.pushView(view, new FlappyDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_breakout) {
            var view = new BreakoutView();
            WatchUi.pushView(view, new BreakoutDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_dino) {
            var view = new DinoView();
            WatchUi.pushView(view, new DinoDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_balanceball) {
            var view = new BalanceBallView();
            WatchUi.pushView(view, new BalanceBallDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_racing) {
            var view = new RacingView();
            WatchUi.pushView(view, new RacingDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_asteroid) {
            var view = new AsteroidView();
            WatchUi.pushView(view, new AsteroidDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_gravityflip) {
            var view = new GravityFlipView();
            WatchUi.pushView(view, new GravityFlipDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_tiltmaze) {
            var view = new TiltMazeView();
            WatchUi.pushView(view, new TiltMazeDelegate(view), WatchUi.SLIDE_LEFT);
        }
    }

    // Games in Games.HAS_HEAVY_GAMES (currently Pinball, Invaders - the
    // largest always-on games). Their code is left out on the lowest-memory
    // devices (see monkey.jungle) to keep the app fitting in 96KB/128KB.
    (:heavyGames)
    private function selectHeavyGame(id as Symbol) as Boolean {
        if (id == :item_pinball) {
            var view = new PinballView();
            WatchUi.pushView(view, new PinballDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_invaders) {
            var view = new InvadersView();
            WatchUi.pushView(view, new InvadersDelegate(view), WatchUi.SLIDE_LEFT);
        } else {
            return false;
        }
        return true;
    }

    (:noHeavyGames)
    private function selectHeavyGame(id as Symbol) as Boolean {
        return false;
    }

    // Games in CustomMainMenuView.TOUCH_ONLY_GAMES. Their code is left out on
    // low-memory non-touch devices (see monkey.jungle), where the menu never
    // shows them and the empty fallback below is built instead.
    (:touchGames)
    private function selectTouchGame(id as Symbol) as Boolean {
        if (id == :item_2048) {
            var view = new Game2048View();
            WatchUi.pushView(view, new Game2048Delegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_snake) {
            var view = new SnakeView();
            WatchUi.pushView(view, new SnakeDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_tictactoe) {
            var view = new TicTacToeView();
            WatchUi.pushView(view, new TicTacToeDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_simon) {
            var view = new SimonView();
            WatchUi.pushView(view, new SimonDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_tetris) {
            var view = new TetrisView();
            WatchUi.pushView(view, new TetrisDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_draw) {
            var view = new DrawView();
            WatchUi.pushView(view, new DrawDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_wordrush) {
            var view = new WordRushView();
            WatchUi.pushView(view, new WordRushDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_memorymatch) {
            var view = new MemoryMatchView();
            WatchUi.pushView(view, new MemoryMatchDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_whack) {
            var view = new WhackView();
            WatchUi.pushView(view, new WhackDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_connect4) {
            var view = new ConnectFourView();
            WatchUi.pushView(view, new ConnectFourDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_minesweeper) {
            var view = new MinesweeperView();
            WatchUi.pushView(view, new MinesweeperDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_slidepuzzle) {
            var view = new SlidePuzzleView();
            WatchUi.pushView(view, new SlidePuzzleDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_reversi) {
            var view = new ReversiView();
            WatchUi.pushView(view, new ReversiDelegate(view), WatchUi.SLIDE_LEFT);
        } else {
            return false;
        }
        return true;
    }

    (:noTouchGames)
    private function selectTouchGame(id as Symbol) as Boolean {
        return false;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var row = _view.rowAt(coords[0], coords[1]);
        if (row >= 0) {
            _view.setSelected(row);
            select(_view.idAt(row));
            return true;
        }
        return false;
    }

    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        var y = dragEvent.getCoordinates()[1];
        var type = dragEvent.getType();
        if (type == WatchUi.DRAG_TYPE_START) {
            _lastDragY = y;
        } else {
            _view.scroll(_lastDragY - y);
            _lastDragY = y;
        }
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            _view.moveSelection(-2);
        } else if (key == WatchUi.KEY_DOWN) {
            _view.moveSelection(2);
        } else if (key == WatchUi.KEY_LEFT) {
            _view.moveSelection(-1);
        } else if (key == WatchUi.KEY_RIGHT) {
            _view.moveSelection(1);
        } else if (key == WatchUi.KEY_ENTER) {
            select(_view.idAt(_view.selectedIndex()));
        } else {
            return false;
        }
        return true;
    }

}
