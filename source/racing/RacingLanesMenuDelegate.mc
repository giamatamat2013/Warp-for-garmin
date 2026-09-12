import Toybox.Lang;
import Toybox.WatchUi;

class RacingLanesMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as RacingView;

    function initialize(view as RacingView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_lanes_2) {
            _view.setLaneCount(2);
        } else if (item == :item_lanes_3) {
            _view.setLaneCount(3);
        } else if (item == :item_lanes_4) {
            _view.setLaneCount(4);
        } else if (item == :item_lanes_5) {
            _view.setLaneCount(5);
        }
    }

}
