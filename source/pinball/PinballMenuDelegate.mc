import Toybox.Lang;
import Toybox.WatchUi;

class PinballMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as PinballView;

    function initialize(view as PinballView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_reset) {
            _view.resetGame();
        }
    }

}

