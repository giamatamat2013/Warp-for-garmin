import Toybox.Lang;
import Toybox.WatchUi;

class DinoFrequencyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as DinoView;

    function initialize(view as DinoView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        // Spawn gap multiplier: smaller means less time (and space) between
        // cacti, so difficulty rises as this shrinks.
        if (item == :item_frequency_very_easy) {
            _view.setSpawnFrequency(1.6);
        } else if (item == :item_frequency_easy) {
            _view.setSpawnFrequency(1.3);
        } else if (item == :item_frequency_normal) {
            _view.setSpawnFrequency(1.0);
        } else if (item == :item_frequency_hard) {
            _view.setSpawnFrequency(0.75);
        } else if (item == :item_frequency_very_hard) {
            _view.setSpawnFrequency(0.55);
        }
    }

}
