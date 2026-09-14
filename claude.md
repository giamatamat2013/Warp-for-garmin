# Project Instructions

## Adding Games

When adding a new game to the main menu:

- Add its menu item and launch handling as usual.
- Add the game to `CustomMainMenuView.buildItems()` with a stable `key` and an integer `priority`.
- Keep the default order based first on immediate fun and replay value for a new user. Lower `priority` values appear earlier.
- Put polished, visually engaging games that are fun and easy to understand first. Prefer games that visibly demonstrate effort and replay value over bare-minimum arcade mechanics.
- Place the new game deliberately in the priority order. Do not append it automatically to the end.
- Previously played games are still promoted above unplayed games by the recent-play sorting logic.

Current default discovery order:

1. Draw
2. Breakout
3. Racing
4. Tetris
5. 2048
6. Flappy
7. Pong
8. Snake
9. Dino
10. Simon
11. Tic-Tac-Toe
12. Balance Ball
13. Maze

If the new game is more appealing to a new user than an existing entry, adjust the priorities of the affected games so the order remains intentional.
