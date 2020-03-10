//
/******************************************************************************
 * user.js                                                                    *
 * Inspired by pyllyukko's user.js with some tweaking                         *
 * https://github.com/pyllyukko/user.js                                       *
 ******************************************************************************/

/******************************************************************************
 * SECTION: HTML5 / APIs / DOM                                                *
 ******************************************************************************/

// PREF: Disable "beacon" asynchronous HTTP transfers (used for analytics)
// https://developer.mozilla.org/en-US/docs/Web/API/navigator.sendBeacon
user_pref("beacon.enabled", false);

// PREF: Disable pinging URIs specified in HTML <a> ping= attributes
// http://kb.mozillazine.org/Browser.send_pings
user_pref("browser.send_pings", false);
user_pref("browser.send_pings.require_same_host", true);

// PREF: Disable battery API (Firefox < 52)
// https://developer.mozilla.org/en-US/docs/Web/API/BatteryManager
// https://bugzilla.mozilla.org/show_bug.cgi?id=1313580
user_pref("dom.battery.enabled", false);

// PREF: Disable clipboard event detection (onCut/onCopy/onPaste) via Javascript
// NOTICE: Disabling clipboard events breaks Ctrl+C/X/V copy/cut/paste functionaility in JS-based web applications (Google Docs...)
// https://developer.mozilla.org/en-US/docs/Mozilla/Preferences/Preference_reference/dom.event.clipboardevents.enabled
user_pref("dom.event.clipboardevents.enabled", false);

// Don't allow websites to prevent use of right-click, or otherwise messing with the context menu.
user_pref("dom.event.contextmenu.enabled", false);

// PREF: Disable IndexedDB (disabled)
// https://developer.mozilla.org/en-US/docs/IndexedDB
// https://en.wikipedia.org/wiki/Indexed_Database_API
// https://wiki.mozilla.org/Security/Reviews/Firefox4/IndexedDB_Security_Review
// http://forums.mozillazine.org/viewtopic.php?p=13842047
// https://github.com/pyllyukko/user.js/issues/8
// NOTICE-DISABLED: IndexedDB could be used for tracking purposes, but is required for some add-ons to work (notably uBlock), so is left enabled
//user_pref("dom.indexedDB.enabled", false);

// PREF: Disable DOM storage (disabled)
// http://kb.mozillazine.org/Dom.storage.enabled
// https://html.spec.whatwg.org/multipage/webstorage.html
// NOTICE-DISABLED: Disabling DOM storage is known to cause`TypeError: localStorage is null` errors
//user_pref("dom.storage.enabled", false);

// PREF: Disable Location-Aware Browsing (geolocation)
// https://www.mozilla.org/en-US/firefox/geolocation/
user_pref("geo.enabled", false);
user_pref("geo.wifi.uri", "");

// PREF: Disable WebRTC getUserMedia, screen sharing, audio capture, video capture
// https://wiki.mozilla.org/Media/getUserMedia
// https://blog.mozilla.org/futurereleases/2013/01/12/capture-local-camera-and-microphone-streams-with-getusermedia-now-enabled-in-firefox/
// https://developer.mozilla.org/en-US/docs/Web/API/Navigator
user_pref("media.getusermedia.screensharing.enabled", false);
user_pref("media.getusermedia.audiocapture.enabled", false);
user_pref("media.navigator.enabled", false);
user_pref("media.navigator.video.enabled", false);

// PREF: Disable WebRTC entirely to prevent leaking internal IP addresses (Firefox < 42)
// NOTICE: Disabling WebRTC breaks peer-to-peer file sharing tools (reep.io ...)
user_pref("media.peerconnection.enabled", false);


// PREF: Disable webGL
// https://en.wikipedia.org/wiki/WebGL
// https://www.contextis.com/resources/blog/webgl-new-dimension-browser-exploitation/
user_pref("webgl.disabled", true);

/******************************************************************************
 * SECTION: Firefox (anti-)features / components                              *                            *
 ******************************************************************************/

 user_pref("app.normandy.api_url", "");
 user_pref("app.normandy.enabled", false);

// PREF: Disable SHIELD
// https://support.mozilla.org/en-US/kb/shield
// https://bugzilla.mozilla.org/show_bug.cgi?id=1370801
user_pref("app.shield.optoutstudies.enabled", false);

// PREF: Enable Auto Update (disabled)
// NOTICE: Fully automatic updates are disabled and left to package management systems on Linux. Windows users may want to change this setting.
// CIS 2.1.1
//user_pref("app.update.auto", false);

