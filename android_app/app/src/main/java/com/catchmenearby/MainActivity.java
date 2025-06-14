package com.catchmenearby;

import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
// import androidx.navigation.NavController;
// import androidx.navigation.fragment.NavHostFragment;
// import androidx.navigation.ui.NavigationUI;
// import com.google.android.material.bottomnavigation.BottomNavigationView; // Already imported if needed
import com.google.firebase.FirebaseApp; // Keep this if direct FirebaseApp access is still needed elsewhere, otherwise AuthViewModel handles it.
import androidx.lifecycle.ViewModelProvider;
import android.content.Intent;
import androidx.navigation.NavController;
import androidx.navigation.fragment.NavHostFragment;
import androidx.navigation.ui.NavigationUI;
import com.catchmenearby.R;
import com.catchmenearby.features.auth.ui.LoginActivity;
import com.catchmenearby.features.auth.viewmodel.AuthViewModel;
import com.catchmenearby.core.services.LocationService; // Import LocationService
import com.catchmenearby.features.profile.model.UserProfile; // Import UserProfile
import com.catchmenearby.features.profile.viewmodel.ProfileViewModel; // To observe profile changes for location service
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.firebase.auth.FirebaseUser;

import android.widget.Toast; // For displaying messages
import androidx.annotation.NonNull; // For onRequestPermissionsResult


public class MainActivity extends AppCompatActivity {

    private AuthViewModel authViewModel;
    private ProfileViewModel profileViewModel; // Added to get profile for LocationService
    private LocationService locationService; // Location service instance
    private NavController navController;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        locationService = new LocationService(this); // Initialize LocationService
        authViewModel = new ViewModelProvider(this).get(AuthViewModel.class);
        // Initialize ProfileViewModel to observe the current user's profile
        profileViewModel = new ViewModelProvider(this).get(ProfileViewModel.class);

        // Observe user LiveData
        authViewModel.getUserLiveData().observe(this, firebaseUser -> {
            if (firebaseUser == null) {
                // No user signed in, redirect to LoginActivity
                Intent intent = new Intent(MainActivity.this, LoginActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK); // Clear back stack
                startActivity(intent);
                finish(); // Finish MainActivity so user can't navigate back to it
            } else {
                // User is signed in.
                // Ensure content view is set and proceed with app setup if not already done.
                // This check prevents re-setting content view if already set.
                if (findViewById(android.R.id.content) == null ||
                    findViewById(android.R.id.content).getTag() == null ||
                    !findViewById(android.R.id.content).getTag().equals("main_activity_content_set")) {

                    setContentView(R.layout.activity_main);
                    findViewById(android.R.id.content).setTag("main_activity_content_set"); // Mark content as set

                    System.out.println("MainActivity: User " + firebaseUser.getUid() + " is signed in. Setting up NavController.");

                    BottomNavigationView bottomNav = findViewById(R.id.bottom_navigation_view);
                    NavHostFragment navHostFragment = (NavHostFragment) getSupportFragmentManager()
                            .findFragmentById(R.id.nav_host_fragment);

                    if (navHostFragment != null) {
                        navController = navHostFragment.getNavController();
                        NavigationUI.setupWithNavController(bottomNav, navController);

                        // Temp button for EditProfile - conceptually this would be in a Profile Fragment
                        Button tempEditProfileButton = findViewById(R.id.buttonGoToEditProfile_main);
                        if (tempEditProfileButton != null) { // Renaming this button's purpose for clarity
                           tempEditProfileButton.setText("View My Profile (Temp)"); // Change button text
                            navController.addOnDestinationChangedListener((controller, destination, arguments) -> {
                                // Show button only on profile tab for this demo
                                if (destination.getId() == R.id.profileFragment) {
                                    tempEditProfileButton.setVisibility(android.view.View.VISIBLE);
                                } else {
                                    tempEditProfileButton.setVisibility(android.view.View.GONE);
                                }
                            });
                            tempEditProfileButton.setOnClickListener(v -> {
                                FirebaseUser currentUser = authViewModel.getUserLiveData().getValue();
                                if (currentUser != null) {
                                    Intent intent = new Intent(MainActivity.this, com.catchmenearby.features.profile.ui.ViewProfileActivity.class);
                                    intent.putExtra(com.catchmenearby.features.profile.ui.ViewProfileActivity.EXTRA_USER_ID, currentUser.getUid());
                                    startActivity(intent);
                                } else {
                                    // Should not happen if user is in MainActivity, but good practice
                                    Toast.makeText(MainActivity.this, "Please login again.", Toast.LENGTH_SHORT).show();
                                    Intent loginIntent = new Intent(MainActivity.this, LoginActivity.class);
                                    loginIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                                    startActivity(loginIntent);
                                    finish();
                                }
                            });
                        }

                    } else {
                        System.err.println("Error: NavHostFragment not found in MainActivity!");
                        // Handle this error appropriately, maybe show an error message or fallback UI
                    }
                }
            }
        });

        // Initial check: if there's no user right away (before observer fires for the first time),
        // and we don't want a flicker of MainActivity layout, we can choose not to call setContentView yet.
        // The observer will handle setting the content view once auth state is confirmed.
        // However, for simplicity, some prefer to set a loading screen or the main layout initially.
        // If getUserLiveData().getValue() is null initially, the observer will immediately redirect.
        // If it's not null, the observer will immediately try to set content.
        // The check `findViewById(android.R.id.content).getTag()` handles re-entry.

        // If starting without a user, the observer will redirect.
        // If starting with a user, the observer will set the content view.
        // This structure avoids setting content view if user is immediately found to be null.
    }
}
