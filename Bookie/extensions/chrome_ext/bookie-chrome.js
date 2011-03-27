/*jslint eqeqeq: false, browser: true, debug: true, onevar: true, plusplus: false, newcap: false, */
/*global $: false, window: false, self: false, escape: false, mor: false, sprintf: false, chrome: false, localStorage: false, jQuery: false */

/* chrome-extension-specific bookie functionality */

var bookie = (function (module, $) {

    // PRIVATE

    /**
     * This will call a shared function that maps data to the ui form
     * The specifics here is getting the tab info from Chrome vs FF
     *
     */
    populateForm = function () {
        chrome.tabs.getSelected(null, populateFormBase);
    };

    // provide helpers for dealing with notifications from events fired through
    // the plugin. I think at some point we really want to do something to map
    // these to generic notifications and provide these more as a chrome
    // specific mapper
    module.ui.badge = {
        'clear': function () {
            chrome.browserAction.setBadgeText({text: ''});
        },

        'set': function (text, bgcolor) {
            if (bgcolor !== undefined) {
                chrome.browserAction.setBadgeBackgroundColor({color: bgcolor});
            }

            chrome.browserAction.setBadgeText({text: text});
        },

        // colors must be defined in the RGB syntax for the chrome api to work
        'colors': {
            'green': [15, 232, 12, 255]
        }
    };

    return module;

})(bookie || {}, jQuery);