// PREF: Disable sending Firefox crash reports to Mozilla servers
// https://wiki.mozilla.org/Breakpad
// http://kb.mozillazine.org/Breakpad
// https://dxr.mozilla.org/mozilla-central/source/toolkit/crashreporter
// https://bugzilla.mozilla.org/show_bug.cgi?id=411490
// A list of submitted crash reports can be found at about:crashes
user_pref("breakpad.reportURL", "");

// PREF: Disable sending reports of tab crashes to Mozilla (about:tabcrashed), don't nag user about unsent crash reports
// https://hg.mozilla.org/mozilla-central/file/tip/browser/app/profile/firefox.js
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.enabled", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);

// PREF: Disable "Recommended by Pocket" in Firefox Quantum
user_pref("browser.newtabpage.activity-stream.section.highlights.includePocket", false);

// PREF: Disable Pocket
// https://support.mozilla.org/en-US/kb/save-web-pages-later-pocket-firefox
// https://github.com/pyllyukko/user.js/issues/143
user_pref("extensions.pocket.enabled", false);
user_pref("extensions.pocket.site", "");
user_pref("extensions.pocket.oAuthConsumerKey", ""); 
user_pref("extensions.pocket.api", ""); 

// PREF: Disable collection/sending of the health report (healthreport.sqlite*)
// https://support.mozilla.org/en-US/kb/firefox-health-report-understand-your-browser-perf
// https://gecko.readthedocs.org/en/latest/toolkit/components/telemetry/telemetry/preferences.html
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);

// PREF: Disable Mozilla telemetry/experiments
// https://wiki.mozilla.org/Platform/Features/Telemetry
// https://wiki.mozilla.org/Privacy/Reviews/Telemetry
// https://wiki.mozilla.org/Telemetry
// https://www.mozilla.org/en-US/legal/privacy/firefox.html#telemetry
// https://support.mozilla.org/t5/Firefox-crashes/Mozilla-Crash-Reporter/ta-p/1715
// https://wiki.mozilla.org/Security/Reviews/Firefox6/ReviewNotes/telemetry
// https://gecko.readthedocs.io/en/latest/browser/experiments/experiments/manifest.html
// https://wiki.mozilla.org/Telemetry/Experiments
user_pref("experiments.activeExperiment", false);
user_pref("experiments.enabled", false);
user_pref("experiments.manifest.uri", "");
user_pref("experiments.supported", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.cachedClientID", "");
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.hybridContent.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.server", "");
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);

// PREF: Disallow Necko to do A/B testing
// https://trac.torproject.org/projects/tor/ticket/13170
user_pref("network.allow-experiments", false);

// PREF: Enable hardening against various fingerprinting vectors (Tor Uplift project)
// https://wiki.mozilla.org/Security/Tor_Uplift/Tracking
// https://bugzilla.mozilla.org/show_bug.cgi?id=1333933
user_pref("privacy.resistFingerprinting", true);

// PREF: Enable Firefox Tracking Protection
// https://wiki.mozilla.org/Security/Tracking_protection
// https://support.mozilla.org/en-US/kb/tracking-protection-firefox
// https://support.mozilla.org/en-US/kb/tracking-protection-pbm
// https://kontaxis.github.io/trackingprotectionfirefox/
// https://feeding.cloud.geek.nz/posts/how-tracking-protection-works-in-firefox/
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);

/*******************************************************************************
 * SECTION: UI related                                                         *
 *******************************************************************************/

user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);

// PREF: Disable new tab tile ads & preload
// http://www.thewindowsclub.com/disable-remove-ad-tiles-from-firefox
// http://forums.mozillazine.org/viewtopic.php?p=13876331#p13876331
// https://wiki.mozilla.org/Tiles/Technical_Documentation#Ping
// https://gecko.readthedocs.org/en/latest/browser/browser/DirectoryLinksProvider.html#browser-newtabpage-directory-source
// https://gecko.readthedocs.org/en/latest/browser/browser/DirectoryLinksProvider.html#browser-newtabpage-directory-ping
// TODO: deprecated? not in DXR, some dead links
user_pref("browser.newtab.preload", false);

user_pref("browser.onboarding.enabled", false);

