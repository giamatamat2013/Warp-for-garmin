import Toybox.Lang;
import Toybox.WatchUi;

class SimonMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as SimonView;

    function initialize(view as SimonView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty) {
            WatchUi.pushView(new Rez.Menus.SimonDifficultyMenu(), new SimonDifficultyMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.SimonSpeedMenu(), new SimonSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
