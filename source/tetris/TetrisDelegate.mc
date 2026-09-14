import Toybox.Lang;
import Toybox.WatchUi;

(:touchGames)
class TetrisDelegate extends WatchUi.BehaviorDelegate {

    private var _view as TetrisView;

    function initialize(view as TetrisView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_LEFT) {
            _view.moveLeft();
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            _view.moveRight();
        } else if (direction == WatchUi.SWIPE_UP) {
            _view.rotate();
        } else if (direction == WatchUi.SWIPE_DOWN) {
            _view.hardDrop();
        } else {
            return false;
        }
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        _view.rotate();
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_LEFT) {
            _view.moveLeft();
        } else if (key == WatchUi.KEY_RIGHT) {
            _view.moveRight();
        } else if (key == WatchUi.KEY_UP) {
            _view.rotate();
        } else if (key == WatchUi.KEY_DOWN) {
            _view.hardDrop();
        } else {
            return false;
        }
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, [[Rez.Strings.menu_label_board_size, :setBoardSize, [Rez.Strings.board_size_7, Rez.Strings.board_size_9, Rez.Strings.board_size_11, Rez.Strings.board_size_13], [7, 9, 11, 13], [5, 16, 9]], GameMenu.speed(GameMenu.STANDARD_SPEEDS)]);
        return true;
    }

}
