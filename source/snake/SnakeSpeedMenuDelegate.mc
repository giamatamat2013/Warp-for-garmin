import Toybox.Lang;
import Toybox.WatchUi;

class SnakeSpeedMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as SnakeView;

    function initialize(view as SnakeView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        // Scaled down from before (paired with a raised BASE_TICK_MS in
        // SnakeView) so every speed setting is much slower overall.
        if (item == :item_speed_very_slow) {
            _view.setSpeedMultiplier(0.4);
        } else if (item == :item_speed_slow) {
            _view.setSpeedMultiplier(0.55);
        } else if (item == :item_speed_normal) {
            _view.setSpeedMultiplier(0.7);
        } else if (item == :item_speed_fast) {
            _view.setSpeedMultiplier(0.9);
        } else if (item == :item_speed_very_fast) {
            _view.setSpeedMultiplier(1.1);
        }
    }

}
