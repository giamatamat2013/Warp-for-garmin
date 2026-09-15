import Toybox.Lang;
import Toybox.WatchUi;

(:touchGames)
class MinesweeperDelegate extends WatchUi.BehaviorDelegate {

    private var _view as MinesweeperView;

    function initialize(view as MinesweeperView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        _view.handleTap(coords[0], coords[1]);
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, [[Rez.Strings.menu_label_board_size, :setBoardSize, [Rez.Strings.board_size_8x8, Rez.Strings.board_size_10x10, Rez.Strings.board_size_12x12], [8, 10, 12]]]);
        return true;
    }

}
