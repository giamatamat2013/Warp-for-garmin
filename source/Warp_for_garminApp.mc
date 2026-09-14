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
        // Custom icon menu instead of the stock Menu2 list - see
        // CustomMainMenuView for the per-device touch-only game filtering
        // (previously done here) and common/GameIcons.mc for the icons.
        var view = new CustomMainMenuView();
        return [ view, new CustomMainMenuDelegate(view) ];
    }

}

function getApp() as Warp_for_garminApp {
    return Application.getApp() as Warp_for_garminApp;
}
