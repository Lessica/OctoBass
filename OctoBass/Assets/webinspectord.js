// ==UserScript==
// @name         OctoBass Analytics
// @namespace    OctoBass
// @version      0.1
// @description  Mobile advertisement inspector.
// @author       Who cares?
// @match        https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo/related
// @grant        unsafeWindow
// ==/UserScript==


(function () {

    'use strict';

    function isWKWebView() {
        return window.webkit !== undefined || typeof(unsafeWindow) !== 'undefined';
    }

    function onDocumentReady(event) {


        /* A simple hash function from Java. */
        function DoJavaHash(str) {
            var hash = 0, i, chr;
            for (i = 0; i < str.length; i++) {
                chr = str.charCodeAt(i);
                hash = ((hash << 5) - hash) + chr;
                hash |= 0; // Convert to 32 bit integer
            }
            return hash;
        }


        /* Iterate all nodes recursively. */
        function DoIterateNodes(node, level = 0, report = '') {
            report += level.toString() + ':' + node.nodeName.toLowerCase() + ',';
            var nodes = node.childNodes;
            for (var i = 0; i < nodes.length; i++) {
                if (!nodes[i]) {
                    continue;
                }
                if (nodes[i].childNodes.length > 0) {
                    report += DoIterateNodes(nodes[i], level + 1);
                }
            }
            return report;
        }


        /* The WebKit report function. */
        function DoWebKitReport(obj) {
            // https://developer.apple.com/documentation/webkit/wkusercontentcontroller/1537172-addscriptmessagehandler?language=objc
            window.webkit.messageHandlers._$webinspectord_report.postMessage(obj);
        }


        /* The WebKit media notification function. */
        function DoWebKitNotifyMediaStatus(e) {
            if (e.target) {
                window.webkit.messageHandlers._$webinspectord_notify_media_status.postMessage({
                    'type': e.target.tagName.toLowerCase(),
                    'src': e.target.currentSrc,
                    'paused': e.target.paused,
                    'ended': e.target.ended,
                    'currentTime': e.target.currentTime,
                    'duration': e.target.duration,
                });
            }
        }


        /* Legacy media notification function. */
        function DoLegacyNotifyMediaStatus(e) {
            if (e.target) {
                window.location.href = 'webinspectord://notify/media_status?type=' + e.target.tagName.toLowerCase()
                    + '&src=' + encodeURIComponent(e.target.currentSrc)
                    + '&paused=' + e.target.paused.toString()
                    + '&ended=' + e.target.ended.toString()
                    + '&currentTime=' + e.target.currentTime.toString()
                    + '&duration=' + e.target.duration.toString();
            }
        }


        /* Only works when the document is ready. */
        if (document.readyState !== 'complete') {
            console.debug('document not ready');
            return;
        }
        console.debug('document ready');


        /* Some helper functions. */
        const theWindow = typeof(unsafeWindow) !== 'undefined' ? unsafeWindow : window;

        /* Get element by selector */
        // https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector
        //document.querySelector(selector)

        /* Get element by point (x, y) */
        // https://developer.mozilla.org/en-US/docs/Web/API/DocumentOrShadowRoot/elementFromPoint
        //document.elementFromPoint(x, y)

        /**
         * Highlight DOM element with random color.
         * @param el The element to be highlighted.
         */
        function highlightElement(el) {

            if (el === null) {
                return;
            }

            function getRandomColor() {
                const letters = '0123456789ABCDEF';
                var color = '#';
                for (var i = 0; i < 6; i++) {
                    color += letters[Math.floor(Math.random() * 16)];
                }
                return color;
            }

            var shouldHighlight = true;

            if (typeof highlightElement.highlightedElement !== 'undefined') {
                const prevEl = highlightElement.highlightedElement;
                if (prevEl !== el) {
                    prevEl.style.outline = '';
                    prevEl.style.backgroundColor = '';
                } else {
                    shouldHighlight = false;
                }
            }

            if (shouldHighlight) {
                highlightElement.highlightedElement = el;

                const color = getRandomColor();
                el.style.outline = color + ' solid 1px';
                el.style.backgroundColor = color + '45';
            }

        }

        /**
         * Scroll a DOM element to visible area.
         * @param el The element to be scrolled.
         */
        function scrollToElement(el) {

            // Non-standard: https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoViewIfNeeded
            if (typeof el.scrollIntoViewIfNeeded === 'function') {
                el.scrollIntoViewIfNeeded();
                return;
            }

            /**
             * Check if an element is visible in current view-port.
             * @param el The element to be tested.
             * @returns A boolean value indicates the visible status.
             */
            function isInViewport(el) {
                const bounding = el.getBoundingClientRect();
                return (
                    bounding.top >= 0 &&
                    bounding.left >= 0 &&
                    bounding.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
                    bounding.right <= (window.innerWidth || document.documentElement.clientWidth)
                );
            }

            if (el === null) {
                return;
            }

            if (isInViewport(el)) {
                return;
            }

            // Experimental: https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView
            el.scrollIntoView({
                'block': 'nearest',
                'inline': 'nearest',
            }); // the same as: `el.scrollIntoView(true);`

        }

        /**
         * Get the rect of a DOM element.
         * @param el An element.
         * @returns The rect of the element.
         */
        function getElementRect(el) {

            if (el === null) {
                return null;
            }

            // https://developer.mozilla.org/en-US/docs/Web/API/Element/getBoundingClientRect
            const rect = el.getBoundingClientRect();
            return [rect.x, rect.y, rect.width, rect.height];

        }

        /**
         * Get the selector of a DOM element.
         * @param el An element.
         * @returns The selector of the element.
         */
        function getElementSelector(el) {

            if (el === null) {
                return null;
            }

            var stack = [];
            while (el.parentNode != null) {
                var sibCount = 0;
                var sibIndex = 0;
                for (var i = 0; i < el.parentNode.childNodes.length; i++) {
                    var sib = el.parentNode.childNodes[i];
                    if (sib.nodeName == el.nodeName) {
                        if (sib === el) {
                            sibIndex = sibCount;
                        }
                        sibCount++;
                    }
                }
                if (el.hasAttribute('id') && el.id != '') {
                    stack.unshift(el.nodeName.toLowerCase() + '#' + el.id);
                } else if (sibCount > 1) {
                    stack.unshift(el.nodeName.toLowerCase() + ':nth-of-type(' + (sibIndex + 1) + ')');
                } else {
                    stack.unshift(el.nodeName.toLowerCase());
                }
                el = el.parentNode;
            }

            return stack.slice(1).join(' > '); // removes the html element

        }

        theWindow._$highlightElement = highlightElement;
        theWindow._$scrollToElement = scrollToElement;
        theWindow._$getElementRect = getElementRect;
        theWindow._$getElementSelector = getElementSelector;


        /* Media events */
        // https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener
        ['play', 'ended', 'pause'].forEach( (evt) => { document.addEventListener(evt, isWKWebView() ? DoWebKitNotifyMediaStatus : DoLegacyNotifyMediaStatus, true); } );


        /* Performance begin */
        // https://developer.mozilla.org/en-US/docs/Web/API/Performance/now
        const t0 = performance.now();


        /* Build report */
        var cnt = 0;
        var report = '';
        report += '15,';
        const video_DOMs = document.getElementsByTagName('video');
        report += video_DOMs.length.toString() + ',';
        const audio_DOMs = document.getElementsByTagName('audio');
        report += audio_DOMs.length.toString() + ',';
        report += document.images.length.toString() + ',';
        report += document.embeds.length.toString() + ',';
        report += document.styleSheets.length.toString() + ',';
        report += document.scripts.length.toString() + ',';
        report += document.links.length.toString() + ',';
        report += document.forms.length.toString() + ',';
        cnt += 9;


        /* DOM count */
        report += document.all.length.toString() + ',';
        cnt++;


        /* DOM levels */
        const node_levels = DoIterateNodes(document);
        report += DoJavaHash(node_levels) + ',';
        cnt++;


        /* Page URL (no arguments) */
        const page_prot = window.location.protocol;
        if (page_prot == 'http:' || page_prot == 'https:') {
            report += DoJavaHash('origin='
                                 + window.location.origin) + ',';
            report += DoJavaHash('path='
                                 + window.location.pathname) + ',';
        } else {
            // ignore local file://
            report += '0,0,';
        }
        cnt += 2;


        /* Document title (< 64 bytes) */
        report += DoJavaHash('title='
                             + document.title.slice(0, 64)) + ',';
        cnt++;


        /* Inner Text (< 256 bytes) */
        report += DoJavaHash('innerText=' + document.body.innerText.slice(0, 256)) + ',';
        cnt++;


        /* Video detection */
        for (let video_DOM of video_DOMs) {

            /* Video attributes */
            video_DOM.setAttribute('autoplay', true);
            video_DOM.setAttribute('playsinline', true);

            /* Video report */
            report += DoJavaHash(
                'video;.src=' + video_DOM.currentSrc
                + ';.videoWidth=' + video_DOM.videoWidth.toString()
                + ';.videoHeight=' + video_DOM.videoHeight.toString()
                + ';.duration=' + Math.round(video_DOM.duration).toString()
            ) + ',';
            cnt++;

        }


        /* Audio detection */
        for (let audio_DOM of audio_DOMs) {

            /* Audio report */
            report += DoJavaHash(
                'audio;.src=' + audio_DOM.currentSrc
                + ';.duration=' + Math.round(audio_DOM.duration).toString()
            ) + ',';
            cnt++;

        }


        /* Image detection */
        for (let image_DOM of document.images) {
            report += DoJavaHash(
                'image;.src=' + image_DOM.currentSrc
                + ';.naturalWidth=' + Math.round(image_DOM.naturalWidth).toString()
                + ';.naturalHeight=' + Math.round(image_DOM.naturalHeight).toString()
            ) + ',';
            cnt++;
        }


        /* Embeds */
        for (let embed_DOM of document.embeds) {
            report += DoJavaHash(
                'embed;.src=' + embed_DOM.src
                + ';.type=' + embed_DOM.type
                + ';.width=' + Math.round(embed_DOM.width).toString()
                + ';.height=' + Math.round(embed_DOM.height).toString()
            ) + ',';
            cnt++;
        }


        /* Stylesheets */
        for (let style_DOM of document.styleSheets) {
            if (style_DOM.href === null) {
                report += DoJavaHash('stylesheet;.href=null;.count(.rules)=' + style_DOM.rules.length.toString()) + ',';
            } else {
                // We cannot get rules from external CSS due to CORS.
                report += DoJavaHash('stylesheet;.href=' + style_DOM.href) + ',';
            }
            cnt++;
        }


        /* Scripts */
        for (let script_DOM of document.scripts) {
            if (script_DOM.src === null || script_DOM.src.length === 0) {
                report += DoJavaHash('script;.src=null') + ',';
            } else {
                report += DoJavaHash('script;.src=' + script_DOM.src) + ',';
            }
            cnt++;
        }


        /* Links */
        for (let link_DOM of document.links) {
            report += DoJavaHash(
                'link;.href=' + link_DOM.href
                + ';.id=' + link_DOM.id
                + ';.name=' + link_DOM.name
                + ';.className=' + link_DOM.className
            ) + ',';
            cnt++;
        }


        /* Forms */
        for (let form_DOM of document.forms) {

            const count_elements = form_DOM.elements.length;
            report += DoJavaHash(
                'form;.id=' + form_DOM.id
                + ';.action=' + form_DOM.action
                + ';.method=' + form_DOM.method
                + ';.count(.elements)=' + count_elements.toString()
            ) + ',';
            cnt++;

            report += count_elements.toString() + ',';
            cnt++;

            for (let element_DOM of form_DOM.elements) {
                report += DoJavaHash(
                    element_DOM.tagName.toLowerCase() + ';.type=' + element_DOM.type
                    + ';.id=' + element_DOM.id
                    + ';.name=' + element_DOM.name
                ) + ',';
                cnt++;
            }

        }


        /* Termination */
        report = (cnt + 2).toString() + ',' + report + '0';


        /* Performance end */
        const t1 = performance.now();
        console.debug(`took ${t1 - t0} ms.`);


        /* Print report */
        console.debug(node_levels);
        console.debug(report);
        if (window.webkit !== undefined) {
            DoWebKitReport(report);
            return;
        }

        return report;


    }

    if (self === top && document.readyState === 'complete') {
        return onDocumentReady();
    } else if (isWKWebView()) {
        document.addEventListener('readystatechange', onDocumentReady);
    }

})();

