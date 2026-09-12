import Toybox.Lang;
import Toybox.WatchUi;

class FlappyGapMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as FlappyView;

    function initialize(view as FlappyView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        // Gap multiplier: smaller means a narrower gap between pipes, so
        // difficulty rises as this shrinks.
        if (item == :item_gap_very_easy) {
            _view.setGapMultiplier(1.0);
        } else if (item == :item_gap_easy) {
            _view.setGapMultiplier(0.8);
        } else if (item == :item_gap_normal) {
            _view.setGapMultiplier(0.65);
        } else if (item == :item_gap_hard) {
            _view.setGapMultiplier(0.5);
        } else if (item == :item_gap_very_hard) {
            _view.setGapMultiplier(0.38);
        }
    }

}
