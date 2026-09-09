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

}
