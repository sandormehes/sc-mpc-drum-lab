// Shared post-processing used by every drum engine.

(
~processDrumSignal = {
    |signal, foldAmount = 0, foldDrive = 10, drive = 1,
    bits = 16, sampleRateReduction = 44100, highPassFrequency = 20|

    var folded;
    var steps;
    var foldMix;

    foldMix = foldAmount.clip(0, 1);
    folded = (signal * (1 + (foldMix * foldDrive))).fold2;
    signal = XFade2.ar(signal, folded, foldMix.linlin(0, 1, -1, 1));

    signal = Latch.ar(
        signal,
        Impulse.ar(sampleRateReduction.clip(300, SampleRate.ir))
    );

    steps = 2 ** bits.clip(2, 16);
    signal = (signal * steps).round / steps;
    signal = (signal * drive).tanh;
    signal = HPF.ar(signal, highPassFrequency);
    signal = LeakDC.ar(signal);
    Limiter.ar(signal, 0.95, 0.005);
};
)
