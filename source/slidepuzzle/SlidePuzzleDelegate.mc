import Toybox.Lang;
import Toybox.WatchUi;

(:touchGames)
class SlidePuzzleDelegate extends WatchUi.BehaviorDelegate {

    private var _view as SlidePuzzleView;

    function initialize(view as SlidePuzzleView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        _view.handleTap(coords[0], coords[1]);
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, [[Rez.Strings.menu_label_board_size, :setBoardSize, [Rez.Strings.board_size_3x3, Rez.Strings.board_size_4x4, Rez.Strings.board_size_5x5], [3, 4, 5]]]);
        return true;
    }

}
