import Toybox.Lang;
import Toybox.WatchUi;

(:extendedCode)
class DvdDelegate extends WatchUi.BehaviorDelegate {

    private var _view as DvdView;

    function initialize(view as DvdView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // ENTER or a tap pauses / resumes.
    function onSelect() as Boolean {
        _view.togglePause();
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, [GameMenu.speed([0.5, 0.75, 1.0, 1.5, 2.0])]);
        return true;
    }

}
