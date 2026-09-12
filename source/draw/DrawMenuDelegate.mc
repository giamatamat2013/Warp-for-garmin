import Toybox.Lang;
import Toybox.WatchUi;

class DrawMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as DrawView;

    function initialize(view as DrawView) {
        MenuInputDelegate.initialize();
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_tool_brush) {
            _view.setTool(_view.TOOL_BRUSH);
        } else if (item == :item_tool_line) {
            _view.setTool(_view.TOOL_LINE);
        } else if (item == :item_tool_rectangle) {
            _view.setTool(_view.TOOL_RECTANGLE);
        } else if (item == :item_tool_circle) {
            _view.setTool(_view.TOOL_CIRCLE);
        } else if (item == :item_clear) {
            _view.clearCanvas();
        }
    }

}
