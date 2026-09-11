import Toybox.Lang;
import Toybox.Application.Storage;

// Persistent (survives app restarts and device reboots) high-score storage
// shared by every game. Each game uses its own storage key so scores don't
// collide.
module HighScores {

    function get(key as String) as Number {
        var v = Storage.getValue(key);
        if (v == null) {
            return 0;
        }
        return v as Number;
    }

    // Null when nothing has been recorded yet, distinct from a real 0 -
    // needed by games (like a timed maze) where 0 isn't a meaningful default.
    function getRaw(key as String) as Number? {
        return Storage.getValue(key) as Number?;
    }

    // Saves score as the new best under key if it beats the stored one.
    // Returns true if this was a new high score.
    function submit(key as String, score as Number) as Boolean {
        var best = get(key);
        if (score > best) {
            Storage.setValue(key, score);
            return true;
        }
        return false;
    }

    // Same as submit, but for timed challenges where finishing fast is the
    // goal, so a lower value is the better one.
    function submitFastest(key as String, timeMs as Number) as Boolean {
        var stored = getRaw(key);
        if (stored == null || timeMs < (stored as Number)) {
            Storage.setValue(key, timeMs);
            return true;
        }
        return false;
    }

}
