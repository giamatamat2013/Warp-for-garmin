import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class Warp_for_garminApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var menu = new Rez.Menus.MainMenu();

        // 2048 is swipe-only; hide it on devices with no touchscreen rather
        // than shipping a game that can't be controlled there.
        if (!System.getDeviceSettings().isTouchScreen) {
            var index = menu.findItemById(:item_2048);
            if (index >= 0) {
                menu.deleteItem(index);
            }
        }

        return [ menu, new MainMenuDelegate() ];
    }

}

function getApp() as Warp_for_garminApp {
    return Application.getApp() as Warp_for_garminApp;
}
