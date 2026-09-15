# Project Instructions

## Adding Games

When adding a new game to the main menu:

- Add it to `source/Games.mc` (`IDS`, `KEYS`, `labels()`) and its icon string to `GameIcons.ICONS`, all at the same index, with a stable `key`. The index is the priority.
- Handle its id in `CustomMainMenuDelegate.select()` (or `selectTouchGame()` for touch-only games, whose classes need the `(:touchGames)` annotation).
- Use `GameMenu.open()` for its settings menu instead of adding menu resources or menu delegate classes.
- Keep the default order based first on immediate fun and replay value for a new user. Lower indices appear earlier.
- The app must fit 96KB/128KB devices: avoid large inline data (dictionaries, word lists, per-item dictionaries); put data in `resources/jsondata` and load it on demand. Run a full export to check.
- Put polished, visually engaging games that are fun and easy to understand first. Prefer games that visibly demonstrate effort and replay value over bare-minimum arcade mechanics.
- Place the new game deliberately in the order. Do not append it automatically to the end.
- Previously played games are still promoted above unplayed games by the recent-play sorting logic.

Current default discovery order:

1. Draw
2. Breakout
3. Memory Match
4. Space Invaders
5. Whack-a-Mole
6. Racing
7. Gravity Flip
8. Asteroid Dodge
9. Bowling
10. Connect Four
11. Tetris
12. 2048
13. Minesweeper
14. Word Rush
15. Flappy Bird
16. Dino Runner
17. Tilt Maze
18. 15 Puzzle
19. Pong
20. Snake
21. Simon
22. Balance Ball
23. Reversi
24. Checkers
25. Chess
26. Tic-Tac-Toe

If the new game is more appealing to a new user than an existing entry, adjust the priorities of the affected games so the order remains intentional.

