/******************************************************************************
 * user-overrides.js                                                          *
 * Inspired by ghacks and pyllyukko's user.js with some tweaking              *
 * https://github.com/ghacksuserjs/ghacks-user.js/                            *
 * https://github.com/pyllyukko/user.js/                                      *
 ******************************************************************************/

user_pref("_user.js.parrot", "overrides section syntax error");

/* 0000: disable about:config warning ***/
user_pref("browser.aboutConfig.showWarning", true);

/* 0102: set startup page [SETUP-CHROME]
 * 0=blank, 1=home, 2=last visited page, 3=resume previous session
 * [NOTE] Session Restore is cleared with history (2803, 2804), and not used in Private Browsing mode
 * [SETTING] General>Startup>Restore previous session ***/
user_pref("browser.startup.page", 3);

/*** [SECTION 0200]: GEOLOCATION / LANGUAGE / LOCALE ***/
/* 0211: use US English locale regardless of the system locale
 * [SETUP-WEB] May break some input methods e.g xim/ibus for CJK languages [1]
 * [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=867501,1629630 ***/
user_pref("javascript.use_us_english_locale", false); // [HIDDEN PREF]

/*** [SECTION 0300]: QUIET FOX ***/
/* 0301: disable auto-INSTALLING Firefox updates [NON-WINDOWS]
 * [NOTE] You will still get prompts to update, and should do so in a timely manner
 * [SETTING] General>Firefox Updates>Check for updates but let you choose to install them ***/
user_pref("app.update.auto", true);
/* 0302: disable auto-INSTALLING Firefox updates via a background service [FF90+] [WINDOWS]
 * [SETTING] General>Firefox Updates>Automatically install updates>When Firefox is not running
 * [1] https://support.mozilla.org/kb/enable-background-updates-firefox-windows ***/
user_pref("app.update.background.scheduling.enabled", true);

/*** [SECTION 0700]: HTTP* / TCP/IP / DNS / PROXY / SOCKS etc ***/
/* 0701: disable IPv6
 * IPv6 can be abused, especially with MAC addresses, and can leak with VPNs: assuming
 * your ISP and/or router and/or website is IPv6 capable. Most sites will fall back to IPv4
 * [STATS] Firefox telemetry (July 2021) shows ~10% of all connections are IPv6
 * [NOTE] This is an application level fallback. Disabling IPv6 is best done at an
 * OS/network level, and/or configured properly in VPN setups. If you are not masking your IP,
 * then this won't make much difference. If you are masking your IP, then it can only help.
 * [NOTE] PHP defaults to IPv6 with "localhost". Use "php -S 127.0.0.1:PORT"
 * [TEST] https://ipleak.org/
 * [1] https://www.internetsociety.org/tag/ipv6-security/ (Myths 2,4,5,6) ***/
user_pref("network.dns.disableIPv6", false);
/* 0703: disable using UNC (Uniform Naming Convention) paths [FF61+]
 * [SETUP-CHROME] Can break extensions for profiles on network shares
 * [1] https://gitlab.torproject.org/tpo/applications/tor-browser/-/issues/26424 ***/
user_pref("network.file.disable_unc_paths", false); // [HIDDEN PREF]

/*** [SECTION 0800]: LOCATION BAR / SEARCH BAR / SUGGESTIONS / HISTORY / FORMS ***/
/* 0808: disable search and form history
 * [SETUP-WEB] Be aware that autocomplete form data can be read by third parties [1][2]
 * [NOTE] We also clear formdata on exit (2803)
 * [SETTING] Privacy & Security>History>Custom Settings>Remember search and form history
 * [1] https://blog.mindedsecurity.com/2011/10/autocompleteagain.html
 * [2] https://bugzilla.mozilla.org/381681 ***/
user_pref("browser.formfill.enable", true);

/*** [SECTION 1000]: DISK AVOIDANCE
   [NOTE] Cache is isolated with network partitioning (FF85+) or FPI
***/
/* 1001: disable disk cache
 * [SETUP-CHROME] If you think disk cache helps perf, then feel free to override this
 * [NOTE] We also clear cache on exit (2803) ***/
