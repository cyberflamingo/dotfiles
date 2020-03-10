# macOS-home-call-drop
Simple shell script to fix macOS privacy issues and remove mostly useless(at least for me) macOS calls to cupertino. Great addition to software like Little Snitch. By default it disable useless services, daemons running in background - If you don't use Push Notifications, Spotlight Suggestions or do not like to send your browsing history, bookmarks and more to Apple you should run it. Script does not affect iCloud and FindMyMac so if you don't use iCloud you should disable services related to iCloud as well, just edit <b>config.sh</b> to choose which services you want to disable. Most of them are described, uncomment to let script disable it! Comments about agents and daemons are my guesses based on MacOS internal knowledge and research, some may be less accurate than others. I did didn't thoroughly checked all of them one by one, so can't know for sure. 

Script as well disable Spotlight suggestions in system and as well in Safari, it seems that by default each keystorke is being sent out to apple.

## Usage
MacOS High sierra and up, requires to have sip disabled.

Audit current settings
<pre>
bash homecall.sh audit
</pre>

Fix
<pre>
bash homecall.sh fix
</pre>

Optionally you can restore it back to default by
<pre>
bash homecall.sh restore
</pre>

## Contribution
If you find something interesting, please open issue and start disccussion. Feel free to fork and pull request. Any update can bring something that aware macOS user would like to disable.

## Notice
Be careful with modifying and using this script if you are not aware about what it exactly does. You can break you system very easily and make it non bootable. Script has been developed with macOS sierra and tested with High Sierra but i believe it will work just fine with previous versions, it just may throw some warnings due fact that some services has been added recently. It can be safely ignored.

## License
GNU General Public License v3.0
