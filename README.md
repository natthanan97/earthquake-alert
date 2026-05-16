# Earthquake Alert

แอปมือถือ Cross-platform สำหรับติดตามแผ่นดินไหวแบบ Real-time พร้อมระบบแจ้งเตือนตามตำแหน่งที่อยู่ปัจจุบัน สร้างด้วย Flutter + Riverpod

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart 3.11.5+) |
| State Management | Riverpod 2.6.1 |
| Real-time Data | WebSocket (p2pquake API) |
| Historical Data | USGS FDSN Web Services REST API |
| Offline Cache | SQLite via sqflite 2.4.2 |
| User Preferences | shared_preferences 2.5.3 |
| Map | flutter_map 7.0.2 |
| Location | geolocator 13.0.2 |
| Notifications | flutter_local_notifications 18.0.1 |
| Background Service | flutter_foreground_task 8.15.0 |
| UI Theme | Material 3, Dark theme, Deep orange |

**Platforms:** Android, iOS, macOS, Windows, Linux, Web

---

## Features

### Real-time Earthquake Streaming
- เชื่อมต่อ WebSocket กับ `wss://api.p2pquake.net/v2/ws` (ข้อมูล JMA จากญี่ปุ่น)
- Reconnect อัตโนมัติด้วย exponential backoff (delay 5 วินาที)
- แสดงสถานะการเชื่อมต่อแบบ Live (Connected / Reconnecting / Disconnected)

### Multi-source Data Aggregation
- **p2pquake** — ข้อมูล Real-time ผ่าน WebSocket (เน้น Japan Meteorological Agency)
- **USGS fdsnws** — ข้อมูลย้อนหลัง 7 วันทั่วโลกผ่าน REST API
- Deduplication อัตโนมัติ โดยใช้ composite key: `timestamp + lat + lon + magnitude`

### Offline Cache (SQLite)
- เก็บข้อมูลแผ่นดินไหวล่าสุดสูงสุด 500 events ลง SQLite
- เปิด app ครั้งแรก → โหลด 50 events จาก cache ทันทีก่อน WebSocket connect
- ไม่มีเน็ต → `historicalEarthquakesProvider` fallback ดึงจาก DB แทน REST API
- Auto-prune ตัดข้อมูลเก่าเกิน 500 records อัตโนมัติ

### Interactive Dashboard (Home Screen)
- จำนวนแผ่นดินไหววันนี้
- ขนาด magnitude สูงสุดของวัน
- Card แผ่นดินไหวที่ใกล้ที่สุด พร้อมระยะทาง
- Alert radius tile แสดงค่าจาก Settings แบบ realtime
- รายการประวัติย้อนหลังแบบ scrollable

### Real-time Feed
- Buffer สูงสุด 200 events สำหรับ WebSocket stream
- กรองตาม magnitude: All / M2+ / M4+ / M6+
- Toggle "Nearby only" (รัศมี 100 กม.)
- Toggle "Today only"
- Highlight event ใหม่ที่เพิ่งมาถึง

### Interactive Map
- แสดง marker และ circle overlay สูงสุด 50 จุดพร้อมกัน
- กดปุ่มเพื่อ center map ที่ตำแหน่งผู้ใช้
- แสดงพิกัด latitude/longitude ปัจจุบัน
- Default center: Tokyo (35.6762°N, 139.6503°E)

### Proximity-based Alerts
- ตรวจจับแผ่นดินไหวในรัศมีที่ผู้ใช้กำหนด (ตั้งได้ 10–500 กม.)
- กรอง magnitude ขั้นต่ำที่จะ trigger notification (ตั้งได้ M2–M6)
- คำนวณระยะทางด้วย Haversine formula
- แจ้งเตือน Local Notification พร้อมระยะห่าง

### Background Monitoring
- Foreground Service ทำงานต่อเนื่องแม้ app ถูก minimize
- Heartbeat ทุก 60 วินาที
- Auto-reconnect WebSocket เมื่อหลุดการเชื่อมต่อ
- Deduplication เพื่อป้องกัน notification ซ้ำ

### Settings (ตั้งค่าได้)
- **Alert Radius** — slider 10–500 กม. (default 50 กม.)
- **Minimum Magnitude** — เลือก M2 / M3 / M4 / M5 / M6 (default M4)
- ค่าทุกอย่างบันทึกด้วย `shared_preferences` ข้ามครั้งที่เปิด app
- Dashboard อ่านค่า radius จาก Settings แบบ realtime

