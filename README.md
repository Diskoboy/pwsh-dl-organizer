# Organize Downloads

Утилита для автоматической сортировки файлов в папке «Загрузки» по типам и правилам.

- **v1** (`organize_downloads.ps1`) — сортировка на месте: Installers, Images, Videos, Audio, Archives, Documents, chat_export, Other.
- **v0.2** (`organize_downloads_v0.2.ps1`) — перенос на другой диск, дубликаты по хешу → `_Duplicates`, старые установщики → `_Quarantine`, конфиг и логи. Подробно: [DOCS_v0.2.md](DOCS_v0.2.md).

**Платформа:** Windows, PowerShell 5.x / 7+

---

## Что делает

- Создаёт в «Загрузках» папки по категориям (см. ниже).
- Переносит туда **только файлы из корня** «Загрузок» по расширению.
- **Особое правило:** файлы `.md`, в имени которых есть `google`, `gemini`, `gpt` или `chat` (без учёта регистра), переносятся в папку **chat_export**. Остальные .md — в **Documents**.
- Не перезаписывает: при совпадении имени добавляет `_1`, `_2` и т.д.
- Существующие подпапки не трогает.

### Категории по расширениям

| Папка | Расширения |
|-------|------------|
| Installers | .exe, .msi |
| Images | .png, .jpg, .jpeg, .gif, .webp, .bmp, .ico |
| Videos | .mp4, .mkv, .avi, .mov, .wmv, .webm |
| Audio | .mp3, .wav, .flac, .m4a, .ogg |
| Archives | .zip, .7z, .rar, .tar, .gz |
| Documents | .txt, .xlsx, .xls, .pdf, .docx, .doc, .md |
| chat_export | только .md по имени (google/gemini/gpt/chat) |
| Other | всё остальное |

---

## Быстрый старт

**v1 (сортировка в самой папке «Загрузки»):**
```powershell
cd organize-downloads
.\organize_downloads.ps1
```

**v0.2 (перенос на другой диск, дубликаты, автоочистка, лог; один файл, все настройки в скрипте):**
```powershell
.\organize_downloads_v0.2.ps1
# переопределить цель:
.\organize_downloads_v0.2.ps1 -TargetPath "E:\Temponary\.Downloads"
# только показать план (ничего не переносить):
.\organize_downloads_v0.2.ps1 -DryRun
```

С обходом политики выполнения:

```powershell
powershell -ExecutionPolicy Bypass -File "organize-downloads\organize_downloads.ps1"
```

---

## Конфигурация

Целевая папка и список категорий задаются в начале `organize_downloads.ps1`:

- `$base = Join-Path $env:USERPROFILE "Downloads"` — папка «Загрузки» текущего пользователя.
- `$folders` — хеш «папка → массив расширений»; правило для `chat_export` задаётся отдельным условием в цикле.

---

## Документация

Полное описание скрипта, алгоритм, конфигурация, запуск, ограничения и идеи доработок — в **[MANIFEST.md](MANIFEST.md)**.

---

## Публикация на GitHub

1. Установи [Git](https://git-scm.com/download/win), если ещё нет.
2. Репозиторий: [github.com/Diskoboy/pwsh-dl-organizer](https://github.com/Diskoboy/pwsh-dl-organizer).
3. В папке проекта:

```powershell
git init
git add .
git commit -m "Initial commit: Organize Downloads script + docs"
git branch -M main
git remote add origin https://github.com/Diskoboy/pwsh-dl-organizer.git
git push -u origin main
```

Через SSH: `git remote add origin git@github.com:Diskoboy/pwsh-dl-organizer.git`
