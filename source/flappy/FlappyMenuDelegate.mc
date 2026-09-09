import Toybox.Lang;
import Toybox.WatchUi;

class FlappyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as FlappyView;

    function initialize(view as FlappyView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty) {
            WatchUi.pushView(new Rez.Menus.FlappyDifficultyMenu(), new FlappyDifficultyMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.FlappySpeedMenu(), new FlappySpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
