// Shared post-processing used by every drum engine.

(
// Quantize a bipolar signal to the number of signed levels implied by bits.
// The previous implementation used 2 ** bits steps across each half of the
// waveform, which behaved approximately one bit higher than advertised.
~quantizeDrumSignal = {
    |signal, bits = 16|
    var maximumInteger;
    maximumInteger = (2 ** (bits.clip(2, 16) - 1)) - 1;
    (signal * maximumInteger).round / maximumInteger;
};

// Impulse at exactly SampleRate.ir can fail to trigger Latch and produce a
// silent file. Treat a full-rate request as a clean bypass.
~reduceDrumSampleRate = {
    |signal, sampleRateReduction = 44100, minimumRate = 300|
    var reduced, useOriginal;
    reduced = Latch.ar(
        signal,
        Impulse.ar(sampleRateReduction.clip(minimumRate, SampleRate.ir - 1))
    );
    useOriginal = sampleRateReduction >= (SampleRate.ir - 1);
    Select.ar(useOriginal, [reduced, signal]);
};

~processDrumSignal = {
    |signal, foldAmount = 0, foldDrive = 10, drive = 1,
    bits = 16, sampleRateReduction = 44100, highPassFrequency = 20|

    var folded;
    var foldMix;

    foldMix = foldAmount.clip(0, 1);
    folded = (signal * (1 + (foldMix * foldDrive))).fold2;
    signal = XFade2.ar(signal, folded, foldMix.linlin(0, 1, -1, 1));

    signal = ~reduceDrumSampleRate.(signal, sampleRateReduction, 300);

    signal = ~quantizeDrumSignal.(signal, bits);
    signal = (signal * drive).tanh;
    signal = HPF.ar(signal, highPassFrequency);
    signal = LeakDC.ar(signal);
    Limiter.ar(signal, 0.95, 0.005);
};
)
