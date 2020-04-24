/******************************************************************************
 * user-overrides.js                                                          *
 * Inspired by ghacks and pyllyukko's user.js with some tweaking              *
 * https://github.com/ghacksuserjs/ghacks-user.js/                            *
 * https://github.com/pyllyukko/user.js/                                      *
 ******************************************************************************/

user_pref("_user.js.parrot", "overrides section syntax error");

/* 0000: disable about:config warning
 * FF71-72: chrome://global/content/config.xul
 * FF73+: chrome://global/content/config.xhtml ***/
user_pref("general.warnOnAboutConfig", true); // XUL/XHTML version
user_pref("browser.aboutConfig.showWarning", true); // HTML version [FF71+]

/*** [SECTION 0100]: STARTUP ***/
/* 0101: disable default browser check
 * [SETTING] General>Startup>Always check if Firefox is your default browser ***/
user_pref("browser.shell.checkDefaultBrowser", true);
/* 0102: set START page (0=blank, 1=home, 2=last visited page, 3=resume previous session)
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

// FF74
// 0203: use Mozilla geolocation service instead of Google when geolocation is enabled
   // Optionally enable logging to the console (defaults to false)
   // [-] https://bugzilla.mozilla.org/1613627
user_pref("geo.wifi.uri", "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%");

/* 0302a: disable auto-INSTALLING Firefox updates [NON-WINDOWS FF65+]
 * [NOTE] In FF65+ on Windows this SETTING (below) is now stored in a file and the pref was removed
 * [SETTING] General>Firefox Updates>Check for updates but let you choose to install them ***/
user_pref("app.update.auto", true);

/* 0211: enforce US English locale regardless of the system locale
 * [SETUP-WEB] May break some input methods e.g xim/ibus for CJK languages, see [2]
 * [1] https://bugzilla.mozilla.org/867501
 * [2] https://bugzilla.mozilla.org/1629630 ***/
user_pref("javascript.use_us_english_locale", false); // [HIDDEN PREF]

/* 0306: disable extension metadata
 * used when installing/updating an extension, and in daily background update checks:
 * when false, extension detail tabs will have no description ***/
user_pref("extensions.getAddons.cache.enabled", false);

// 0330: disable Hybdrid Content telemetry
   // [-] https://bugzilla.mozilla.org/1520491
user_pref("toolkit.telemetry.hybridContent.enabled", false); // [FF59+]

/* 0412: disable SB checks for downloads (remote)
 * To verify the safety of certain executable files, Firefox may submit some information about the
 * file, including the name, origin, size and a cryptographic hash of the contents, to the Google
 * Safe Browsing service which helps Firefox determine whether or not the file should be blocked
 * [SETUP-SECURITY] If you do not understand this, or you want this protection, then override it ***/
user_pref("browser.safebrowsing.downloads.remote.enabled", true);
user_pref("browser.safebrowsing.downloads.remote.url", "https://sb-ssl.google.com/safebrowsing/clientreport/download?key=%GOOGLE_SAFEBROWSING_API_KEY%");

/* 0605: disable link-mouseover opening connection to linked server
 * [1] https://news.slashdot.org/story/15/08/14/2321202/how-to-quash-firefoxs-silent-requests
 * [2] https://www.ghacks.net/2015/08/16/block-firefox-from-connecting-to-sites-when-you-hover-over-links/ ***/
user_pref("network.http.speculative-parallel-limit", 0);

/* 0801: disable location bar using search
 * Don't leak URL typos to a search engine, give an error message instead.
 * Examples: "secretplace,com", "secretplace/com", "secretplace com", "secret place.com"
 * [NOTE] Search buttons in the dropdown work, but hitting 'enter' in the location bar will fail
 * [TIP] You can add keywords to search engines in options (e.g. 'd' for DuckDuckGo) and
 * the dropdown will now auto-select it and you can then hit 'enter' and it will work
 * [SETUP-CHROME] If you don't, or rarely, type URLs, or you use a default search
 * engine that respects privacy, then you probably don't need this ***/
user_pref("keyword.enabled", true);

