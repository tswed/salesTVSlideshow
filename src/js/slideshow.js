/**
 * Created by tswed on 9/3/16.
 */

var URLs = [];
var singleSlide = [];
var siteIndex = 0;
var allSlideInfo = [];
var displayTimes = [];
var slideTitles = [];
var transitionTime = 60000;
var menu;
var content;
var currentDate = new Date();
var isDuringDay;
var advanceSlide;

window.onload = loadPage;

function loadPage() {
    content = document.getElementById('slideFrame');
    menu = document.getElementById('menu');

    readFile("../slideshow.txt");

    content.src = URLs[0];

    displayTitle(0);

    transitionTime = displayTimes[siteIndex] * 1000;

    advanceSlide = setTimeout(changeSlide, transitionTime);
}

function changeSlide() {
    isDuringDay = checkTime();

    if (isDuringDay) {
        content.src = URLs[++siteIndex];
        displayTitle(siteIndex);

        if (siteIndex > URLs.length) {
            siteIndex = -1;
        }

        transitionTime = displayTimes[siteIndex] * 1000;
        nextSlide();
    }
    else {
        setTimeout(changeSlide, 0);
    }
}

function displayTitle(siteIndex) {
    document.getElementById("slideTitle").innerHTML = slideTitles[siteIndex];
}

function nextSlide() {
    advanceSlide = setTimeout(changeSlide, transitionTime);
}

function checkTime() {
    if (currentDate.getHours() >= 8 && currentDate.getHours() <= 17) {
        return true;
    }
    return false;
}

function readFile(file) {
    {
        var rawFile = new XMLHttpRequest();
        rawFile.open("GET", file, false);

        rawFile.onreadystatechange = function ()
        {
            if(rawFile.readyState === 4) {

                if (rawFile.status === 200 || rawFile.status == 0) {

                    var allText = rawFile.responseText;

                    allText = allText.replace(/[\n\r]/g, '');

                    allSlideInfo = allText.split(';');

                    for (var i = 0; i < allSlideInfo.length; i++) {
                        singleSlide = allSlideInfo[i].split("|");
                        loadSlideShow(singleSlide, i);
                    }
                }
            } else {
                alert("File not read");
            }
        };
        rawFile.send(null);
    }
}

function loadSlideShow(singleSlide, i) {
    URLs[i] = singleSlide[0];
    slideTitles[i] = singleSlide[1];
    displayTimes[i] = singleSlide[2];
}

