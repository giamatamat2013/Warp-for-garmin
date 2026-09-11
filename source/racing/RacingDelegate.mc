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
        WatchUi.pushView(new Rez.Menus.RacingMenu(), new RacingMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

}
