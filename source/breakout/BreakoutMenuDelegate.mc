import Toybox.Lang;
import Toybox.WatchUi;

class BreakoutMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as BreakoutView;

    function initialize(view as BreakoutView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty) {
            WatchUi.pushView(new Rez.Menus.BreakoutDifficultyMenu(), new BreakoutDifficultyMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.BreakoutSpeedMenu(), new BreakoutSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
