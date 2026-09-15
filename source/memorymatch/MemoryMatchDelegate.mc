import Toybox.Lang;
import Toybox.WatchUi;

(:touchGames)
class MemoryMatchDelegate extends WatchUi.BehaviorDelegate {

    private var _view as MemoryMatchView;

    function initialize(view as MemoryMatchView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        _view.handleTap(coords[0], coords[1]);
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.openOptions(_view, GameMenu.level(Rez.Strings.menu_label_difficulty, :setDifficulty, [4, 6, 8, 10, 12]), true);
        return true;
    }

}
