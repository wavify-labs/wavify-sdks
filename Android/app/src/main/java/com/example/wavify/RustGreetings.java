package com.example.wavify;

import android.content.Context;

public class RustGreetings {

    private Context context;
    public RustGreetings(Context context) {
        this.context = context;
    }

    private static native String greeting(final String pattern);
    public String sayHello(String to) {
        return greeting(to);
    }

    private static native long createModelFfi(final String modelPath, final String tokenizerPath);
    public long createModel(String modelPath, String tokenizerPath) {
        return createModelFfi(modelPath, tokenizerPath);
    }

    private static native String processFfi(final float[] data, final long model);
    public String process(float[] data, long model) {return processFfi(data, model);};

}


