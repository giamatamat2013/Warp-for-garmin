import Toybox.Lang;
import Toybox.WatchUi;

class GravityFlipDelegate extends WatchUi.BehaviorDelegate {

    private var _view as GravityFlipView;

    function initialize(view as GravityFlipView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START || key == WatchUi.KEY_UP || key == WatchUi.KEY_DOWN) {
            _view.flipGravity();
            return true;
        }
        return false;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        _view.flipGravity();
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.GravityFlipMenu(), new GravityFlipMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

}
