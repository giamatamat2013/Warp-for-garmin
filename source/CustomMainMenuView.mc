import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

// Custom main menu: a scrollable two-column grid of game tiles.
//
// Add a game here: add {:id => :item_x, :label => "X"} to buildItems() below
// (it's filtered out automatically for non-touch devices if listed in
// TOUCH_ONLY_GAMES), then handle :item_x in CustomMainMenuDelegate.select().
class CustomMainMenuView extends WatchUi.View {

    private const COLUMNS = 2;
    private const TILE_HEIGHT = 78;
    private const ICON_BOX = 38;
    private const GRID_MARGIN = 4;
    private const GRID_GAP = 4;
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
            { :id => :item_draw, :key => "draw", :priority => 1, :label => WatchUi.loadResource(Rez.Strings.game_draw) as String },
            { :id => :item_breakout, :key => "breakout", :priority => 2, :label => WatchUi.loadResource(Rez.Strings.game_breakout) as String },
            { :id => :item_racing, :key => "racing", :priority => 3, :label => WatchUi.loadResource(Rez.Strings.game_racing) as String },
            { :id => :item_tetris, :key => "tetris", :priority => 4, :label => WatchUi.loadResource(Rez.Strings.game_tetris) as String },
            { :id => :item_2048, :key => "2048", :priority => 5, :label => WatchUi.loadResource(Rez.Strings.game_2048) as String },
            { :id => :item_flappy, :key => "flappy", :priority => 6, :label => WatchUi.loadResource(Rez.Strings.game_flappy) as String },
            { :id => :item_pong, :key => "pong", :priority => 7, :label => WatchUi.loadResource(Rez.Strings.game_pong) as String },
            { :id => :item_snake, :key => "snake", :priority => 8, :label => WatchUi.loadResource(Rez.Strings.game_snake) as String },
            { :id => :item_dino, :key => "dino", :priority => 9, :label => WatchUi.loadResource(Rez.Strings.game_dino) as String },
            { :id => :item_simon, :key => "simon", :priority => 10, :label => WatchUi.loadResource(Rez.Strings.game_simon) as String },
            { :id => :item_tictactoe, :key => "tictactoe", :priority => 11, :label => WatchUi.loadResource(Rez.Strings.game_tictactoe) as String },
            { :id => :item_balanceball, :key => "balanceball", :priority => 12, :label => WatchUi.loadResource(Rez.Strings.game_balanceball) as String },
            { :id => :item_maze, :key => "maze", :priority => 13, :label => WatchUi.loadResource(Rez.Strings.game_maze) as String }
        ];

        var filtered = [];
        if (System.getDeviceSettings().isTouchScreen) {
            filtered = all;
        } else {
        var i = 0;
            while (i < all.size()) {
                if (TOUCH_ONLY_GAMES.indexOf(all[i][:id]) < 0) {
                    filtered.add(all[i]);
                }
                i++;
            }
        }
        sortItems(filtered);
        return filtered;
    }

    private function sortItems(items as Array<Dictionary>) as Void {
        var i = 1;
        while (i < items.size()) {
            var current = items[i];
            var j = i - 1;
            while (j >= 0 && comesAfter(items[j], current)) {
                items[j + 1] = items[j];
                j--;
            }
            items[j + 1] = current;
            i++;
        }
    }

    private function comesAfter(left as Dictionary, right as Dictionary) as Boolean {
        var leftRecent = HighScores.getPlayedOrder(left[:key] as String);
        var rightRecent = HighScores.getPlayedOrder(right[:key] as String);
        if (leftRecent != rightRecent) {
            return leftRecent < rightRecent;
        }
        return (left[:priority] as Number) > (right[:priority] as Number);
    }

    function markPlayed(id as Symbol) as Void {
        var i = 0;
        while (i < _items.size()) {
            if (_items[i][:id] == id) {
                HighScores.markPlayed(_items[i][:key] as String);
                return;
            }
            i++;
        }
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

    // Moves the selection by tile index and keeps the selected tile visible.
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

    // Returns the tile index at screen coordinates, or -1 outside the grid.
    function rowAt(x as Number, y as Number) as Number {
        var tileWidth = (_width - GRID_MARGIN * 2 - GRID_GAP) / COLUMNS;
        var column = ((x - GRID_MARGIN) / (tileWidth + GRID_GAP)).toNumber();
        var row = ((y + _scrollY) / TILE_HEIGHT).toNumber();
        if (x < GRID_MARGIN || x >= _width - GRID_MARGIN || y < 0 || y > _height || column < 0 || column >= COLUMNS || row < 0) {
            return -1;
        }
        var index = row * COLUMNS + column;
        if (index >= _items.size()) {
            return -1;
        }
        return index;
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
        var top = (_selected / COLUMNS).toNumber() * TILE_HEIGHT;
        var bottom = top + TILE_HEIGHT;
        if (top < _scrollY) {
            _scrollY = top;
        } else if (bottom > _scrollY + _height) {
            _scrollY = bottom - _height;
        }
        clampScroll();
    }

    private function clampScroll() as Void {
        var totalRows = ((_items.size() + COLUMNS - 1) / COLUMNS).toNumber();
        var maxScroll = totalRows * TILE_HEIGHT - _height;
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
            var rowTop = (i / COLUMNS).toNumber() * TILE_HEIGHT - _scrollY;
            if (rowTop + TILE_HEIGHT >= 0 && rowTop <= _height) {
                drawTile(dc, i, rowTop);
            }
            i++;
        }

        drawScrollbar(dc);
    }

    private function drawTile(dc as Dc, index as Number, rowTop as Number) as Void {
        var item = _items[index];
        var isSelected = (index == _selected);
        var tileWidth = (_width - GRID_MARGIN * 2 - GRID_GAP) / COLUMNS;
        var column = index % COLUMNS;
        var tileX = GRID_MARGIN + column * (tileWidth + GRID_GAP);

        if (isSelected) {
            dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(tileX, rowTop + 2, tileWidth, TILE_HEIGHT - 4, 8);
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(tileX, rowTop + 2, tileWidth, TILE_HEIGHT - 4, 8);
        }

        var iconColor = isSelected ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY;
        var iconX = tileX + (tileWidth - ICON_BOX) / 2;
        var iconY = rowTop + 8;
        GameIcons.draw(dc, item[:id] as Symbol, iconX, iconY, ICON_BOX, iconColor);

        var textColor = isSelected ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY;
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(tileX + tileWidth / 2, rowTop + TILE_HEIGHT - 18, Graphics.FONT_XTINY, item[:label] as String, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawScrollbar(dc as Dc) as Void {
        var totalRows = ((_items.size() + COLUMNS - 1) / COLUMNS).toNumber();
        var totalHeight = totalRows * TILE_HEIGHT;
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
