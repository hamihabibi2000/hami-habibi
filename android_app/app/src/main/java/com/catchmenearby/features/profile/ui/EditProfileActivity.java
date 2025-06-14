package com.catchmenearby.features.profile.ui;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.lifecycle.ViewModelProvider;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import com.catchmenearby.R;
import com.catchmenearby.features.profile.viewmodel.ProfileViewModel;
import com.google.android.material.switchmaterial.SwitchMaterial;
import com.google.android.material.textfield.TextInputEditText;
import java.util.List;

public class EditProfileActivity extends AppCompatActivity {

    private ProfileViewModel viewModel;
    private TextInputEditText editTextUsername, editTextBio;
    private SwitchMaterial switchLocationSharing;
    private LinearLayout linearLayoutPhotos;
    private Button buttonAddPhoto, buttonSaveProfile;
    private ProgressBar progressBarLoading, progressBarSaving;
    private Toolbar toolbar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_edit_profile);

        toolbar = findViewById(R.id.toolbar_edit_profile);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setDisplayShowHomeEnabled(true);
        }
        // The title is set in XML: app:title="Edit Profile"

        viewModel = new ViewModelProvider(this).get(ProfileViewModel.class);

        editTextUsername = findViewById(R.id.editTextUsername_edit);
        editTextBio = findViewById(R.id.editTextBio_edit);
        switchLocationSharing = findViewById(R.id.switchLocationSharing_edit);
        linearLayoutPhotos = findViewById(R.id.linearLayoutPhotos_edit);
        buttonAddPhoto = findViewById(R.id.buttonAddPhoto_edit);
        buttonSaveProfile = findViewById(R.id.buttonSaveProfile_edit);
        progressBarLoading = findViewById(R.id.progressBar_editProfile_loading);
        progressBarSaving = findViewById(R.id.progressBar_editProfile_saving);

        setupObservers();
        setupListeners();

        // ViewModel's init calls fetchUserProfile()
    }

    private void setupObservers() {
        viewModel.getIsLoading().observe(this, isLoading -> {
            // Differentiate between initial load and saving progress
            if (isLoading && viewModel.getUserProfileLiveData().getValue() == null) { // Initial load
                progressBarLoading.setVisibility(View.VISIBLE);
            } else {
                progressBarLoading.setVisibility(View.GONE);
            }
            if (isLoading && viewModel.getUserProfileLiveData().getValue() != null) { // Saving
                 progressBarSaving.setVisibility(View.VISIBLE);
                 buttonSaveProfile.setEnabled(false);
            } else {
                progressBarSaving.setVisibility(View.GONE);
                buttonSaveProfile.setEnabled(true);
            }
        });

        viewModel.getErrorMessage().observe(this, error -> {
            if (error != null && !error.isEmpty()) {
                Toast.makeText(this, error, Toast.LENGTH_LONG).show();
            }
        });

        viewModel.getUserProfileLiveData().observe(this, userProfile -> {
            // This observer is mainly for initial population or if profile is re-fetched.
            // Individual LiveData for fields will handle UI updates during editing.
            // This one is handled by getUsernameState etc.
        });

        viewModel.getUsernameState().observe(this, username -> {
            if (editTextUsername.getText() == null || !editTextUsername.getText().toString().equals(username)) {
                editTextUsername.setText(username);
            }
        });
        viewModel.getBioState().observe(this, bio -> {
             if (editTextBio.getText() == null || !editTextBio.getText().toString().equals(bio)) {
                editTextBio.setText(bio);
            }
        });
        viewModel.getLocationSharingEnabledState().observe(this, enabled -> {
            if (switchLocationSharing.isChecked() != enabled) {
                 switchLocationSharing.setChecked(enabled);
            }
        });
        viewModel.getPhotoItemsState().observe(this, photos -> updatePhotoListView(photos));


        viewModel.getSaveSuccess().observe(this, success -> {
            if (success) {
                Toast.makeText(this, "Profile saved successfully!", Toast.LENGTH_SHORT).show();
                finish(); // Close activity on successful save
            }
        });
    }

    private void setupListeners() {
        editTextUsername.addTextChangedListener(new TextWatcherAdapter() {
            @Override public void afterTextChanged(Editable s) { viewModel.updateUsername(s.toString()); }
        });
        editTextBio.addTextChangedListener(new TextWatcherAdapter() {
            @Override public void afterTextChanged(Editable s) { viewModel.updateBio(s.toString()); }
        });
        switchLocationSharing.setOnCheckedChangeListener((buttonView, isChecked) -> viewModel.updateLocationSharingEnabled(isChecked));

        buttonSaveProfile.setOnClickListener(v -> viewModel.saveProfile());
        buttonAddPhoto.setOnClickListener(v -> {
            // Placeholder: adds a dummy URL. Real implementation would use ImagePicker.
            viewModel.addPhotoPlaceholder("user_photos/new_placeholder_" + System.currentTimeMillis() + ".jpg");
        });
    }

    private void updatePhotoListView(List<String> photoURLs) {
        linearLayoutPhotos.removeAllViews();
        if (photoURLs == null) return;

        for (int i = 0; i < photoURLs.size(); i++) {
            final int index = i;
            String url = photoURLs.get(i);

            View photoView = LayoutInflater.from(this).inflate(R.layout.item_photo_edit, linearLayoutPhotos, false);
            TextView textViewPhotoUrl = photoView.findViewById(R.id.textViewPhotoUrl_item); // Assume this ID exists in item_photo_edit.xml
            Button buttonRemovePhoto = photoView.findViewById(R.id.buttonRemovePhoto_item); // Assume this ID exists

            textViewPhotoUrl.setText(url.substring(url.lastIndexOf('/') + 1)); // Show file name or part of URL
            buttonRemovePhoto.setOnClickListener(v -> viewModel.removePhotoAtIndex(index));

            linearLayoutPhotos.addView(photoView);
        }
         buttonAddPhoto.setVisibility(photoURLs.size() < 7 ? View.VISIBLE : View.GONE);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            finish(); // Handles Up arrow
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    // Simplified TextWatcher
    abstract class TextWatcherAdapter implements TextWatcher {
        @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
        @Override public void onTextChanged(CharSequence s, int start, int before, int count) {}
    }
}
