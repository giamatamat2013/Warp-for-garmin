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

        // These games are tap/swipe-only; hide them on devices with no
        // touchscreen rather than shipping a game that can't be controlled
        // there. Pong, Flappy Bird and Breakout all have button fallbacks,
        // so they stay available everywhere.
        if (!System.getDeviceSettings().isTouchScreen) {
            var touchOnlyGames = [:item_2048, :item_snake, :item_tictactoe, :item_simon];
            var i = 0;
            while (i < touchOnlyGames.size()) {
                var index = menu.findItemById(touchOnlyGames[i]);
                if (index >= 0) {
                    menu.deleteItem(index);
                }
                i++;
            }
        }

        return [ menu, new MainMenuDelegate() ];
    }

}

function getApp() as Warp_for_garminApp {
    return Application.getApp() as Warp_for_garminApp;
}
