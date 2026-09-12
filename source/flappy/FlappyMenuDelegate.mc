import Toybox.Lang;
import Toybox.WatchUi;

class FlappyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as FlappyView;

    function initialize(view as FlappyView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_gap_size) {
            WatchUi.pushView(new Rez.Menus.FlappyGapMenu(), new FlappyGapMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_pipe_spacing) {
            WatchUi.pushView(new Rez.Menus.FlappySpacingMenu(), new FlappySpacingMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_speed) {
            WatchUi.pushView(new Rez.Menus.FlappySpeedMenu(), new FlappySpeedMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