user_pref("browser.cache.disk.enable", true);
/* 1005: disable automatic Firefox start and session restore after reboot [FF62+] [WINDOWS]
 * [1] https://bugzilla.mozilla.org/603903 ***/
user_pref("toolkit.winRegisterApplicationRestart", true);

/*** [SECTION 1200]: HTTPS (SSL/TLS / OCSP / CERTS / HPKP)
   Your cipher and other settings can be used in server side fingerprinting
   [TEST] https://www.ssllabs.com/ssltest/viewMyClient.html
   [TEST] https://browserleaks.com/ssl
   [TEST] https://ja3er.com/
   [1] https://www.securityartwork.es/2017/02/02/tls-client-fingerprinting-with-bro/
***/

/** CERTS / HPKP (HTTP Public Key Pinning) ***/
/* 1220: disable or limit SHA-1 certificates
 * 0 = allow all
 * 1 = block all
 * 3 = only allow locally-added roots (e.g. anti-virus) (default)
 * 4 = only allow locally-added roots or for certs in 2015 and earlier
 * [SETUP-CHROME] If you have problems, update your software: SHA-1 is obsolete
 * [1] https://blog.mozilla.org/security/2016/10/18/phasing-out-sha-1-on-the-public-web/ ***/
user_pref("security.pki.sha1_enforcement_level", 3);
/* 1223: enable strict pinning
 * PKP (Public Key Pinning) 0=disabled 1=allow user MiTM (such as your antivirus), 2=strict
 * [SETUP-WEB] If you rely on an AV (antivirus) to protect your web browsing
 * by inspecting ALL your web traffic, then leave at current default=1
 * [1] https://gitlab.torproject.org/tpo/applications/tor-browser/-/issues/16206 ***/
user_pref("security.cert_pinning.enforcement_level", 1);

/** MIXED CONTENT ***/
/* 1241: disable insecure passive content (such as images) on https pages [SETUP-WEB] ***/
user_pref("security.mixed_content.block_display_content", false);
/* 1244: enable HTTPS-Only mode in all windows [FF76+]
 * When the top-level is HTTPS, insecure subresources are also upgraded (silent fail)
 * [SETTING] to add site exceptions: Padlock>HTTPS-Only mode>On (after "Continue to HTTP Site")
 * [SETTING] Privacy & Security>HTTPS-Only Mode (and manage exceptions)
 * [TEST] http://example.com [upgrade]
 * [TEST] http://neverssl.com/ [no upgrade] ***/
user_pref("dom.security.https_only_mode", false); // [FF76+]
   // user_pref("dom.security.https_only_mode_pbm", true); // [FF80+]
/* 1245: enable HTTPS-Only mode for local resources [FF77+] ***/
   // user_pref("dom.security.https_only_mode.upgrade_local", true);
/* 1246: disable HTTP background requests [FF82+]
 * When attempting to upgrade, if the server doesn't respond within 3 seconds,
 * Firefox sends HTTP requests in order to check if the server supports HTTPS or not
 * This is done to avoid waiting for a timeout which takes 90 seconds
 * [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1642387,1660945 ***/
user_pref("dom.security.https_only_mode_send_http_background_request", true);

/** UI (User Interface) ***/
/* 1271: control "Add Security Exception" dialog on SSL warnings
 * 0=do neither 1=pre-populate url 2=pre-populate url + pre-fetch cert (default)
 * [1] https://github.com/pyllyukko/user.js/issues/210 ***/
user_pref("browser.ssl_override_behavior", 2);

/*** [SECTION 1400]: FONTS ***/
/* 1401: disable rendering of SVG OpenType fonts ***/
user_pref("gfx.font_rendering.opentype_svg.enabled", true);