### Country Detection
- แปลง lat/lon เป็น country code (ISO 3166-1 alpha-2)
- แสดง flag emoji ของประเทศ
- รองรับ 40+ ภูมิภาค seismically-active
- Fallback: "🌐 International"

---

## Architecture

```
lib/
├── main.dart                               # Entry point, NavigationShell (4 tabs)
├── models/
│   └── earthquake.dart                     # Earthquake data model + dedupKey
├── providers/
│   ├── earthquake_provider.dart            # Core Riverpod providers & notifiers
│   ├── earthquake_feed_provider.dart       # Feed filtering & display logic
│   └── settings_provider.dart             # AppSettings AsyncNotifier
├── screens/
│   ├── home_screen.dart                    # Dashboard (stats, history, nearby)
│   ├── earthquake_feed_screen.dart         # Real-time feed with filters
│   ├── map_screen.dart                     # Interactive map with overlays
│   └── settings_screen.dart               # Alert radius + magnitude settings
├── services/
│   ├── earthquake_service.dart             # USGS API integration
│   ├── websocket_service.dart              # p2pquake WebSocket client
│   ├── notification_service.dart           # Local push notifications
│   ├── background_service.dart             # Foreground service (isolate)
│   ├── location_service.dart               # GPS via geolocator
│   ├── distance_service.dart               # Haversine distance calculations
│   ├── proximity_alert_service.dart        # Nearby earthquake detection
│   ├── historical_earthquake_service.dart  # USGS historical fetch
│   ├── database_service.dart              # SQLite offline cache
│   └── settings_service.dart              # shared_preferences persistence
├── utils/
│   └── country_flag_helper.dart            # Country detection from coordinates
└── widgets/
    ├── earthquake_card.dart
    ├── earthquake_feed_item.dart
    ├── earthquake_detail_sheet.dart
    ├── earthquake_history_list.dart
    ├── websocket_status_card.dart
    ├── connection_status_badge.dart
    ├── hero_quake_card.dart
    ├── nearby_quake_card.dart
    └── statistics_card.dart
```

### Data Flow

```
WebSocket (p2pquake) ──► RealtimeEarthquakesNotifier ──► DatabaseService (SQLite)
         ▲                          │
         │               (on startup: load 50 cached)
         │                          │
USGS REST API ──────► HistoricalEarthquakesProvider ──► DatabaseService (SQLite)
         │                (offline fallback: read DB)
         │                          │
         └──────────────────────────▼
                       combinedFeedProvider (merge + dedupe)
                                    │
                       filteredFeedProvider (magnitude / nearby / today)
                                    │
                                   UI

SettingsService (shared_preferences)
         │
         ├──► ProximityAlertService  (alert radius + min magnitude)
         └──► Dashboard StatisticsCard (alert radius display)
```

### State Management Patterns (Riverpod)

| Provider Type | ใช้สำหรับ |
|---|---|
| `StateProvider` | User position, Map focus state |
| `FutureProvider` | USGS historical data (async REST) |
| `StreamProvider` | WebSocket status/events |
| `NotifierProvider` | Realtime feed, Filtered feed |
| `AsyncNotifierProvider` | AppSettings (radius, min magnitude) |
| `Provider` | Services, Computed values |

---

## External APIs

### WebSocket — p2pquake
- **URL**: `wss://api.p2pquake.net/v2/ws`
- **Event Code**: `551` (earthquake report)
- **ข้อมูลสำคัญ**: latitude, longitude, magnitude, depth, location name, JMA intensity scale (maxScale 10–70)
- กรอง event ที่มีพิกัดไม่ valid (lat/lon = -200) ออก

### REST — USGS FDSN
- **URL**: `https://earthquake.usgs.gov/fdsnws/event/1/query`
- **Format**: GeoJSON
- **Parameters**: `starttime`, `endtime`, `minmagnitude` (default 2.5), `orderby=time`

---

## Key Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  http: ^1.2.2
  web_socket_channel: ^3.0.1
  geolocator: ^13.0.2
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  flutter_local_notifications: ^18.0.1
  flutter_foreground_task: ^8.15.0
  permission_handler: ^11.3.1
  sqflite: ^2.4.2
  shared_preferences: ^2.5.3
  path: ^1.9.1
  intl: ^0.20.2
  collection: ^1.19.1
```

---

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run code generation (Riverpod)
dart run build_runner build

# Run app
flutter run
```

**Permissions ที่ต้องการ:**
- Location (foreground + background)
- Notifications
- Internet

---

## App Info

- **App Name**: earthquake_alert
- **Version**: 1.0.0+1
- **Dart SDK**: >=3.11.5
- **Flutter**: >=3.0.0
