import Toybox.Lang;
import Toybox.WatchUi;

class DinoDelegate extends WatchUi.BehaviorDelegate {

    private var _view as DinoView;

    function initialize(view as DinoView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        _view.jump();
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_ENTER) {
            _view.jump();
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        GameMenu.open(_view, [GameMenu.level(Rez.Strings.menu_label_cactus_height, :setCactusHeight, [0.6, 0.8, 1.0, 1.25, 1.5]), GameMenu.level(Rez.Strings.menu_label_cactus_frequency, :setSpawnFrequency, [1.6, 1.3, 1.0, 0.75, 0.55]), GameMenu.speed(GameMenu.STANDARD_SPEEDS)]);
        return true;
    }

}
