import Toybox.Lang;
import Toybox.WatchUi;

class MazeMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as MazeView;

    function initialize(view as MazeView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_board_size) {
            WatchUi.pushView(new Rez.Menus.MazeBoardSizeMenu(), new MazeBoardSizeMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
