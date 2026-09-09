import Toybox.Lang;
import Toybox.WatchUi;

class BreakoutDelegate extends WatchUi.BehaviorDelegate {

    private var _view as BreakoutView;

    function initialize(view as BreakoutView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_LEFT || key == WatchUi.KEY_UP) {
            _view.movePaddle(-14.0);
            return true;
        } else if (key == WatchUi.KEY_RIGHT || key == WatchUi.KEY_DOWN) {
            _view.movePaddle(14.0);
            return true;
        }
        return false;
    }

    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        var x = dragEvent.getCoordinates()[0];
        _view.setPaddleCenterX(x);
        return true;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_LEFT) {
            _view.movePaddle(-24.0);
            return true;
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            _view.movePaddle(24.0);
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.BreakoutMenu(), new BreakoutMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

}
