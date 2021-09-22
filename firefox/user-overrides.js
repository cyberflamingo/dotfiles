/******************************************************************************
 * user-overrides.js                                                          *
 * Inspired by ghacks and pyllyukko's user.js with some tweaking              *
 * https://github.com/ghacksuserjs/ghacks-user.js/                            *
 * https://github.com/pyllyukko/user.js/                                      *
 ******************************************************************************/

user_pref("_user.js.parrot", "overrides section syntax error");

/* 0000: disable about:config warning
 * FF73-86: chrome://global/content/config.xhtml ***/
user_pref("general.warnOnAboutConfig", true); // XHTML version
user_pref("browser.aboutConfig.showWarning", true); // HTML version [FF71+]

/*** [SECTION 0100]: STARTUP ***/
/* 0101: disable default browser check
 * [SETTING] General>Startup>Always check if Firefox is your default browser ***/
user_pref("browser.shell.checkDefaultBrowser", true);
/* 0102: set startup page [SETUP-CHROME]
 * 0=blank, 1=home, 2=last visited page, 3=resume previous session
 * [NOTE] Session Restore is not used in PB mode (0110) and is cleared with history (2803, 2804)
 * [SETTING] General>Startup>Restore previous session ***/
user_pref("browser.startup.page", 3);
/* 0103: set HOME+NEWWINDOW page
 * about:home=Activity Stream (default, see 0105), custom URL, about:blank
 * [SETTING] Home>New Windows and Tabs>Homepage and new windows ***/
user_pref("browser.startup.homepage", "about:home");
/* 0104: set NEWTAB page
 * true=Activity Stream (default, see 0105), false=blank page
 * [SETTING] Home>New Windows and Tabs>New tabs ***/
user_pref("browser.newtabpage.enabled", true);
user_pref("browser.newtab.preload", true);

/** LANGUAGE / LOCALE ***/
/* 0211: enforce US English locale regardless of the system locale
 * [SETUP-WEB] May break some input methods e.g xim/ibus for CJK languages [1]
 * [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=867501,1629630 ***/
user_pref("javascript.use_us_english_locale", false); // [HIDDEN PREF]

/* 0302a: disable auto-INSTALLING Firefox updates [NON-WINDOWS FF65+]
 * [NOTE] In FF65+ on Windows this SETTING (below) is now stored in a file and the pref was removed
 * [SETTING] General>Firefox Updates>Check for updates but let you choose to install them ***/
user_pref("app.update.auto", true);

/* 0412: disable SB checks for downloads (remote)
 * To verify the safety of certain executable files, Firefox may submit some information about the
 * file, including the name, origin, size and a cryptographic hash of the contents, to the Google
 * Safe Browsing service which helps Firefox determine whether or not the file should be blocked
 * [SETUP-SECURITY] If you do not understand this, or you want this protection, then override it ***/
user_pref("browser.safebrowsing.downloads.remote.enabled", true);
user_pref("browser.safebrowsing.downloads.remote.url", "https://sb-ssl.google.com/safebrowsing/clientreport/download?key=%GOOGLE_SAFEBROWSING_API_KEY%");

/* 0801: disable location bar using search
 * Don't leak URL typos to a search engine, give an error message instead.
 * Examples: "secretplace,com", "secretplace/com", "secretplace com", "secret place.com"
 * [NOTE] This does **not** affect explicit user action such as using search buttons in the
 * dropdown, or using keyword search shortcuts you configure in options (e.g. 'd' for DuckDuckGo)
 * [SETUP-CHROME] If you don't, or rarely, type URLs, or you use a default search
 * engine that respects privacy, then you probably don't need this ***/
user_pref("keyword.enabled", true);

/* 0901: disable saving passwords
 * [NOTE] This does not clear any passwords already saved
 * [SETTING] Privacy & Security>Logins and Passwords>Ask to save logins and passwords for websites ***/
user_pref("signon.rememberSignons", false);

