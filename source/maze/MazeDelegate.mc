import Toybox.Lang;
import Toybox.WatchUi;

class MazeDelegate extends WatchUi.BehaviorDelegate {

    private const NUDGE = 60.0;
    private var _view as MazeView;

    function initialize(view as MazeView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Tilt drives normal play; these keys are a fallback for devices or
    // simulators without live accelerometer input.
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            _view.nudge(0.0, -NUDGE);
        } else if (key == WatchUi.KEY_DOWN) {
            _view.nudge(0.0, NUDGE);
        } else if (key == WatchUi.KEY_LEFT) {
            _view.nudge(-NUDGE, 0.0);
        } else if (key == WatchUi.KEY_RIGHT) {
            _view.nudge(NUDGE, 0.0);
        } else if (key == WatchUi.KEY_ENTER) {
            _view.resetGame();
        } else {
            return false;
        }
        return true;
    }

    // No score or difficulty to configure, so the menu button just starts a
    // fresh maze instead of opening a submenu.
    function onMenu() as Boolean {
        _view.resetGame();
        return true;
    }

}
