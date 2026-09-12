import Toybox.Lang;
import Toybox.WatchUi;

class FlappySpeedMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as FlappyView;

    function initialize(view as FlappyView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        // Scaled down from the last pass (which made everything too fast)
        // so the old Slow speed now sits at Normal, keeping the same
        // proportional spacing between levels.
        if (item == :item_speed_very_slow) {
            _view.setSpeedMultiplier(0.9);
        } else if (item == :item_speed_slow) {
            _view.setSpeedMultiplier(1.15);
        } else if (item == :item_speed_normal) {
            _view.setSpeedMultiplier(1.6);
        } else if (item == :item_speed_fast) {
            _view.setSpeedMultiplier(2.2);
        } else if (item == :item_speed_very_fast) {
            _view.setSpeedMultiplier(2.9);
        }
    }

}
