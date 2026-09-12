import Toybox.Lang;
import Toybox.WatchUi;

class SnakeMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as SnakeView;

    function initialize(view as SnakeView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_board_size) {
            WatchUi.pushView(new Rez.Menus.SnakeBoardSizeMenu(), new SnakeBoardSizeMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.SnakeSpeedMenu(), new SnakeSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
