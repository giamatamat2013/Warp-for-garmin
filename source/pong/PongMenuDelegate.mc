import Toybox.Lang;
import Toybox.WatchUi;

class PongMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as PongView;

    function initialize(view as PongView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_easy) {
            _view.setDifficulty(2.0, 2.2);
        } else if (item == :item_normal) {
            _view.setDifficulty(3.5, 3.0);
        } else if (item == :item_hard) {
            _view.setDifficulty(5.5, 4.5);
        } else if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.PongSpeedMenu(), new PongSpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
