import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class CosmographApp extends Application.AppBase {

    var mView;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        mView = new CosmographView();
        onSettingsChanged();
        return [ mView ];
    }

    function onSettingsChanged() as Void {
        mView.onSettingsChanged();
        WatchUi.requestUpdate();
    }

}

function getApp() as CosmographApp {
    return Application.getApp() as CosmographApp;
}