/* 0850a: disable location bar suggestion types
 * If all three suggestion types are false, search engine keywords are disabled
 * [SETTING] Privacy & Security>Address Bar>When using the address bar, suggest ***/
user_pref("browser.urlbar.suggest.history", false);

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

/* 1602: ALL: control the amount of information to send
 * 0=send full URI (default), 1=scheme+host+port+path, 2=scheme+host+port ***/
user_pref("network.http.referer.trimmingPolicy", 2); // [DEFAULT: 0]
/* 1603: CROSS ORIGIN: control when to send a referer
 * 0=always (default), 1=only if base domains match, 2=only if hosts match
 * [SETUP-WEB] Known to cause issues with older modems/routers and some sites e.g vimeo, icloud ***/
//user_pref("network.http.referer.XOriginPolicy", 2); // [DEFAULT: 0]
 /* 1604: CROSS ORIGIN: control the amount of information to send [FF52+]
  * 0=send full URI (default), 1=scheme+host+port+path, 2=scheme+host+port ***/
user_pref("network.http.referer.XOriginTrimmingPolicy", 2); // [DEFAULT: 0]

/* 1825: disable widevine CDM (Content Decryption Module)
 * [SETUP-WEB] if you *need* CDM, e.g. Netflix, Amazon Prime, Hulu, whatever ***/
user_pref("media.gmp-widevinecdm.visible", true);
user_pref("media.gmp-widevinecdm.enabled", true);
/* 1830: disable all DRM content (EME: Encryption Media Extension)
 * [SETUP-WEB] if you *need* EME, e.g. Netflix, Amazon Prime, Hulu, whatever
 * [SETTING] General>DRM Content>Play DRM-controlled content
 * [1] https://www.eff.org/deeplinks/2017/10/drms-dead-canary-how-we-just-lost-web-what-we-learned-it-and-what-we-need-do-next ***/
user_pref("media.eme.enabled", true);

/* 2401: disable website control over browser right-click context menu
 * [NOTE] Shift-Right-Click will always bring up the browser right-click context menu ***/
user_pref("dom.event.contextmenu.enabled", false);

/* 2402: disable website access to clipboard events/content [SETUP-HARDEN]
 * [NOTE] This will break some sites' functionality e.g. Outlook, Twitter, Facebook, Wordpress
 * This applies to onCut/onCopy/onPaste events - i.e. it requires interaction with the website
 * [WARNING] If both 'middlemouse.paste' and 'general.autoScroll' are true (at least one
 * is default false) then enabling this pref can leak clipboard content, see [2]
 * [1] https://www.ghacks.net/2014/01/08/block-websites-reading-modifying-clipboard-contents-firefox/
 * [2] https://bugzilla.mozilla.org/1528289 */
//user_pref("dom.event.clipboardevents.enabled", false);

/* 2502: disable Battery Status API
 * Initially a Linux issue (high precision readout) that was fixed.
 * However, it is still another metric for fingerprinting, used to raise entropy.
 * e.g. do you have a battery or not, current charging status, charge level, times remaining etc
 * [NOTE] From FF52+ Battery Status API is only available in chrome/privileged code. see [1]
 * [1] https://bugzilla.mozilla.org/1313580 ***/
user_pref("dom.battery.enabled", false);

/* 2605: block web content in file processes [FF55+]
 * [SETUP-WEB] You may want to disable this for corporate or developer environments
 * [1] https://bugzilla.mozilla.org/1343184 ***/
user_pref("browser.tabs.remote.allowLinkedWebInFileUriProcess", true);

/** EXTENSIONS ***/
/* 2660: lock down allowed extension directories
 * [SETUP-CHROME] This will break extensions, language packs, themes and any other
 * XPI files which are installed outside of profile and application directories
 * [1] https://mike.kaply.com/2012/02/21/understanding-add-on-scopes/
 * [1] archived: https://archive.is/DYjAM ***/
user_pref("extensions.autoDisableScopes", 3); // [DEFAULT: 15]

/** SECURITY ***/
/* 2684: enforce a security delay on some confirmation dialogs such as install, open/save
 * [1] https://www.squarefree.com/2004/07/01/race-conditions-in-security-dialogs/ ***/
user_pref("security.dialog_enable_delay", 3000);

