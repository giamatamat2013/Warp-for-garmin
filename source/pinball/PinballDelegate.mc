import Toybox.Lang;
import Toybox.WatchUi;

(:heavyGames)
class PinballDelegate extends WatchUi.BehaviorDelegate {

    private var _view as PinballView;

    function initialize(view as PinballView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_LEFT || key == WatchUi.KEY_UP) {
            _view.setLeftFlipper(true);
            return true;
        } else if (key == WatchUi.KEY_RIGHT || key == WatchUi.KEY_DOWN) {
            _view.setRightFlipper(true);
            return true;
        } else if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _view.setLeftFlipper(true);
            _view.setRightFlipper(true);
            return true;
        }
        return false;
    }

    function onKeyReleased(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_LEFT || key == WatchUi.KEY_UP) {
            _view.setLeftFlipper(false);
            return true;
        } else if (key == WatchUi.KEY_RIGHT || key == WatchUi.KEY_DOWN) {
            _view.setRightFlipper(false);
            return true;
        } else if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _view.setLeftFlipper(false);
            _view.setRightFlipper(false);
            return true;
        }
        return false;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        // Left half or right half of screen
        var dcWidth = Toybox.System.getDeviceSettings().screenWidth;
        if (coords[0] < dcWidth / 2) {
            _view.setLeftFlipper(true);
        } else {
            _view.setRightFlipper(true);
        }
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, []);
        return true;
    }

}

