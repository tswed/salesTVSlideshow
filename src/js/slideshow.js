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
var content;
var advanceSlide;

window.onload = loadPage;


function loadPage() {
    content = document.getElementById('slideFrame');

    readFile("../slideshow.txt");

    content.src = URLs[0];

    displayTime();
    displayTitle(0);

    transitionTime = displayTimes[siteIndex] * 100;

    advanceSlide = setTimeout(changeSlide, transitionTime);
}

function displayTime() {
    var currentDate = new Date();
    var clock = document.getElementById('clock');
    var hours = currentDate.getHours() ? currentDate.getHours() - 12 : currentDate.getHours();
    var minutes = currentDate.getMinutes() < 10 ? "0" + currentDate.getMinutes() : currentDate.getMinutes();
    var am_pm = currentDate.getHours() >= 12 ? "PM" : "AM";

    hours = hours < 10 ? "0" + hours : hours;

    clock.innerHTML = hours + ":" + minutes + " " + am_pm;
}

function changeSlide() {
    content.src = URLs[++siteIndex];
    displayTitle(siteIndex);

    if (siteIndex > URLs.length) {
        siteIndex = -1;
    }

    transitionTime = displayTimes[siteIndex] * 100;
    nextSlide();
}

function displayTitle(siteIndex) {
    document.getElementById("slideTitle").innerHTML = slideTitles[siteIndex];
}

function nextSlide() {
    advanceSlide = setTimeout(changeSlide, transitionTime);
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

