import Toybox.Lang;
import Toybox.WatchUi;

class TetrisDifficultyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as TetrisView;

    function initialize(view as TetrisView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty_very_easy) {
            _view.setDifficulty(0);
        } else if (item == :item_difficulty_easy) {
            _view.setDifficulty(1);
        } else if (item == :item_difficulty_normal) {
            _view.setDifficulty(2);
        } else if (item == :item_difficulty_hard) {
            _view.setDifficulty(4);
        } else if (item == :item_difficulty_very_hard) {
            _view.setDifficulty(7);
        }
    }

}
