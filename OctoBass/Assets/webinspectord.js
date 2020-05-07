document.onreadystatechange = function () {


    'use strict';


    // A simple hash function from Java.
    function DoJavaHash(str) {
        var hash = 0, i, chr;
        for (i = 0; i < str.length; i++) {
            chr = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + chr;
            hash |= 0; // Convert to 32 bit integer
        }
        return hash;
    }
    
    // The WebKit report function.
    function DoReport(obj) {
        window.webkit.messageHandlers._$webinspectord_report.postMessage(obj);
    }


    if (document.readyState !== 'complete') {
        console.debug('document not ready');
        return;
    }
    console.debug('document ready');


    // Performance begin
    var t0 = performance.now();


    // Build report
    var cnt = 0;
    var report = '';
    report += '13,';
    var video_DOMs = document.getElementsByTagName('video');
    report += video_DOMs.length.toString() + ',';
    report += document.images.length.toString() + ',';
    report += document.embeds.length.toString() + ',';
    report += document.styleSheets.length.toString() + ',';
    report += document.scripts.length.toString() + ',';
    report += document.links.length.toString() + ',';
    report += document.forms.length.toString() + ',';
    cnt += 8;


    // DOM count
    report += document.all.length.toString() + ',';
    cnt++;


    // Page URL (no arguments)
    var page_prot = window.location.protocol;
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


    // Document title (< 64 bytes)
    report += DoJavaHash('title='
                         + document.title.slice(0, 64)) + ',';
    cnt++;


    // Inner Text (< 256 bytes)
    report += DoJavaHash('innerText=' + document.body.innerText.slice(0, 256)) + ',';
    cnt++;


    // Video detection
    for (var video_DOM of video_DOMs) {
        report += DoJavaHash(
            'video;.src=' + video_DOM.currentSrc
            + ';.videoWidth=' + video_DOM.videoWidth.toString()
            + ';.videoHeight=' + video_DOM.videoHeight.toString()
            + ';.duration=' + Math.round(video_DOM.duration).toString()
        ) + ',';
        cnt++;
    }


    // Image detection
    for (var image_DOM of document.images) {
        report += DoJavaHash(
            'image;.src=' + image_DOM.currentSrc
            + ';.width=' + image_DOM.width.toString()
            + ';.height=' + image_DOM.height.toString()
        ) + ',';
        cnt++;
    }


    // Embeds
    for (var embed_DOM of document.embeds) {
        report += DoJavaHash(
            'embed;.src=' + embed_DOM.src
            + ';.type=' + embed_DOM.type
            + ';.width=' + embed_DOM.width
            + ';.height=' + embed_DOM.height
        ) + ',';
        cnt++;
    }


    // Stylesheets
    for (var style_DOM of document.styleSheets) {
        if (style_DOM.href === null) {
            report += DoJavaHash('stylesheet;.href=null;.count(.rules)=' + style_DOM.rules.length.toString()) + ',';
        } else {
            // We cannot get rules from external CSS due to CORS.
            report += DoJavaHash('stylesheet;.href=' + style_DOM.href) + ',';
        }
        cnt++;
    }


    // Scripts
    for (var script_DOM of document.scripts) {
        if (script_DOM.src === null || script_DOM.src.length === 0) {
            report += DoJavaHash('script;.src=null') + ',';
        } else {
            report += DoJavaHash('script;.src=' + script_DOM.src) + ',';
        }
        cnt++;
    }


    // Links
    for (var link_DOM of document.links) {
        report += DoJavaHash(
            'link;.href=' + link_DOM.href
            + ';.id=' + link_DOM.id
            + ';.name=' + link_DOM.name
            + ';.className=' + link_DOM.className
        ) + ',';
        cnt++;
    }


    // Forms
    for (var form_DOM of document.forms) {

        var count_elements = form_DOM.elements.length;
        report += DoJavaHash(
            'form;.id=' + form_DOM.id
            + ';.action=' + form_DOM.action
            + ';.method=' + form_DOM.method
            + ';.count(.elements)=' + count_elements.toString()
        ) + ',';
        cnt++;

        report += count_elements.toString() + ',';
        cnt++;

        for (var element_DOM of form_DOM.elements) {
            report += DoJavaHash(
                element_DOM.tagName + ';.type=' + element_DOM.type
                + ';.id=' + element_DOM.id
                + ';.name=' + element_DOM.name
            ) + ',';
            cnt++;
        }

    }


    // Termination
    report = (cnt + 2).toString() + ',' + report + '0';


    // Print report
    console.debug(report);
    DoReport(report);


    // Performance end
    var t1 = performance.now();
    console.debug(`took ${t1 - t0} ms.`);


};

