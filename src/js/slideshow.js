/**
 * Created by tswed on 9/3/16.
 */

var siteIndex = 0;
var URLs = [];
var displayTimes = [];
var transitionTime = 60000;

var menu;
var content;
var currentDate = new Date();
var isAfterHours;
var advanceSlide;

window.onload = loadPage;

function loadPage() {
    content = document.getElementById('slideFrame');
    menu = document.getElementById('menu');

    getURLs("../../slideshow.txt");
    content.src = URLs[0];

    transitionTime = displayTimes[siteIndex] * 1000;

    advanceSlide = setTimeout(changeSlide, transitionTime);
}

function changeSlide() {
    isAfterHours = checkTime();

    if (isAfterHours) {
        pauseShow();
    }

    content.src = URLs[++siteIndex];

    if (siteIndex > URLs.length) {
        siteIndex = -1;
    }

    transitionTime = displayTimes[siteIndex] * 1000;
    nextSlide();
}

function pauseShow() {
    window.clearTimeout(advanceSlide);
}

function nextSlide() {
    advanceSlide = setTimeout(changeSlide, transitionTime);
}

function checkTime() {
    if (currentDate.getHours() >= 11 && currentDate.getHours() < 14) {
        return true;
    }
    return false;
}

function getURLs(file) {
    {
        var rawFile = new XMLHttpRequest();
        rawFile.open("GET", file, false);

        rawFile.onreadystatechange = function ()
        {
            if(rawFile.readyState === 4) {

                if (rawFile.status === 200 || rawFile.status == 0) {

                    var allText = rawFile.responseText;
                    allText = allText.replace(/[\n\r\s]/g, '');

                    URLs = allText.split(';');

                    for (var i=0; i < URLs.length; i++) {
                        var commaIndex = URLs[i].lastIndexOf(",");

                        displayTimes[i] = URLs[i].slice(commaIndex + 1, URLs[i].length);
                        URLs[i] = URLs[i].substring(0, commaIndex);
                    }
                }
            } else {
                alert("File not read");
            }
        };
        rawFile.send(null);
    }
}