// PREF: Force Punycode for Internationalized Domain Names
// http://kb.mozillazine.org/Network.IDN_show_punycode
// https://www.xudongz.com/blog/2017/idn-phishing/
// https://wiki.mozilla.org/IDN_Display_Algorithm
// https://en.wikipedia.org/wiki/IDN_homograph_attack
// https://www.mozilla.org/en-US/security/advisories/mfsa2017-02/
// CIS Mozilla Firefox 24 ESR v1.0.0 - 3.6
user_pref("network.IDN_show_punycode", true);

user_pref("lightweightThemes.selectedThemeID", "firefox-compact-dark@mozilla.org");

/******************************************************************************
 * SECTION: Automatic connections                                             *
 ******************************************************************************/

// PREF: Disable search suggestions in the search bar
// http://kb.mozillazine.org/Browser.search.suggest.enabled
user_pref("browser.search.suggest.enabled", false);

// PREF: Disable "Show search suggestions in location bar results"
user_pref("browser.urlbar.suggest.searches", false);

// PREF: When using the location bar, don't suggest URLs from browsing history
user_pref("browser.urlbar.suggest.history", false);

// PREF: Disable automatic captive portal detection (Firefox >= 52.0)
// https://support.mozilla.org/en-US/questions/1157121
user_pref("network.captive-portal-service.enabled", false);

/******************************************************************************
 * SECTION: Extensions / plugins                                              *
 ******************************************************************************/

// PREF: Opt-out of add-on metadata updates
// https://blog.mozilla.org/addons/how-to-opt-out-of-add-on-metadata-updates/
user_pref("extensions.getAddons.cache.enabled", false);

user_pref("extensions.webservice.discoverURL", "");
//user_pref("extensions.autoDisableScopes", 14);

/******************************************************************************
 * SECTION: HTTP                                                              *
 ******************************************************************************/

// PREF: Accept Only 1st Party Cookies
// http://kb.mozillazine.org/Network.cookie.cookieBehavior#1
// NOTICE: Blocking 3rd-party cookies breaks a number of payment gateways
// CIS 2.5.1
user_pref("network.cookie.cookieBehavior", 1);

// PREF: Send a referer header with the target URI as the source
// https://bugzilla.mozilla.org/show_bug.cgi?id=822869
// https://github.com/pyllyukko/user.js/issues/227
// NOTICE: Spoofing referers breaks functionality on websites relying on authentic referer headers
// NOTICE: Spoofing referers breaks visualisation of 3rd-party sites on the Lightbeam addon
// NOTICE: Spoofing referers disables CSRF protection on some login pages not implementing origin-header/cookie+token based CSRF protection
// TODO: https://github.com/pyllyukko/user.js/issues/94, commented-out XOriginPolicy/XOriginTrimmingPolicy = 2 prefs
//user_pref("network.http.referer.spoofSource", true);

user_pref("network.http.referer.trimmingPolicy", 2);

// PREF: Don't send referer headers when following links across different domains (disabled)
// https://github.com/pyllyukko/user.js/issues/227
user_pref("network.http.referer.XOriginPolicy", 2);
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);

//user_pref("network.proxy.http", "127.0.0.1");
//user_pref("network.proxy.http_port", "8118");

// PREF: DNT HTTP header (disabled)
// https://www.mozilla.org/en-US/firefox/dnt/
// https://en.wikipedia.org/wiki/Do_not_track_header
// https://dnt-dashboard.mozilla.org
// https://github.com/pyllyukko/user.js/issues/11
// NOTICE: Do No Track must be enabled manually
user_pref("privacy.donottrackheader.enabled", true);

// PREF: Enable first-party isolation
// https://bugzilla.mozilla.org/show_bug.cgi?id=1299996
// https://bugzilla.mozilla.org/show_bug.cgi?id=1260931
// https://wiki.mozilla.org/Security/FirstPartyIsolation
user_pref("privacy.firstparty.isolate", true);

// PREF: Reduce TLS Sessions tracking
// https://www.tomshardware.com/news/browsers-permanent-tracking-tls-sessions,37959.html
user_pref("devtools.remote.tls-handshake-timeout", 60);
//user_pref("network.http.spdy.enforce-tls-profile", false);
//user_pref("network.proxy.proxy_over_tls", false);
//user_pref("security.webauth.u2f", false);
//user_pref("security.webauth.webauthn", false);
user_pref("security.tls.version.min", 2);
user_pref("security.ssl.disable_session_identifiers", true);

/******************************************************************************
 * SECTION: Automatic connections                                             *
 ******************************************************************************/

// PREF: Disable DNS prefetching
// http://kb.mozillazine.org/Network.dns.disablePrefetch
// https://developer.mozilla.org/en-US/docs/Web/HTTP/Controlling_DNS_prefetching
user_pref("network.dns.disablePrefetch", true);

