import Toybox.Lang;
import Toybox.WatchUi;

class FlappySpacingMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as FlappyView;

    function initialize(view as FlappyView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        // Spacing multiplier: smaller means pipes are packed closer
        // together (less time to react/reposition between them), so
        // difficulty rises as this shrinks.
        if (item == :item_spacing_very_easy) {
            _view.setSpacingMultiplier(1.4);
        } else if (item == :item_spacing_easy) {
            _view.setSpacingMultiplier(1.15);
        } else if (item == :item_spacing_normal) {
            _view.setSpacingMultiplier(1.0);
        } else if (item == :item_spacing_hard) {
            _view.setSpacingMultiplier(0.8);
        } else if (item == :item_spacing_very_hard) {
            _view.setSpacingMultiplier(0.65);
        }
    }

}
