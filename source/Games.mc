import Toybox.Lang;

// The game list shared by the main menu and its icons, as parallel arrays
// (cheaper in app memory than one dictionary per game).
//
// Order is the default discovery order for a new user: a game's index is its
// priority, lower appears earlier. Previously played games are still promoted
// above unplayed ones by CustomMainMenuView's recent-play sorting.
//
// Add a game: insert it at a deliberate position in IDS, KEYS, labels() and
// GameIcons.ICONS (same index in each), then handle its id in
// CustomMainMenuDelegate.select().
module Games {

    // Whether this build includes the :heavyGames-annotated games (Pinball,
    // Invaders - the largest always-on games). False on the lowest-memory
    // devices, where monkey.jungle excludes that code entirely to fit the
    // 96KB/128KB limit; see CustomMainMenuView and MainMenuDelegate.
    (:heavyGames)
    const HAS_HEAVY_GAMES = true;
    (:noHeavyGames)
    const HAS_HEAVY_GAMES = false;

    const IDS = [:item_draw, :item_breakout, :item_invaders, :item_racing, :item_gravityflip,
        :item_asteroid, :item_pinball, :item_tetris, :item_2048, :item_wordrush, :item_flappy,
        :item_dino, :item_tiltmaze, :item_pong, :item_snake, :item_simon, :item_balanceball,
        :item_tictactoe];

    // Stable storage keys for recent-play tracking; never rename.
    const KEYS = ["draw", "breakout", "invaders", "racing", "gravityflip",
        "asteroid", "pinball", "tetris", "2048", "wordrush", "flappy",
        "dino", "tiltmaze", "pong", "snake", "simon", "balanceball",
        "tictactoe"];

    function labels() as Array<ResourceId> {
        return [Rez.Strings.game_draw, Rez.Strings.game_breakout, Rez.Strings.game_invaders,
            Rez.Strings.game_racing, Rez.Strings.game_gravityflip, Rez.Strings.game_asteroid,
            Rez.Strings.game_pinball, Rez.Strings.game_tetris, Rez.Strings.game_2048,
            Rez.Strings.game_wordrush, Rez.Strings.game_flappy, Rez.Strings.game_dino,
            Rez.Strings.game_tiltmaze, Rez.Strings.game_pong, Rez.Strings.game_snake,
            Rez.Strings.game_simon, Rez.Strings.game_balanceball, Rez.Strings.game_tictactoe];
    }
}
