import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;

class CosmographView extends WatchUi.WatchFace {
    var width = 0;
    var height = 0;
    var centerX = 0;
    var centerY = 0;
    var radius = 0;
    var innerRadius = 0;
    var rotationOffset = Math.PI / 2.0; // Make 0 the top value instead of pi/2.

    var backgroundColor = null;
    var palette1 = null;
    var palette1alt = null;
    var palette1dark = null;
    var palette1darker = null;
    var palette1light = null;
    var palette2 = null;
    var palette2dark = null;

    var isSmallScreen = null;
    var faceImage = null;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        width = dc.getWidth();
        height = dc.getHeight();
        centerX = width / 2.0;
        centerY = width / 2.0;
        radius = centerY;
        if (centerX <= centerY) { // Math.min
            radius = centerX;
        }

        if (width <= 400) {
            isSmallScreen = true;
            faceImage = Application.loadResource(Rez.Drawables.face386);
        } else if (width <= 460) {
            isSmallScreen = false;
            faceImage = Application.loadResource(Rez.Drawables.face450);
        }
        setColors();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(backgroundColor, backgroundColor);
        dc.clear();
        if (dc has :setAntiAlias ) { dc.setAntiAlias(true); }
        drawClockFace(dc);
        
        drawProgressBars(dc);

        drawHands(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

    /* -------- AUX FUNCTIONS -------- */
    function drawClockFace(dc) as Void {
        dc.drawBitmap(0, 0, faceImage);
    }


    function drawHands(dc) as Void {
        var time = System.getClockTime();
        var hours = time.hour % 12;
        var minutes = time.min;
        var seconds = time.sec;

        // Calculate hand angles
        var hourAngle = (hours + minutes / 60.0) * Math.PI / 6.0;
        var minuteAngle = minutes * Math.PI / 30.0;
        var secondAngle = seconds * Math.PI / 30.0;

        // Draw hour hand
        dc.setColor(palette1, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 12);
        drawHand(dc, hourAngle, radius * 0.5, radius * 0.1, 12, palette1);
        drawHand(dc, hourAngle, radius * 0.4, radius * 0.07, 6, backgroundColor);
        drawHand(dc, hourAngle, radius * 0.08, 0, 12, palette1);

        // Draw minute hand
        dc.setColor(palette1alt, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 9);
        drawHand(dc, minuteAngle, radius * 0.6, radius * 0.1, 10, palette1alt);
        drawHand(dc, minuteAngle, radius * 0.56, radius * 0.07, 4, backgroundColor);
        drawHand(dc, minuteAngle, radius * 0.08, 0, 10, palette1alt);
        
        // Draw second hand
        dc.setColor(palette1light, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 5);
        drawHand(dc, secondAngle, radius * 0.85, radius * 0.16, 3, palette1light);

        // Small dark circle on top of needle.
        dc.setColor(palette1dark, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 1);
    }

    function drawHand(dc, angle, length, conterWeightLen, width, color) as Void {
        var endX = centerX + (length * Math.cos(angle - rotationOffset));
        var endY = centerY + (length * Math.sin(angle - rotationOffset));
        dc.setPenWidth(width);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(centerX, centerY, endX, endY);

        var conterWeightEndX = centerX + (conterWeightLen * Math.cos(angle - rotationOffset  - Math.PI));
        var conterWeightEndY = centerY + (conterWeightLen * Math.sin(angle - rotationOffset  - Math.PI));
        dc.drawLine(centerX, centerY, conterWeightEndX, conterWeightEndY);
    }

    function drawProgressBars(dc) as Void {
        var radiusOffSet = radius * 0.4;
        var xOffSet = 3;
        var yOffSet = isSmallScreen ? 9 : 13;
        var coord = [
            [centerX - xOffSet, centerY + radiusOffSet],
            [centerX - xOffSet - radiusOffSet, centerY - yOffSet],
            [centerX - xOffSet + radiusOffSet, centerY - yOffSet]
        ];

        // Draw the progress bars
        drawProgressBar(dc, coord[0][0], coord[0][1], 0, 100, 34);
        drawProgressBar(dc, coord[1][0], coord[1][1], 0, 100, 75);
        drawProgressBar(dc, coord[2][0], coord[2][1], 0, 100, 50);
    }

    function drawProgressBar(dc, x, y, max, min, value) {
        var outerCircleSize = isSmallScreen ? 53 : 63;
        var innerCircleSize = isSmallScreen ? 37 : 53;
        var needleLength = isSmallScreen ? 47 : 57;
        var counterNeedleLength = isSmallScreen ? 10 : 10;
        var useAltColor = true;
        var needleColor = useAltColor ? palette1light : palette2;

        dc.setColor(palette1alt, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, outerCircleSize);
        dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, innerCircleSize);

        // Calculate the angle
        var range = max - min;
        var relativeValue = value - min;
        var percentage = relativeValue.toFloat() / range.toFloat();
        var angle = Math.toRadians(270 - (percentage * 360)); // Start at 12 o'clock, clockwise

        // Calculate the needle endpoint
        var needleEndX = x + needleLength * Math.cos(angle);
        var needleEndY = y + needleLength * Math.sin(angle);
        
        var counterNeedleEndX = x + (counterNeedleLength) * Math.cos(angle - Math.PI);
        var counterNeedleEndY = y + (counterNeedleLength) * Math.sin(angle - Math.PI);

        // Draw the needle
        dc.setColor(needleColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(x, y, needleEndX, needleEndY);
        dc.setPenWidth(3);
        dc.drawLine(x, y, counterNeedleEndX, counterNeedleEndY);
        dc.fillCircle(x, y, 3);
        dc.setColor(palette1dark, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 1);
    }
    
    /* -------- STATIC FUNCTIONS -------- */
    function setColors() as Void {
        backgroundColor = Graphics.COLOR_BLACK;
        
        palette2 = Graphics.COLOR_RED;
        palette2dark = Graphics.COLOR_DK_RED;
       
        // White.
        palette1 = Graphics.createColor(255, 225, 225, 225);
        palette1alt = Graphics.createColor(255, 195, 195, 195);
        palette1dark = Graphics.createColor(255, 155, 155, 155);
        palette1darker = Graphics.createColor(255, 55, 55, 55);
        palette1light = Graphics.COLOR_WHITE;
    }
}
