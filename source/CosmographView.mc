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

    var hasVectorFont = false;
    var font20 = null;
    var font20Height = 0;
    var xtinyFont = null;

    var backgroundColor = null;
    var palette1 = null;
    var palette1dark = null;
    var palette1darker = null;
    var palette1light = null;
    var palette2 = null;
    var palette2dark = null;

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
        innerRadius = radius * 0.75;

        if (Graphics has :getVectorFont) {
            hasVectorFont = true;
            font20 = Graphics.getVectorFont({:face=>["RobotoRegular"], :size=>20});
            font20Height = dc.getFontHeight(font20);
        } else {
            hasVectorFont = false;
        }
        xtinyFont = Graphics.FONT_XTINY;
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
        // Draw 60 ticks
        var tickLength = radius * 0.07;
        var tickWidth = 2; // Default tick width
        for (var i = 0; i < 60; i++) {
            var angle = i * Math.PI / 30.0 - rotationOffset; // Convert tick number to radians with 90 dregrees rotation
            
            if (hasVectorFont && (i == 29 || i == 30 || i ==  31)) { // Skip these for making room.
                continue;
            } else if (hasVectorFont && i % 5 == 0) { // Draw numbers at 5, 15, 25, 35, 45, 55.
                var number = i;
                var text = number.format("%02d");
                if (i == 0) {
                    text = "60";
                }
                dc.setColor(palette1, Graphics.COLOR_TRANSPARENT);
                if (i == 20 || i == 25 || i == 35 || i == 40) {
                    dc.drawRadialText(centerX, centerY, font20, text, Graphics.TEXT_JUSTIFY_CENTER, radiansToDegrees(angle + 2*Math.PI), radius - 4, 1);
                } else {
                    dc.drawRadialText(centerX, centerY, font20, text, Graphics.TEXT_JUSTIFY_CENTER, radiansToDegrees(angle + 2*Math.PI), radius - font20Height + 4, 0);
                }
            } else {
                var startX = centerX + (radius * Math.cos(angle));
                var startY = centerY + (radius * Math.sin(angle));
                var endX = centerX + ((radius - tickLength) * Math.cos(angle));
                var endY = centerY + ((radius - tickLength) * Math.sin(angle));

                dc.setPenWidth(tickWidth);
                dc.setColor(palette1, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(startX, startY, endX, endY);
            }
        }
        
        if (hasVectorFont) {
            // Text at the bottom.
            dc.setColor(palette1, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            dc.drawText(centerX, height - font20Height - 1, font20, "swiss", Graphics.TEXT_JUSTIFY_CENTER);
        }
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

        // Draw center dot
        dc.setColor(palette1dark, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 10);

        // Draw hour hand
        drawHand(dc, hourAngle, radius * 0.6, radius * 0.08, 12, palette1dark);
        drawHand(dc, hourAngle, radius * 0.9, radius * 0.1, 6, backgroundColor);
        drawHand(dc, hourAngle, radius * 0.5, radius * 0.08, 12, palette1dark);
        drawHand(dc, hourAngle, radius * 0.3, radius * 0.1, 6, backgroundColor);
        // Draw minute hand
        drawHand(dc, minuteAngle, radius * 0.8, radius * 0.08, 10, palette1dark);
        drawHand(dc, minuteAngle, radius * 0.9, radius * 0.1, 4, backgroundColor);
        drawHand(dc, minuteAngle, radius * 0.6, radius * 0.08, 10, palette1dark);
        drawHand(dc, minuteAngle, radius * 0.3, radius * 0.1, 4, backgroundColor);
        // Draw second hand
        drawHand(dc, secondAngle, radius * 0.87, radius * 0.13, 3, palette1light);

        // Small red circle colors.
        dc.setColor(palette1light, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 5);
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
    
    /* -------- STATIC FUNCTIONS -------- */
    function radiansToDegrees(angle) { // take a radian and return a degree.
        return angle * 180.0 / Math.PI * -1; // * -1 because garmin is inverted for some reason.
    }

    function degreesToRadians(angle) { // take a degree and return a radian.
        return angle * Math.PI / 180.0 * -1;
    }

    function setColors() as Void {
        backgroundColor = Graphics.COLOR_BLACK;
        
        palette2 = Graphics.COLOR_RED;
        palette2dark = Graphics.COLOR_DK_RED;
       
        // White.
        palette1 = Graphics.COLOR_WHITE;
        palette1dark = Graphics.createColor(255, 155, 155, 155);
        palette1darker = Graphics.createColor(255, 55, 55, 55);
        palette1light = Graphics.COLOR_WHITE;
    }
}
