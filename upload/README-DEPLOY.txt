WHAM BAM — SERVER UPLOAD PACKAGE
=================================

Upload ALL 6 files below into the SAME directory (the site root of
whambam.games). All asset paths in the HTML are relative, so they must
sit next to the HTML file — do not put them in subfolders.

FILES
-----
index.html                The game (all HTML/CSS/JS inline)
logo.png                  Favicon, apple-touch-icon, og:image, home logo, ad logo
splash.png                Splash / landing screen — PORTRAIT art (phones)
splash-desktop.png        Splash / landing screen — LANDSCAPE art (desktop)
mode-poster.svg           Select-Game screen — PORTRAIT art (stacked panels)
mode-poster-desktop.png   Select-Game screen — LANDSCAPE art (side-by-side)
legal-style.css           Shared stylesheet for privacy/terms pages
privacy.html              Privacy Policy page
terms.html                Terms of Service page

NOTE ON THE HTML FILENAME
-------------------------
The game file is index.html — synced from the root headband-game-web.html
(source of truth). Asset filenames must NOT be renamed — they are
referenced by name in the HTML.

IMPORTANT — logo.png is referenced by ABSOLUTE URL for social sharing:
  https://whambam.games/logo.png
So logo.png must be at the domain ROOT for og:image previews to work.

NOT NEEDED ON THE SERVER
------------------------
Word decks / taboo cards load at runtime from Supabase.
The Supabase JS SDK loads from CDN.
Source files (.xlsx, source .svg/.jpg artwork, mobile/, capacitor-app/,
db/, bluewall-option/) are build/source assets only — do not upload.

CACHING
-------
After replacing files, hard-refresh (Ctrl+Shift+R) or purge CDN cache —
the HTML/CSS and the PNGs cache aggressively.
