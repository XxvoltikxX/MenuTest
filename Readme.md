# 💎 LuminaqHUB (MenuTest)

Nowoczesny, ciemny interfejs typu **explorer** dla środowiska **Roblox**. Zamiast klasycznych zakładek i list modułów LuminaqHUB stawia na:

- **Dashboard** z profilem gracza, statystykami live i szybkim dostępem do funkcji.
- **Wyszukiwarkę scriptów** dla aktualnej gry (nazwa, opis, kategoria i tagi).
- **Panel szczegółów** z przyciskiem uruchamiania oraz opcjami (suwaki / przełączniki).
- **Karty serwera** (rejoin, server hop, kopiowanie JobId) i stopkę statusu.

Repozytorium: `https://github.com/XxvoltikxX/MenuTest`

---

## ⚡ Szybki start

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Loader.lua?t="
    .. tostring(tick())
))()
```

`Loader.lua` automatycznie wykrywa `PlaceId` / `GameId`:

1. Jeśli gra jest w tabeli `Games` → uruchamia `Games/<ID>/Script.lua`.
2. Jeśli nie ma dedykowanego scriptu → uruchamia `Games/Universal.lua` jako **LuminaqHUB**.

Ręczne wymuszenie uniwersalnego pakietu:

```lua
getgenv()._ForceUniversal = true
-- lub: getgenv()._ForceLuminaq = true
```

---

## 🪟 Tworzenie explorera (`CreateExplorer`)

```lua
local MENU = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua"
))()

local Explorer = MENU:CreateExplorer({
    Name = "LuminaqHUB",              -- nazwa w splashu (max 16 znaków)
    Tittle = "Welcome to LuminaqHub", -- tytuł powitalny
    ToggleUIKeybind = "K",            -- klawisz ukrywania / pokazywania menu
    GameId = "LuminaqHUB",            -- ID profilu konfiguracji
    Scripts = { ... },                -- lista scriptów (patrz niżej)
    OnCleanup = function()
        -- opcjonalne sprzątanie po zamknięciu menu
    end,
})
```

### Co zwraca `CreateExplorer`?

| Pole | Opis |
| --- | --- |
| `ScreenGui` | Główny `ScreenGui` menu |
| `MainFrame` | Ramka okna |
| `Notify(text, success)` | Powiadomienie toast |
| `Refresh()` | Odświeżenie listy i quick access |
| `SelectCategory(name)` | Przełączenie kategorii (`"Dashboard"`, `"Player"`, `"Render"`, `"Misc"`) |
| `SetVisible(state)` | Pokazanie / ukrycie okna |
| `Cleanup()` | Zamknięcie menu i zwolnienie połączeń |

---

## 📦 Rejestr scriptów

Każdy wpis w `Scripts` to jedna funkcja lub akcja widoczna w explorerze.

```lua
{
    Name        = "WalkSpeed",                 -- nazwa wyświetlana
    Description = "Zwiększa prędkość postaci", -- opis w liście i szczegółach
    Category    = "Player",                    -- "Player" | "Render" | "Misc"
    Tags        = { "speed", "movement" },     -- tagi do wyszukiwania
    Icon        = "zap",                       -- ikona Lucide
    Mode        = "toggle",                    -- "toggle" | "action"
    Pinned      = true,                        -- pokaż w Szybkim Dostępie
    Default     = false,                       -- stan początkowy dla toggle
    OnToggle    = function(state) end,         -- wywoływane przy zmianie stanu
    Run         = function() end,              -- akcja dla Mode = "action"
    Url         = "https://.../Script.lua",    -- alternatywa: pobierz i uruchom
    Options     = { ... },                     -- opcje w panelu szczegółów
}
```

### Opcje (`Options`)

```lua
Options = {
    {
        Type = "slider",
        Name = "Prędkość",
        Min = 16,
        Max = 300,
        Default = 50,
        Step = 1,
        Suffix = " studs/s",
        Callback = function(value) end,
    },
    {
        Type = "toggle",
        Name = "Sprint na Shift",
        Default = false,
        Callback = function(state) end,
    },
}
```

### Wyszukiwanie i kategorie

- Pole wyszukiwania filtruje po **nazwie, opisie, kategorii i tagach**.
- Pigułki `Dashboard`, `Player`, `Render`, `Misc` przełączają widok.
- Wpisy z `Pinned = true` trafiają do sekcji **Szybki Dostęp** na dashboardzie.
- `Url` pozwala podpiąć zewnętrzny script — zostanie pobrany, skompilowany i uruchomiony.

---

## 🧰 Wbudowany pakiet Universal

`Games/Universal.lua` rejestruje następujące funkcje:

**Player**
- WalkSpeed (+ sprint na Shift, osobna prędkość sprintu)
- Infinite Jump (+ siła skoku)
- Flight / Fly (+ prędkość i noclip w locie)
- Noclip
- Click TP (Ctrl + LPM)

**Render**
- Player ESP (highlight, chams, nicki, dystans, zasięg)
- Tracers (linie od dołu ekranu, grubość)
- Fullbright

**Misc**
- AntiAFK (domyślnie włączony)
- AntiFling (domyślnie włączony)
- Reset Character
- Low Graphics
- Copy JobId
- Rejoin Server

Wszystkie funkcje są dostępne z poziomu wyszukiwarki, panelu szczegółów oraz Szybkiego Dostępu.

---

## ➕ Dodawanie nowej gry

1. Dodaj wpis w `Loader.lua`:

```lua
local Games = {
    [1234567890] = { name = "Moja Gra", folder = "1234567890" },
}
```

2. Utwórz `Games/1234567890/Script.lua` i zbuduj explorer:

```lua
local MENU = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua"
))()

