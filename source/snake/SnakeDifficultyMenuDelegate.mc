import Toybox.Lang;
import Toybox.WatchUi;

class SnakeDifficultyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as SnakeView;

    function initialize(view as SnakeView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty_very_easy) {
            _view.setDifficulty(16);
        } else if (item == :item_difficulty_easy) {
            _view.setDifficulty(14);
        } else if (item == :item_difficulty_normal) {
            _view.setDifficulty(12);
        } else if (item == :item_difficulty_hard) {
            _view.setDifficulty(10);
        } else if (item == :item_difficulty_very_hard) {
            _view.setDifficulty(8);
        }
    }

}
