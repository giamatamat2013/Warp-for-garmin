import Toybox.Lang;
import Toybox.WatchUi;

class DinoDelegate extends WatchUi.BehaviorDelegate {

    private var _view as DinoView;

    function initialize(view as DinoView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        _view.jump();
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_ENTER) {
            _view.jump();
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.DinoMenu(), new DinoMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

}
