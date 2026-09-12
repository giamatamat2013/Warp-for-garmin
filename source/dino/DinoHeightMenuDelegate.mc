import Toybox.Lang;
import Toybox.WatchUi;

class DinoHeightMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as DinoView;

    function initialize(view as DinoView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        // Height multiplier: taller cacti need a better-timed jump, so
        // difficulty rises as this grows.
        if (item == :item_height_very_easy) {
            _view.setCactusHeight(0.6);
        } else if (item == :item_height_easy) {
            _view.setCactusHeight(0.8);
        } else if (item == :item_height_normal) {
            _view.setCactusHeight(1.0);
        } else if (item == :item_height_hard) {
            _view.setCactusHeight(1.25);
        } else if (item == :item_height_very_hard) {
            _view.setCactusHeight(1.5);
        }
    }

}
