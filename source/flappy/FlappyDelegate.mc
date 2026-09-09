import Toybox.Lang;
import Toybox.WatchUi;

class FlappyDelegate extends WatchUi.BehaviorDelegate {

    private var _view as FlappyView;

    function initialize(view as FlappyView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        _view.flap();
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_ENTER) {
            _view.flap();
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        _view.resetGame();
        return true;
    }

}
