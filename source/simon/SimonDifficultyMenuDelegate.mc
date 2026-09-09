import Toybox.Lang;
import Toybox.WatchUi;

class SimonDifficultyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as SimonView;

    function initialize(view as SimonView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    // setDifficulty(startLength, strikesAllowed): Very Easy starts short and
    // forgives mistakes; Very Hard jumps straight to a 3-step sequence with
    // zero tolerance for a wrong tap.
    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty_very_easy) {
            _view.setDifficulty(1, 3);
        } else if (item == :item_difficulty_easy) {
            _view.setDifficulty(1, 1);
        } else if (item == :item_difficulty_normal) {
            _view.setDifficulty(1, 0);
        } else if (item == :item_difficulty_hard) {
            _view.setDifficulty(2, 0);
        } else if (item == :item_difficulty_very_hard) {
            _view.setDifficulty(3, 0);
        }
    }

}
