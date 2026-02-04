# Organize Downloads

Утилита для автоматической сортировки файлов в папке «Загрузки» по типам (расширениям). Раскладывает файлы по подпапкам: Installers, Images, Videos, Archives, Documents, Other.

**Платформа:** Windows, PowerShell 5.x / 7+

## Быстрый старт

```powershell
cd organize-downloads
.\organize_downloads.ps1
```

Или с обходом политики выполнения:

```powershell
powershell -ExecutionPolicy Bypass -File "organize-downloads\organize_downloads.ps1"
```

## Что делает

- Создаёт в «Загрузках» папки: **Installers**, **Images**, **Videos**, **Archives**, **Documents**, **Other**
- Переносит туда файлы из корня «Загрузок» по расширению
- Не перезаписывает: при совпадении имени добавляет `_1`, `_2` и т.д.
- Существующие подпапки не трогает

## Конфигурация

Целевая папка и список категорий задаются в начале `organize_downloads.ps1` (переменная `$base` и хеш `$folders`).

## Документация

Подробное описание — в [MANIFEST.md](MANIFEST.md): алгоритм, конфигурация, запуск, ограничения, идеи доработок.

---

## Публикация на GitHub

1. **Установи Git**, если ещё нет: [git-scm.com](https://git-scm.com/download/win).

2. Репозиторий: [github.com/Diskoboy/pwsh-dl-organizer](https://github.com/Diskoboy/pwsh-dl-organizer) (если создаёшь новый — без README, у нас уже есть).

3. **В папке проекта выполни в терминале:**

```powershell
cd "f:\Temp\cursor\organize-downloads"

git init
git add .
git commit -m "Initial commit: Organize Downloads script + docs"
git branch -M main
git remote add origin https://github.com/Diskoboy/pwsh-dl-organizer.git
git push -u origin main
```

Через SSH:

```powershell
git remote add origin git@github.com:Diskoboy/pwsh-dl-organizer.git
```
