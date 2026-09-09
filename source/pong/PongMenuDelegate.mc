import Toybox.Lang;
import Toybox.WatchUi;

class PongMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as PongView;

    function initialize(view as PongView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty) {
            WatchUi.pushView(new Rez.Menus.PongDifficultyMenu(), new PongDifficultyMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.PongSpeedMenu(), new PongSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
