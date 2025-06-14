package com.catchmenearby.core.services;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.os.Looper;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.Priority;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.GeoPoint;
import com.catchmenearby.features.profile.model.UserProfile;
// import java.util.Date; // Not needed if using FieldValue.serverTimestamp()
import java.util.HashMap;
import java.util.Map;

public class LocationService {
    private static final String TAG = "LocationService";
    public static final int LOCATION_PERMISSION_REQUEST_CODE = 1001;

    private FusedLocationProviderClient fusedLocationClient;
    private LocationCallback locationCallback;
    private Context applicationContext; // Use application context to avoid activity leaks
    private FirebaseFirestore db = FirebaseFirestore.getInstance();
    private FirebaseAuth auth = FirebaseAuth.getInstance();

    private MutableLiveData<Location> lastKnownLocationLiveData = new MutableLiveData<>();
    private MutableLiveData<String> locationErrorLiveData = new MutableLiveData<>();

    private UserProfile currentUserProfileSettings; // Cache for user's location sharing preference

    public LocationService(Context context) {
        this.applicationContext = context.getApplicationContext();
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this.applicationContext);
        createLocationCallback();
        Log.d(TAG, "LocationService initialized.");
    }

    public LiveData<Location> getLastKnownLocationLiveData() { return lastKnownLocationLiveData; }
    public LiveData<String> getLocationErrorLiveData() { return locationErrorLiveData; }

    private void createLocationCallback() {
        locationCallback = new LocationCallback() {
            @Override
            public void onLocationResult(@NonNull LocationResult locationResult) {
                // No need to iterate, getLastLocation() from result is fine for most cases
                Location lastLocation = locationResult.getLastLocation();
                if (lastLocation != null) {
                    lastKnownLocationLiveData.setValue(lastLocation);
                    Log.d(TAG, "Location updated via callback: " + lastLocation.getLatitude() + ", " + lastLocation.getLongitude());
                    if (currentUserProfileSettings != null && currentUserProfileSettings.isLocationSharingEnabled()) {
                        updateLocationInFirestore(lastLocation);
                    } else {
                        Log.d(TAG, "Location sharing disabled by settings, not updating Firestore.");
                    }
                }
            }
        };
    }

    // Call this when user profile data (especially locationSharingEnabled) is available or changes.
    public void updateProfileSettings(UserProfile userProfile) {
        this.currentUserProfileSettings = userProfile;
        Log.d(TAG, "Profile settings updated. Location sharing enabled: " + (userProfile != null && userProfile.isLocationSharingEnabled()));
        evaluateLocationNeeds(); // Re-evaluate based on new settings
    }

    private void evaluateLocationNeeds() {
        if (currentUserProfileSettings == null || !currentUserProfileSettings.isLocationSharingEnabled()) {
            Log.d(TAG, "Location sharing disabled or profile not set. Stopping updates.");
            stopLocationUpdatesInternal();
            return;
        }
        // If sharing is enabled, check permissions and start if granted.
        // The actual start request will be done by Activity via requestLocationUpdates or similar.
        // This method just logs the state. The Activity should handle permission checks.
        if (hasLocationPermission()) {
            Log.d(TAG, "Location sharing enabled and permission granted. Ready to start updates if requested by Activity.");
            // An Activity would call a method like requestLocationUpdatesFromActivity() here.
        } else {
            Log.d(TAG, "Location sharing enabled but permission NOT granted. Activity needs to request permission.");
        }
    }

    // To be called from an Activity context (e.g. MainActivity onResume or after permission grant)
    public void startLocationUpdatesFromActivity(Activity activity) {
        if (currentUserProfileSettings == null || !currentUserProfileSettings.isLocationSharingEnabled()) {
            Log.d(TAG, "Attempted to start updates, but sharing is disabled in settings.");
            stopLocationUpdatesInternal(); // Ensure stopped
            return;
        }

        if (!hasLocationPermission()) {
            Log.d(TAG, "Attempted to start updates, but permission not granted. Requesting...");
            requestLocationPermission(activity); // Request permission if not already granted
            return;
        }

        Log.d(TAG, "Starting location updates (requested by Activity).");
        LocationRequest locationRequest = new LocationRequest.Builder(Priority.PRIORITY_BALANCED_POWER_ACCURACY, 600000) // e.g., every 10 mins
                                           .setMinUpdateIntervalMillis(300000) // e.g., fastest 5 mins
                                           .setMinUpdateDistanceMeters(500) // 500 meters
                                           .build();
        try {
            fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper());
        } catch (SecurityException e) {
            Log.e(TAG, "SecurityException while requesting location updates: " + e.getMessage());
            locationErrorLiveData.setValue("Location permission error: " + e.getMessage());
        }
    }

    // Internal method to stop updates
    private void stopLocationUpdatesInternal() {
        Log.d(TAG, "Stopping location updates (internal call).");
        fusedLocationClient.removeLocationUpdates(locationCallback);
    }

    // Public method to be called from Activity onPause or when sharing is disabled
    public void stopLocationUpdatesFromActivity() {
        stopLocationUpdatesInternal();
    }

    public boolean hasLocationPermission() {
        return ActivityCompat.checkSelfPermission(applicationContext, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
               ActivityCompat.checkSelfPermission(applicationContext, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    public void requestLocationPermission(Activity activity) {
        Log.d(TAG, "Requesting location permissions from activity.");
        ActivityCompat.requestPermissions(activity,
            new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION},
            LOCATION_PERMISSION_REQUEST_CODE);
    }

    private void updateLocationInFirestore(Location location) {
        FirebaseUser firebaseUser = auth.getCurrentUser();
        if (firebaseUser == null) {
            Log.e(TAG, "User not logged in, cannot update location in Firestore.");
            return;
        }

        GeoPoint geoPoint = new GeoPoint(location.getLatitude(), location.getLongitude());
        Map<String, Object> data = new HashMap<>();
        data.put("lastKnownLocation", geoPoint);
        data.put("updatedAt", FieldValue.serverTimestamp()); // Use server timestamp

        db.collection("users").document(firebaseUser.getUid()).update(data)
            .addOnSuccessListener(aVoid -> Log.d(TAG, "User location updated in Firestore."))
            .addOnFailureListener(e -> Log.e(TAG, "Error updating location in Firestore: " + e.getMessage()));
    }

    // Call this from Activity's onRequestPermissionsResult
    public void handlePermissionsResult(Activity activity, int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Log.d(TAG, "Location permission granted by user via dialog.");
                // Try starting updates again if profile settings allow
                if (this.currentUserProfileSettings != null && this.currentUserProfileSettings.isLocationSharingEnabled()) {
                     startLocationUpdatesFromActivity(activity); // Pass activity context
                }
            } else {
                Log.d(TAG, "Location permission denied by user via dialog.");
                locationErrorLiveData.setValue("Location permission denied. Some features may not work.");
            }
        }
    }
}
