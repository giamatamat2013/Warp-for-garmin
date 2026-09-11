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
        } else if (id == :item_flappy) {
            var view = new FlappyView();
            WatchUi.pushView(view, new FlappyDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_snake) {
            var view = new SnakeView();
            WatchUi.pushView(view, new SnakeDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_breakout) {
            var view = new BreakoutView();
            WatchUi.pushView(view, new BreakoutDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_tictactoe) {
            var view = new TicTacToeView();
            WatchUi.pushView(view, new TicTacToeDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_simon) {
            var view = new SimonView();
            WatchUi.pushView(view, new SimonDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_dino) {
            var view = new DinoView();
            WatchUi.pushView(view, new DinoDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_tetris) {
            var view = new TetrisView();
            WatchUi.pushView(view, new TetrisDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_balanceball) {
            var view = new BalanceBallView();
            WatchUi.pushView(view, new BalanceBallDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_maze) {
            var view = new MazeView();
            WatchUi.pushView(view, new MazeDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :item_racing) {
            var view = new RacingView();
            WatchUi.pushView(view, new RacingDelegate(view), WatchUi.SLIDE_LEFT);
        }
    }

}