/** CACHE ***/
/* 1001: disable disk cache
 * [SETUP-PERF] If you think disk cache may help (heavy tab user, high-res video),
 * or you use a hardened Temporary Containers, then feel free to override this
 * [NOTE] We also clear cache on exiting Firefox (see 2803) ***/
user_pref("browser.cache.disk.enable", true);

/** SESSIONS & SESSION RESTORE ***/
/* 1020: exclude "Undo Closed Tabs" in Session Restore ***/
user_pref("browser.sessionstore.max_tabs_undo", 4);

/* 1601: ALL: control when images/links send a referer
 * 0=never, 1=send only when links are clicked, 2=for links and images (default) ***/
user_pref("network.http.sendRefererHeader", 1);
/* 1602: ALL: control the amount of information to send
 * 0=send full URI (default), 1=scheme+host+port+path, 2=scheme+host+port ***/
user_pref("network.http.referer.trimmingPolicy", 2);

/* 1825: disable widevine CDM (Content Decryption Module)
 * [NOTE] This is covered by the EME master switch (1830) ***/
user_pref("media.gmp-widevinecdm.enabled", true);
/* 1830: disable all DRM content (EME: Encryption Media Extension)
 * [SETUP-WEB] e.g. Netflix, Amazon Prime, Hulu, HBO, Disney+, Showtime, Starz, DirectTV
 * [SETTING] General>DRM Content>Play DRM-controlled content
 * [TEST] https://bitmovin.com/demos/drm
 * [1] https://www.eff.org/deeplinks/2017/10/drms-dead-canary-how-we-just-lost-web-what-we-learned-it-and-what-we-need-do-next ***/
user_pref("media.eme.enabled", true);

/* 2401: disable website control over browser right-click context menu
 * [NOTE] Shift-Right-Click will always bring up the browser right-click context menu ***/
user_pref("dom.event.contextmenu.enabled", false);

/* 2402: disable website access to clipboard events/content [SETUP-HARDEN]
 * [NOTE] This will break some sites' functionality e.g. Outlook, Twitter, Facebook, Wordpress
 * This applies to onCut/onCopy/onPaste events - i.e. it requires interaction with the website
 * [WARNING] In FF88 or lower, with clipboardevents enabled, if both 'middlemouse.paste' and
 * 'general.autoScroll' are true (at least one is default false) then the clipboard can leak [1]
 * [1] https://bugzilla.mozilla.org/1528289 ***/
user_pref("dom.event.clipboardevents.enabled", false);

/* 2421: disable Ion and baseline JIT to harden against JS exploits [SETUP-HARDEN]
 * [NOTE] In FF75+, when **both** Ion and JIT are disabled, **and** the new
 * hidden pref is enabled, then Ion can still be used by extensions (1599226)
 * [WARNING] Disabling Ion/JIT can cause some site issues and performance loss
 * [1] https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-0817 ***/
user_pref("javascript.options.ion", false);
user_pref("javascript.options.baselinejit", false);
user_pref("javascript.options.jit_trustedprincipals", true); // [FF75+] [HIDDEN PREF]

/** DOWNLOADS ***/
/* 2651: enforce user interaction for security by always asking where to download
 * [SETUP-CHROME] On Android this blocks longtapping and saving images
 * [SETTING] General>Downloads>Always ask you where to save files ***/
user_pref("browser.download.useDownloadDir", true);
/* 2654: disable "open with" in download dialog [FF50+] [SETUP-HARDEN]
 * This is very useful to enable when the browser is sandboxed (e.g. via AppArmor)
 * in such a way that it is forbidden to run external applications.
 * [WARNING] This may interfere with some users' workflow or methods
 * [1] https://bugzilla.mozilla.org/1281959 ***/
user_pref("browser.download.forbid_open_with", true);

/** SECURITY ***/
/* 2684: enforce a security delay on some confirmation dialogs such as install, open/save
 * [1] https://www.squarefree.com/2004/07/01/race-conditions-in-security-dialogs/ ***/
user_pref("security.dialog_enable_delay", 3000);

