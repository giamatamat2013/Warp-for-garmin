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
3. Space Invaders
4. Racing
5. Gravity Flip
6. Asteroid Dodge
7. Pinball
8. Tetris
9. 2048
10. Word Rush
11. Flappy Bird
12. Dino Runner
13. Tilt Maze
14. Pong
15. Snake
16. Simon
17. Balance Ball
18. Tic-Tac-Toe

If the new game is more appealing to a new user than an existing entry, adjust the priorities of the affected games so the order remains intentional.

