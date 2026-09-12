import Toybox.Lang;
import Toybox.WatchUi;

class TetrisBoardSizeMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as TetrisView;

    function initialize(view as TetrisView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_grid_7) {
            _view.setBoardSize(7);
        } else if (item == :item_grid_9) {
            _view.setBoardSize(9);
        } else if (item == :item_grid_11) {
            _view.setBoardSize(11);
        } else if (item == :item_grid_13) {
            _view.setBoardSize(13);
        } else if (item == :item_grid_custom) {
            var keypad = new NumberKeypadView("Board Width", 5, 16, 9);
            WatchUi.pushView(keypad, new NumberKeypadDelegate(keypad, _view.method(:onCustomBoardSize)), WatchUi.SLIDE_UP);
        }
    }

}
