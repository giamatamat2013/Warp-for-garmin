import Toybox.Lang;
import Toybox.WatchUi;

class RacingDifficultyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as RacingView;

    function initialize(view as RacingView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    // Difficulty is the gap between bot cars - a bigger multiplier means
    // more room to react.
    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty_very_easy) {
            _view.setDifficulty(1.6);
        } else if (item == :item_difficulty_easy) {
            _view.setDifficulty(1.3);
        } else if (item == :item_difficulty_normal) {
            _view.setDifficulty(1.0);
        } else if (item == :item_difficulty_hard) {
            _view.setDifficulty(0.75);
        } else if (item == :item_difficulty_very_hard) {
            _view.setDifficulty(0.55);
        }
    }

}
