package com.catchmenearby.features.profile.ui;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.catchmenearby.R; // Assuming R is available
// import com.bumptech.glide.Glide; // Example for image loading
import java.util.List;
import java.util.ArrayList;

public class PhotoViewAdapter extends RecyclerView.Adapter<PhotoViewAdapter.PhotoViewHolder> {
    private List<String> photoUrls;
    private Context context;

    public PhotoViewAdapter(Context context, List<String> photoUrls) {
        this.context = context;
        this.photoUrls = photoUrls != null ? photoUrls : new ArrayList<>();
    }

    @NonNull
    @Override
    public PhotoViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_photo_view, parent, false);
        return new PhotoViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull PhotoViewHolder holder, int position) {
        String url = photoUrls.get(position);
        if (url != null && !url.isEmpty()) {
            String filename = url.substring(url.lastIndexOf('/') + 1);
            if (filename.contains("?")) { // Clean up query parameters for display
                filename = filename.substring(0, filename.indexOf('?'));
            }
            holder.photoUrlTextView.setText(filename);

            // Placeholder for actual image loading. In a real app, use Glide or Picasso:
            // Glide.with(holder.itemView.getContext())
            //      .load(url)
            //      .placeholder(R.drawable.ic_placeholder_photo_24dp) // Optional placeholder
            //      .error(R.drawable.ic_placeholder_photo_24dp) // Optional error image
            //      .into(holder.photoImageView);
            holder.photoImageView.setImageResource(R.drawable.ic_placeholder_photo_24dp); // Set placeholder
            holder.photoImageView.setColorFilter(null); // Clear tint if set on placeholder
        } else {
            holder.photoUrlTextView.setText("Invalid URL");
            holder.photoImageView.setImageResource(R.drawable.ic_placeholder_photo_24dp); // Error/placeholder
        }
    }

    @Override
    public int getItemCount() {
        return photoUrls.size();
    }

    static class PhotoViewHolder extends RecyclerView.ViewHolder {
        ImageView photoImageView;
        TextView photoUrlTextView;
        PhotoViewHolder(View itemView) {
            super(itemView);
            photoImageView = itemView.findViewById(R.id.imageViewPhoto_item_view);
            photoUrlTextView = itemView.findViewById(R.id.textViewPhotoUrl_item_view);
        }
    }

    public void updateData(List<String> newPhotoUrls) {
        this.photoUrls.clear();
        if (newPhotoUrls != null) {
            this.photoUrls.addAll(newPhotoUrls);
        }
        notifyDataSetChanged(); // Consider DiffUtil for more complex lists
    }
}
