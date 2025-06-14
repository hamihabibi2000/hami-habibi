package com.catchmenearby.features.profile.ui;

import android.content.Intent;
import android.os.Bundle;
import android.view.MenuItem;
import android.view.View;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.catchmenearby.R;
import com.catchmenearby.features.profile.model.UserProfile;
import com.catchmenearby.features.profile.viewmodel.ProfileViewModel; // Re-using for now
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Locale;

public class ViewProfileActivity extends AppCompatActivity {
    public static final String EXTRA_USER_ID = "extra_user_id"; // To pass the UserID to this activity

    private TextView usernameTextView, bioTextView, noBioTextView, photosLabelTextView, noPhotosTextView;
    private TextView locationStatusTextView, accountTypeTextView; // Added for details
    private ImageView locationStatusImageView, accountTypeImageView; // Added for icons
    private RecyclerView photosRecyclerView;
    private PhotoViewAdapter photoAdapter;
    private ProfileViewModel profileViewModel;
    private ProgressBar progressBar;
    private View contentScrollView; // The NestedScrollView or main content area

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_view_profile);

        Toolbar toolbar = findViewById(R.id.toolbar_view_profile);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setDisplayShowHomeEnabled(true); // Show back arrow
        }

        usernameTextView = findViewById(R.id.textViewUsername_view);
        bioTextView = findViewById(R.id.textViewBio_view);
        noBioTextView = findViewById(R.id.textViewNoBio_view);
        photosLabelTextView = findViewById(R.id.textViewPhotosLabel_view);
        noPhotosTextView = findViewById(R.id.textViewNoPhotos_view);
        photosRecyclerView = findViewById(R.id.recyclerViewPhotos_view);
        progressBar = findViewById(R.id.progressBar_view_profile);
        contentScrollView = findViewById(R.id.nestedScrollView_view_profile);

        locationStatusTextView = findViewById(R.id.textViewLocationStatus_view);
        locationStatusImageView = findViewById(R.id.imageViewLocationStatus);
        accountTypeTextView = findViewById(R.id.textViewAccountType_view);
        accountTypeImageView = findViewById(R.id.imageViewAccountType);

        photosRecyclerView.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        photoAdapter = new PhotoViewAdapter(this, new ArrayList<>());
        photosRecyclerView.setAdapter(photoAdapter);

        String userId = getIntent().getStringExtra(EXTRA_USER_ID);
        profileViewModel = new ViewModelProvider(this).get(ProfileViewModel.class);

        observeViewModel();

        if (userId != null && !userId.isEmpty()) {
            profileViewModel.fetchSpecificUserProfile(userId);
        } else {
            // Fallback or error: No user ID provided
            Toast.makeText(this, "No User ID provided.", Toast.LENGTH_LONG).show();
            usernameTextView.setText("Error: User ID missing");
            progressBar.setVisibility(View.GONE);
            contentScrollView.setVisibility(View.VISIBLE); // Show to display error message
        }
    }

    private void observeViewModel() {
        profileViewModel.getUserProfileLiveData().observe(this, userProfile -> {
            if (userProfile != null) {
                updateUI(userProfile);
                contentScrollView.setVisibility(View.VISIBLE);
            } else {
                // Can be null if error or during initial load before fetch completes for a specific user
                // Error messages are handled by observing errorMessage LiveData
                 contentScrollView.setVisibility(View.GONE); // Hide content if profile is null after an attempt
            }
        });

        profileViewModel.getIsLoading().observe(this, isLoading -> {
            if (isLoading != null && isLoading) {
                progressBar.setVisibility(View.VISIBLE);
                contentScrollView.setVisibility(View.GONE);
            } else {
                progressBar.setVisibility(View.GONE);
                // Content visibility is handled by userProfileLiveData observer
            }
        });

        profileViewModel.getErrorMessage().observe(this, error -> {
            if (error != null && !error.isEmpty()) {
                Toast.makeText(this, "Error: " + error, Toast.LENGTH_LONG).show();
                // If profile is already loaded, don't hide it for a non-critical error
                // If profile is null and error occurs, then it's a critical load failure.
                if (profileViewModel.getUserProfileLiveData().getValue() == null) {
                    usernameTextView.setText("Failed to load profile"); // Show error in main view
                    contentScrollView.setVisibility(View.VISIBLE); // Ensure some part of UI is visible for error
                }
            }
        });
    }

    private void updateUI(UserProfile profile) {
        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle(profile.getUsername() + "'s Profile");
        }
        usernameTextView.setText(profile.getUsername());

        if (profile.getBio() != null && !profile.getBio().isEmpty()) {
            bioTextView.setText(profile.getBio());
            bioTextView.setVisibility(View.VISIBLE);
            noBioTextView.setVisibility(View.GONE);
        } else {
            bioTextView.setVisibility(View.GONE);
            noBioTextView.setVisibility(View.VISIBLE);
        }

        if (profile.getPhotoURLs() != null && !profile.getPhotoURLs().isEmpty()) {
            photoAdapter.updateData(profile.getPhotoURLs());
            photosRecyclerView.setVisibility(View.VISIBLE);
            photosLabelTextView.setVisibility(View.VISIBLE);
            noPhotosTextView.setVisibility(View.GONE);
        } else {
            photosRecyclerView.setVisibility(View.GONE);
            photosLabelTextView.setVisibility(View.GONE);
            noPhotosTextView.setVisibility(View.VISIBLE);
        }

        // Update details section
        if(profile.isLocationSharingEnabled()){
            locationStatusTextView.setText("Location Sharing: Enabled");
            locationStatusImageView.setImageResource(R.drawable.ic_location_on_24dp);
            locationStatusImageView.setColorFilter(ContextCompat.getColor(this, R.color.secondaryTextCyan)); // Example color
        } else {
            locationStatusTextView.setText("Location Sharing: Disabled");
            locationStatusImageView.setImageResource(R.drawable.ic_location_off_24dp); // You'd need this icon
            locationStatusImageView.setColorFilter(ContextCompat.getColor(this, R.color.material_grey_600)); // Example color
        }

        if(profile.isPremiumUser()){
            accountTypeTextView.setText("Account: Premium User");
            accountTypeImageView.setImageResource(R.drawable.ic_star_filled_24dp); // You'd need this icon
            accountTypeImageView.setColorFilter(ContextCompat.getColor(this, R.color.highlightPurple)); // Example color
        } else {
            accountTypeTextView.setText("Account: Standard User");
            accountTypeImageView.setImageResource(R.drawable.ic_star_border_24dp);
            accountTypeImageView.setColorFilter(ContextCompat.getColor(this, R.color.secondaryTextCyan));
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            finish(); // Go back to the previous activity
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
}
