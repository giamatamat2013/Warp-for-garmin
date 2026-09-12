import Toybox.Lang;
import Toybox.WatchUi;

class BalanceBallLevelMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as BalanceBallView;

    function initialize(view as BalanceBallView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    // Difficulty and speed used to fight each other as separate menus (a
    // big/easy boundary paired with twitchy/hard tilt response felt
    // inconsistent), so one level now sets both together — a bigger
    // boundary (easier) always comes with gentler tilt response (easier)
    // too. Pulled easier across the board vs. the old separate scales.
    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty_very_easy) {
            _view.setLevel(0.95, 0.35);
        } else if (item == :item_difficulty_easy) {
            _view.setLevel(0.90, 0.45);
        } else if (item == :item_difficulty_normal) {
            _view.setLevel(0.85, 0.55);
        } else if (item == :item_difficulty_hard) {
            _view.setLevel(0.75, 0.7);
        } else if (item == :item_difficulty_very_hard) {
            _view.setLevel(0.65, 0.85);
        }
    }

}
