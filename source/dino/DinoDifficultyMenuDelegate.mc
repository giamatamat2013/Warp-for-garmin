import Toybox.Lang;
import Toybox.WatchUi;

class DinoDifficultyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as DinoView;

    function initialize(view as DinoView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

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
