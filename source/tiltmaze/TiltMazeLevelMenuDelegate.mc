import Toybox.Lang;
import Toybox.WatchUi;

class TiltMazeLevelMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as TiltMazeView;

    function initialize(view as TiltMazeView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_grid_size) {
            WatchUi.pushView(new Rez.Menus.TiltMazeGridMenu(), new TiltMazeGridMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}

class TiltMazeGridMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as TiltMazeView;

    function initialize(view as TiltMazeView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_grid_7) {
            _view.setGridSize(7);
        } else if (item == :item_grid_9) {
            _view.setGridSize(9);
        } else if (item == :item_grid_11) {
            _view.setGridSize(11);
        } else if (item == :item_grid_13) {
            _view.setGridSize(13);
        }
    }

}

