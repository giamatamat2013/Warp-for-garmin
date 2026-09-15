import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.System;
import Toybox.Math;
import Toybox.Lang;

(:heavyGames)
class BowlingView extends WatchUi.View {

    private const NUM_PINS = 10;
    private const BALL_RADIUS = 5;
    private const PIN_RADIUS = 4;
    private const FRICTION = 0.05;
    private const MIN_SPEED = 0.4;
    private const PULL_SCALE = 0.12;
    private const MAX_PULL = 90.0;
    private const MIN_PULL = 6.0;

    private const PIN_STANDING = 0;
    private const PIN_FALLING = 1;
    private const PIN_DOWN = 2;
    // Ticks for a falling pin to finish toppling (33ms/tick, so ~200ms).
    private const FALL_TICKS = 6.0;
    // Once a falling pin is half toppled, any still-standing pin within this
    // many pixels, roughly in the direction it's falling, gets knocked down
    // too - a domino cascade standing in for full pin-on-pin contact physics.
    private var _chainRadius as Float = 0.0;

    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _laneLeft as Number = 0;
    private var _laneRight as Number = 0;
    private var _pinAreaTop as Number = 0;

    private var _pinX as Array<Float>;
    private var _pinY as Array<Float>;
    private var _pinState as Array<Number>;
    private var _pinFallProgress as Array<Float>;
    private var _pinFallDirX as Array<Float>;
    private var _pinFallDirY as Array<Float>;
    private var _pinCascaded as Array<Boolean>;

    private var _ballStartX as Float = 0.0;
    private var _ballStartY as Float = 0.0;
    private var _ballX as Float = 0.0;
    private var _ballY as Float = 0.0;
    private var _ballVelX as Float = 0.0;
    private var _ballVelY as Float = 0.0;
    private var _ballMoving as Boolean = false;
    private var _gutter as Boolean = false;
    private var _standingAtRollStart as Number = NUM_PINS;

    private var _aiming as Boolean = false;
    private var _aimCurX as Number = 0;
    private var _aimCurY as Number = 0;
    private var _aimLastX as Number = 0;
    private var _aimLastY as Number = 0;
    // Total distance the finger has traveled since the drag started, not the
    // net start-to-current displacement - so pulling as far as the bezel
    // allows and then wiggling in place keeps adding power instead of
    // leaving the player stuck with no more screen to drag across.
    private var _aimPower as Float = 0.0;
    // The farthest point reached from the start, which locks in the throw
    // direction (see trackFarthest/releaseAim).
    private var _aimFarX as Number = 0;
    private var _aimFarY as Number = 0;
    private var _aimFarDistSq as Float = 0.0;

    // Flat list of every roll's pin count, in standard bowling scoring order
    // (this is what computeScore walks). _frameRolls holds just the current
    // frame's rolls, used to drive the frame-advance state machine below.
    private var _rolls as Array<Number>;
    private var _frameRolls as Array<Number>;
    private var _frame as Number = 1;
    private var _frameRollIndex as Number = 0;
    private var _gameOver as Boolean = false;
    private var _finalScore as Number = 0;

    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _pinX = [];
        _pinY = [];
        _pinState = [];
        _pinFallProgress = [];
        _pinFallDirX = [];
        _pinFallDirY = [];
        _pinCascaded = [];
        var p = 0;
        while (p < NUM_PINS) {
            _pinX.add(0.0);
            _pinY.add(0.0);
            _pinState.add(PIN_STANDING);
            _pinFallProgress.add(0.0);
            _pinFallDirX.add(0.0);
            _pinFallDirY.add(0.0);
            _pinCascaded.add(false);
            p++;
        }
        _rolls = [];
        _frameRolls = [];
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _laneLeft = _width / 2 - _width / 3;
        _laneRight = _width / 2 + _width / 3;
        _pinAreaTop = _height / 6;

