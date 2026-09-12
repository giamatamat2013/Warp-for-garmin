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

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.DrawMenu(), new DrawMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

}