/*** [SECTION 1600]: HEADERS / REFERERS
   Expect some breakage e.g. banks: use an extension if you need precise control
                  full URI: https://example.com:8888/foo/bar.html?id=1234
     scheme+host+port+path: https://example.com:8888/foo/bar.html
          scheme+host+port: https://example.com:8888
   [1] https://feeding.cloud.geek.nz/posts/tweaking-referrer-for-privacy-in-firefox/
***/
/* 1601: control when to send a cross origin referer
 * 0=always (default), 1=only if base domains match, 2=only if hosts match
 * [SETUP-WEB] Known to cause issues with older modems/routers and some sites e.g vimeo, icloud, instagram ***/
user_pref("network.http.referer.XOriginPolicy", 0);
/* 1602: control the amount of cross origin information to send [FF52+]
 * 0=send full URI (default), 1=scheme+host+port+path, 2=scheme+host+port ***/
user_pref("network.http.referer.XOriginTrimmingPolicy", 0);

/*** [SECTION 2000]: PLUGINS / MEDIA / WEBRTC ***/
/* 2001: disable WebRTC (Web Real-Time Communication)
 * [SETUP-WEB] WebRTC can leak your IP address from behind your VPN, but if this is not
 * in your threat model, and you want Real-Time Communication, this is the pref for you
 * [1] https://www.privacytools.io/#webrtc ***/
user_pref("media.peerconnection.enabled", true);
/* 2002: limit WebRTC IP leaks if using WebRTC
 * In FF70+ these settings match Mode 4 (Mode 3 in older versions) [3]
 * [TEST] https://browserleaks.com/webrtc
 * [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1189041,1297416,1452713
 * [2] https://wiki.mozilla.org/Media/WebRTC/Privacy
 * [3] https://tools.ietf.org/html/draft-ietf-rtcweb-ip-handling-12#section-5.2 ***/
user_pref("media.peerconnection.ice.default_address_only", false);
user_pref("media.peerconnection.ice.no_host", false); // [FF51+]
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", false); // [FF70+]
/* 2003: disable screensharing ***/
user_pref("media.getusermedia.screensharing.enabled", true);
user_pref("media.getusermedia.browser.enabled", false);
user_pref("media.getusermedia.audiocapture.enabled", false);
/* 2022: disable all DRM content (EME: Encryption Media Extension)
 * [SETUP-WEB] e.g. Netflix, Amazon Prime, Hulu, HBO, Disney+, Showtime, Starz, DirectTV
 * [SETTING] General>DRM Content>Play DRM-controlled content
 * [TEST] https://bitmovin.com/demos/drm
 * [1] https://www.eff.org/deeplinks/2017/10/drms-dead-canary-how-we-just-lost-web-what-we-learned-it-and-what-we-need-do-next ***/
user_pref("media.eme.enabled", true);
/* 2031: disable autoplay of HTML5 media if you interacted with the site [FF78+]
 * 0=sticky (default), 1=transient, 2=user
 * Firefox's Autoplay Policy Documentation [PDF] is linked below via SUMO
 * [NOTE] If you have trouble with some video sites, then add an exception (2030)
 * [1] https://support.mozilla.org/questions/1293231 ***/
user_pref("media.autoplay.blocking_policy", 0);

/*** [SECTION 2300]: WEB WORKERS
   A worker is a JS "background task" running in a global context, i.e. it is different from
   the current window. Workers can spawn new workers (must be the same origin & scheme),
   including service and shared workers. Shared workers can be utilized by multiple scripts and
   communicate between browsing contexts (windows/tabs/iframes) and can even control your cache.

   [1]    Web Workers: https://developer.mozilla.org/docs/Web/API/Web_Workers_API
   [2]         Worker: https://developer.mozilla.org/docs/Web/API/Worker
   [3] Service Worker: https://developer.mozilla.org/docs/Web/API/Service_Worker_API
   [4]   SharedWorker: https://developer.mozilla.org/docs/Web/API/SharedWorker
   [5]   ChromeWorker: https://developer.mozilla.org/docs/Web/API/ChromeWorker
   [6]  Notifications: https://support.mozilla.org/questions/1165867#answer-981820
***/
/* 2302: disable service workers [FF32, FF44-compat]
 * Service workers essentially act as proxy servers that sit between web apps, and the
 * browser and network, are event driven, and can control the web page/site it is associated
 * with, intercepting and modifying navigation and resource requests, and caching resources.
 * [NOTE] Service workers require HTTPS, have no DOM access, and are not supported in PB mode [1]
 * [SETUP-WEB] Disabling service workers will break some sites. This pref is required true for
 * service worker notifications (2304), push notifications (disabled, 2305) and service worker
 * cache (2740). If you enable this pref, then check those settings as well
 * [1] https://bugzilla.mozilla.org/show_bug.cgi?id=1320796#c7 ***/
