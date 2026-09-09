import Toybox.Lang;
import Toybox.WatchUi;

class PongDifficultyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as PongView;

    function initialize(view as PongView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty_very_easy) {
            _view.setDifficulty(1.2, 1.5);
        } else if (item == :item_difficulty_easy) {
            _view.setDifficulty(2.0, 2.2);
        } else if (item == :item_difficulty_normal) {
            _view.setDifficulty(3.5, 3.0);
        } else if (item == :item_difficulty_hard) {
            _view.setDifficulty(5.5, 4.5);
        } else if (item == :item_difficulty_very_hard) {
            _view.setDifficulty(7.5, 6.0);
        }
    }

}
