import Toybox.Lang;
import Toybox.WatchUi;

class RacingSpeedMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as RacingView;

    function initialize(view as RacingView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

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
