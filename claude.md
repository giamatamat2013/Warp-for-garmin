# Project Instructions

## Adding Games

When adding a new game to the main menu:

- Add it to `source/Games.mc` (`IDS`, `KEYS`, `labels()`) and its icon string to `GameIcons.ICONS`, all at the same index, with a stable `key`. The index is the priority.
- Handle its id in `CustomMainMenuDelegate.select()` (or `selectTouchGame()` for touch-only games, whose classes need the `(:touchGames)` annotation).
- Annotate every class of the game with `:extendedCode` (merged into any existing annotation, e.g. `(:touchGames :extendedCode)`) so its code is paged in on demand instead of sitting in the heap on API 5.1+ devices.
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
11. DVD Bounce
12. Tetris
13. 2048
14. Minesweeper
15. Word Rush
16. Flappy Bird
17. Dino Runner
18. Tilt Maze
19. 15 Puzzle
20. Pong
21. Snake
22. Simon
23. Balance Ball
24. Reversi
25. Checkers
26. Chess
27. Tic-Tac-Toe

If the new game is more appealing to a new user than an existing entry, adjust the priorities of the affected games so the order remains intentional.

