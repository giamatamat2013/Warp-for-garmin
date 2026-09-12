import Toybox.Lang;
import Toybox.WatchUi;

class TetrisMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as TetrisView;

    function initialize(view as TetrisView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_board_size) {
            WatchUi.pushView(new Rez.Menus.TetrisBoardSizeMenu(), new TetrisBoardSizeMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.TetrisSpeedMenu(), new TetrisSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
