import Toybox.Lang;
import Toybox.WatchUi;

class BalanceBallDifficultyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as BalanceBallView;

    function initialize(view as BalanceBallView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    // Difficulty shrinks the safe boundary the ball must stay inside.
    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty_very_easy) {
            _view.setDifficulty(0.85);
        } else if (item == :item_difficulty_easy) {
            _view.setDifficulty(0.78);
        } else if (item == :item_difficulty_normal) {
            _view.setDifficulty(0.72);
        } else if (item == :item_difficulty_hard) {
            _view.setDifficulty(0.62);
        } else if (item == :item_difficulty_very_hard) {
            _view.setDifficulty(0.52);
        }
    }

}
