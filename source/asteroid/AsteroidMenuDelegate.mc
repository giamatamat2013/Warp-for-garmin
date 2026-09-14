import Toybox.Lang;
import Toybox.WatchUi;

class AsteroidMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as AsteroidView;

    function initialize(view as AsteroidView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.AsteroidSpeedMenu(), new AsteroidSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}

