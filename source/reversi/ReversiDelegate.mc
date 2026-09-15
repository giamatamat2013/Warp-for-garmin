import Toybox.Lang;
import Toybox.WatchUi;

(:touchGames)
class ReversiDelegate extends WatchUi.BehaviorDelegate {

    private var _view as ReversiView;

    function initialize(view as ReversiView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        _view.handleTap(coords[0], coords[1]);
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.openOptions(_view, [Rez.Strings.menu_label_difficulty, :setDifficulty, [Rez.Strings.menu_label_easy, Rez.Strings.menu_label_normal, Rez.Strings.menu_label_hard], [0, 1, 2]], true);
        return true;
    }

}
