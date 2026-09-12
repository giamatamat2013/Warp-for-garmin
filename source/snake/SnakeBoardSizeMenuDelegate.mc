import Toybox.Lang;
import Toybox.WatchUi;

class SnakeBoardSizeMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as SnakeView;

    function initialize(view as SnakeView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_grid_16) {
            _view.setBoardSize(16);
        } else if (item == :item_grid_14) {
            _view.setBoardSize(14);
        } else if (item == :item_grid_12) {
            _view.setBoardSize(12);
        } else if (item == :item_grid_10) {
            _view.setBoardSize(10);
        } else if (item == :item_grid_8) {
            _view.setBoardSize(8);
        } else if (item == :item_grid_custom) {
            var keypad = new NumberKeypadView("Board Size", 6, 24, 12);
            WatchUi.pushView(keypad, new NumberKeypadDelegate(keypad, _view.method(:onCustomBoardSize)), WatchUi.SLIDE_UP);
        }
    }

}