user_pref("dom.serviceWorkers.enabled", true);
/* 2305: disable Push Notifications [FF44+]
 * Push is an API that allows websites to send you (subscribed) messages even when the site
 * isn't loaded, by pushing messages to your userAgentID through Mozilla's Push Server
 * [NOTE] Push requires service workers (2302) to subscribe to and display, and is behind
 * a prompt (7002). Disabling service workers alone doesn't stop Firefox polling the
 * Mozilla Push Server. To remove all subscriptions, reset your userAgentID.
 * [1] https://support.mozilla.org/kb/push-notifications-firefox
 * [2] https://developer.mozilla.org/docs/Web/API/Push_API ***/
user_pref("dom.push.enabled", true);
   // user_pref("dom.push.userAgentID", "");

/*** [SECTION 2400]: DOM (DOCUMENT OBJECT MODEL) ***/
/* 2401: disable "Confirm you want to leave" dialog on page close
 * Does not prevent JS leaks of the page close event
 * [1] https://developer.mozilla.org/docs/Web/Events/beforeunload ***/
user_pref("dom.disable_beforeunload", false);
/* 2402: prevent scripts from moving and resizing open windows ***/
user_pref("dom.disable_window_move_resize", false);
/* 2404: limit events that can cause a popup [SETUP-WEB] ***/
user_pref("dom.popup_allowed_events", "change click dblclick auxclick mousedown mouseup pointerdown pointerup notificationclick reset submit touchend contextmenu");
/* 2406: disable clipboard commands (cut/copy) from "non-privileged" content [FF41+]
 * this disables document.execCommand("cut"/"copy") to protect your clipboard
 * [1] https://bugzilla.mozilla.org/1170911 ***/
user_pref("dom.allow_cut_copy", true);

/*** [SECTION 2500]: FINGERPRINTING ***/
/* 2503: open links targeting new windows in a new tab instead
 * Stops malicious window sizes and some screen resolution leaks.
 * You can still right-click a link and open in a new window
 * [TEST] https://arkenfox.github.io/TZP/tzp.html#screen
 * [1] https://gitlab.torproject.org/tpo/applications/tor-browser/-/issues/9881 ***/
user_pref("browser.link.open_newwindow.restriction", 2);
/* 2504: disable WebGL (Web Graphics Library)
 * [SETUP-WEB] If you need it then enable it. RFP still randomizes canvas for naive scripts ***/
user_pref("webgl.disabled", false);

/*** [SECTION 2600]: MISCELLANEOUS ***/
/* 2601: prevent accessibility services from accessing your browser [RESTART]
 * [SETTING] Privacy & Security>Permissions>Prevent accessibility services from accessing your browser (FF80 or lower)
 * [1] https://support.mozilla.org/kb/accessibility-services ***/
user_pref("accessibility.force_disabled", 0);
/* 2602: disable sending additional analytics to web servers
 * [1] https://developer.mozilla.org/docs/Web/API/Navigator/sendBeacon ***/
user_pref("beacon.enabled", true);
/* 2619: use Punycode in Internationalized Domain Names to eliminate possible spoofing
 * [SETUP-WEB] Might be undesirable for non-latin alphabet users since legitimate IDN's are also punycoded
 * [TEST] https://www.xn--80ak6aa92e.com/ (www.apple.com)
 * [1] https://wiki.mozilla.org/IDN_Display_Algorithm
 * [2] https://en.wikipedia.org/wiki/IDN_homograph_attack
 * [3] CVE-2017-5383: https://www.mozilla.org/security/advisories/mfsa2017-02/
 * [4] https://www.xudongz.com/blog/2017/idn-phishing/ ***/
