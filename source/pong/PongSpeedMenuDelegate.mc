import Toybox.Lang;
import Toybox.WatchUi;

class PongSpeedMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as PongView;

    function initialize(view as PongView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_speed_very_slow) {
            _view.setSpeedMultiplier(0.5);
        } else if (item == :item_speed_slow) {
            _view.setSpeedMultiplier(0.7);
        } else if (item == :item_speed_normal) {
            _view.setSpeedMultiplier(1.0);
        } else if (item == :item_speed_fast) {
            _view.setSpeedMultiplier(1.5);
        } else if (item == :item_speed_very_fast) {
            _view.setSpeedMultiplier(2.0);
        }
    }

}
