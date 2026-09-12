import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Categorized picker for shapes, tools, and colors.
class DrawToolbarView extends WatchUi.View {

    public const KIND_CATEGORY = 0;
    public const KIND_TOOL = 1;
    public const KIND_SIZE = 2;
    public const KIND_UNDO = 3;
    public const KIND_CLEAR = 4;
    public const KIND_COLOR = 5;
    public const KIND_BACK = 6;

    public const CATEGORY_ROOT = 0;
    public const CATEGORY_SHAPES = 1;
    public const CATEGORY_TOOLS = 2;
    public const CATEGORY_COLORS = 3;

    private var _view as DrawView;
    private var _buttons as Array<Dictionary> = [] as Array<Dictionary>;
    private var _cols as Number = 5;
    private var _cellSize as Number = 0;
    private var _originX as Number = 0;
    private var _originY as Number = 0;
    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _category as Number = CATEGORY_ROOT;

    function initialize(view as DrawView) {
        View.initialize();
        _view = view;
        rebuildButtons();
    }

    private function rebuildButtons() as Void {
        if (_category == CATEGORY_ROOT) {
            _buttons = [
                { :kind => KIND_CATEGORY, :value => CATEGORY_SHAPES },
                { :kind => KIND_CATEGORY, :value => CATEGORY_TOOLS },
                { :kind => KIND_CATEGORY, :value => CATEGORY_COLORS },
                { :kind => KIND_BACK, :value => 0 }
            ] as Array<Dictionary>;
        } else if (_category == CATEGORY_SHAPES) {
            _buttons = [
                { :kind => KIND_TOOL, :value => _view.TOOL_LINE },
                { :kind => KIND_TOOL, :value => _view.TOOL_RECTANGLE },
                { :kind => KIND_TOOL, :value => _view.TOOL_RECTANGLE_FILL },
                { :kind => KIND_TOOL, :value => _view.TOOL_CIRCLE },
                { :kind => KIND_TOOL, :value => _view.TOOL_CIRCLE_FILL },
                { :kind => KIND_TOOL, :value => _view.TOOL_TRIANGLE },
                { :kind => KIND_TOOL, :value => _view.TOOL_TRIANGLE_FILL },
                { :kind => KIND_BACK, :value => 0 }
            ] as Array<Dictionary>;
        } else if (_category == CATEGORY_TOOLS) {
            _buttons = [
                { :kind => KIND_TOOL, :value => _view.TOOL_BUCKET },
                { :kind => KIND_TOOL, :value => _view.TOOL_SPRAY },
                { :kind => KIND_SIZE, :value => 0 },
                { :kind => KIND_SIZE, :value => 1 },
                { :kind => KIND_SIZE, :value => 2 },
                { :kind => KIND_SIZE, :value => 3 },
                { :kind => KIND_SIZE, :value => 4 },
                { :kind => KIND_SIZE, :value => 5 },
                { :kind => KIND_SIZE, :value => 6 },
                { :kind => KIND_SIZE, :value => 7 },
                { :kind => KIND_BACK, :value => 0 }
            ] as Array<Dictionary>;
        } else {
            _buttons = [] as Array<Dictionary>;
            var n = _view.colorCount();
            var i = 0;
            while (i < n) {
                _buttons.add({ :kind => KIND_COLOR, :value => i });
                i++;
            }
            _buttons.add({ :kind => KIND_BACK, :value => 0 });
        }
        _cols = _category == CATEGORY_ROOT ? 2 : 4;
    }

    function selectCategory(category as Number) as Void {
        _category = category;
        rebuildButtons();
        layoutGrid();
        WatchUi.requestUpdate();
    }

