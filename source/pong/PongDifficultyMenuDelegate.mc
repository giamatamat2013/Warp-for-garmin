import Toybox.Lang;
import Toybox.WatchUi;

class PongDifficultyMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as PongView;

    function initialize(view as PongView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        // setDifficulty(aiSpeed, ballSpeed, aiReactionTicks) — reactionTicks
        // is how many ticks the AI waits between looks at the ball; 1 means
        // it re-checks every tick (perfect tracking).
        if (item == :item_difficulty_very_easy) {
            _view.setDifficulty(3.0, 1.5, 16);
        } else if (item == :item_difficulty_easy) {
            _view.setDifficulty(3.5, 2.2, 9);
        } else if (item == :item_difficulty_normal) {
            _view.setDifficulty(4.5, 3.0, 4);
        } else if (item == :item_difficulty_hard) {
            _view.setDifficulty(5.5, 4.5, 2);
        } else if (item == :item_difficulty_very_hard) {
            _view.setDifficulty(7.5, 6.0, 1);
        }
    }

}