/* 2703: delete cookies and site data on close
 * 0=keep until they expire (default), 2=keep until you close Firefox
 * [NOTE] The setting below is disabled (but not changed) if you block all cookies (2701 = 2)
 * [SETTING] Privacy & Security>Cookies and Site Data>Delete cookies and site data when Firefox is closed ***/
user_pref("network.cookie.lifetimePolicy", 3);
user_pref("network.cookie.lifetime.days", 30);

/*** [SECTION 2800]: SHUTDOWN
     You should set the values to what suits you best.
     - "Offline Website Data" includes appCache (2730), localStorage (2710),
       service worker cache (2740), and QuotaManager (IndexedDB (2720), asm-cache)
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

/* 4504: enable RFP letterboxing [FF67+]
 * Dynamically resizes the inner window (FF67; 200w x100h: FF68+; stepped ranges) by applying letterboxing,
 * using dimensions which waste the least content area, If you use the dimension pref, then it will only apply
 * those resolutions. The format is "width1xheight1, width2xheight2, ..." (e.g. "800x600, 1000x1000, 1600x900")
 * [SETUP-WEB] This does NOT require RFP (see 4501) **for now**, so if you're not using 4501, or you are but you're
 * not taking anti-fingerprinting seriously and a little visual change upsets you, then feel free to flip this pref
 * [WARNING] The dimension pref is only meant for testing, and we recommend you DO NOT USE it
 * [1] https://bugzilla.mozilla.org/1407366 ***/
user_pref("privacy.resistFingerprinting.letterboxing", false); // [HIDDEN PREF]

/*** [SECTION 4600]: RFP ALTERNATIVES
   * non-RFP users:
       Enable the whole section (see the SETUP tag below)
   * RFP users:
       Make sure these are reset in about:config. They are redundant. In fact, some
       even cause RFP to not behave as you would expect and alter your fingerprint
   * ESR RFP users:
       Reset those *up to and including* your version. Add those *after* your version
       as active prefs in your overrides. This is assuming that the patch wasn't also
       backported to Firefox ESR. Backporting RFP patches to ESR is rare.
***/
user_pref("_user.js.parrot", "4600 syntax error: the parrot's crossed the Jordan");
// [SETUP-non-RFP] Non-RFP users replace the * with a slash on this line to enable these
// FF55+
// 4601: [2514] spoof (or limit?) number of CPU cores [FF48+]
   // [NOTE] *may* affect core chrome/Firefox performance, will affect content.
   // [1] https://bugzilla.mozilla.org/1008453
   // [2] https://trac.torproject.org/projects/tor/ticket/21675
   // [3] https://trac.torproject.org/projects/tor/ticket/22127
   // [4] https://html.spec.whatwg.org/multipage/workers.html#navigator.hardwareconcurrency
   // user_pref("dom.maxHardwareConcurrency", 2);
// * * * /
// FF56+
// 4602: [2411] disable resource/navigation timing
user_pref("dom.enable_resource_timing", false);
// 4603: [2412] disable timing attacks
   // [1] https://wiki.mozilla.org/Security/Reviews/Firefox/NavigationTimingAPI
user_pref("dom.enable_performance", false);
// 4604: [2512] disable device sensor API
   // Optional protection depending on your device
   // [1] https://trac.torproject.org/projects/tor/ticket/15758
   // [2] https://blog.lukaszolejnik.com/stealing-sensitive-browser-data-with-the-w3c-ambient-light-sensor-api/
   // [3] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1357733,1292751
   // user_pref("device.sensors.enabled", false);
// 4605: [2515] disable site specific zoom
   // Zoom levels affect screen res and are highly fingerprintable. This does not stop you using
   // zoom, it will just not use/remember any site specific settings. Zoom levels on new tabs
   // and new windows are reset to default and only the current tab retains the current zoom
user_pref("browser.zoom.siteSpecific", false);
// 4606: [2501] disable gamepad API - USB device ID enumeration
   // Optional protection depending on your connected devices
   // [1] https://trac.torproject.org/projects/tor/ticket/13023
   // user_pref("dom.gamepad.enabled", false);