    function goBack() as Void {
        if (_category != CATEGORY_ROOT) {
            _category = CATEGORY_ROOT;
            rebuildButtons();
            layoutGrid();
            WatchUi.requestUpdate();
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        layoutGrid();
    }

    private function layoutGrid() as Void {
        var w = _width;
        var h = _height;
        var count = _buttons.size();
        var rows = (count + _cols - 1) / _cols;

        // Inset the whole grid a bit so corner buttons never land under a
        // round bezel, then size cells to whichever dimension is tighter.
        var minSide = w < h ? w : h;
        var inset = minSide * 0.09;
        var gridW = w - inset * 2;
        var gridH = h - inset * 2;
        var cell = gridW / _cols;
        var cellByRow = gridH / rows;
        if (cellByRow < cell) {
            cell = cellByRow;
        }
        _cellSize = cell.toNumber();
        _originX = ((w - _cellSize * _cols) / 2).toNumber();
        _originY = ((h - _cellSize * rows) / 2).toNumber();
    }

    private function cellCenter(index as Number) as Array<Number> {
        var row = index / _cols;
        var col = index % _cols;
        var cx = _originX + col * _cellSize + (_cellSize / 2);
        var cy = _originY + row * _cellSize + (_cellSize / 2);
        return [cx, cy] as Array<Number>;
    }

    // Hit-tests a tap against the grid; used by DrawToolbarDelegate.
    function buttonAt(x as Number, y as Number) as Dictionary? {
        var i = 0;
        while (i < _buttons.size()) {
            var c = cellCenter(i);
            var half = _cellSize / 2;
            if (x >= c[0] - half && x < c[0] + half && y >= c[1] - half && y < c[1] + half) {
                return _buttons[i];
            }
            i++;
        }
        return null;
    }

    private function isActive(btn as Dictionary) as Boolean {
        if (btn[:kind] == KIND_TOOL) {
            return (btn[:value] as Number) == _view.getTool();
        } else if (btn[:kind] == KIND_SIZE) {
            return (btn[:value] as Number) == _view.getSizeIndex();
        } else if (btn[:kind] == KIND_COLOR) {
            return (btn[:value] as Number) == _view.getColorIndex();
        }
        return false;
    }

    private function drawToolIcon(dc as Dc, tool as Number, cx as Number, cy as Number, r as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        if (tool == _view.TOOL_BRUSH) {
            dc.drawLine(cx - r, cy + r, cx, cy - r / 2);
            dc.drawLine(cx, cy - r / 2, cx + r, cy + r);
            dc.fillCircle(cx - r, cy + r, 2);
        } else if (tool == _view.TOOL_LINE) {
            dc.drawLine(cx - r, cy + r, cx + r, cy - r);
        } else if (tool == _view.TOOL_RECTANGLE) {
            dc.drawRectangle(cx - r, cy - (r / 2), r * 2, r);
        } else if (tool == _view.TOOL_RECTANGLE_FILL) {
            dc.fillRectangle(cx - r, cy - (r / 2), r * 2, r);
        } else if (tool == _view.TOOL_CIRCLE) {
            dc.drawCircle(cx, cy, r);
        } else if (tool == _view.TOOL_CIRCLE_FILL) {
            dc.fillCircle(cx, cy, r);
        } else if (tool == _view.TOOL_ERASER) {
            dc.drawRectangle(cx - r, cy - (r / 2), r * 2, r);
            dc.drawLine(cx - r, cy - (r / 2), cx + r, cy + (r / 2));
        } else if (tool == _view.TOOL_TRIANGLE) {
            dc.drawLine(cx, cy - r, cx - r, cy + r);
            dc.drawLine(cx - r, cy + r, cx + r, cy + r);
            dc.drawLine(cx + r, cy + r, cx, cy - r);
        } else if (tool == _view.TOOL_TRIANGLE_FILL) {
            dc.fillPolygon([
                [cx, cy - r],
                [cx - r, cy + r],
                [cx + r, cy + r]
            ]);
        } else if (tool == _view.TOOL_BUCKET) {
            dc.drawLine(cx - r, cy - (r / 2), cx + r, cy - (r / 2));
            dc.drawLine(cx - r, cy - (r / 2), cx - (r / 2), cy + r);
            dc.drawLine(cx + r, cy - (r / 2), cx + (r / 2), cy + r);
            dc.drawLine(cx - (r / 2), cy + r, cx + (r / 2), cy + r);
            dc.fillCircle(cx, cy + r - 2, 2);
        } else if (tool == _view.TOOL_SPRAY) {
            dc.fillCircle(cx, cy, 2);
            dc.fillCircle(cx - (r / 2), cy - (r / 2), 1);
            dc.fillCircle(cx + (r / 2), cy - (r / 3), 1);
            dc.fillCircle(cx - (r / 3), cy + (r / 2), 1);
            dc.fillCircle(cx + (r / 2), cy + (r / 2), 1);
        }
    }

    private function drawUndoIcon(dc as Dc, cx as Number, cy as Number, r as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 200, 60);
        dc.fillPolygon([
            [cx - r + 2, cy - 4],
            [cx - r - 4, cy],
            [cx - r + 2, cy + 4]
        ]);
    }

