# attendance

A new Flutter project.

<service
    android:name="com.flutter_phone_state.BackgroundService"
    android:enabled="true"
    android:exported="true" />

<receiver
    android:name="com.flutter_phone_state.BootReceiver"
    android:enabled="true"
    android:exported="true">
<intent-filter>
<action android:name="android.intent.action.BOOT_COMPLETED" />
</intent-filter>
</receiver>
