import Toybox.Lang;
import Toybox.WatchUi;

class RacingMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as RacingView;

    function initialize(view as RacingView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty) {
            WatchUi.pushView(new Rez.Menus.RacingDifficultyMenu(), new RacingDifficultyMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.RacingSpeedMenu(), new RacingSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
