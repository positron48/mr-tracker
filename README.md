# MR Tracker

Нативное macOS-приложение (SwiftUI + SwiftData) для ведения своих GitLab merge requests.
Создавалось под приватный GitLab, доступный только из локальной сети / через VPN.

<!-- При желании добавь сюда скриншот: docs/screenshot.png -->

## Возможности

- **Добавление MR одной ссылкой.** Вставьте URL merge request и нажмите Enter — название,
  ветки и прочая инфа подтянутся из GitLab автоматически.
- **Своя статусная модель:** создан → на ревью → аппрув → на проде; отмена из любого
  состояния. Цветной бейдж статуса с выпадающим списком.
- **Умный sync.** Кнопка «Обновить» подтягивает approve, факт merge, статус CI и число
  нерешённых комментариев. Статус двигается автоматически по approve/merge, при этом
  **ручная отмена не перетирается**. Запросы идут строго последовательно с троттлингом —
  без «ддоса» инстанса.
- **Ветки.** Показывает ветку MR и целевую ветку (куда мержится); `main`/`master`
  скрывается. Клик по ветке копирует её имя в буфер с уведомлением.
- **Произвольные ссылки-плашки.** На MR и на группу можно навесить любые ссылки —
  выводятся короткой плашкой по поддомену (`planka.lala.ru` → `planka`), дубликаты
  нумеруются (`planka`, `planka2`, …).
- **Группы-задачи.** MR объединяются в группы со сводкой по статусам/CI и
  сворачиванием.
- **Архив.** Готовые и отменённые MR уезжают вниз под спойлер с пагинацией.
- **Настройки.** Base URL + Personal Access Token (хранится в Keychain),
  профиль и недавняя активность из GitLab.

## Требования

- macOS 15+
- **Xcode** (не только Command Line Tools — макрос `@Model` из SwiftData
  поставляется только с полным Xcode).

## Сборка и запуск

```sh
# переключить активный тулчейн на Xcode (один раз)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# собрать MRTracker.app в текущей папке
./make-app.sh

# собрать и установить в /Applications
./make-app.sh release install

# тесты
swift test
```

Можно также открыть `Package.swift` в Xcode и запустить через ⌘R.

## Авторизация

GitLab приватный, поэтому используется Personal Access Token:

1. В GitLab: аватар → **Edit profile** → **Access Tokens** → **Add new token**.
2. Scope достаточно **`read_api`** (приложение только читает, ничего не пишет в GitLab).
3. Скопируйте токен (`glpat-…`) — он показывается один раз.
4. В приложении: **⌘,** → вкладка «Подключение» → впишите Base URL
   (`https://gitlab.host`) и токен → «Сохранить» → «Проверить».

Токен хранится в системном Keychain и отправляется в заголовке `PRIVATE-TOKEN`
к `…/api/v4`. Под VPN GitLab должен быть доступен с localhost.

## Архитектура

```
Sources/MRTracker/
  MRTrackerApp.swift          @main, WindowGroup + Settings, SwiftData-контейнер
  Models/                     SwiftData @Model: MergeRequest, TaskGroup, CustomLink, MRStatus
  Services/
    GitLabClient.swift        actor, REST API v4
    KeychainStore.swift       PAT в Keychain, base URL в UserDefaults
    LinkLabeler.swift         подписи-плашки по поддомену + дедуп
    MRURLParser.swift         разбор ссылки на MR
  ViewModels/AppModel.swift   @Observable, оркестрация и логика sync
  Views/                      ContentView, MRRowView, GroupSectionView,
                              ArchiveSection, AddMRBar, LinkChipsView, SettingsView, FlowLayout
Tests/MRTrackerTests/         юнит-тесты на парсер URL и labeler
```

## Лицензия

MIT
