import Toybox.Lang;
import Toybox.WatchUi;

// One shared settings menu for every game. It replaces a menu resource plus a
// delegate class per game and submenu, which cost ~25KB of app memory and kept
// the app from fitting on 128KB devices.
//
// A setting is [title, setter, labels, values] with an optional 5th element
// [min, max, default] that adds a "Custom..." number keypad option.
//   title  - Rez.Strings id shown in the main menu (and on the keypad)
//   setter - symbol of a one-argument method on the game view, called with values[i]
//   labels - Rez.Strings ids, one per value
module GameMenu {

    typedef Resettable as interface {
        function resetGame() as Void;
    };

    const IDS = [:i0, :i1, :i2, :i3, :i4, :i5, :i6, :i7];

    // Main menu: one entry per setting (each opens its options), then Reset.
    function open(view as Object, settings as Array<Array>) as Void {
        var menu = new WatchUi.Menu();
        var n = settings.size();
        for (var i = 0; i < n; i++) {
            menu.addItem(settings[i][0] as ResourceId, IDS[i]);
        }
        menu.addItem(Rez.Strings.menu_label_reset, IDS[n]);
        WatchUi.pushView(menu, new GameMenuDelegate(view, settings, null), WatchUi.SLIDE_UP);
    }

    // A single setting's options, followed by Reset when shown as the main menu.
    function openOptions(view as Object, setting as Array, withReset as Boolean) as Void {
        var menu = new WatchUi.Menu();
        var labels = setting[2] as Array;
        var n = labels.size();
        for (var i = 0; i < n; i++) {
            menu.addItem(labels[i] as ResourceId, IDS[i]);
        }
        if (setting.size() > 4) {
            menu.addItem(Rez.Strings.board_size_custom, IDS[n]);
            n++;
        }
        if (withReset) {
            menu.addItem(Rez.Strings.menu_label_reset, IDS[n]);
        }
        WatchUi.pushView(menu, new GameMenuDelegate(view, null, setting), WatchUi.SLIDE_UP);
    }

    function speed(values as Array) as Array {
        return [Rez.Strings.menu_label_speed, :setSpeedMultiplier, [
            Rez.Strings.menu_label_speed_very_slow, Rez.Strings.menu_label_speed_slow,
            Rez.Strings.menu_label_speed_normal, Rez.Strings.menu_label_speed_fast,
            Rez.Strings.menu_label_speed_very_fast], values];
    }

    const STANDARD_SPEEDS = [0.6, 0.8, 1.0, 1.3, 1.6];

    // Five options labelled Very Easy .. Very Hard.
    function level(title as ResourceId, setter as Symbol, values as Array) as Array {
        return [title, setter, [
            Rez.Strings.menu_label_very_easy, Rez.Strings.menu_label_easy,
            Rez.Strings.menu_label_normal, Rez.Strings.menu_label_hard,
            Rez.Strings.menu_label_very_hard], values];
    }
}

class GameMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _view as Object;
    private var _settings as Array<Array>?;
    private var _setting as Array?;

    function initialize(view as Object, settings as Array<Array>?, setting as Array?) {
        MenuInputDelegate.initialize();
        _view = view;
        _settings = settings;
        _setting = setting;
    }

    function onMenuItem(item as Symbol) as Void {
        var i = GameMenu.IDS.indexOf(item);
        var settings = _settings;
        if (settings != null) {
            if (i < settings.size()) {
                GameMenu.openOptions(_view, settings[i], false);
            } else {
                (_view as GameMenu.Resettable).resetGame();
            }
            return;
        }

        var s = _setting as Array;
        var values = s[3] as Array;
        var setter = _view.method(s[1] as Symbol);
        if (i < values.size()) {
            setter.invoke(values[i]);
        } else if (s.size() > 4 && i == values.size()) {
            var k = s[4] as Array<Number>;
            var keypad = new NumberKeypadView(WatchUi.loadResource(s[0] as ResourceId) as String, k[0], k[1], k[2]);
            WatchUi.pushView(keypad, new NumberKeypadDelegate(keypad, setter as Method(value as Number) as Void), WatchUi.SLIDE_UP);
        } else {
            (_view as GameMenu.Resettable).resetGame();
        }
    }

}