user_pref("network.IDN_show_punycode", false);
/* 2620: enforce PDFJS, disable PDFJS scripting [SETUP-CHROME]
 * This setting controls if the option "Display in Firefox" is available in the setting below
 *   and by effect controls whether PDFs are handled in-browser or externally ("Ask" or "Open With")
 * PROS: pdfjs is lightweight, open source, and as secure/vetted more than most
 *   Exploits are rare (one serious case in seven years), treated seriously and patched quickly.
 *   It doesn't break "state separation" of browser content (by not sharing with OS, independent apps).
 *   It maintains disk avoidance and application data isolation. It's convenient. You can still save to disk.
 * CONS: You may prefer a different pdf reader for security reasons
 * CAVEAT: JS can still force a pdf to open in-browser by bundling its own code
 * [SETTING] General>Applications>Portable Document Format (PDF) ***/
user_pref("pdfjs.disabled", false); // [DEFAULT: false]
user_pref("pdfjs.enableScripting", true); // [FF86+]
/* 2623: disable permissions delegation [FF73+]
 * Currently applies to cross-origin geolocation, camera, mic and screen-sharing
 * permissions, and fullscreen requests. Disabling delegation means any prompts
 * for these will show/use their correct 3rd party origin
 * [1] https://groups.google.com/forum/#!topic/mozilla.dev.platform/BdFOMAuCGW8/discussion ***/
user_pref("permissions.delegation.enabled", true);

/** DOWNLOADS ***/
/* 2651: enable user interaction for security by always asking where to download
 * [SETUP-CHROME] On Android this blocks longtapping and saving images
 * [SETTING] General>Downloads>Always ask you where to save files ***/
user_pref("browser.download.useDownloadDir", true);
/* 2652: disable adding downloads to the system's "recent documents" list ***/
user_pref("browser.download.manager.addToRecentDocs", true);

/*** [SECTION 2700]: PERSISTENT STORAGE
   Data SET by websites including
          cookies : profile\cookies.sqlite
     localStorage : profile\webappsstore.sqlite
        indexedDB : profile\storage\default
   serviceWorkers :

   [NOTE] indexedDB and serviceWorkers are not available in Private Browsing Mode
   [NOTE] Blocking cookies also blocks websites access to: localStorage (incl. sessionStorage),
   indexedDB, sharedWorker, and serviceWorker (and therefore service worker cache and notifications)
   If you set a site exception for cookies (either "Allow" or "Allow for Session") then they become
   accessible to websites except shared/service workers where the cookie setting must be "Allow"
***/
/* 2701: disable or isolate 3rd-party cookies and site-data [SETUP-WEB]
 * 0 = Accept cookies and site data
 * 1 = (Block) All third-party cookies
 * 2 = (Block) All cookies
 * 3 = (Block) Cookies from unvisited websites
 * 4 = (Block) Cross-site tracking cookies (default)
 * 5 = (Isolate All) Cross-site cookies (TCP: Total Cookie Protection / dFPI: dynamic FPI) [1] (FF86+)
 * Option 5 with FPI enabled (4001) is ignored and not shown, and option 4 used instead
 * [NOTE] You can set cookie exceptions under site permissions or use an extension
 * [NOTE] Enforcing category to custom ensures ETP related prefs are always honored
 * [SETTING] Privacy & Security>Enhanced Tracking Protection>Custom>Cookies
 * [1] https://blog.mozilla.org/security/2021/02/23/total-cookie-protection/ ***/
user_pref("network.cookie.cookieBehavior", 4);
user_pref("browser.contentblocking.category", "standard");
/* 2702: set third-party cookies (if enabled, see 2701) to session-only
 * [NOTE] .sessionOnly overrides .nonsecureSessionOnly except when .sessionOnly=false and
 * .nonsecureSessionOnly=true. This allows you to keep HTTPS cookies, but session-only HTTP ones
 * [1] https://feeding.cloud.geek.nz/posts/tweaking-cookies-for-privacy-in-firefox/ ***/
