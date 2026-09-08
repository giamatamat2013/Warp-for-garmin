import Toybox.Lang;
import Toybox.WatchUi;

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    // Add a game here: give it a menu-item in resources/menus/menu.xml, then a
    // case below pushing its View+Delegate. If a game needs a feature not every
    // device has (a higher API level, a touchscreen, ...), hide its menu-item
    // for unsupported devices in Warp_for_garminApp.getInitialView() instead of
    // raising the requirement for everyone.
    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :item_pong) {
            var view = new PongView();
            WatchUi.pushView(view, new PongDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_2048) {
            var view = new Game2048View();
            WatchUi.pushView(view, new Game2048Delegate(view), WatchUi.SLIDE_LEFT);
        }
    }

}
