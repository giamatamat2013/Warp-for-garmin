import Toybox.Lang;
import Toybox.WatchUi;

(:heavyGames)
class BowlingDelegate extends WatchUi.BehaviorDelegate {

    private var _view as BowlingView;

    function initialize(view as BowlingView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        if (_view.isGameOver()) {
            if (dragEvent.getType() == WatchUi.DRAG_TYPE_STOP) {
                _view.resetGame();
            }
            return true;
        }

        var coords = dragEvent.getCoordinates();
        var type = dragEvent.getType();
        if (type == WatchUi.DRAG_TYPE_START) {
            _view.startAim(coords[0], coords[1]);
        } else if (type == WatchUi.DRAG_TYPE_CONTINUE) {
            _view.updateAim(coords[0], coords[1]);
        } else if (type == WatchUi.DRAG_TYPE_STOP) {
            _view.releaseAim(coords[0], coords[1]);
        }
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        if (_view.isGameOver()) {
            _view.resetGame();
        }
        return true;
    }

}
