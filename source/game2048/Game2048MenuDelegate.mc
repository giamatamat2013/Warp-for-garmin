import Toybox.Lang;
import Toybox.WatchUi;

class Game2048MenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as Game2048View;

    function initialize(view as Game2048View) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_grid_5) {
            _view.setBoardSize(5);
        } else if (item == :item_grid_4) {
            _view.setBoardSize(4);
        } else if (item == :item_grid_3) {
            _view.setBoardSize(3);
        } else if (item == :item_grid_custom) {
            var keypad = new NumberKeypadView("Board Size", 3, 8, 4);
            WatchUi.pushView(keypad, new NumberKeypadDelegate(keypad, _view.method(:onCustomBoardSize)), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
