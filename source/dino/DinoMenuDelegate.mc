import Toybox.Lang;
import Toybox.WatchUi;

class DinoMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as DinoView;

    function initialize(view as DinoView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_cactus_height) {
            WatchUi.pushView(new Rez.Menus.DinoHeightMenu(), new DinoHeightMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_cactus_frequency) {
            WatchUi.pushView(new Rez.Menus.DinoFrequencyMenu(), new DinoFrequencyMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.DinoSpeedMenu(), new DinoSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
