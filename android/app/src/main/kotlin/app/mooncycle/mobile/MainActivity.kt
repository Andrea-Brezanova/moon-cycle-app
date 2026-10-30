package app.mooncycle.mobile

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // "Hide app in app switcher": FLAG_SECURE keeps the app's contents out of
        // the recent-apps thumbnail (and out of screenshots) while it is set.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.mooncycle/privacy_shield")
            .setMethodCallHandler { call, result ->
                if (call.method == "setEnabled") {
                    val on = call.arguments as? Boolean ?: false
                    if (on) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