/* 2703: delete cookies and site data on close
 * 0=keep until they expire (default), 2=keep until you close Firefox
 * [NOTE] The setting below is disabled (but not changed) if you block all cookies (2701 = 2)
 * [SETTING] Privacy & Security>Cookies and Site Data>Delete cookies and site data when Firefox is closed ***/
user_pref("network.cookie.lifetimePolicy", 2);

/*** [SECTION 2800]: SHUTDOWN
     - Sanitizing on shutdown is all or nothing. It does not use Managed Exceptions under
       Privacy & Security>Delete cookies and site data when Firefox is closed (1681701)
     - If you want to keep some sites' cookies (exception as "Allow") and optionally other site
       data but clear all the rest on close, then you need to set the "cookie" and optionally the
       "offlineApps" prefs below to false, and to set the cookie lifetime pref to 2 (2703)
     - "Offline Website Data" includes appCache (2730), localStorage (2720),
       service worker cache (2740), and QuotaManager (IndexedDB, asm-cache)
     - In both 2803 + 2804, the 'download' and 'history' prefs are combined in the
       Firefox interface as "Browsing & Download History" and their values will be synced
***/

/* 2803: set what items to clear on shutdown (if 2802 is true) [SETUP-CHROME]
 * [NOTE] If 'history' is true, downloads will also be cleared regardless of the value
 * but if 'history' is false, downloads can still be cleared independently
 * However, this may not always be the case. The interface combines and syncs these
 * prefs when set from there, and the sanitize code may change at any time
 * [SETTING] Privacy & Security>History>Custom Settings>Clear history when Firefox closes>Settings ***/
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.history", false); // Browsing & Download History
user_pref("privacy.clearOnShutdown.sessions", false); // Active Logins

/*** [SECTION 5000]: PERSONAL
     Non-project related but useful. If any of these interest you, add them to your overrides
     To save some overrides, we've made a few active as they seem to be universally used ***/

// PREF: Delete Search and Form History
// CIS Version 1.2.0 October 21st, 2011 2.5.6
user_pref("browser.formfill.expire_days", 30);

// PREF: Disable snippets/messages from Mozilla
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.topSitesRows", 2);

/* [TODO] Reduce TLS Sessions tracking
 * [WARNING] May probably alter your TLS fingerprint.
 * [1] https://www.tomshardware.com/news/browsers-permanent-tracking-tls-sessions,37959.html ***/
   // user_pref("devtools.remote.tls-handshake-timeout", 60);
   // user_pref("network.http.spdy.enforce-tls-profile", false);
   // user_pref("network.proxy.proxy_over_tls, false");
   // user_pref("security.webauth.u2f, false");
   // user_pref("security.webauth.webauthn, false");

/* APPEARANCE ***/
// Devtools dark theme
user_pref("devtools.theme", "dark");

// PREF: Disable Pocket API
// https://support.mozilla.org/en-US/kb/save-web-pages-later-pocket-firefox
// https://github.com/pyllyukko/user.js/issues/143
user_pref("extensions.pocket.api", "");
/* UX FEATURES: disable and hide the icons and menus ***/
user_pref("extensions.pocket.enabled", false); // Pocket Account [FF46+]
user_pref("extensions.pocket.oAuthConsumerKey", "");
user_pref("extensions.pocket.site", "");
// Highlight All find results
user_pref("findbar.highlightAll", true);

// Override mailto: preferences and block Yahoo Mail & Gmail
user_pref("gecko.handlerService.schemes.mailto.0.name", "");
user_pref("gecko.handlerService.schemes.mailto.0.uriTemplate", "");
user_pref("gecko.handlerService.schemes.mailto.1.name", "");
user_pref("gecko.handlerService.schemes.mailto.1.uriTemplate", "");

// PREF: Don't use OS values to determine locale, force using Firefox locale setting
// http://kb.mozillazine.org/Intl.locale.matchOS
user_pref("intl.locale.matchOS", false);

