# thunderbird-privacy-profile

This is a privacy thunderbird profile for everyone.  
If you have more privacy settings or add-ons, submit a issue or pull request.  

### Build with Thunderbird v52.9

## How to use

* Clone or download the repository  

* Create a [new profile in thunderbird](https://support.mozilla.org/en-US/kb/using-multiple-profiles) or use your default profile  

* Copy the files into the profile  

      * Windows: %APPDATA%\Thunderbird\Profiles\  
      * Linux: /home/user/.thunderbird/  
      * MacOS: /Library/Thunderbird/Profiles/  



## addons

#### [Enigmail](https://addons.mozilla.org/en-US/thunderbird/addon/enigmail/)
#### [No Resource URI Leak](https://addons.mozilla.org/en-US/thunderbird/addon/no-resource-uri-leak/)



## about:config settings

#### Disable web push notifications, not needed

dom.push.connection.enabled = false


#### In the browser, links to previously visited websites are displayed differently than unknown websites. For this reason, Mozille 2010 has introduced the following option to prevent the different formatting of visited links.

layout.css.visited_links_enabled = false


#### Thunderbird offers the possibility to block the sending of the referer to third party sites.

network.http.referer.XOriginPolicy = 2


#### External plug-ins only activated if the user really allows it by mouse click

plugins.click_to_play = true


#### OCSP replies must be valid if the web server supports OCSP.Stapling

security.OCSP.require = true


#### Blocking font caching to prevent tracking

gfx.downloadable_fonts.disable_cache = true


#### Disable function for reading media input and output devices

media.navigator.enabled = false  
media.navigator.video.enabled = false  


#### With the AudioContext API, Javascript can generate and manipulate sound snippets in the AudioBuffer and retrieve the results. The results differ depending on the audio hardware and software. The data can be used for fingerprinting, as shown on the [AudioContext Fingerprint Test Page](https://audiofingerprint.openwpm.com/).

dom.webaudio.enabled = false


#### Disable transmission of statistics when playing videos

media.video_stats.enabled = false


#### The Gamepad API provides information about a connected gamepad.

dom.gamepad.enabled = false


#### Deactivation of the geolocation API

geo.enabled = false  
browser.search.geoip.timeout = 1  


#### The high-precision timing APIs can be abused by web applications to analyze the loading of resources or user behavior. Info: They can be needed for browser games

dom.enable_resource_timing = false  
dom.enable_performance = false  


#### Disable Clipboard Events

dom.event.clipboardevents.enabled = false


#### Disable speculative loading of web pages

network.http.speculative-parallel-limit = "0"


#### Disable Kill Switch for add-ons and disable metadata update

extensions.blocklist.enabled = false  
extensions.getAddons.cache.enabled = false  


#### Disable HTML5 Beacons

beacon.enabled = false


#### Disable Google Safebrowsing

browser.safebrowsing.phishing.enabled = false
browser.safebrowsing.malware.enabled = false
browser.safebrowsing.blockedURIs.enabled = false
browser.safebrowsing.downloads.enabled = false
browser.safebrowsing.downloads.remote.enabled = false
browser.safebrowsing.downloads.remote.url = ""


#### Disable telemetry data for Mozilla

datareporting.policy.dataSubmissionEnabled = false
toolkit.telemetry.enabled = false
toolkit.telemetry.unified = false
toolkit.telemetry.server = ""


#### Disable Microsoft Family Safety

security.family_safety.mode = 0


#### Display for IDN domains always the punycode representation

network.IDN_show_punycode = true


#### Disable auto update, you will still be notified

app.update.auto = false  
app.update.enabled = false  


#### Disabled thunderbird tries for \"something.com\" if you type \"something\"

browser.fixup.alternate.enabled = false


#### Disable search suggests

browser.search.suggest.enabled = false


#### Disable the Battery API

dom.battery.enabled = false


#### Disable about:addons' Get Add-ons panel

extensions.webservice.discoverURL = ""


#### Disable about:config warning

general.warnOnAboutConfig = false


#### Disable WebRTC

media.peerconnection.enabled = false


#### Disable DNS prefetching

network.dns.disablePrefetch = true


#### Disable link prefetching

network.prefetch-next = false


#### Reminder font fingerprinting

browser.display.use_document_fonts = 0  

intl.locale.matchOS = false  
general.useragent.locale = en-US  


#### Disable check for default mail client

mail.shell.checkDefaultClient = false


#### Remove remote start page

mailnews.start_page.enabled = false  
mailnews.start_page.url = ""  


#### Disable cookie tracking and history

network.cookie.cookieBehavior = 1  
network.cookie.lifetimePolicy = 2  
network.cookie.prefsMigrated = true
places.history.enabled = false  


#### Enable spam check

mail.spam.version = 1

