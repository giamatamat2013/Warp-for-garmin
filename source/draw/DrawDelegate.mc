import Toybox.Lang;
import Toybox.WatchUi;

class DrawDelegate extends WatchUi.BehaviorDelegate {

    private var _view as DrawView;

    function initialize(view as DrawView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        var coords = dragEvent.getCoordinates();
        var type = dragEvent.getType();
        if (type == WatchUi.DRAG_TYPE_START) {
            _view.startStroke(coords[0], coords[1]);
        } else if (type == WatchUi.DRAG_TYPE_CONTINUE) {
            _view.extendStroke(coords[0], coords[1]);
        } else if (type == WatchUi.DRAG_TYPE_STOP) {
            _view.endStroke(coords[0], coords[1]);
        }
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        _view.handleTap(coords[0], coords[1]);
        return true;
    }

    // Swipe left is a quick shortcut for undo, without opening the menu.
    // Other directions fall through so the default back-swipe still works.
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        if (swipeEvent.getDirection() == WatchUi.SWIPE_LEFT) {
            _view.undoLast();
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        var toolbar = new DrawToolbarView(_view);
        WatchUi.pushView(toolbar, new DrawToolbarDelegate(_view, toolbar), WatchUi.SLIDE_UP);
        return true;
    }

}