// PREF: Disable WebRTC getUserMedia, screen sharing, audio capture, video capture
// https://wiki.mozilla.org/Media/getUserMedia
// https://blog.mozilla.org/futurereleases/2013/01/12/capture-local-camera-and-microphone-streams-with-getusermedia-now-enabled-in-firefox/
// https://developer.mozilla.org/en-US/docs/Web/API/Navigator
user_pref("media.navigator.video.enabled", false);

/* [TODO] Enable only whitelisted URL protocol handlers
 * NOTICE: Disabling nonessential protocols breaks all interaction wit
 * custom protocols such as mailto:, irc:, magnet: ... and breaks opening
 * third-party mail/messaging/torrent/... clients when clicking on links
 * with these protocols.
 * Add externally-handled protocols from Windows 8.1 and Windows 10
 * (currently contains protocols only from Linux and Windows 7) that might
 * pose a similar threat (see e.g. https://news.ycombinator.com/item?id=13044991)
 * Add externally-handled protocols from Mac OS X that might pose a similar
 * threat (see e.g. https://news.ycombinator.com/item?id=13044991)
 * If you want to enable a protocol, set network.protocol-handler.expose.(protocol)
 * to true and network.protocol-handler.external.(protocol) to:
 *  * true, if the protocol should be handled by an external application
 *  * false, if the protocol should be handled internally by Firefox
 * [1] http://kb.mozillazine.org/Network.protocol-handler.external-default
 * [2] http://kb.mozillazine.org/Network.protocol-handler.warn-external-default
 * [3] http://kb.mozillazine.org/Network.protocol-handler.expose.%28protocol%29
 * [4] https://news.ycombinator.com/item?id=13047883
 * [5] https://bugzilla.mozilla.org/show_bug.cgi?id=167475
 * [6] https://github.com/pyllyukko/user.js/pull/285#issuecomment-298124005 ***/
   // user_pref("network.protocol-handler.warn-external-default", true);
   // user_pref("network.protocol-handler.external.javascript", false);
   // user_pref("network.protocol-handler.external.data", false);
   // user_pref("network.protocol-handler.expose-all", false);

// Proxy settings
user_pref("network.proxy.type", 1);
user_pref("network.proxy.http", "127.0.0.1");
user_pref("network.proxy.http_port", "8118");
   // user_pref("network.proxy.ssl", "127.0.0.1");
   // user_pref("network.proxy.ssl_port", "8118");

/*** [SECTION 6750]: DoH ***/
/* 6751: DoH mode
 * 2: enable TRR (with System fallback)
 * 3: enable TRR (without System fallback)
 * 5: Disable TRR ***/
user_pref("network.trr.mode", 2);
/* 6752: DoH resolver
 * The second pref is optional for DoH mode 2 and required for mode 3 ***/
user_pref("network.trr.custom_uri", "https://127.0.0.1:3000/dns-query");
user_pref("network.trr.bootstrapAddress", "127.0.0.1");
user_pref("network.trr.early-AAAA", true);
user_pref("network.trr.uri", "https://127.0.0.1:3000/dns-query");
user_pref("network.trr.wait-for-A-and-AAAA", false);
user_pref("network.trr.wait-for-portal", true);
/* 6754: ***/
user_pref("network.dns.skipTRR-when-parental-control-enabled", false);
/* 6755: enable ESNI
 * ESNI has nothing to do with DoH, but the implementation in Firefox requires it ***/
user_pref("network.dns.echconfig.enabled", true);
user_pref("network.dns.use_https_rr_as_altsvc", true);

/* PREF: Force hardware acceleration to make Firefox snappier
 * https://wiki.mozilla.org/Blocklisting/Blocked_Graphics_Drivers#On_X11
 * [WARNING] Potential security risk
 * https://security.stackexchange.com/a/13840
***/
user_pref("layers.acceleration.force-enabled", false);

/* Enable Fission
 * [NOTE] This option will be made default later this year ***/
user_pref("fission.autostart", true);
user_pref("gfx.webrender.all", true);


user_pref("_user.js.parrot", "SUCCESS");
