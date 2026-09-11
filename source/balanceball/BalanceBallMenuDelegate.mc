import Toybox.Lang;
import Toybox.WatchUi;

class BalanceBallMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as BalanceBallView;

    function initialize(view as BalanceBallView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty) {
            WatchUi.pushView(new Rez.Menus.BalanceBallDifficultyMenu(), new BalanceBallDifficultyMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.BalanceBallSpeedMenu(), new BalanceBallSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
