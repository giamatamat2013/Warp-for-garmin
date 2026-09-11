import Toybox.Lang;

// Shared helper for turning a raw accelerometer reading (milli-g) into a
// calibrated, clamped tilt value in the range -1.0..1.0. A raw reading always
// includes gravity and the watch is rarely worn perfectly level, so both
// tilt-controlled games calibrate against the reading captured while the
// watch was held flat and treat that as "no tilt".
module TiltSensor {

    // A ~25 degree tilt away from the calibrated baseline reaches full
    // deflection.
    const SENSITIVITY_DIVISOR = 420.0;

    function normalize(raw as Number, baseline as Number) as Float {
        var v = (raw - baseline) / SENSITIVITY_DIVISOR;
        if (v > 1.0) {
            return 1.0;
        }
        if (v < -1.0) {
            return -1.0;
        }
        return v;
    }

}
