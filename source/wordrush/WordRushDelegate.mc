import Toybox.Lang;
import Toybox.WatchUi;

class WordRushDelegate extends WatchUi.BehaviorDelegate {

    private var _view as WordRushView;

    function initialize(view as WordRushView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        _view.handleTap(coords[0], coords[1]);
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.WordRushMenu(), new WordRushMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

}