// If your OS or ISP does not support IPv6, there is no reason to have this preference set to false.
user_pref("network.dns.disableIPv6", true);

// PREF: Disable speculative pre-connections
// https://support.mozilla.org/en-US/kb/how-stop-firefox-making-automatic-connections#w_speculative-pre-connections
// https://bugzilla.mozilla.org/show_bug.cgi?id=814169
user_pref("network.http.speculative-parallel-limit", "0");

// PREF: Disable downloading homepage snippets/messages from Mozilla
// https://support.mozilla.org/en-US/kb/how-stop-firefox-making-automatic-connections#w_mozilla-content
// https://wiki.mozilla.org/Firefox/Projects/Firefox_Start/Snippet_Service
user_pref("browser.aboutHomeSnippets.updateUrl", "");
user_pref("browser.newtabpage.activity-stream.asrouter.providers.snippets", "");
user_pref("browser.newtabpage.activity-stream.disableSnippets", true);
user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);
// Disable Activity Stream Top Stories, Pocket-based and/or sponsored content
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.feeds.discoverystreamfeed", false);

// PREF: Disable prefetching of <link rel="next"> URLs
// http://kb.mozillazine.org/Network.prefetch-next
// https://developer.mozilla.org/en-US/docs/Web/HTTP/Link_prefetching_FAQ#Is_there_a_preference_to_disable_link_prefetching.3F
user_pref("network.prefetch-next", false);

/*******************************************************************************
 * SECTION: Caching                                                            *
 ******************************************************************************/

// PREF: Disable disk cache
// http://kb.mozillazine.org/Browser.cache.disk.enable
user_pref("browser.cache.disk.enable", false);

// PREF: Do not download URLs for the offline cache
// http://kb.mozillazine.org/Browser.cache.offline.enable
user_pref("browser.cache.offline.enable", false);
user_pref("browser.cache.offline.insecure.enable", false);

user_pref("browser.sessionstore.max_tabs_undo", 4);

// PREF: Clear SSL Form Session Data
// http://kb.mozillazine.org/Browser.sessionstore.privacy_level#2
// Store extra session data for unencrypted (non-HTTPS) sites only.
// CIS Version 1.2.0 October 21st, 2011 2.5.7
// NOTE: CIS says 1, we use 2
user_pref("browser.sessionstore.privacy_level", 2);

// PREF: Cookies last for the number of days specified by network.cookie.lifetime.days
// http://kb.mozillazine.org/Network.cookie.lifetimePolicy#3_2
user_pref("network.cookie.lifetimePolicy", 3);
user_pref("network.cookie.lifetime.days", 30);

// PREF: Require manual intervention to autofill known username/passwords sign-in forms
// http://kb.mozillazine.org/Signon.autofillForms
// https://www.torproject.org/projects/torbrowser/design/#identifier-linkability
user_pref("signon.autofillForms", false);

/******************************************************************************
 * SECTION: Misc                                                              *
 ******************************************************************************/

// PREF: Don't try to guess domain names when entering an invalid domain name in URL bar
// http://www-archive.mozilla.org/docs/end-user/domain-guessing.html
//user_pref("browser.fixup.alternate.enabled", false);

//user_pref("media.autoplay.enabled", false);

// PREF: Disable video stats to reduce fingerprinting threat
// https://bugzilla.mozilla.org/show_bug.cgi?id=654550
// https://github.com/pyllyukko/user.js/issues/9#issuecomment-100468785
// https://github.com/pyllyukko/user.js/issues/9#issuecomment-148922065
user_pref("media.video_stats.enabled", false);

user_pref("browser.urlbar.placeholderName", "DuckDuckGo");

user_pref("browser.urlbar.speculativeConnect.enabled", false);
// PREF: Don't trim HTTP off of URLs in the address bar.
// https://bugzilla.mozilla.org/show_bug.cgi?id=665580
user_pref("browser.urlbar.trimURLs", false);

// Replate mailto: preferences
user_pref("gecko.handlerService.schemes.mailto.0.name", "ProtonMail");
// ProtonMail not working yet tho
user_pref("gecko.handlerService.schemes.mailto.0.uriTemplate", "https://mail.protonmail.com/secure/start?action=compose&to=%s");
user_pref("gecko.handlerService.schemes.mailto.1.name", "");
user_pref("gecko.handlerService.schemes.mailto.1.uriTemplate", "");
