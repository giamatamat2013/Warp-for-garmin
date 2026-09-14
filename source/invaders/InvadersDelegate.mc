import Toybox.Lang;
import Toybox.WatchUi;

class InvadersDelegate extends WatchUi.BehaviorDelegate {

    private var _view as InvadersView;

    function initialize(view as InvadersView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_LEFT || key == WatchUi.KEY_UP) {
            _view.moveCannon(-14.0);
            return true;
        } else if (key == WatchUi.KEY_RIGHT || key == WatchUi.KEY_DOWN) {
            _view.moveCannon(14.0);
            return true;
        } else if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _view.fireBullet();
            return true;
        }
        return false;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        _view.setCannonCenterX(coords[0]);
        _view.fireBullet();
        return true;
    }

    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        var x = dragEvent.getCoordinates()[0];
        _view.setCannonCenterX(x);
        return true;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_LEFT) {
            _view.moveCannon(-28.0);
            return true;
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            _view.moveCannon(28.0);
            return true;
        } else if (direction == WatchUi.SWIPE_UP) {
            _view.fireBullet();
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.InvadersMenu(), new InvadersMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

}

