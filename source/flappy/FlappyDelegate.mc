import Toybox.Lang;
import Toybox.WatchUi;

class FlappyDelegate extends WatchUi.BehaviorDelegate {

    private var _view as FlappyView;

    function initialize(view as FlappyView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        _view.flap();
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_ENTER) {
            _view.flap();
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, [GameMenu.level(Rez.Strings.menu_label_gap_size, :setGapMultiplier, [1.0, 0.8, 0.65, 0.5, 0.38]), GameMenu.level(Rez.Strings.menu_label_pipe_spacing, :setSpacingMultiplier, [1.4, 1.15, 1.0, 0.8, 0.65]), GameMenu.speed([0.9, 1.15, 1.6, 2.2, 2.9])]);
        return true;
    }

}
