import Toybox.Lang;
import Toybox.WatchUi;

class InvadersMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as InvadersView;

    function initialize(view as InvadersView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.InvadersSpeedMenu(), new InvadersSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}