    private function drawClearIcon(dc as Dc, cx as Number, cy as Number, r as Number) as Void {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(cx - r, cy - r, cx + r, cy + r);
        dc.drawLine(cx - r, cy + r, cx + r, cy - r);
    }

    private function drawSizeIcon(dc as Dc, sizeIndex as Number, cx as Number, cy as Number, r as Number) as Void {
        var w = _view.penWidthAt(sizeIndex);
        var dotR = w / 2;
        if (dotR < 2) {
            dotR = 2;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, dotR);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, r);
    }

    private function drawBackIcon(dc as Dc, cx as Number, cy as Number, r as Number) as Void {
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(cx - (r / 2), cy, cx - (r / 6), cy + (r / 2));
        dc.drawLine(cx - (r / 6), cy + (r / 2), cx + (r / 2), cy - (r / 3));
    }

    private function drawCategoryIcon(dc as Dc, category as Number, cx as Number, cy as Number, r as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        if (category == CATEGORY_SHAPES) {
            dc.drawRectangle(cx - r, cy - r, r, r);
            dc.drawCircle(cx + r / 2, cy + r / 2, r / 2);
        } else if (category == CATEGORY_TOOLS) {
            dc.drawLine(cx - r, cy + r, cx + r, cy - r);
            dc.drawCircle(cx - r, cy + r, 3);
            dc.drawCircle(cx + r, cy - r, 3);
        } else {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx - r / 2, cy, r / 2);
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx + r / 2, cy, r / 2);
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy + r / 2, r / 2);
        }
    }

    private function drawCategoryLabel(dc as Dc, category as Number, cx as Number, cy as Number) as Void {
        var label = category == CATEGORY_SHAPES ? "Shapes" : category == CATEGORY_TOOLS ? "Tools" : "Colors";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 20, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var i = 0;
        while (i < _buttons.size()) {
            var btn = _buttons[i];
            var c = cellCenter(i);
            var cx = c[0];
            var cy = c[1];
            var r = (_cellSize / 2) - 4;
            if (r < 4) {
                r = 4;
            }

            if (isActive(btn)) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(cx, cy, r + 3);
            }

            var kind = btn[:kind];
            if (kind == KIND_CATEGORY) {
                drawCategoryIcon(dc, btn[:value] as Number, cx, cy - 8, r - 3);
                drawCategoryLabel(dc, btn[:value] as Number, cx, cy);
            } else if (kind == KIND_TOOL) {
                drawToolIcon(dc, btn[:value] as Number, cx, cy, r - 2);
            } else if (kind == KIND_SIZE) {
                drawSizeIcon(dc, btn[:value] as Number, cx, cy, r);
            } else if (kind == KIND_UNDO) {
                drawUndoIcon(dc, cx, cy, r - 2);
            } else if (kind == KIND_CLEAR) {
                drawClearIcon(dc, cx, cy, r - 3);
            } else if (kind == KIND_COLOR) {
                var col = _view.colorAt(btn[:value] as Number);
                dc.setColor(col, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(cx, cy, r - 2);
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                dc.drawCircle(cx, cy, r - 2);
            } else if (kind == KIND_BACK) {
                drawBackIcon(dc, cx, cy, r);
            }
            i++;
        }
    }

}