        var pinSpacing = _width / 16;
        var rowSpacing = pinSpacing * 8 / 5;
        _chainRadius = (pinSpacing * 1.5).toFloat();

        var rowCounts = [4, 3, 2, 1] as Array<Number>;
        var centerX = _width / 2;
        var idx = 0;
        var row = 0;
        while (row < rowCounts.size()) {
            var count = rowCounts[row];
            var rowY = _pinAreaTop + row * rowSpacing;
            var offsetStart = -((count - 1) * pinSpacing) / 2;
            var i = 0;
            while (i < count) {
                _pinX[idx] = (centerX + offsetStart + i * pinSpacing).toFloat();
                _pinY[idx] = rowY.toFloat();
                idx++;
                i++;
            }
            row++;
        }

        _ballStartX = centerX.toFloat();
        _ballStartY = (_height - _height / 8).toFloat();
        resetGame();
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), 33, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTimerTick() as Void {
        if (_ballMoving) {
            updateBall();
        }
        updateFallingPins();
        WatchUi.requestUpdate();
    }

    function isGameOver() as Boolean {
        return _gameOver;
    }

    function isBallMoving() as Boolean {
        return _ballMoving;
    }

    function resetGame() as Void {
        _rolls = [];
        _frameRolls = [];
        _frame = 1;
        _frameRollIndex = 0;
        _gameOver = false;
        _finalScore = 0;
        resetPinsFullRack();
        resetBallToStart();
    }

    private function resetPinsFullRack() as Void {
        var i = 0;
        while (i < NUM_PINS) {
            _pinState[i] = PIN_STANDING;
            _pinFallProgress[i] = 0.0;
            _pinCascaded[i] = false;
            i++;
        }
    }

    private function resetBallToStart() as Void {
        _ballX = _ballStartX;
        _ballY = _ballStartY;
        _ballVelX = 0.0;
        _ballVelY = 0.0;
        _ballMoving = false;
        _gutter = false;
        _standingAtRollStart = countStanding();
    }

    private function countStanding() as Number {
        var n = 0;
        var i = 0;
        while (i < NUM_PINS) {
            if (_pinState[i] == PIN_STANDING) {
                n++;
            }
            i++;
        }
        return n;
    }

    function startAim(x as Number, y as Number) as Void {
        if (_gameOver || _ballMoving) {
            return;
        }
        _aiming = true;
        _aimCurX = x;
        _aimCurY = y;
        _aimLastX = x;
        _aimLastY = y;
        _aimPower = 0.0;
        _aimFarX = x;
        _aimFarY = y;
        _aimFarDistSq = 0.0;
    }

    // Power accumulates from every bit of finger travel, not the net
    // start-to-current distance - so once a pull reaches the bezel, small
    // back-and-forth movement keeps building power instead of stalling.
    // Direction is locked to whichever point ends up farthest from the
    // start, updated only when a new record is set - so wiggling in place
    // afterward to add power can't drag the aim off toward wherever that
    // wiggle happened to end.
    function updateAim(x as Number, y as Number) as Void {
        if (!_aiming) {
            return;
        }
        addAimTravel(x, y);
        trackFarthest(x, y);
        _aimCurX = x;
        _aimCurY = y;
    }

    private function addAimTravel(x as Number, y as Number) as Void {
        var dx = (x - _aimLastX).toFloat();
        var dy = (y - _aimLastY).toFloat();
        _aimPower += Math.sqrt(dx * dx + dy * dy).toFloat();
        _aimLastX = x;
        _aimLastY = y;
    }

    // Distance is measured from the ball's own position, not from wherever
    // the finger first touched down - that must match releaseAim's anchor
    // (and the on-screen aim line, which is drawn from the ball) or the
    // throw goes somewhere unrelated to what the player sees pointing at.
    private function trackFarthest(x as Number, y as Number) as Void {
        var dx = (x - _ballStartX).toFloat();
        var dy = (y - _ballStartY).toFloat();
        var distSq = dx * dx + dy * dy;
        if (distSq > _aimFarDistSq) {
            _aimFarDistSq = distSq;
            _aimFarX = x;
            _aimFarY = y;
        }
    }

    // Power (how hard) comes from the accumulated travel above. Direction
    // (which way) comes from the ball-to-farthest-point vector: drag toward
    // where you want the ball to go, like pointing an arrow, then release -
    // the ball travels that same way, it doesn't reverse like a slingshot.
    // The two are independent, so running out of screen to pull across
    // never caps how hard the throw can be.
    function releaseAim(x as Number, y as Number) as Void {
        if (!_aiming) {
            return;
        }
        _aiming = false;
        addAimTravel(x, y);
        trackFarthest(x, y);

        var pull = _aimPower;
        if (pull < MIN_PULL) {
            return;
        }
        if (pull > MAX_PULL) {
            pull = MAX_PULL;
        }
        var power = pull * PULL_SCALE;

        var dx = (_aimFarX - _ballStartX).toFloat();
        var dy = (_aimFarY - _ballStartY).toFloat();
        var dist = Math.sqrt(dx * dx + dy * dy).toFloat();
        if (dist < 2.0) {
            // No usable direction (the whole pull stayed near the start) -
            // default to a straight throw up the lane.
            _ballVelX = 0.0;
            _ballVelY = -power;
        } else {
            var scale = power / dist;
            _ballVelX = dx * scale;
            _ballVelY = dy * scale;
        }
        _ballMoving = true;
    }

    private function updateBall() as Void {
        _ballX += _ballVelX;
        _ballY += _ballVelY;

        if (_ballX < _laneLeft || _ballX > _laneRight) {
            _gutter = true;
            resolveRoll();
            return;
        }

        checkCollisions();

        var speed = Math.sqrt(_ballVelX * _ballVelX + _ballVelY * _ballVelY).toFloat();
        if (speed > 0) {
            var newSpeed = speed - FRICTION;
            if (newSpeed < 0) {
                newSpeed = 0.0;
            }
            _ballVelX = _ballVelX * newSpeed / speed;
            _ballVelY = _ballVelY * newSpeed / speed;
            speed = newSpeed;
        }

        if (speed < MIN_SPEED || _ballY < (_pinAreaTop - 20).toFloat()) {
            resolveRoll();
        }
    }

    private function checkCollisions() as Void {
        var speed = Math.sqrt(_ballVelX * _ballVelX + _ballVelY * _ballVelY).toFloat();
        var dirX = 0.0;
        var dirY = -1.0;
        if (speed > 0.01) {
            dirX = _ballVelX / speed;
            dirY = _ballVelY / speed;
        }
        var i = 0;
        while (i < NUM_PINS) {
            if (_pinState[i] == PIN_STANDING) {
                var dx = _ballX - _pinX[i];
                var dy = _ballY - _pinY[i];
                var limit = (BALL_RADIUS + PIN_RADIUS).toFloat();
                if (dx * dx + dy * dy <= limit * limit) {
                    knockDown(i, dirX, dirY);
                }
            }
            i++;
        }
    }

    // A little random spread on every fall direction (ball hit or cascaded)
    // means otherwise-identical hits don't always catch (or always miss) the
    // same neighbors - some rolls clip just enough pins to chain into a
    // strike, others narrowly miss, instead of the cascade cone being a
    // perfectly repeatable yes/no on distance and angle alone.
    private const FALL_JITTER_DEG = 22.0;

    private function knockDown(i as Number, dirX as Float, dirY as Float) as Void {
        if (_pinState[i] != PIN_STANDING) {
            return;
        }
        var jitterDeg = (((Math.rand() % 2000).abs() / 1000.0) - 1.0) * FALL_JITTER_DEG;
        var rad = jitterDeg * Math.PI / 180.0;
        var cosA = Math.cos(rad).toFloat();
        var sinA = Math.sin(rad).toFloat();
        var jx = dirX * cosA - dirY * sinA;
        var jy = dirX * sinA + dirY * cosA;

        _pinState[i] = PIN_FALLING;
        _pinFallProgress[i] = 0.0;
        _pinFallDirX[i] = jx;
        _pinFallDirY[i] = jy;
        _pinCascaded[i] = false;
    }

    // Advances every currently-falling pin's topple animation, and - once a
    // pin is half toppled - lets it knock over any still-standing pin close
    // by and roughly in its fall direction, so pins visibly domino into each
    // other over a couple of ticks instead of the whole cluster vanishing
    // on the same frame the ball arrives.
    private function updateFallingPins() as Void {
        var i = 0;
        while (i < NUM_PINS) {
            if (_pinState[i] == PIN_FALLING) {
                _pinFallProgress[i] += 1.0 / FALL_TICKS;
                if (!_pinCascaded[i] && _pinFallProgress[i] >= 0.5) {
                    _pinCascaded[i] = true;
                    cascadeFrom(i);
                }
                if (_pinFallProgress[i] >= 1.0) {
                    _pinFallProgress[i] = 1.0;
                    _pinState[i] = PIN_DOWN;
                }
            }
            i++;
        }
    }

    private function cascadeFrom(i as Number) as Void {
        var j = 0;
        while (j < NUM_PINS) {
            if (j != i && _pinState[j] == PIN_STANDING) {
                var ndx = _pinX[j] - _pinX[i];
                var ndy = _pinY[j] - _pinY[i];
                var dist = Math.sqrt(ndx * ndx + ndy * ndy).toFloat();
                if (dist > 0.0 && dist <= _chainRadius) {
                    var dot = (ndx * _pinFallDirX[i] + ndy * _pinFallDirY[i]) / dist;
                    if (dot > 0.3) {
                        knockDown(j, _pinFallDirX[i], _pinFallDirY[i]);
                    }
                }
            }
            j++;
        }
    }

    private function resolveRoll() as Void {
        var pins = _gutter ? 0 : (_standingAtRollStart - countStanding());
        _rolls.add(pins);
        _frameRolls.add(pins);
        advanceFrameState(pins);
        resetBallToStart();
    }

    // Standard ten-pin frame state machine. Frames 1-9: two rolls, unless
    // the first is a strike (frame ends immediately, pins stay knocked for
    // roll 2 otherwise - only a NEW frame gets a fresh rack). Frame 10 is
    // the special case: it always gets a bonus roll after a strike or
    // spare, and that bonus roll (and the one after a strike's second
    // ball) plays on a freshly re-racked lane, exactly like real bowling.
    private function advanceFrameState(pins as Number) as Void {
        if (_frame < 10) {
            if (_frameRollIndex == 0 && pins == 10) {
                finishFrame();
            } else if (_frameRollIndex == 0) {
                _frameRollIndex = 1;
            } else {
                finishFrame();
            }
            return;
        }

        // Frame 10.
        if (_frameRollIndex == 0) {
            if (pins == 10) {
                resetPinsFullRack();
            }
            _frameRollIndex = 1;
        } else if (_frameRollIndex == 1) {
            var first = _frameRolls[0];
            var second = _frameRolls[1];
            if (first == 10 || first + second == 10) {
                resetPinsFullRack();
                _frameRollIndex = 2;
            } else {
                finishGame();
            }
        } else {
            finishGame();
        }
    }

    private function finishFrame() as Void {
        _frame++;
        _frameRollIndex = 0;
        _frameRolls = [];
        resetPinsFullRack();
    }

    private function finishGame() as Void {
        _gameOver = true;
        _finalScore = computeScore(_rolls, false);
        HighScores.submit("bowling_best", _finalScore);
    }

    // Classic frame-by-frame lookahead scorer: walks the flat roll list one
    // frame at a time, folding in the next one or two rolls for a strike or
    // spare's bonus. Runs exactly ten iterations regardless of whether a
    // frame consumed one, two, or (frame 10 only) three rolls, so the
    // tenth-frame's extra roll needs no special handling here - it's just
    // more rolls in the same flat list.
    // partial: when true, stop (rather than crash) once a frame's bonus
    // rolls haven't happened yet, returning the score accumulated so far.
    private function computeScore(rolls as Array<Number>, partial as Boolean) as Number {
        var score = 0;
        var rollIdx = 0;
        var frame = 0;
        while (frame < 10) {
            if (rollIdx >= rolls.size()) {
                break;
            }
            if (rolls[rollIdx] == 10) {
                if (rollIdx + 2 >= rolls.size()) {
                    break;
                }
                score += 10 + rolls[rollIdx + 1] + rolls[rollIdx + 2];
                rollIdx += 1;
            } else if (rollIdx + 1 < rolls.size() && rolls[rollIdx] + rolls[rollIdx + 1] == 10) {
                if (rollIdx + 2 >= rolls.size()) {
                    break;
                }
                score += 10 + rolls[rollIdx + 2];
                rollIdx += 2;
            } else {
                if (rollIdx + 1 >= rolls.size()) {
                    break;
                }
                score += rolls[rollIdx] + rolls[rollIdx + 1];
                rollIdx += 2;
            }
            frame++;
        }
        return score;
    }

    // Standing pins are a plain circle; a falling pin's circle shrinks and
    // slides along its fall direction as it topples, and a downed pin is
    // left lying flat at the end of that slide - so a knocked pin visibly
    // falls (and can be seen falling into its neighbors) instead of just
    // vanishing.
    private function drawPin(dc as Dc, i as Number) as Void {
        var state = _pinState[i];
        if (state == PIN_STANDING) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_pinX[i].toNumber(), _pinY[i].toNumber(), PIN_RADIUS);
            return;
        }

        var slide = PIN_RADIUS * 1.8;
        if (state == PIN_FALLING) {
            var t = _pinFallProgress[i];
            var drawX = _pinX[i] + _pinFallDirX[i] * t * slide;
            var drawY = _pinY[i] + _pinFallDirY[i] * t * slide;
            var r = PIN_RADIUS * (1.0 - t * 0.5);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(drawX.toNumber(), drawY.toNumber(), r.toNumber());
        } else {
            var drawX = _pinX[i] + _pinFallDirX[i] * slide;
            var drawY = _pinY[i] + _pinFallDirY[i] * slide;
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(drawX.toNumber(), drawY.toNumber(), (PIN_RADIUS * 0.5).toNumber());
        }
    }

    // Lets the player see their pull building even after their finger hits
    // the bezel and stops moving net-outward, since power keeps accumulating
    // from wiggling in place (see _aimPower).
    private function drawPowerMeter(dc as Dc) as Void {
        var barW = _width - 20;
        var barX = 10;
        var barY = _height - 14;
        var frac = _aimPower / MAX_PULL;
        if (frac > 1.0) {
            frac = 1.0;
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(barX, barY, barW, 8);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_YELLOW);
        dc.fillRectangle(barX, barY, (barW * frac).toNumber(), 8);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
        dc.clear();

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(_laneLeft, 0, _laneLeft, _height);
        dc.drawLine(_laneRight, 0, _laneRight, _height);

        var i = 0;
        while (i < NUM_PINS) {
            drawPin(dc, i);
            i++;
        }

        if (_aiming) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(_ballStartX.toNumber(), _ballStartY.toNumber(), _aimCurX, _aimCurY);
            drawPowerMeter(dc);
        }

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_ballX.toNumber(), _ballY.toNumber(), BALL_RADIUS);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_gameOver) {
            dc.drawText(_width / 2, 2, Graphics.FONT_TINY, "Game Over! Score: " + _finalScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            var scoreSoFar = computeScore(_rolls, true);
            dc.drawText(_width / 2, 2, Graphics.FONT_TINY, "Frame " + _frame.toString() + "  Score: " + scoreSoFar.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
