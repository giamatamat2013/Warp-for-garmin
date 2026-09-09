import Toybox.Lang;
import Toybox.WatchUi;

class TicTacToeMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as TicTacToeView;

    function initialize(view as TicTacToeView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_difficulty_easy) {
            _view.setDifficulty(0);
        } else if (item == :item_difficulty_normal) {
            _view.setDifficulty(1);
        } else if (item == :item_difficulty_hard) {
            _view.setDifficulty(2);
        } else if (item == :item_reset) {
            _view.resetGame();
        }
    }

}