// 4607: [2503] disable giving away network info [FF31+]
   // e.g. bluetooth, cellular, ethernet, wifi, wimax, other, mixed, unknown, none
   // [1] https://developer.mozilla.org/docs/Web/API/Network_Information_API
   // [2] https://wicg.github.io/netinfo/
   // [3] https://bugzilla.mozilla.org/960426
user_pref("dom.netinfo.enabled", false); // [DEFAULT: true on Android]
// 4608: [2021] disable the SpeechSynthesis (Text-to-Speech) part of the Web Speech API
   // [1] https://developer.mozilla.org/docs/Web/API/Web_Speech_API
   // [2] https://developer.mozilla.org/docs/Web/API/SpeechSynthesis
   // [3] https://wiki.mozilla.org/HTML5_Speech_API
user_pref("media.webspeech.synth.enabled", false);
// * * * /
// FF57+
// 4610: [2506] disable video statistics - JS performance fingerprinting [FF25+]
   // [1] https://trac.torproject.org/projects/tor/ticket/15757
   // [2] https://bugzilla.mozilla.org/654550
user_pref("media.video_stats.enabled", false);
// 4611: [2509] disable touch events
   // fingerprinting attack vector - leaks screen res & actual screen coordinates
   // 0=disabled, 1=enabled, 2=autodetect
   // Optional protection depending on your device
   // [1] https://developer.mozilla.org/docs/Web/API/Touch_events
   // [2] https://trac.torproject.org/projects/tor/ticket/10286
   // user_pref("dom.w3c_touch_events.enabled", 0);
// * * * /
// FF59+
// 4612: [2511] disable MediaDevices change detection [FF51+]
   // [1] https://developer.mozilla.org/docs/Web/Events/devicechange
   // [2] https://developer.mozilla.org/docs/Web/API/MediaDevices/ondevicechange
user_pref("media.ondevicechange.enabled", false);
// * * * /
// FF60+
// 4613: [2011] disable WebGL debug info being available to websites
   // [1] https://bugzilla.mozilla.org/1171228
   // [2] https://developer.mozilla.org/docs/Web/API/WEBGL_debug_renderer_info
user_pref("webgl.enable-debug-renderer-info", false);
// * * * /
// FF65+
// 4614: [2516] disable PointerEvents
   // [1] https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent
user_pref("dom.w3c_pointer_events.enabled", false);
// * * * /
// FF67+
// 4615: [2618] disable exposure of system colors to CSS or canvas [FF44+]
   // [NOTE] See second listed bug: may cause black on black for elements with undefined colors
   // [SETUP-CHROME] Might affect CSS in themes and extensions
   // [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=232227,1330876
user_pref("ui.use_standins_for_native_colors", true);
// 4616: enforce prefers-color-scheme as light [FF67+]
   // 0=light, 1=dark : This overrides your OS value
//user_pref("ui.systemUsesDarkTheme", 0); // [HIDDEN PREF]
// * * * /
// ***/






/*** [SECTION 5000]: PERSONAL
     Non-project related but useful. If any of these interest you, add them to your overrides ***/


// PREF: Delete Search and Form History
// CIS Version 1.2.0 October 21st, 2011 2.5.6
user_pref("browser.formfill.expire_days", 30);

// PREF: Disable snippets/messages from Mozilla
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.topSitesRows", 2);

// PREF: Don't reveal build ID
// Value taken from Tor Browser
// https://bugzilla.mozilla.org/show_bug.cgi?id=583181
//user_pref("browser.startup.homepage_override.buildID", "20100101");

// PREF: Disable remote debugging
// https://developer.mozilla.org/en-US/docs/Tools/Remote_Debugging/Debugging_Firefox_Desktop
// https://developer.mozilla.org/en-US/docs/Tools/Tools_Toolbox#Advanced_settings
//user_pref("devtools.debugger.force-local", true);

// TODO Reduce TLS Sessions tracking (WARNING Probably alter TLS fingerprint)
// https://www.tomshardware.com/news/browsers-permanent-tracking-tls-sessions,37959.html
//user_pref("devtools.remote.tls-handshake-timeout", 60);
//user_pref("network.http.spdy.enforce-tls-profile", false);
//user_pref("network.proxy.proxy_over_tls, false");
//user_pref("security.webauth.u2f, false");
//user_pref("security.webauth.webauthn, false");

