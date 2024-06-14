package com.example.wavify;

import android.content.Context;

public class SttEngine {
    private Context context;
    public SttEngine(Context context) {
        this.context = context;
    }

    private static native long createFfi(final String modelPath, final String apiKey);
    public long create(String modelPath, String apiKey) {
        return createFfi(modelPath, apiKey);
    }

    private static native long destroyFfi(final long model);
    public long destroy(long model) {
        return destroyFfi(model);
    }

    private static native String sttFfi(final float[] data, final long model);
    public String stt(float[] data, long model) {return sttFfi(data, model);};

}


