import Toybox.Lang;
import Toybox.WatchUi;

(:touchGames)
class SimonDelegate extends WatchUi.BehaviorDelegate {

    private var _view as SimonView;

    function initialize(view as SimonView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        _view.handleTap(coords[0], coords[1]);
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, [GameMenu.level(Rez.Strings.menu_label_difficulty, :setDifficulty, [[1, 3], [1, 1], [1, 0], [2, 0], [3, 0]]), GameMenu.speed([0.6, 0.8, 1.0, 1.4, 1.9])]);
        return true;
    }

}
