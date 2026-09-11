import Toybox.Lang;
import Toybox.WatchUi;

class BalanceBallSpeedMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as BalanceBallView;

    function initialize(view as BalanceBallView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    // Speed scales how strongly a given tilt accelerates the ball.
    function onMenuItem(item as Symbol) as Void {
        if (item == :item_speed_very_slow) {
            _view.setSpeedMultiplier(0.6);
        } else if (item == :item_speed_slow) {
            _view.setSpeedMultiplier(0.8);
        } else if (item == :item_speed_normal) {
            _view.setSpeedMultiplier(1.0);
        } else if (item == :item_speed_fast) {
            _view.setSpeedMultiplier(1.3);
        } else if (item == :item_speed_very_fast) {
            _view.setSpeedMultiplier(1.6);
        }
    }

}