// Devtools dark theme
user_pref("devtools.theme", "dark");

// PREF: Disable Pocket
// https://support.mozilla.org/en-US/kb/save-web-pages-later-pocket-firefox
// https://github.com/pyllyukko/user.js/issues/143
user_pref("extensions.pocket.api", "");
/* UX FEATURES: disable and hide the icons and menus ***/
user_pref("extensions.pocket.enabled", false); // Pocket Account [FF46+]
user_pref("extensions.pocket.oAuthConsumerKey", "");
user_pref("extensions.pocket.site", "");
user_pref("extensions.webservice.discoverURL", "");

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

// PREF: Disable speech recognition
// https://dvcs.w3.org/hg/speech-api/raw-file/tip/speechapi.html
// https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition
// https://wiki.mozilla.org/HTML5_Speech_API
//user_pref("media.webspeech.recognition.enable", false);

// TODO needs tweaking
// PREF: Enable only whitelisted URL protocol handlers
// http://kb.mozillazine.org/Network.protocol-handler.external-default
// http://kb.mozillazine.org/Network.protocol-handler.warn-external-default
// http://kb.mozillazine.org/Network.protocol-handler.expose.%28protocol%29
// https://news.ycombinator.com/item?id=13047883
// https://bugzilla.mozilla.org/show_bug.cgi?id=167475
// https://github.com/pyllyukko/user.js/pull/285#issuecomment-298124005
// NOTICE: Disabling nonessential protocols breaks all interaction with custom protocols such as mailto:, irc:, magnet: ... and breaks opening third-party mail/messaging/torrent/... clients when clicking on links with these protocols
// TODO: Add externally-handled protocols from Windows 8.1 and Windows 10 (currently contains protocols only from Linux and Windows 7) that might pose a similar threat (see e.g. https://news.ycombinator.com/item?id=13044991)
// TODO: Add externally-handled protocols from Mac OS X that might pose a similar threat (see e.g. https://news.ycombinator.com/item?id=13044991)
// If you want to enable a protocol, set network.protocol-handler.expose.(protocol) to true and network.protocol-handler.external.(protocol) to:
//   * true, if the protocol should be handled by an external application
//   * false, if the protocol should be handled internally by Firefox
//user_pref("network.protocol-handler.warn-external-default", true);
//user_pref("network.protocol-handler.external.javascript", false);
//user_pref("network.protocol-handler.external.data", false);
//user_pref("network.protocol-handler.expose-all", false);

// Proxy settings
user_pref("network.proxy.http", "127.0.0.1");
user_pref("network.proxy.http_port", "8118");
user_pref("network.proxy.ssl", "127.0.0.1");
user_pref("network.proxy.ssl_port", "8118");
//user_pref("network.proxy.socks_remote_dns", true);
user_pref("network.proxy.type", 1);


// PREF: Trusted Recursive Resolver (DNS-over-HTTPS)
// https://wiki.mozilla.org/Trusted_Recursive_Resolver
user_pref("network.trr.bootstrapAddress", "9.9.9.9");
user_pref("network.trr.mode", 2);
user_pref("network.trr.uri", "https://dns.quad9.net/dns-query");

// PREF: Enable Firefox Tracking Protection
// https://wiki.mozilla.org/Security/Tracking_protection
// https://support.mozilla.org/en-US/kb/tracking-protection-firefox
// https://support.mozilla.org/en-US/kb/tracking-protection-pbm
// https://kontaxis.github.io/trackingprotectionfirefox/
// https://feeding.cloud.geek.nz/posts/how-tracking-protection-works-in-firefox/
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);

// TODO needs to be locked
// https://www.askvg.com/tip-disable-telemetry-and-data-collection-in-mozilla-firefox-quantum/
//user_pref("toolkit.telemetry.cachedClientID", "");

// TODO check ArchWiki pages for Firefox
// https://wiki.archlinux.org/index.php/Firefox
// https://wiki.archlinux.org/index.php/Firefox/Tweaks

user_pref("_user.js.parrot", "SUCCESS");