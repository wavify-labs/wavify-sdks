package com.example.wavify;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class RustGreetings {
    private Context context;
    public RustGreetings(Context context) {
        this.context = context;
    }

    private static native String greeting(final String pattern);
    public String sayHello(String to) {
        return greeting(to);
    }

    private static native String createModelFfi(final String model);
    public String createModel(String dirPath) {
        return createModelFfi(dirPath);
    }
}


