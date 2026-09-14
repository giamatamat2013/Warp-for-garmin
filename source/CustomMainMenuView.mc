import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

// Custom main menu: a scrollable list of rows, each with a hand-drawn icon
// (see common/GameIcons.mc) next to the game name. Connect IQ's built-in
// Menu2 only shows plain text rows, so this view + CustomMainMenuDelegate
// replace it to give every game a distinct visual identity.
//
// Add a game here: add {:id => :item_x, :label => "X"} to buildItems() below
// (it's filtered out automatically for non-touch devices if listed in
// TOUCH_ONLY_GAMES), then handle :item_x in CustomMainMenuDelegate.onSelect().
class CustomMainMenuView extends WatchUi.View {

    private const ROW_HEIGHT = 60;
    private const ICON_BOX = 44;
    private const TOUCH_ONLY_GAMES = [:item_2048, :item_snake, :item_tictactoe, :item_simon, :item_tetris, :item_draw];

    private var _items as Array<Dictionary> = [];
    private var _selected as Number = 0;
    private var _scrollY as Number = 0;
    private var _width as Number = 0;
    private var _height as Number = 0;

    function initialize() {
        View.initialize();
        _items = buildItems();
    }

    private function buildItems() as Array<Dictionary> {
        var all = [
            { :id => :item_pong, :label => WatchUi.loadResource(Rez.Strings.game_pong) as String },
            { :id => :item_2048, :label => WatchUi.loadResource(Rez.Strings.game_2048) as String },
            { :id => :item_flappy, :label => WatchUi.loadResource(Rez.Strings.game_flappy) as String },
            { :id => :item_snake, :label => WatchUi.loadResource(Rez.Strings.game_snake) as String },
            { :id => :item_breakout, :label => WatchUi.loadResource(Rez.Strings.game_breakout) as String },
            { :id => :item_tictactoe, :label => WatchUi.loadResource(Rez.Strings.game_tictactoe) as String },
            { :id => :item_simon, :label => WatchUi.loadResource(Rez.Strings.game_simon) as String },
            { :id => :item_dino, :label => WatchUi.loadResource(Rez.Strings.game_dino) as String },
            { :id => :item_tetris, :label => WatchUi.loadResource(Rez.Strings.game_tetris) as String },
            { :id => :item_balanceball, :label => WatchUi.loadResource(Rez.Strings.game_balanceball) as String },
            { :id => :item_maze, :label => WatchUi.loadResource(Rez.Strings.game_maze) as String },
            { :id => :item_racing, :label => WatchUi.loadResource(Rez.Strings.game_racing) as String },
            { :id => :item_draw, :label => WatchUi.loadResource(Rez.Strings.game_draw) as String }
        ];

        if (System.getDeviceSettings().isTouchScreen) {
            return all;
        }

        var filtered = [];
        var i = 0;
        while (i < all.size()) {
            if (TOUCH_ONLY_GAMES.indexOf(all[i][:id]) < 0) {
                filtered.add(all[i]);
            }
            i++;
        }
        return filtered;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
    }

    function itemCount() as Number {
        return _items.size();
    }

    function selectedIndex() as Number {
        return _selected;
    }

    function idAt(index as Number) as Symbol {
        return _items[index][:id] as Symbol;
    }

    // Moves the selection by delta rows (negative = up), clamping at the
    // ends, and scrolls just enough to keep the new row fully on screen.
    function moveSelection(delta as Number) as Void {
        var next = _selected + delta;
        if (next < 0) {
            next = 0;
        } else if (next > _items.size() - 1) {
            next = _items.size() - 1;
        }
        _selected = next;
        ensureVisible();
        WatchUi.requestUpdate();
    }

    // Returns the row index at the given screen coordinates, or -1 if the
    // tap landed outside the list (used for touch selection).
    function rowAt(x as Number, y as Number) as Number {
        if (x < 0 || x > _width) {
            return -1;
        }
        var row = ((y + _scrollY) / ROW_HEIGHT).toNumber();
        if (row < 0 || row >= _items.size()) {
            return -1;
        }
        return row;
    }

    function setSelected(index as Number) as Void {
        if (index >= 0 && index < _items.size()) {
            _selected = index;
            ensureVisible();
            WatchUi.requestUpdate();
        }
    }

    function scroll(deltaPixels as Number) as Void {
        _scrollY += deltaPixels;
        clampScroll();
        WatchUi.requestUpdate();
    }

    private function ensureVisible() as Void {
        var top = _selected * ROW_HEIGHT;
        var bottom = top + ROW_HEIGHT;
        if (top < _scrollY) {
            _scrollY = top;
        } else if (bottom > _scrollY + _height) {
            _scrollY = bottom - _height;
        }
        clampScroll();
    }

    private function clampScroll() as Void {
        var maxScroll = _items.size() * ROW_HEIGHT - _height;
        if (maxScroll < 0) {
            maxScroll = 0;
        }
        if (_scrollY < 0) {
            _scrollY = 0;
        } else if (_scrollY > maxScroll) {
            _scrollY = maxScroll;
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var i = 0;
        while (i < _items.size()) {
            var rowTop = i * ROW_HEIGHT - _scrollY;
            if (rowTop + ROW_HEIGHT >= 0 && rowTop <= _height) {
                drawRow(dc, i, rowTop);
            }
            i++;
        }

        drawScrollbar(dc);
    }

    private function drawRow(dc as Dc, index as Number, rowTop as Number) as Void {
        var item = _items[index];
        var isSelected = (index == _selected);

        if (isSelected) {
            dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(4, rowTop + 2, _width - 8, ROW_HEIGHT - 4, 10);
        }

        var iconColor = isSelected ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY;
        var iconX = 14;
        var iconY = rowTop + (ROW_HEIGHT - ICON_BOX) / 2;
        GameIcons.draw(dc, item[:id] as Symbol, iconX, iconY, ICON_BOX, iconColor);

        var textColor = isSelected ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY;
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(iconX + ICON_BOX + 14, rowTop + ROW_HEIGHT / 2, Graphics.FONT_MEDIUM, item[:label] as String, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawScrollbar(dc as Dc) as Void {
        var totalHeight = _items.size() * ROW_HEIGHT;
        if (totalHeight <= _height) {
            return;
        }
        var trackH = _height - 8;
        var barH = trackH * _height / totalHeight;
        if (barH < 16) {
            barH = 16;
        }
        var maxScroll = totalHeight - _height;
        var barY = 4 + (trackH - barH) * _scrollY / maxScroll;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(_width - 6, barY, 3, barH, 2);
    }

}
