import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class CosmographView extends WatchUi.WatchFace {
    var width = 0;
    var height = 0;
    var centerX = 0;
    var centerY = 0;
    var radius = 0;
    var innerRadius = 0;
    var rotationOffset = Math.PI / 2.0; // Make 0 the top value instead of pi/2.

    var backgroundColor = null;
    var color1w0 = null;
    var color1w1 = null;
    var color1w2 = null;
    var color1w3 = null;
    var color1w5 = null;
    var color1w6 = null;
    var color1w7 = null;
    var color1w10 = null;

    var ledFontBig = null;
    var ledFontStorre = null;

    var isSmallScreen = null;
    var faceImage = null;
    var small0 = null;
    var small1 = null;
    var small2 = null;
    var small3 = null;
    var small4 = null;

    var isSleeping = false;
    var lastUpdate = null;
    var lastDateUpdate = null;
    var bodyBat = 0;
    var stress = 0;
    var step = 0;
    var sunset = 0;
    var sunrise = 0;
    var sunPosition = 0;
    var battery = 0;
    var batteryInDays = 0;
    var stepGoal = 0;
    var stepGoalPercentage = 0.0;
    var calories = "";
    var distance = "";
    var heartRate = "";
    var date = "";

    var metricU = null;
    var metricR = null;
    var metricD = null;
    var metricL = null;
    var showSecondHand = null;
    var showIcon = null;
    var backgroundColorPref = null;
    var color1 = null;
    var color2 = null;
    var color3 = null;
    var color4 = null;
    var color5 = null;
    var color6 = null;
    var color7 = null;
    var color8 = null;

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
        } else if (width <= 460) {
            isSmallScreen = false;
        }
        small0 = Application.loadResource(Rez.Drawables.small_0);
        small1 = Application.loadResource(Rez.Drawables.small_1);
        small2 = Application.loadResource(Rez.Drawables.small_2);
        small3 = Application.loadResource(Rez.Drawables.small_3);
        small4 = Application.loadResource(Rez.Drawables.small_4);
        ledFontBig = Application.loadResource( Rez.Fonts.id_led_big );
        ledFontStorre = Application.loadResource( Rez.Fonts.id_storre );

        cacheProps();
        setColors();
    }

    function onSettingsChanged() {
        lastUpdate = null;
        cacheProps();
        setColors();
        WatchUi.requestUpdate();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        updateDate();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var now = Time.now().value();
        if(lastUpdate == null or now - lastUpdate > 60) {
            lastUpdate = now;
            updateMetrics();
        }
        if (isSleeping == false) {
            dc.setColor(backgroundColor, backgroundColor);
            dc.clear();
            if (dc has :setAntiAlias ) { dc.setAntiAlias(true); }
            drawClockFace(dc);
            drawProgressBars(dc);
            drawMetrics(dc);
            drawHands(dc);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        lastUpdate = null;
        isSleeping = false;
        cacheProps();
        setColors();
        WatchUi.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isSleeping = true;
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

        var hourColor = color1w2;
        var minuteColor = color1w6;
        var secondColor = color1w0;

        // Draw hour hand
        dc.setColor(hourColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 12);
        drawHand(dc, hourAngle, radius * 0.5, radius * 0.1, 12, hourColor);
        drawHand(dc, hourAngle, radius * 0.4, radius * 0.07, 6, backgroundColor);
        drawHand(dc, hourAngle, radius * 0.08, 0, 12, hourColor);

        // Draw minute hand
        dc.setColor(minuteColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 9);
        drawHand(dc, minuteAngle, radius * 0.6, radius * 0.1, 10, minuteColor);
        drawHand(dc, minuteAngle, radius * 0.56, radius * 0.07, 4, backgroundColor);
        drawHand(dc, minuteAngle, radius * 0.08, 0, 10, minuteColor);
        
        // Draw second hand
        if (showSecondHand) {
            dc.setColor(secondColor, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(centerX, centerY, 5);
            drawHand(dc, secondAngle, radius * 0.85, radius * 0.16, 3, secondColor);
        }

        // Small dark circle on top of needle.
        dc.setColor(color1w7, Graphics.COLOR_TRANSPARENT);
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
        drawProgressBar(dc, coord[0][0], coord[0][1], getValueForCircleMetric(metricD), getTypeForCircleMetric(metricD));
        drawProgressBar(dc, coord[1][0], coord[1][1], getValueForCircleMetric(metricL), getTypeForCircleMetric(metricL));
        drawProgressBar(dc, coord[2][0], coord[2][1], getValueForCircleMetric(metricR), getTypeForCircleMetric(metricR));
    }

    function drawProgressBar(dc, x, y, value, type) {
        // var outerCircleSize = isSmallScreen ? 53 : 63;
        var outerCircleSize = 53;
        // var innerCircleSize = isSmallScreen ? 37 : 53;
        var innerCircleSize = 37;
        var needleLength = isSmallScreen ? 47 : 57;
        var counterNeedleLength = isSmallScreen ? 10 : 10;
        var needleColor = color1w0;
        var max = getMaxForType(type);
        var min = 0;

        dc.setColor(color1w5, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, outerCircleSize);
        dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, innerCircleSize);

        drawMetricFace(dc, x, y, type, outerCircleSize);

        // Calculate the angle
        var range = max - min;
        var relativeValue = value - min;
        var percentage = relativeValue.toFloat() / range.toFloat();
        var angle = Math.toRadians((percentage * 360)) - rotationOffset; // Start at 12 o'clock, clockwise

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
        dc.setColor(color1w7, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 1);
    }

    function drawMetricFace(dc, x, y, type, radius) {
        if (type == 0) {
            dc.drawBitmap(x-radius, y-radius, small0);
        } else if (type == 1) {
            dc.drawBitmap(x-radius, y-radius, small1);
        } else if (type == 2) {
            dc.drawBitmap(x-radius, y-radius, small2);
        } else if (type == 3) {
            dc.drawBitmap(x-radius, y-radius, small3);
        } else if (type == 4) {
            dc.drawBitmap(x-radius, y-radius, small4);
        }
    }

    function drawMetrics(dc) as Void {
        var radiusOffSet = radius * 0.5;
        var xOffSet = 3;
        var x = centerX - xOffSet;
        var y = centerY - radiusOffSet;
        var charSize = 24;

        // Backgrounds.
        dc.setColor(color1w10, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, ledFontBig, "####", Graphics.TEXT_JUSTIFY_CENTER);

        // Values.
        dc.setColor(color1w1, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x+2*charSize, y, ledFontBig, getMetricUValue(), Graphics.TEXT_JUSTIFY_RIGHT);

        // Text.
        dc.setColor(color1w3, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y-13, ledFontStorre, getMetricUText(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    function updateMetrics() as Void {
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory) && (Toybox.SensorHistory has :getStressHistory)) {
            var bbIterator = Toybox.SensorHistory.getBodyBatteryHistory({:period => 1});
            var stIterator = Toybox.SensorHistory.getStressHistory({:period => 1});
            var bb = bbIterator.next();
            var st = stIterator.next();

            if(bb != null) {
                bodyBat = bb.data;
            }
            if(st != null) {
                stress = st.data;
            }
        }
        var monitorInfo = ActivityMonitor.getInfo();
        var activityInfo = Activity.getActivityInfo();
        step = monitorInfo.steps;
        stepGoal = monitorInfo.stepGoal;
        stepGoalPercentage = 100.0 * step / stepGoal;
        calories = monitorInfo.calories.format("%04d");
        var km = monitorInfo.distance / 100000.0; // km / day.
        if (km >= 10) {
            distance = km.format("%.1f");
        } else {
            distance = km.format("%.2f");
        }
        var hrSample = activityInfo.currentHeartRate;
        if (hrSample != null) {
            heartRate = hrSample.format("%04d");
        } else if (ActivityMonitor has :getHeartRateHistory) {
            // Falling back to historical HR from ActivityMonitor
            var hist = ActivityMonitor.getHeartRateHistory(1, /* newestFirst */ true).next();
            if ((hist != null) && (hist.heartRate != ActivityMonitor.INVALID_HR_SAMPLE)) {
                heartRate = hist.heartRate.format("%04d");
            }
        }
        battery = System.getSystemStats().battery;
        batteryInDays = System.getSystemStats().batteryInDays;
    }

    function updateDate() as Void {
        var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        date = today.day_of_week - 1;
    }
    
    /* -------- STATIC FUNCTIONS -------- */
    function setColors() as Void {
        // Default white theme.
        backgroundColor = Graphics.COLOR_BLACK;
        color1w0 = Graphics.COLOR_WHITE;
        color1w2 = Graphics.createColor(255, 225, 225, 225);
        color1w5 = Graphics.createColor(255, 195, 195, 195);
        color1w6 = Graphics.createColor(255, 170, 170, 170);
        color1w7 = Graphics.createColor(255, 155, 155, 155);
        color1w10 = Graphics.createColor(255, 55, 55, 55);

        color1w1 = color1w0;
        color1w3 = color1w2;

        var color = null;
        color = getColorFromString(backgroundColorPref);
        if (color != null) {
            backgroundColor = color;
        }
        color = getColorFromString(color1);
        if (color != null) {
            color1w0 = color;
        }
        color = getColorFromString(color2);
        if (color != null) {
            color1w2 = color;
        }
        color = getColorFromString(color3);
        if (color != null) {
            color1w5 = color;
        }
        color = getColorFromString(color4);
        if (color != null) {
            color1w6 = color;
        }
        color = getColorFromString(color5);
        if (color != null) {
            color1w7 = color;
        }
        color = getColorFromString(color6);
        if (color != null) {
            color1w10 = color;
        }
        color = getColorFromString(color7);
        if (color != null) {
            color1w1 = color;
        }
        color = getColorFromString(color8);
        if (color != null) {
            color1w3 = color;
        }
    }
    
    function cacheProps() as Void {
        metricU = Application.Properties.getValue("metricU");
        metricR = Application.Properties.getValue("metricR");
        metricD = Application.Properties.getValue("metricD");
        metricL = Application.Properties.getValue("metricL");
        showSecondHand = Application.Properties.getValue("showSecondHand");
        showIcon = Application.Properties.getValue("showIcon");
        backgroundColorPref = Application.Properties.getValue("backgroundColor");
        color1 = Application.Properties.getValue("color1");
        color2 = Application.Properties.getValue("color2");
        color3 = Application.Properties.getValue("color3");
        color4 = Application.Properties.getValue("color4");
        color5 = Application.Properties.getValue("color5");
        color6 = Application.Properties.getValue("color6");
        color7 = Application.Properties.getValue("color7");
        color8 = Application.Properties.getValue("color8");

        if (!showIcon) {
            if (isSmallScreen) {
                faceImage = Application.loadResource(Rez.Drawables.face386alt);
            } else {
                faceImage = Application.loadResource(Rez.Drawables.face450alt);
            }
        } else {
            if (isSmallScreen) {
                faceImage = Application.loadResource(Rez.Drawables.face386);
            } else {
                faceImage = Application.loadResource(Rez.Drawables.face450);
            }
        }

    }
    
    function day_name(day_of_week) {
        var names = [
            "SUN",
            "MON",
            "TUE",
            "WED",
            "THU",
            "FRI",
            "SAT",
        ];
        return names[day_of_week];
    }

    function getMetricUText() {
        if (metricU == 0) {
            return "KM TODAY:";
        } else if (metricU == 1) {
            return "DLY CALORIES:";
        } else if (metricU == 2) {
            return "LIVE HR:";
        } else if (metricU == 3) {
            return "BATTERY:";
        } else if (metricU == 4) {
            return "BATTERY:";
        } else if (metricU == 5) {
            return "BODY BATT:";
        } else if (metricU == 6) {
            return "DAY:";
        }
        return "KM TODAY:";
    }

    function getMetricUValue() {
        if (metricU == 0) {
            return distance;
        } else if (metricU == 1) {
            return calories;
        } else if (metricU == 2) {
            return heartRate;
        } else if (metricU == 3) {
            return battery.format("%.1f");
        } else if (metricU == 4) {
            return batteryInDays.format("%02d");
        } else if (metricU == 5) {
            return bodyBat.format("%.1f");
        } else if (metricU == 6) {
            return day_name(date);
        }
        return distance;
    }

    function getTypeForCircleMetric(metric) {
        if (metric == 0) { // Heart Rate
            return 4;
        } else if (metric == 1) { // Week day
            return 2;
        } else if (metric == 2) { // Battery
            return 1;
        } else if (metric == 3) { // Body Battery
            return 1;
        } else if (metric == 4) { // Setp goal
            return 1;
        } else if (metric == 5) { // Stress
            return 1;
        }
        return 3;
    }

    function getValueForCircleMetric(metric) {
        if (metric == 0) { // Heart Rate
            return heartRate.toNumber();
        } else if (metric == 1) { // Week day
            return date;
        } else if (metric == 2) { // Battery
            return battery;
        } else if (metric == 3) { // Body Battery
            return bodyBat;
        } else if (metric == 4) { // Setp goal
            return stepGoalPercentage;
        } else if (metric == 5) { // Stress
            return stress;
        }
        return heartRate.toNumber();
    }

    function getMaxForType(type) {
        if (type == 3) { // Heart Rate
            return 200;
        } else if (type == 2) { // Week day
            return 7;
        } else if (type == 1) { // Battery
            return 100;
        }
        return 100;
    }

    function getColorFromString(color) {
        if (color == null || color.length() == null || color.length() <= 5 || color == "") {
            return null;
        }

        var i = color.find(",");
        if (i == null) {
            return null;
        }

        var j = color.substring(i+1, color.length());
        if (j == null) {
            return null;
        }
        j = j.find(",");
        if (j == null) {
            return null;
        }
        j = i + 1 + j;

        // Parse the components
        var red = color.substring(0, i).toNumber();
        var green = color.substring(i+1, j).toNumber();
        var blue = color.substring(j+1, color.length()).toNumber();

        if (red == null || green == null || blue == null) {
            return null;
        }

        return Graphics.createColor(255, red, green, blue);
    }
}
