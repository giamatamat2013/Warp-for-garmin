import Toybox.Lang;
import Toybox.WatchUi;

(:bigGames)
class ChessDelegate extends WatchUi.BehaviorDelegate {

    private var _view as ChessView;

    function initialize(view as ChessView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        _view.handleTap(coords[0], coords[1]);
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            _view.cycleCursor(-1);
        } else if (key == WatchUi.KEY_DOWN) {
            _view.cycleCursor(1);
        } else if (key == WatchUi.KEY_ENTER) {
            _view.confirmCursor();
        } else {
            return false;
        }
        return true;
    }

    function onBack() as Boolean {
        return _view.cancelSelection();
    }

    function onMenu() as Boolean {
        GameMenu.openOptions(_view, [Rez.Strings.menu_label_difficulty, :setDifficulty, [Rez.Strings.menu_label_easy, Rez.Strings.menu_label_normal, Rez.Strings.menu_label_hard], [0, 1, 2]], true);
        return true;
    }
}
