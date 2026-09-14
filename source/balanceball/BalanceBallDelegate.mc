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
        GameMenu.open(_view, [GameMenu.level(Rez.Strings.menu_label_difficulty, :setLevel, [[0.95, 0.35], [0.90, 0.45], [0.85, 0.55], [0.75, 0.7], [0.65, 0.85]])]);
        return true;
    }

}
