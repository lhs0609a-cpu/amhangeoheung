package com.amhangeoheung.amhangeoheung_app

import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.amhangeoheung/location"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isMockLocationEnabled" -> {
                    result.success(isMockLocationEnabled())
                }
                "isLocationSpoofed" -> {
                    result.success(isLocationSpoofed())
                }
                "getMockLocationApps" -> {
                    result.success(getMockLocationApps())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Mock Location 설정이 활성화되어 있는지 확인
     */
    private fun isMockLocationEnabled(): Boolean {
        return try {
            // 방법 1: 개발자 옵션에서 Mock Location 앱이 설정되어 있는지 확인
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val mockLocationApp = Settings.Secure.getString(
                    contentResolver,
                    Settings.Secure.MOCK_LOCATION
                )
                !mockLocationApp.isNullOrEmpty()
            } else {
                // Android 6.0 미만
                @Suppress("DEPRECATION")
                Settings.Secure.getInt(
                    contentResolver,
                    Settings.Secure.ALLOW_MOCK_LOCATION,
                    0
                ) != 0
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 현재 위치가 스푸핑된 것인지 확인
     */
    private fun isLocationSpoofed(): Boolean {
        return try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager

            // GPS Provider 확인
            val gpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
            if (!gpsEnabled) {
                return false // GPS가 꺼져있으면 체크 불가
            }

            // Mock Location 앱 설치 여부 확인
            val mockAppsInstalled = checkForMockLocationApps()
            if (mockAppsInstalled) {
                return true
            }

            // Mock location 설정 확인
            isMockLocationEnabled()
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 알려진 Mock Location 앱이 설치되어 있는지 확인
     */
    private fun checkForMockLocationApps(): Boolean {
        val knownMockApps = listOf(
            "com.lexa.fakegps",
            "com.incorporateapps.fakegps.fre",
            "com.fakegps.mock",
            "com.blogspot.newapphorizons.fakegps",
            "de.robv.android.xposed.installer",
            "com.byterev.hexisedmocklocations",
            "com.devadvance.fakelocationgps",
            "com.dansoftware.fakelocationpro",
            "com.evezzon.fakegps",
            "com.fakegps.route.pro",
            "org.hola.gpslocation",
            "com.lkr.fakelocation",
            "com.gsmartstudio.fakegps",
            "com.fakegps.joystic",
            "com.theappninjas.gpsjoystick",
            "com.theappninjas.fakegpsgo",
            "com.rosteam.gpsemulator",
            "com.mock.location"
        )

        val packageManager = packageManager
        for (packageName in knownMockApps) {
            try {
                packageManager.getPackageInfo(packageName, 0)
                return true // Mock location 앱 발견
            } catch (e: Exception) {
                // 앱이 설치되지 않음
            }
        }
        return false
    }

    /**
     * 설치된 Mock Location 앱 목록 반환
     */
    private fun getMockLocationApps(): List<String> {
        val knownMockApps = listOf(
            "com.lexa.fakegps",
            "com.incorporateapps.fakegps.fre",
            "com.fakegps.mock",
            "com.blogspot.newapphorizons.fakegps",
            "de.robv.android.xposed.installer",
            "com.byterev.hexisedmocklocations",
            "com.devadvance.fakelocationgps",
            "com.dansoftware.fakelocationpro",
            "com.evezzon.fakegps",
            "com.fakegps.route.pro",
            "org.hola.gpslocation",
            "com.lkr.fakelocation",
            "com.gsmartstudio.fakegps",
            "com.fakegps.joystic",
            "com.theappninjas.gpsjoystick",
            "com.theappninjas.fakegpsgo",
            "com.rosteam.gpsemulator",
            "com.mock.location"
        )

        val installedMockApps = mutableListOf<String>()
        val packageManager = packageManager

        for (packageName in knownMockApps) {
            try {
                packageManager.getPackageInfo(packageName, 0)
                installedMockApps.add(packageName)
            } catch (e: Exception) {
                // 앱이 설치되지 않음
            }
        }

        return installedMockApps
    }

    companion object {
        /**
         * Location 객체가 Mock인지 확인 (API 18+)
         */
        fun isLocationMock(location: Location): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                location.isFromMockProvider
            } else {
                false
            }
        }
    }
}
