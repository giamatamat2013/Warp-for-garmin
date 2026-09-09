import Toybox.Lang;
import Toybox.WatchUi;

class TicTacToeDelegate extends WatchUi.BehaviorDelegate {

    private var _view as TicTacToeView;

    function initialize(view as TicTacToeView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        _view.handleTap(coords[0], coords[1]);
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.TicTacToeMenu(), new TicTacToeMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

}
