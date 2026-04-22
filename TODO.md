# Multi-Role Delivery App: Rider Features Implementation
Kumpra - Buyer/Rider Delivery System

## Phase 1: Backend Rider API (PHP) - COMPLETE ✅
- [x] Update schema.sql: Add rider_lat/lng to batches  
- [x] php/api/riders/auth/login.php
- [x] php/api/riders/batches/available.php
- [x] php/api/riders/batches/accept.php
- [x] php/api/riders/location/update.php
- [x] database.php: getRidersIdColumn(), getRidersPasswordColumn()

## Phase 2: Flutter Rider Integration - IN PROGRESS ✅
- [x] pubspec deps + geolocator/ws
- [x] rider_geolocation_service.dart 
- [x] Fix rider_home_screen.dart API
- [x] onboarding role choice (pending exact match)
- [x] rider_tracking_screen.dart
- [ ] buyer updates (batches/list.php rider pos, chat)

- [x] Update schema.sql: Add rider_lat/lng to batches
- [x] php/api/riders/auth/login.php
- [x] php/api/riders/batches/available.php
- [x] php/api/riders/batches/accept.php
- [x] php/api/riders/location/update.php
- [x] Update database.php: getRidersIdColumn(), getRidersPasswordColumn()

## Phase 2: Flutter Rider Flow
- [ ] pubspec.yaml: Add geolocator, web_socket_channel
- [ ] lib/services/rider_geolocation_service.dart
- [ ] Fix rider_home_screen.dart API calls
- [ ] lib/screens/onboarding_screen.dart: Role selector
- [ ] lib/screens/rider_tracking_screen.dart + chat_screen.dart

## Phase 3: Real-Time & Polish
- [ ] PHP WebSocket/chat endpoint
- [ ] Integrate WS in tracking/chat screens
- [ ] Update buyer order_tracking_screen.dart for rider pos/chat
- [ ] Test full flow: Buyer batch → Rider accept → Track/Chat → Deliver

Current Progress: Phase 1 Backend