local Explorer = MENU:CreateExplorer({
    Name = "MojaGra",
    Tittle = "Moja Gra · LuminaqHUB",
    ToggleUIKeybind = "K",
    GameId = tostring(game.PlaceId),
    Scripts = {
        {
            Name = "Auto Collect",
            Description = "Automatycznie zbiera przedmioty",
            Category = "Misc",
            Tags = { "autofarm", "collect" },
            Icon = "zap",
            Mode = "toggle",
            Pinned = true,
            OnToggle = function(state)
                -- logika włączania / wyłączania
            end,
            Options = {
                {
                    Type = "slider",
                    Name = "Zasięg",
                    Min = 5,
                    Max = 100,
                    Default = 20,
                    Step = 1,
                    Suffix = " m",
                    Callback = function(value) end,
                },
            },
        },
    },
})
```

3. Zacommituj i wypchnij zmiany na `main` — Loader pobiera pliki z `raw.githubusercontent.com`.

> Dodawaj gry stopniowo, po jednej. `Games/Universal.lua` pozostaje pakietem zapasowym dla każdej nieobsługiwanej gry.

---

## 🎨 Motywy i sterowanie

- Ikona palety w prawym górnym rogu przełącza **Dark Obsidian** / **Light Pearl**.
- `[K]` (lub własny `ToggleUIKeybind`) ukrywa i pokazuje menu.
- Ikona `–` minimalizuje okno do pływającego przycisku `L`.
- Ikona `×` zamyka menu i uruchamia `OnCleanup`.
- Karta **Serwer & Świat** pokazuje `PlaceId`, liczbę graczy i pozwala wykonać rejoin / server hop / kopiowanie `JobId`.

---

## 🗂️ Starsze API (`CreateWindow`)

`CreateWindow` wraz z zakładkami, modułami i kategoriami nadal istnieje w `Main.lua` dla kompatybilności wstecznej. Nowe gry powinny jednak używać `CreateExplorer` — to domyślny, rozwijany interfejs LuminaqHUB.

---

## 🧩 Ikony

Explorer korzysta z ikon Lucide (`src/Icons.lua`). Przykłady:

`user`, `zap`, `eye`, `plane`, `box`, `crosshair`, `mouse-pointer`, `sun`, `wrench`, `globe`, `refresh-cw`, `shield`, `palette`, `layers`, `settings`, `play`, `download`, `copy`, `cpu`.

Nieznana nazwa ikony nie zatrzyma menu — po prostu pozostawi pusty obrazek.

---

## 📁 Struktura projektu

```
Main.lua                 -- biblioteka, CreateWindow + CreateExplorer
Loader.lua               -- detekcja gry i wybór scriptu
Games/Universal.lua      -- LuminaqHUB: rejestr funkcji uniwersalnych
Games/<ID>/Script.lua    -- dedykowane pakiety gier
src/Explorer.lua         -- silnik dashboardu i wyszukiwarki
src/Window.lua           -- starszy silnik okna (CreateWindow)
src/Icons.lua            -- ikony Lucide
src/elements/            -- kontrolki (Slider, Toggle, Dropdown, ...)
src/tabs/                -- Dashboard i Settings starego okna
```
