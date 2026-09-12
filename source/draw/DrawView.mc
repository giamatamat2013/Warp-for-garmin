import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

class DrawView extends WatchUi.View {

    private const COLORS = [
        Graphics.COLOR_WHITE,
        Graphics.COLOR_LT_GRAY,
        Graphics.COLOR_DK_GRAY,
        Graphics.COLOR_RED,
        Graphics.COLOR_DK_RED,
        Graphics.COLOR_ORANGE,
        Graphics.COLOR_YELLOW,
        Graphics.COLOR_GREEN,
        Graphics.COLOR_DK_GREEN,
        Graphics.COLOR_BLUE,
        Graphics.COLOR_DK_BLUE,
        Graphics.COLOR_PURPLE,
        Graphics.COLOR_PINK
    ] as Array<Number>;

    // Tool modes: freehand brush, or a shape stamped from drag-start to drag-end.
    public const TOOL_BRUSH = 0;
    public const TOOL_LINE = 1;
    public const TOOL_RECTANGLE = 2;
    public const TOOL_CIRCLE = 3;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _colorIndex as Number = 0;
    private var _tool as Number = TOOL_BRUSH;

    // Committed shapes: each is [tool, color, x1, y1, x2, y2, ...] (brush strokes
    // carry extra point pairs; other tools always have exactly one x2,y2 pair).
    private var _shapes as Array<Array<Number> >;
    private var _dragStartX as Number = -1;
    private var _dragStartY as Number = -1;
    private var _dragCurX as Number = -1;
    private var _dragCurY as Number = -1;
    private var _dragging as Boolean = false;
    private var _currentBrushStroke as Array<Number>?;

    function initialize() {
        View.initialize();
        _shapes = [];
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
    }

    function currentColor() as Number {
        return COLORS[_colorIndex];
    }

    function setTool(tool as Number) as Void {
        _tool = tool;
    }

    function clearCanvas() as Void {
        _shapes = [];
        _currentBrushStroke = null;
        _dragging = false;
        WatchUi.requestUpdate();
    }

    // Tapping the color swatch cycles to the next color. It sits at top-center
    // (not a corner) so a round screen's bezel never clips it.
    function handleTap(x as Number, y as Number) as Void {
        var dx = x - (_width / 2);
        var dy = y - 14;
        if (dx * dx + dy * dy <= 144) {
            _colorIndex = (_colorIndex + 1) % COLORS.size();
            WatchUi.requestUpdate();
        }
    }

    function startStroke(x as Number, y as Number) as Void {
        _dragging = true;
        _dragStartX = x;
        _dragStartY = y;
        _dragCurX = x;
        _dragCurY = y;
        if (_tool == TOOL_BRUSH) {
            _currentBrushStroke = [TOOL_BRUSH, currentColor(), x, y] as Array<Number>;
            _shapes.add(_currentBrushStroke);
        }
        WatchUi.requestUpdate();
    }

    function extendStroke(x as Number, y as Number) as Void {
        if (!_dragging) {
            startStroke(x, y);
            return;
        }
        if (_tool == TOOL_BRUSH) {
            var dx = x - _dragCurX;
            var dy = y - _dragCurY;
            // Skip points that barely moved to keep the point list small on long drags.
            if (dx * dx + dy * dy < 4) {
                return;
            }
            _currentBrushStroke.add(x);
            _currentBrushStroke.add(y);
        }
        _dragCurX = x;
        _dragCurY = y;
        WatchUi.requestUpdate();
    }

    function endStroke(x as Number, y as Number) as Void {
        if (!_dragging) {
            return;
        }
        if (_tool != TOOL_BRUSH) {
            _shapes.add([_tool, currentColor(), _dragStartX, _dragStartY, x, y] as Array<Number>);
        }
        _dragging = false;
        _currentBrushStroke = null;
        WatchUi.requestUpdate();
    }

    private function drawShape(dc as Dc, tool as Number, color as Number, x1 as Number, y1 as Number, x2 as Number, y2 as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (tool == TOOL_LINE) {
            dc.drawLine(x1, y1, x2, y2);
        } else if (tool == TOOL_RECTANGLE) {
            var left = x1 < x2 ? x1 : x2;
            var top = y1 < y2 ? y1 : y2;
            var w = (x2 - x1).abs();
            var h = (y2 - y1).abs();
            dc.drawRectangle(left, top, w, h);
        } else if (tool == TOOL_CIRCLE) {
            var radius = Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)).toNumber();
            dc.drawCircle(x1, y1, radius);
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setPenWidth(4);
        var s = 0;
        while (s < _shapes.size()) {
            var shape = _shapes[s];
            var tool = shape[0];
            var color = shape[1];
            if (tool == TOOL_BRUSH) {
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                if (shape.size() == 4) {
                    dc.fillCircle(shape[2], shape[3], 2);
                }
                var i = 2;
                while (i + 3 < shape.size()) {
                    dc.drawLine(shape[i], shape[i + 1], shape[i + 2], shape[i + 3]);
                    i += 2;
                }
            } else {
                drawShape(dc, tool, color, shape[2], shape[3], shape[4], shape[5]);
            }
            s++;
        }

        if (_dragging && _tool != TOOL_BRUSH) {
            drawShape(dc, _tool, currentColor(), _dragStartX, _dragStartY, _dragCurX, _dragCurY);
        }
        dc.setPenWidth(1);

        dc.setColor(currentColor(), Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_width / 2, 14, 8);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(_width / 2, 14, 8);
    }

}
