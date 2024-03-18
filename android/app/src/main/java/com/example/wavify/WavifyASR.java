package com.example.wavify;

import android.content.Context;

public class WavifyASR {

    private Context context;
    public WavifyASR(Context context) {
        this.context = context;
    }

    private static native long createModelFfi(final String modelPath);
    public long createModel(String modelPath) {
        return createModelFfi(modelPath);
    }

    // TODO: implement destoryModel

    private static native String processFfi(final float[] data, final long model);
    public String process(float[] data, long model) {return processFfi(data, model);};

}