user_pref("network.cookie.thirdparty.sessionOnly", false);
user_pref("network.cookie.thirdparty.nonsecureSessionOnly", false); // [FF58+]
/* 2710: enable Enhanced Tracking Protection (ETP) in all windows
 * [SETTING] Privacy & Security>Enhanced Tracking Protection>Custom>Tracking content
 * [SETTING] to add site exceptions: Urlbar>ETP Shield
 * [SETTING] to manage site exceptions: Options>Privacy & Security>Enhanced Tracking Protection>Manage Exceptions ***/
user_pref("privacy.trackingprotection.enabled", false);
/* 2711: enable various ETP lists ***/
user_pref("privacy.trackingprotection.socialtracking.enabled", false);

/*** [SECTION 2800]: SHUTDOWN
   * Sanitizing on shutdown is all or nothing. It does not use Managed Exceptions under
     Privacy & Security>Delete cookies and site data when Firefox is closed (1681701)
   * If you want to keep some sites' cookies (exception as "Allow") and optionally other site
     data but clear all the rest on close, then you need to set the "cookie" and optionally the
     "offlineApps" prefs below to false, and to set the cookie lifetime pref to 2 (2703)
***/
user_pref("privacy.cpd.offlineApps", false); // Offline Website Data

/*** [SECTION 4000]: FPI (FIRST PARTY ISOLATION)
   1278037 - indexedDB (FF51+)
   1277803 - favicons (FF52+)
   1264562 - OCSP cache (FF52+)
   1268726 - Shared Workers (FF52+)
   1316283 - SSL session cache (FF52+)
   1317927 - media cache (FF53+)
   1323644 - HSTS and HPKP (FF54+)
   1334690 - HTTP Alternative Services (FF54+)
   1334693 - SPDY/HTTP2 (FF55+)
   1337893 - DNS cache (FF55+)
   1344170 - blob: URI (FF55+)
   1300671 - data:, about: URLs (FF55+)
   1473247 - IP addresses (FF63+)
   1542309 - top-level domain URLs when host is in the public suffix list (FF68+)
   1506693 - pdfjs range-based requests (FF68+)
   1330467 - site permissions (FF69+)
   1534339 - IPv6 (FF73+)
   1721858 - WebSocket (FF92+)
***/
/* 4001: enable First Party Isolation [FF51+]
 * [SETUP-WEB] Will break most cross-domain logins
 * [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1260931,1299996 ***/
user_pref("privacy.firstparty.isolate", false);

