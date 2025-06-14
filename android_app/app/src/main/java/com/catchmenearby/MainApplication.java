package com.catchmenearby;

import android.app.Application;
import com.google.firebase.FirebaseApp;

public class MainApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        FirebaseApp.initializeApp(this);
        // You can add more general app initializations here
        System.out.println("MainApplication onCreate - Firebase Initialized");
    }
}
