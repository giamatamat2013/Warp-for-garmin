import Toybox.Lang;
import Toybox.WatchUi;

(:touchGames)
class WhackDelegate extends WatchUi.BehaviorDelegate {

    private var _view as WhackView;

    function initialize(view as WhackView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        _view.handleTap(coords[0], coords[1]);
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.openOptions(_view, GameMenu.speed([0.7, 0.85, 1.0, 1.25, 1.6]), true);
        return true;
    }

}
