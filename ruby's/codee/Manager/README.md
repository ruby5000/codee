# Manager — Common Classes Overview

Centralized manager classes for app configuration, auth, media, localization, caching, and more. Each manager has its own README for quick integration.

---

## Core Managers

| Manager | Description | README |
|---------|-------------|--------|
| **AppConfigManager** | App configuration, constants, URLs, feature flags | [APP_CONFIG_README.md](AppConfig/APP_CONFIG_README.md) |
| **SessionManager** | Auth state, session, login/logout | [AUTH_SESSION_README.md](Auth/AUTH_SESSION_README.md) |
| **ImageManager** | Image loading, caching (SDWebImage) | [IMAGE_MANAGER_README.md](Image/IMAGE_MANAGER_README.md) |
| **MediaManager** | Video thumbnails, duration, save to Photos | [MEDIA_MANAGER_README.md](Media/MEDIA_MANAGER_README.md) |
| **LocalizationManager** | Language switching, localized strings | [LOCALIZATION_README.md](Localization/LOCALIZATION_README.md) |
| **CacheManager** | In-memory + disk cache for data | [CACHE_MANAGER_README.md](Cache/CACHE_MANAGER_README.md) |

---

## New Managers

| Manager | Description | README |
|---------|-------------|--------|
| **DeepLinkManager** | Deep links, universal links, URL routing | [DEEPLINK_README.md](DeepLink/DEEPLINK_README.md) |
| **AnalyticsManager** | Events, screen views, Firebase integration | [ANALYTICS_README.md](Analytics/ANALYTICS_README.md) |
| **ValidatorFormatter** | Validation & formatting (email, URL, date) | [VALIDATOR_FORMATTER_README.md](Validator/VALIDATOR_FORMATTER_README.md) |
| **ExtensionsPack** | String, Array, Date, UIView extensions | [EXTENSIONS_README.md](Extensions/EXTENSIONS_README.md) |
| **ErrorHandler** | Centralized error handling, alerts | [ERROR_HANDLER_README.md](ErrorHandler/ERROR_HANDLER_README.md) |
| **DIContainerManager** | Dependency injection container | [DI_README.md](DI/DI_README.md) |
| **BackgroundTaskManager** | BGTaskScheduler, background refresh/sync | [BACKGROUND_TASK_README.md](BackgroundTask/BACKGROUND_TASK_README.md) |
| **SyncManager** | Pending queue, sync, conflict resolution | [SYNC_README.md](Sync/SYNC_README.md) |
| **SearchManager** | Debounced search, filtering | [SEARCH_README.md](Search/SEARCH_README.md) |
| **ApplicationManager** | App orchestrator, startup phases | [APP_ORCHESTRATOR_README.md](AppOrchestrator/APP_ORCHESTRATOR_README.md) |
| **LifecycleManager** | App lifecycle (active, background) | [LIFECYCLE_README.md](Lifecycle/LIFECYCLE_README.md) |
| **MaintenanceManager** | Cache cleanup, storage, migration | [MAINTENANCE_README.md](Maintenance/MAINTENANCE_README.md) |
| **EnvironmentManager** | Debug/release/staging, API URLs | [ENVIRONMENT_README.md](Environment/ENVIRONMENT_README.md) |
| **ThirdPartyManager** | Third-party SDK initialization | [THIRD_PARTY_README.md](ThirdParty/THIRD_PARTY_README.md) |
| **ObservabilityManager** | Metrics, traces, performance | [OBSERVABILITY_README.md](Observability/OBSERVABILITY_README.md) |
| **DownloadManager** | Generic file download | [DOWNLOAD_README.md](Download/DOWNLOAD_README.md) |
| **DeviceManager** | Device info, screen, battery | [DEVICE_README.md](Device/DEVICE_README.md) |
| **TimerManager** | Delay, debounce, throttle, repeating | [SCHEDULER_README.md](Scheduler/SCHEDULER_README.md) |
| **LocationManager** | Location, geocoding | [LOCATION_README.md](Location/LOCATION_README.md) |
| **KeyboardManager** | Keyboard frame, show/hide | [KEYBOARD_README.md](Keyboard/KEYBOARD_README.md) |

---

## Other Managers (Existing)

| Manager | Description | README |
|---------|-------------|--------|
| **FileStorageManager** | File/directory operations | [FILE_MANAGER_README.md](File/FILE_MANAGER_README.md) |
| **PermissionManager** | iOS permission checks/requests | [PERMISSION_MANAGER_README.md](Permission/PERMISSION_MANAGER_README.md) |
| **LoggerManager** | Logging with levels, emoji | [LOGGER_MANAGER_README.md](Logger/LOGGER_MANAGER_README.md) |
| **CoordinatorManager** | Navigation coordination | [COORDINATOR_MANAGER_README.md](Navigation/COORDINATOR_MANAGER_README.md) |
| **ThreadManager** | Thread/concurrency utilities | [THREAD_MANAGER_GUIDE.md](Thread/THREAD_MANAGER_GUIDE.md) |

---

## Quick Integration

1. Add the manager `.swift` file and its folder to your Xcode target.
2. Read the manager's README for setup and usage.
3. Configure at app launch if needed (e.g. `AppConfigManager.baseURL`, `SessionManager` after login).

---

## Folder Structure

```
Manager/
├── README.md
├── AppConfig/          AppConfigManager
├── AppOrchestrator/    ApplicationManager
├── Auth/               SessionManager
├── Image/              ImageManager
├── Media/              MediaManager
├── Localization/       LocalizationManager
├── Cache/              CacheManager
├── DeepLink/           DeepLinkManager
├── Analytics/          AnalyticsManager
├── Validator/          ValidatorFormatter
├── Extensions/         ExtensionsPack
├── ErrorHandler/       ErrorHandler
├── DI/                 DIContainerManager
├── BackgroundTask/     BackgroundTaskManager
├── Sync/               SyncManager
├── Search/             SearchManager
├── Lifecycle/          LifecycleManager
├── Maintenance/       MaintenanceManager
├── Environment/        EnvironmentManager
├── ThirdParty/         ThirdPartyManager
├── Observability/      ObservabilityManager
├── Download/           DownloadManager
├── Device/             DeviceManager
├── Scheduler/          TimerManager
├── Location/           LocationManager
├── Keyboard/           KeyboardManager
├── File/               FileStorageManager
├── Permission/         PermissionManager
├── Logger/             LoggerManager
├── Navigation/         CoordinatorManager
└── Thread/             ThreadManager
```
