import Toybox.Lang;
import Toybox.WatchUi;

class DrawToolbarDelegate extends WatchUi.BehaviorDelegate {

    private var _view as DrawView;
    private var _toolbar as DrawToolbarView;

    function initialize(view as DrawView, toolbar as DrawToolbarView) {
        BehaviorDelegate.initialize();
        _view = view;
        _toolbar = toolbar;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var btn = _toolbar.buttonAt(coords[0], coords[1]);
        if (btn == null) {
            return true;
        }

        var kind = btn[:kind];
        if (kind == _toolbar.KIND_CATEGORY) {
            _toolbar.selectCategory(btn[:value] as Number);
        } else if (kind == _toolbar.KIND_TOOL) {
            _view.setTool(btn[:value] as Number);
            WatchUi.requestUpdate();
        } else if (kind == _toolbar.KIND_SIZE) {
            _view.setBrushSizeIndex(btn[:value] as Number);
        } else if (kind == _toolbar.KIND_UNDO) {
            _view.undoLast();
        } else if (kind == _toolbar.KIND_CLEAR) {
            _view.clearCanvas();
        } else if (kind == _toolbar.KIND_COLOR) {
            _view.setColorIndex(btn[:value] as Number);
            WatchUi.requestUpdate();
        } else if (kind == _toolbar.KIND_BACK) {
            _toolbar.goBack();
        }
        return true;
    }

    // Also allow the hardware back gesture to return to the canvas.
    function onBack() as Boolean {
        _toolbar.goBack();
        return true;
    }

}