/*** [SECTION 4500]: RFP (RESIST FINGERPRINTING)
   RFP covers a wide range of ongoing fingerprinting solutions.
   It is an all-or-nothing buy in: you cannot pick and choose what parts you want

   [WARNING] DO NOT USE extensions to alter RFP protected metrics

 FF41+
    418986 - limit window.screen & CSS media queries leaking identifiable info
      [TEST] https://arkenfox.github.io/TZP/tzp.html#screen
 FF50+
   1281949 - spoof screen orientation
   1281963 - hide contents of navigator.plugins and navigator.mimeTypes
 FF55+
   1330890 - spoof timezone as UTC0
   1360039 - spoof navigator.hardwareConcurrency as 2
   1217238 - reduce precision of time exposed by javascript
 FF56+
   1369303 - spoof/disable performance API
   1333651 - spoof User Agent & Navigator API
      JS: FF91+ the version is spoofed as ESR, and the OS as Windows 10, OS 10.15, Android 10, or Linux
      HTTP Headers: spoofed as Windows or Android
   1369319 - disable device sensor API
   1369357 - disable site specific zoom
   1337161 - hide gamepads from content
   1372072 - spoof network information API as "unknown" when dom.netinfo.enabled = true
   1333641 - reduce fingerprinting in WebSpeech API
 FF57+
   1369309 - spoof media statistics
   1382499 - reduce screen co-ordinate fingerprinting in Touch API
   1217290 & 1409677 - enable some fingerprinting resistance for WebGL
   1382545 - reduce fingerprinting in Animation API
   1354633 - limit MediaError.message to a whitelist
   1382533 & 1697680 - enable fingerprinting resistance for Presentation API (FF57-87)
      Blocks exposure of local IP Addresses via mDNS (Multicast DNS)
 FF58+
    967895 - spoof canvas and enable site permission prompt before allowing canvas data extraction
 FF59+
   1372073 - spoof/block fingerprinting in MediaDevices API
      Spoof: enumerate devices as one "Internal Camera" and one "Internal Microphone"
      Block: suppresses the ondevicechange event
   1039069 - warn when language prefs are not set to "en*" (also see 0210, 0211)
   1222285 & 1433592 - spoof keyboard events and suppress keyboard modifier events
      Spoofing mimics the content language of the document. Currently it only supports en-US.
      Modifier events suppressed are SHIFT and both ALT keys. Chrome is not affected.
 FF60-67
   1337157 - disable WebGL debug renderer info (FF60+)
   1459089 - disable OS locale in HTTP Accept-Language headers (ANDROID) (FF62+)
   1479239 - return "no-preference" with prefers-reduced-motion (FF63+)
   1363508 - spoof/suppress Pointer Events (FF64+)
   1492766 - spoof pointerEvent.pointerid (FF65+)
   1485266 - disable exposure of system colors to CSS or canvas (FF67+)
   1494034 - return "light" with prefers-color-scheme (FF67+)
 FF68-77
   1564422 - spoof audioContext outputLatency (FF70+)
   1595823 - return audioContext sampleRate as 44100 (FF72+)
   1607316 - spoof pointer as coarse and hover as none (ANDROID) (FF74+)
 FF78-90
   1621433 - randomize canvas (previously FF58+ returned an all-white canvas) (FF78+)
   1653987 - limit font visibility to bundled and "Base Fonts" (Windows, Mac, some Linux) (FF80+)
   1461454 - spoof smooth=true and powerEfficient=false for supported media in MediaCapabilities (FF82+)
 FF91+
    531915 - use fdlibm's sin, cos and tan in jsmath (FF93+, ESR91.1+)
***/
/* 4501: enable privacy.resistFingerprinting [FF41+]
 * [SETUP-WEB] RFP can cause some website breakage: mainly canvas, use a site exception via the urlbar
 * RFP also has a few side effects: mainly timezone is UTC0, and websites will prefer light theme
 * [1] https://bugzilla.mozilla.org/418986 ***/
user_pref("privacy.resistFingerprinting", false);
/* 4503: disable mozAddonManager Web API [FF57+]
 * [NOTE] To allow extensions to work on AMO, you also need 2662
 * [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1384330,1406795,1415644,1453988 ***/
user_pref("privacy.resistFingerprinting.block_mozAddonManager", false); // [HIDDEN PREF]
/* 4504: enable RFP letterboxing [FF67+]
 * Dynamically resizes the inner window by applying margins in stepped ranges [2]
 * If you use the dimension pref, then it will only apply those resolutions.
 * The format is "width1xheight1, width2xheight2, ..." (e.g. "800x600, 1000x1000")
 * [SETUP-WEB] This is independent of RFP (4501). If you're not using RFP, or you are but
 * dislike the margins, then flip this pref, keeping in mind that it is effectively fingerprintable
 * [WARNING] DO NOT USE: the dimension pref is only meant for testing
 * [1] https://bugzilla.mozilla.org/1407366
 * [2] https://hg.mozilla.org/mozilla-central/rev/6d2d7856e468#l2.32 ***/
user_pref("privacy.resistFingerprinting.letterboxing", false); // [HIDDEN PREF]
   // user_pref("privacy.resistFingerprinting.letterboxing.dimensions", ""); // [HIDDEN PREF]

user_pref("_user.js.parrot", "SUCCESS");
