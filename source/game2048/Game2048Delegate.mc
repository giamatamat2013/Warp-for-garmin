import Toybox.Lang;
import Toybox.WatchUi;

(:touchGames)
class Game2048Delegate extends WatchUi.BehaviorDelegate {

    private var _view as Game2048View;

    function initialize(view as Game2048View) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        _view.handleSwipe(swipeEvent.getDirection());
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.openOptions(_view, [Rez.Strings.menu_label_board_size, :setBoardSize, [Rez.Strings.board_size_5x5, Rez.Strings.board_size_4x4, Rez.Strings.board_size_3x3], [5, 4, 3], [3, 8, 4]], true);
        return true;
    }

}
