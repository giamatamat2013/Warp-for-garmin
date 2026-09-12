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

    // Tool modes: drag-built strokes (brush/eraser/spray, built up point by
    // point while dragging), shapes stamped from drag-start to drag-end
    // (outline or filled), and the bucket, which is a tap action.
    public const TOOL_BRUSH = 0;
    public const TOOL_LINE = 1;
    public const TOOL_RECTANGLE = 2;
    public const TOOL_RECTANGLE_FILL = 3;
    public const TOOL_CIRCLE = 4;
    public const TOOL_CIRCLE_FILL = 5;
    public const TOOL_TRIANGLE = 6;
    public const TOOL_TRIANGLE_FILL = 7;
    public const TOOL_ERASER = 8;
    public const TOOL_BUCKET = 9;
    public const TOOL_SPRAY = 10;

    // Selectable stroke widths shown directly in the draw toolbar.
    private const PEN_WIDTHS = [1, 2, 3, 4, 6, 8, 12, 16] as Array<Number>;

    private var _width as Number = 0;
    private var _colorIndex as Number = 0;
    private var _sizeIndex as Number = 0;
    private var _tool as Number = TOOL_BRUSH;
    private var _backgroundColor as Number = Graphics.COLOR_BLACK;

    // Committed shapes: each is [tool, color, width, x1, y1, x2, y2, ...].
    // Brush/eraser/spray strokes carry extra point pairs; other tools always
    // have exactly one x2,y2 pair.
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
    }

    function currentColor() as Number {
        return COLORS[_colorIndex];
    }

    // Direct color pick, used by the toolbar's color swatches.
    function setColorIndex(idx as Number) as Void {
        if (idx >= 0 && idx < COLORS.size()) {
            _colorIndex = idx;
            WatchUi.requestUpdate();
        }
    }

    function setTool(tool as Number) as Void {
        _tool = tool;
    }

    function getTool() as Number {
        return _tool;
    }

    function getColorIndex() as Number {
        return _colorIndex;
    }

    function getSizeIndex() as Number {
        return _sizeIndex;
    }

    function colorAt(idx as Number) as Number {
        return COLORS[idx];
    }

    function colorCount() as Number {
        return COLORS.size();
    }

    function penWidthAt(idx as Number) as Number {
        return PEN_WIDTHS[idx];
    }

    function cycleBrushSize() as Void {
        _sizeIndex = (_sizeIndex + 1) % PEN_WIDTHS.size();
        WatchUi.requestUpdate();
    }

    function setBrushSizeIndex(idx as Number) as Void {
        if (idx >= 0 && idx < PEN_WIDTHS.size()) {
            _sizeIndex = idx;
            WatchUi.requestUpdate();
        }
    }

    function undoLast() as Void {
        var n = _shapes.size();
        if (n > 0) {
            _shapes = _shapes.slice(0, n - 1);
            WatchUi.requestUpdate();
        }
    }

    function clearCanvas() as Void {
        _shapes = [];
        _currentBrushStroke = null;
        _dragging = false;
        _backgroundColor = Graphics.COLOR_BLACK;
        WatchUi.requestUpdate();
    }

    // Tapping the color swatch cycles to the next color. It sits at top-center
    // (not a corner) so a round screen's bezel never clips it. Tapping
    // anywhere else with the bucket tool active fills the background.
    function handleTap(x as Number, y as Number) as Void {
        var dx = x - (_width / 2);
        var dy = y - 14;
        if (dx * dx + dy * dy <= 144) {
            _colorIndex = (_colorIndex + 1) % COLORS.size();
            WatchUi.requestUpdate();
            return;
        }
        if (_tool == TOOL_BUCKET) {
            _backgroundColor = currentColor();
            WatchUi.requestUpdate();
        }
    }

    // Tools whose shapes are built up point-by-point while dragging, as
    // opposed to a single shape stamped from drag-start to drag-end.
    private function isDragBuilt(tool as Number) as Boolean {
        return tool == TOOL_BRUSH || tool == TOOL_ERASER || tool == TOOL_SPRAY;
    }

    // Eraser always paints in the background color, regardless of the
    // selected palette color.
    private function strokeColor(tool as Number) as Number {
        return tool == TOOL_ERASER ? _backgroundColor : currentColor();
    }

    // Eraser strokes are drawn extra-wide so erasing is actually usable
    // with a finger on a small screen; spray uses its width as a scatter
    // radius rather than a line width.
    private function strokeWidth(tool as Number) as Number {
        var w = PEN_WIDTHS[_sizeIndex];
        if (tool == TOOL_ERASER) {
            return w * 3;
        } else if (tool == TOOL_SPRAY) {
            return w * 2;
        }
        return w;
    }

    // Scatters a handful of points around (x, y) within the spray radius
    // and bakes them into the given stroke permanently, so the pattern
    // doesn't change on every redraw.
    private function addSprayPoints(stroke as Array<Number>, x as Number, y as Number) as Void {
        var r = strokeWidth(TOOL_SPRAY);
        var span = 2 * r + 1;
        var n = 5;
        var i = 0;
        while (i < n) {
            var ox = (Math.rand() % span) - r;
            var oy = (Math.rand() % span) - r;
            stroke.add(x + ox);
            stroke.add(y + oy);
            i++;
        }
    }

    function startStroke(x as Number, y as Number) as Void {
        if (_tool == TOOL_BUCKET) {
            // Bucket is a tap action; handle it here too so a quick
            // tap-and-release (which still fires a drag start/stop) works.
            _backgroundColor = currentColor();
            WatchUi.requestUpdate();
            return;
        }
        _dragging = true;
        _dragStartX = x;
        _dragStartY = y;
        _dragCurX = x;
        _dragCurY = y;
        if (isDragBuilt(_tool)) {
            var stroke = [_tool, strokeColor(_tool), strokeWidth(_tool)] as Array<Number>;
            _currentBrushStroke = stroke;
            _shapes.add(stroke);
            if (_tool == TOOL_SPRAY) {
                addSprayPoints(stroke, x, y);
            } else {
                stroke.add(x);
                stroke.add(y);
            }
        }
        WatchUi.requestUpdate();
    }

    function extendStroke(x as Number, y as Number) as Void {
        if (_tool == TOOL_BUCKET) {
            return;
        }
        if (!_dragging) {
            startStroke(x, y);
            return;
        }
        if (isDragBuilt(_tool)) {
            var dx = x - _dragCurX;
            var dy = y - _dragCurY;
            // Skip points that barely moved to keep the point list small on long drags.
            if (dx * dx + dy * dy < 4) {
                return;
            }
            var stroke = _currentBrushStroke;
            if (stroke != null) {
                if (_tool == TOOL_SPRAY) {
                    addSprayPoints(stroke, x, y);
                } else {
                    stroke.add(x);
                    stroke.add(y);
                }
            }
        }
        _dragCurX = x;
        _dragCurY = y;
        WatchUi.requestUpdate();
    }

    function endStroke(x as Number, y as Number) as Void {
        if (!_dragging) {
            return;
        }
        if (!isDragBuilt(_tool)) {
            _shapes.add([_tool, currentColor(), PEN_WIDTHS[_sizeIndex], _dragStartX, _dragStartY, x, y] as Array<Number>);
        }
        _dragging = false;
        _currentBrushStroke = null;
        WatchUi.requestUpdate();
    }

    private function drawShape(dc as Dc, tool as Number, color as Number, width as Number, x1 as Number, y1 as Number, x2 as Number, y2 as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(width);
        if (tool == TOOL_LINE) {
            dc.drawLine(x1, y1, x2, y2);
        } else if (tool == TOOL_RECTANGLE || tool == TOOL_RECTANGLE_FILL) {
            var left = x1 < x2 ? x1 : x2;
            var top = y1 < y2 ? y1 : y2;
            var w = (x2 - x1).abs();
            var h = (y2 - y1).abs();
            if (tool == TOOL_RECTANGLE_FILL) {
                dc.fillRectangle(left, top, w, h);
            } else {
                dc.drawRectangle(left, top, w, h);
            }
        } else if (tool == TOOL_CIRCLE || tool == TOOL_CIRCLE_FILL) {
            var radius = Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)).toNumber();
            if (tool == TOOL_CIRCLE_FILL) {
                dc.fillCircle(x1, y1, radius);
            } else {
                dc.drawCircle(x1, y1, radius);
            }
        } else if (tool == TOOL_TRIANGLE || tool == TOOL_TRIANGLE_FILL) {
            var tLeft = x1 < x2 ? x1 : x2;
            var tRight = x1 < x2 ? x2 : x1;
            var tTop = y1 < y2 ? y1 : y2;
            var tBottom = y1 < y2 ? y2 : y1;
            var apexX = (tLeft + tRight) / 2;
            if (tool == TOOL_TRIANGLE_FILL) {
                dc.fillPolygon([
                    [apexX, tTop],
                    [tLeft, tBottom],
                    [tRight, tBottom]
                ]);
            } else {
                dc.drawLine(apexX, tTop, tLeft, tBottom);
                dc.drawLine(tLeft, tBottom, tRight, tBottom);
                dc.drawLine(tRight, tBottom, apexX, tTop);
            }
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(_backgroundColor, _backgroundColor);
        dc.clear();

        var s = 0;
        while (s < _shapes.size()) {
            var shape = _shapes[s];
            var tool = shape[0];
            var color = shape[1];
            var width = shape[2];
            if (isDragBuilt(tool)) {
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                if (tool == TOOL_SPRAY) {
                    var dotR = width / 4;
                    if (dotR < 1) {
                        dotR = 1;
                    }
                    var i = 3;
                    while (i + 1 < shape.size()) {
                        dc.fillCircle(shape[i], shape[i + 1], dotR);
                        i += 2;
                    }
                } else {
                    dc.setPenWidth(width);
                    if (shape.size() == 5) {
                        var r = width / 2;
                        dc.fillCircle(shape[3], shape[4], r > 1 ? r : 1);
                    }
                    var j = 3;
                    while (j + 3 < shape.size()) {
                        dc.drawLine(shape[j], shape[j + 1], shape[j + 2], shape[j + 3]);
                        j += 2;
                    }
                }
            } else {
                drawShape(dc, tool, color, width, shape[3], shape[4], shape[5], shape[6]);
            }
            s++;
        }

        if (_dragging && !isDragBuilt(_tool)) {
            drawShape(dc, _tool, currentColor(), PEN_WIDTHS[_sizeIndex], _dragStartX, _dragStartY, _dragCurX, _dragCurY);
        }
        dc.setPenWidth(1);

        dc.setColor(currentColor(), Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_width / 2, 14, 8);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(_width / 2, 14, 8);
    }

}
