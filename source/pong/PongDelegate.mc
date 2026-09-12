import Toybox.Lang;
import Toybox.WatchUi;

class PongDelegate extends WatchUi.BehaviorDelegate {

    private var _view as PongView;

    function initialize(view as PongView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            _view.movePlayer(-10);
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _view.movePlayer(10);
            return true;
        } else if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _view.setBoostActive(true);
            return true;
        }
        return false;
    }

    function onKeyReleased(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _view.setBoostActive(false);
            return true;
        }
        return false;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var y = clickEvent.getCoordinates()[1];
        if (y < _view.getHeight() / 2) {
            _view.movePlayer(-20);
        } else {
            _view.movePlayer(20);
        }
        return true;
    }

    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        var y = dragEvent.getCoordinates()[1];
        _view.setPlayerY(y);
        return true;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_UP) {
            _view.movePlayer(-20);
            return true;
        } else if (direction == WatchUi.SWIPE_DOWN) {
            _view.movePlayer(20);
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.PongMenu(), new PongMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

}
