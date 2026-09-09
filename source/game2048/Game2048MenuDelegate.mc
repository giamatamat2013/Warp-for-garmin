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
            _view.setDifficulty(5);
        } else if (item == :item_grid_4) {
            _view.setDifficulty(4);
        } else if (item == :item_grid_3) {
            _view.setDifficulty(3);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
