import Toybox.Lang;
import Toybox.WatchUi;

class Game2048Delegate extends WatchUi.BehaviorDelegate {

    private var _view as Game2048View;

    function initialize(view as Game2048View) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        _view.handleSwipe(swipeEvent.getDirection());
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.Game2048Menu(), new Game2048MenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

}
