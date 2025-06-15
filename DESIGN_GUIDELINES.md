# Design Guidelines - Iran Israel App

## 1. Navigation Flow

The application will feature a simple and intuitive navigation structure:

*   **Main Tab Bar Navigation (Bottom of screen):**
    *   **Feed:** (Default screen) Displays the main visual news feed.
    *   **Upload:** Takes the user to the content upload screen.
    *   **Profile:** Takes the user to their own profile screen.
*   **Screen Transitions:**
    *   **Feed -> Post Details (Tap on a post):** View comments, like.
    *   **Feed -> User Profile (Tap on username/photo):** View another user's profile.
    *   **Upload -> Gallery Picker:** Select photos/videos.
    *   **Profile -> Edit Profile:** Modify username/profile photo.

## 2. Color Palette

The design will use a neutral and modern color palette to keep the focus on the visual content.

*   **Primary Background:** White (`#FFFFFF`) or a very light grey (`#F8F9FA`).
*   **Secondary Background (e.g., cards, modal headers):** Slightly off-white/grey (`#E9ECEF`).
*   **Primary Text:** Dark Grey / Near Black (`#212529`).
*   **Secondary Text (e.g., captions, timestamps):** Medium Grey (`#6C757D`).
*   **Accent Color:** A subtle, modern blue (e.g., `#007BFF` or a slightly desaturated version). This will be used for:
    *   Buttons (Upload, Follow, etc.)
    *   Selected tab icons
    *   Links
    *   Loading indicators
*   **Destructive Action Color (e.g., Report):** A muted red (e.g., `#DC3545`).
*   **NO "Sexy Purple":** As per project brief, this theme is to be avoided.

## 3. Iconography

Use standard, clear, and universally understood icons. Material Design Icons or Font Awesome are good sources.

*   **Feed Tab:** `home` or `list`
*   **Upload Tab:** `add_circle_outline` or `camera_alt`
*   **Profile Tab:** `person` or `account_circle`
*   **Like (Not Liked):** `favorite_border` (heart outline)
*   **Like (Liked):** `favorite` (solid heart)
*   **Comment:** `chat_bubble_outline`
*   **Follow:** `person_add`
*   **Unfollow:** `person_remove` or `check_circle` (indicating already following)
*   **Send/Post:** `send`
*   **Back Arrow:** `arrow_back`
*   **Settings/Edit:** `settings` or `edit`
*   **More Options (for reporting):** `more_vert`

## 4. Typography

*   **Primary Font:** A clean, sans-serif font (e.g., Roboto for Android, San Francisco for iOS - system defaults are good).
*   **Font Sizes:**
    *   **Post Captions:** 14-16pt
    *   **Usernames:** 16-18pt (bold)
    *   **Button Text:** 14-16pt
    *   **Timestamps/Meta Info:** 12-14pt

## 5. Content Display

*   **Full-Width Visuals:** Photos and videos in the feed should occupy the maximum possible screen width, with minimal padding.
*   **Aspect Ratio Handling:** Maintain original aspect ratios for media. Letterboxing/Pillarboxing is acceptable if necessary to fit the screen.
*   **Video Playback:** Autoplay videos in the feed (muted by default, user taps to unmute). Show clear play/pause controls.

## 6. Overall Feel

*   **Clean & Modern:** Avoid clutter. Ample white space.
*   **Content-First:** The UI should elevate the photos and videos.
*   **Intuitive:** Interactions should be predictable.
