import Toybox.Lang;
import Toybox.WatchUi;

class WordRushMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as WordRushView;

    function initialize(view as WordRushView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_reset) {
            _view.resetGame();
        }
    }

}

