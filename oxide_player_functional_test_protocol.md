# Oxide Player Functional Test Protocol

Дата: 2026-01-29

> Призначення: базовий протокол функціонального тестування. Використовуйте як чекліст та журнал результатів.

## 1. Onboarding & Permissions
- [ ] **Fresh Install:** Встановити застосунок на чистий пристрій/емулятор.
- [ ] **Permission Request:** Переконатися, що зʼявляється екран "Audio Permission".
- [ ] **Grant Permission:** Натиснути "Allow/Grant" і підтвердити системний діалог.
- [ ] **Library Scan:** Перевірити, що сканування локальної музики стартує одразу після дозволу.

## 2. Home Feed (Online)
- [ ] **Loading State:** Запуск із інтернетом. Є skeleton/loader.
- [ ] **Sections:** Присутні секції "Quick Picks", "Made for You", "Recommended", "Your Library".
- [ ] **Content:** Завантажуються превʼю та назви рекомендованих елементів.
- [ ] **Navigation:** Клік по плейлисту/альбому → відтворення або деталі (залежно від реалізації).

## 3. Search & Discovery
- [ ] **Search Bar:** Відкрити пошук, ввести запит (напр. "Enimkon").
- [ ] **Results:** Є результати для Songs, Videos, Artists, Playlists.
- [ ] **Playback:** Тап по треку → відтворення стартує.
- [ ] **Artist Search:** Тап по Artist → відкривається Artist Page (через `PlaylistTracksScreen` або offline екран).

## 4. Player Controls
- [ ] **Mini Player:** Після старту треку зʼявляється міні-плеєр внизу.
- [ ] **Full Player:** Тап по міні-плеєру → відкривається full player.
- [ ] **Play/Pause:** Тумблер play/pause синхронізує аудіо та UI.
- [ ] **Next/Prev:** Перемикання на наступний/попередній трек коректне.
- [ ] **Seek:** Перетягування прогрес-бару змінює позицію.
- [ ] **Shuffle/Repeat:** Перемикання shuffle/repeat змінює чергу.
- [ ] **Artist Link (CRITICAL):** Тап по імені артиста → перехід на Artist Page.
- [ ] **Like Button:** "Heart" додає трек у "Liked Songs".
- [ ] **Download:** "Download/Cache" стартує і завершує завантаження.

## 5. Library & Offline
- [ ] **Tabs:** В "Library" є вкладки "Tracks", "Albums", "Artists".
- [ ] **Local Playback:** Відтворення локального треку з метаданими і обкладинкою.
- [ ] **Local Artist:** Тап по артисту локального треку → local DetailScreen.
- [ ] **Liked Songs:** Трек з лайком є в "Liked Songs".
- [ ] **Offline Mode:** Вимкнути інтернет → кешований трек відтворюється.

## 6. Settings & Localization
- [ ] **Language:** Settings → Language → Ukrainian → UI оновився одразу.
- [ ] **Theme:** Перемикання Dark/Light або Material You працює.
- [ ] **Cache:** Перегляд Cache Size. Очищення кешу звільняє місце.

## 7. Edge Cases
- [ ] **Missing Artist ID:** Трек без каналу → тап по артисту → toast "Artist page unavailable".
- [ ] **Network Error:** Вимкнути мережу під час онлайн playback → коректний toast/обробка.
- [ ] **Background Play:** Перевести застосунок у фон → відтворення триває, lock screen controls працюють.

## 8. Specific Bug Verification
- [ ] **"Я зігрію тебе взимку":** Відтворити трек → тап по артисту → Artist Page або "unavailable" (якщо ID втрачено) з fallback-спробою.

---

## Журнал результатів
> Заповнюйте під час проходження, додаючи пристрій/версію.

| Дата | Пристрій/OS | Build | Секція | Пункт | Результат | Нотатки |
|---|---|---|---|---|---|---|
|  |  |  |  |  | Pass/Fail |  |
