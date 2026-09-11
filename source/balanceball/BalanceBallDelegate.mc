import Toybox.Lang;
import Toybox.WatchUi;

class BalanceBallDelegate extends WatchUi.BehaviorDelegate {

    private const NUDGE = 60.0;
    private var _view as BalanceBallView;

    function initialize(view as BalanceBallView) {
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

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.BalanceBallMenu(), new BalanceBallMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

}
