import Toybox.Lang;
import Toybox.WatchUi;

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
        _view.resetGame();
        return true;
    }

}
