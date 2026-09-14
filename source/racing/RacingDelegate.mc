import Toybox.Lang;
import Toybox.WatchUi;

class RacingDelegate extends WatchUi.BehaviorDelegate {

    private var _view as RacingView;

    function initialize(view as RacingView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_LEFT) {
            _view.moveLane(-1);
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            _view.moveLane(1);
        } else {
            return false;
        }
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_LEFT) {
            _view.moveLane(-1);
        } else if (key == WatchUi.KEY_RIGHT) {
            _view.moveLane(1);
        } else {
            return false;
        }
        return true;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, [GameMenu.level(Rez.Strings.menu_label_difficulty, :setDifficulty, [1.6, 1.3, 1.0, 0.75, 0.55]), [Rez.Strings.menu_label_lanes, :setLaneCount, [Rez.Strings.lanes_2, Rez.Strings.lanes_3, Rez.Strings.lanes_4, Rez.Strings.lanes_5], [2, 3, 4, 5]], GameMenu.speed(GameMenu.STANDARD_SPEEDS)]);
        return true;
    }

}
