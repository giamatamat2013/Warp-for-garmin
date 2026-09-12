import Toybox.Lang;
import Toybox.WatchUi;

// Pairs with NumberKeypadView. `onConfirm` is invoked with the entered
// Number when OK is tapped on a valid value; the keypad pops itself either
// way (OK or the back gesture), so the caller never has to.
class NumberKeypadDelegate extends WatchUi.BehaviorDelegate {

    private var _view as NumberKeypadView;
    private var _onConfirm as Method(value as Number) as Void;

    function initialize(view as NumberKeypadView, onConfirm as Method(value as Number) as Void) {
        BehaviorDelegate.initialize();
        _view = view;
        _onConfirm = onConfirm;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var idx = _view.keyAt(coords[0], coords[1]);
        if (idx == null) {
            return true;
        }
        var confirmed = _view.pressKey(idx as Number);
        if (confirmed != null) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            _onConfirm.invoke(confirmed as Number);
        }
        return true;
    }

}
