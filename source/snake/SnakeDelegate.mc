import Toybox.Lang;
import Toybox.WatchUi;

(:touchGames)
class SnakeDelegate extends WatchUi.BehaviorDelegate {

    private var _view as SnakeView;

    function initialize(view as SnakeView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_UP) {
            _view.setDirection(0);
        } else if (direction == WatchUi.SWIPE_DOWN) {
            _view.setDirection(1);
        } else if (direction == WatchUi.SWIPE_LEFT) {
            _view.setDirection(2);
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            _view.setDirection(3);
        } else {
            return false;
        }
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            _view.setDirection(0);
        } else if (key == WatchUi.KEY_DOWN) {
            _view.setDirection(1);
        } else if (key == WatchUi.KEY_LEFT) {
            _view.setDirection(2);
        } else if (key == WatchUi.KEY_RIGHT) {
            _view.setDirection(3);
        } else {
            return false;
        }
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, [[Rez.Strings.menu_label_board_size, :setBoardSize, [Rez.Strings.board_size_16x16, Rez.Strings.board_size_14x14, Rez.Strings.board_size_12x12, Rez.Strings.board_size_10x10, Rez.Strings.board_size_8x8], [16, 14, 12, 10, 8], [6, 24, 12]], GameMenu.speed([0.4, 0.55, 0.7, 0.9, 1.1])]);
        return true;
    }

}
