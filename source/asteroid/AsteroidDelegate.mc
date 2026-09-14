import Toybox.Lang;
import Toybox.WatchUi;

class AsteroidDelegate extends WatchUi.BehaviorDelegate {

    private var _view as AsteroidView;

    function initialize(view as AsteroidView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_LEFT || key == WatchUi.KEY_UP) {
            _view.moveShip(-18.0);
            return true;
        } else if (key == WatchUi.KEY_RIGHT || key == WatchUi.KEY_DOWN) {
            _view.moveShip(18.0);
            return true;
        } else if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _view.moveShip(0.0); // Restarts if game over
            return true;
        }
        return false;
    }

    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        var x = dragEvent.getCoordinates()[0];
        _view.setShipCenterX(x);
        return true;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_LEFT) {
            _view.moveShip(-32.0);
            return true;
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            _view.moveShip(32.0);
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, [GameMenu.speed(GameMenu.STANDARD_SPEEDS)]);
        return true;
    }

}
