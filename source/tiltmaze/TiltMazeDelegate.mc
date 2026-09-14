import Toybox.Lang;
import Toybox.WatchUi;

class TiltMazeDelegate extends WatchUi.BehaviorDelegate {

    private var _view as TiltMazeView;

    function initialize(view as TiltMazeView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            _view.nudge(0.0, -18.0);
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _view.nudge(0.0, 18.0);
            return true;
        } else if (key == WatchUi.KEY_LEFT) {
            _view.nudge(-18.0, 0.0);
            return true;
        } else if (key == WatchUi.KEY_RIGHT) {
            _view.nudge(18.0, 0.0);
            return true;
        } else if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _view.resetGame();
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, [[Rez.Strings.menu_label_board_size, :setGridSize, [Rez.Strings.board_size_7x7, Rez.Strings.board_size_9x9, Rez.Strings.board_size_11x11, Rez.Strings.board_size_13x13], [7, 9, 11, 13]]]);
        return true;
    }

}

