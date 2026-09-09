import Toybox.Lang;
import Toybox.WatchUi;

class FlappyDifficultyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as FlappyView;

    function initialize(view as FlappyView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty_very_easy) {
            _view.setDifficulty(1.4);
        } else if (item == :item_difficulty_easy) {
            _view.setDifficulty(1.2);
        } else if (item == :item_difficulty_normal) {
            _view.setDifficulty(1.0);
        } else if (item == :item_difficulty_hard) {
            _view.setDifficulty(0.85);
        } else if (item == :item_difficulty_very_hard) {
            _view.setDifficulty(0.7);
        }
    }

}
