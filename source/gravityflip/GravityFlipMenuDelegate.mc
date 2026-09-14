import Toybox.Lang;
import Toybox.WatchUi;

class GravityFlipMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as GravityFlipView;

    function initialize(view as GravityFlipView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.GravityFlipSpeedMenu(), new GravityFlipSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}

