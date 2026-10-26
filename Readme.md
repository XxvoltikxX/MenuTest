# 💎 MenuTest UI Library

Nowoczesna, ultra-szybka i w pełni responsywna biblioteka interfejsu użytkownika dla środowiska **Roblox**. Zaprojektowana z myślą o maksymalnej płynności (pamięć podręczna modułów, zerowe zacięcia), dark-mode, systemie dynamicznych modułów (inspirowanych klientami PvP), dolnym pasku profilu w stylu **Discord** z dedykowaną zębatką ustawień oraz inteligentnym Master Loaderze z automatyczną detekcją gier.

---

> [!IMPORTANT]
> ### 🤖 INSTRUKCJE DLA AGENTÓW AI I DEWELOPERÓW (PRZECZYTAJ ZANIM NAPISZESZ KOD!)
> 
> Jeżeli jesteś **Agentem AI** lub tworzysz nowy skrypt gry pod `MenuTest`:
> 
> 1. **100% AUTOMATYCZNE KEYBINDY DLA MODUŁÓW**:
>    - **NIGDY NIE IMPLEMENTUJ WŁASNEGO KODU NA KEYBINDY DLA MODUŁÓW!**
>    - Nie twórz żadnych listenerów `UserInputService.InputBegan` ani nie rejestruj manualnie modułów w HUD.
>    - Każdy moduł stworzony przez `Tab:CreateModule({ Name = "...", DefaultKeybind = "X", ... })` **automatycznie i natywnie**:
>      - Przypisuje klawisz skrótu (`DefaultKeybind`).
>      - Reaguje na wciśnięcie klawisza w grze, zmienia stan i wywołuje `Callback(state)`.
>      - Rejestruje się w pływającym HUD (`Keybinds Overlay`) ze statusem `[ON]` / `[OFF]`.
>      - Zapisuje i wczytuje zbindowany klawisz w konfiguracjach pod kluczem `<Flag>_Bind`.
>      - Umożliwia graczowi zmianę bindu bezpośrednio z poziomu UI (kliknięcie kółkiem myszy `MouseButton3` lub kliknięcie w plakietkę `[...]`).
> 
> 2. **BRAK RĘCZNEGO NISZCZENIA / CZYSZCZENIA GUI**:
>    - Nie twórz w skryptach gier własnych funkcji usuwania starego GUI ani szukania `ScreenGui` w `CoreGui`/`PlayerGui`.
>    - Biblioteka `MenuTest` automatycznie i bezpiecznie niszczy poprzednie instancje okna, rozłącza zdarzenia i zapobiega wyciekom pamięci przy każdym załadowaniu skryptu.
> 
> 3. **USTAWIENIA W PASKU PROFILU W STYLU DISCORD**:
>    - Zakładka `Settings` **NIE znajduje się na liście zakładek sidebara**.
>    - Obok awatara i nazwy gracza na dole sidebara znajduje się dedykowany przycisk zębatki Lucide (`settings`).
>    - Kliknięcie zębatki płynnie otwiera panel Ustawień (Motywy, AntiAFK, Keybinds Overlay, Configi). Ponowne kliknięcie lub wybranie dowolnej zakładki płynnie przywraca poprzednią zakładkę.
> 
> 4. **CZYSTY, MODUŁOWY KOD**:
>    - Skrypt gry powinien składać się wyłącznie z:
>      1. Załadowania biblioteki (`loadstring(...)`).
>      2. Wywołania `MENU:CreateWindow({...})`.
>      3. Stworzenia zakładek (`Window:CreateTab(...)`).
>      4. Stworzenia modułów (`Tab:CreateModule({...})`) z ich opcjami (`AddToggle`, `AddSlider`, itp.).

---

## 📑 Spis Treści
1. [Szybki Start (Quick Start)](#-szybki-start-quick-start)
2. [Architektura Biblioteki](#-architektura-biblioteki)
3. [Inicjalizacja Okna (CreateWindow)](#-inicjalizacja-okna-createwindow)
4. [Tworzenie Zakładek (Tabs)](#-tworzenie-zakładek-tabs)
5. [System Modułów (Modules & Automatyczne Keybindy)](#-system-modułów-modules--automatyczne-keybindy)
   - [Struktura modułu](#struktura-modułu)
   - [Kontrola modułu przez użytkownika](#kontrola-modułu-przez-użytkownika)
   - [Dodawanie opcji wewnątrz modułu](#dodawanie-opcji-wewnątrz-modułu)
6. [Niezależne Kontrolki Zakładki (Stand-alone Controls)](#-niezależne-kontrolki-zakładki-stand-alone-controls)
7. [Pasek Profilu i Ustawienia (Discord-Style Settings)](#-pasek-profilu-i-ustawienia-discord-style-settings)
8. [System Motywów (Themes)](#-system-motywów-themes)
9. [System Konfiguracji (Configs)](#-system-konfiguracji-configs)
10. [Master Loader i Dodawanie Nowych Gier](#-master-loader-i-dodawanie-nowych-gier)
11. [Wzorcowy Skrypt Gry dla Agenta AI](#-wzorcowy-skrypt-gry-dla-agenta-ai)

---

## ⚡ Szybki Start (Quick Start)

Podstawowy skrypt uruchomieniowy:

```lua
local MENU = loadstring(game:HttpGet("https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua"))()

local Window = MENU:CreateWindow({
    Name = "MyHub",
    Tittle = "My Super Cheat Hub",
    TittlePos = "Center",
    ToggleUIKeybind = "Insert",
    TestMobile = false,
    GameId = tostring(game.PlaceId)
})

local Tab = Window:CreateTab("Player", "user")

local SpeedModule = Tab:CreateModule({
    Name = "Speed",
    Description = "Zwiększa prędkość poruszania się",
    Default = false,
    DefaultKeybind = "X", -- Automatyczny bind! Zero dodatkowego kodu!
    Flag = "Player_Speed",
    Callback = function(state)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = state and 50 or 16
        end
    end
})

SpeedModule:AddSlider({
    Name = "Prędkość",
    Min = 16,
    Max = 200,
    Default = 50,
    Suffix = " studs/s",
    Flag = "Player_SpeedValue",
    Callback = function(val)
        -- Logika suwaka
    end
})
```

---

## 🏗️ Architektura Biblioteki

```
┌────────────────────────────────────────────────────────┐
│                      MAIN WINDOW                       │
├──────────────┬─────────────────────────────────────────┤
│   SIDEBAR    │              PAGES AREA                 │
│              │                                         │
│ [Dashboard]  │  ┌─────────────────┐ ┌────────────────┐ │
│ [Player]     │  │  Module 1 (LPM) │ │ Module 2 (LPM) │ │
│ [Combat]     │  │  - Sub-Toggle   │ │ - Sub-Slider   │ │
│ [Render]     │  │  - Sub-Dropdown │ │ - Sub-Color    │ │
│              │  └─────────────────┘ └────────────────┘ │
│              │  [2-Kolumnowy Responsywny Układ Kart]   │
├──────────────┤                                         │
│ DISCORD BAR  │                                         │
│ [Avatar]     │                                         │
│ [Nick]  [⚙]  │                                         │
└───────┴──┴───┴─────────────────────────────────────────┘
```

- **Pasek boczny (Sidebar)**: Lista zakładek użytkownika oraz dolny panel profilu z awatarem Roblox i przyciskiem Ustawień `[⚙]`.
- **Pages Area**: 2-kolumnowy grid modułów w danej zakładce, układający się automatycznie.
- **Discord-Style User Bar**: Wzorowany na Discordzie – awatar, nick i dedykowana zębatka ustawień.

---

## 🪟 Inicjalizacja Okna (`CreateWindow`)

```lua
local Window = MENU:CreateWindow({
    Name = "NazwaMenu",         -- Identyfikator w lewym górnym rogu (max 16 znaków)
    Tittle = "Tytuł Okna",      -- Główny tytuł wyświetlany na pasku okna
    TittlePos = "Center",       -- Pozycja tytułu: "Left", "Center", "Right"
    ToggleUIKeybind = "Insert", -- Klawisz otwierania/ukrywania menu (np. "Insert", "RightShift", "K")
    TestMobile = false,         -- Włącza pływający przycisk toggle dla urządzeń mobilnych
    GameId = tostring(game.PlaceId) -- ID gry do profilowania konfiguracji
})
```

---

## 📑 Tworzenie Zakładek (`Tabs`)

Zakładki tworzy się przy użyciu metody `Window:CreateTab(name, icon, order)`:

```lua
local TabPlayer   = Window:CreateTab("Player", "user")
local TabCombat   = Window:CreateTab("Combat", "crosshair")
local TabAutoFarm = Window:CreateTab("AutoFarm", "zap")
local TabRender   = Window:CreateTab("Render", "eye")
```

### Dostępne ikony (Lucide Icons):
Możesz używać dowolnej popularnej ikony z rodziny Lucide, m.in.:
- `"user"`, `"zap"`, `"eye"`, `"crosshair"`, `"shield"`, `"layers"`, `"wrench"`, `"palette"`, `"layout-dashboard"`, `"settings"`, `"refresh-cw"`, `"folder"`, `"save"`, `"trash"`, `"check"`, itp.

---

## 📦 System Modułów (`Modules` & Automatyczne Keybindy)

Moduł to podstawowa jednostka funkcyjna w `MenuTest`. Idealna do opcji typu `KillAura`, `Fly`, `AutoFarm`, `ESP`.

### Struktura modułu:

```lua
local MyModule = TabPlayer:CreateModule({
    Name = "Fly",                      -- Czytelna nazwa modułu
    Description = "Latanie w powietrzu",-- Krótki opis wyświetlany pod nazwą
    Default = false,                   -- Stan początkowy (true/false)
    DefaultKeybind = "F",              -- DOMYŚLNY KLAWISZ (np. "F", "X", "V")
    Flag = "Player_Fly",               -- Unikalna flaga do zapisu konfiguracji
    Callback = function(state)         -- Funkcja uruchamiana przy zmianie stanu (true / false)
        if state then
            -- Kod włączenia
        else
            -- Kod wyłączenia
        end
    end
})
```

### Kontrola modułu przez użytkownika:
- **LPM (Lewy Przycisk Myszy)**: Włącza / Wyłącza moduł.
- **PPM (Prawy Przycisk Myszy)**: Rozwija / Zwija dodatkowe opcje modułu.
- **MouseButton3 (Środkowy Przycisk Myszy / Rolka)** lub kliknięcie w **`[...]`**:
  - Aktywuje tryb bindowania klawisza.
  - Wciśnij dowolny klawisz, aby przypisać go do modułu.
  - Wciśnij **Backspace** lub **Delete**, aby skasować bind.
- **Pływający HUD (`Keybinds Overlay`)**: Moduł natychmiast pojawia się na ekranie HUD z aktualnym statusem.

### Dodawanie opcji wewnątrz modułu:

Do każdego modułu możesz dopiąć kontrolki podrzędne (rozwijane PPM):

```lua
-- 1. Suwak w module
MyModule:AddSlider({
    Name = "Prędkość",
    Min = 10,
    Max = 200,
    Default = 50,
    Suffix = " studs/s",
    Flag = "Fly_Speed",
    Callback = function(val)
        speedValue = val
    end
})

-- 2. Przełącznik w module
MyModule:AddToggle({
    Name = "Noclip",
    Default = false,
    Flag = "Fly_Noclip",
    Callback = function(state)
        noclipActive = state
    end
})

-- 3. Lista wyboru w module
MyModule:AddDropdown({
    Name = "Tryb",
    Options = {"Velocity", "CFrame", "BodyGyro"},
    Default = "Velocity",
    Flag = "Fly_Mode",
    Callback = function(selected)
        currentMode = selected
    end
})

-- 4. Próbnik koloru w module (płynny z paletą SV, suwakiem Hue i Alpha)
MyModule:AddColorPicker({
    Name = "Kolor Aury",
    Default = Color3.fromRGB(0, 255, 170),
    Flag = "Fly_AuraColor",
    Callback = function(color)
        updateAura(color)
    end
})

-- 5. Pole tekstowe w module
MyModule:AddInput({
    Name = "Własny Tag",
    Placeholder = "Wpisz tag gracza...",
    Default = "",
    Flag = "Fly_Tag",
    Callback = function(text)
        print("Wpisano:", text)
    end
})

-- 6. Przycisk w module
MyModule:AddButton({
    Name = "Zresetuj Pozycję",
    Callback = function()
        resetPos()
    end
})

-- Programowe ustawienie stanu modułu:
MyModule:Set(true) -- Włącza moduł i odpala Callback(true)
```

---

## 🎛️ Niezależne Kontrolki Zakładki (Stand-alone Controls)

Jeśli chcesz dodać kontrolkę bezpośrednio do strony zakładki (poza modułami), użyj metod `Tab:Create...`:

```lua
Tab:CreateToggle({ Name = "Auto Collect", Default = false, Flag = "Auto_Collect", Callback = function(v) end })
Tab:CreateSlider({ Name = "Zasięg", Min = 5, Max = 100, Default = 20, Suffix = "m", Flag = "Range", Callback = function(v) end })
Tab:CreateDropdown({ Name = "Cel", Options = {"Najbliższy", "Najsłabszy"}, Default = "Najbliższy", Flag = "Target", Callback = function(v) end })
Tab:CreateColorPicker({ Name = "ESP Kolor", Default = Color3.fromRGB(255, 50, 50), Flag = "ESP_Color", Callback = function(v) end })
Tab:CreateInput({ Name = "Webhook", Placeholder = "URL...", Default = "", Flag = "Webhook", Callback = function(v) end })
Tab:CreateButton({ Name = "Teleport", Callback = function() end })
```

---

## 🗂️ Nowoczesny System Kategorii i Sekcji (Categories & Sections)

Możesz podzielić dowolną zakładkę na eleganckie, zwijane karty kategorii (Category Cards) z nagłówkami, ikonami Lucide, opisami i plakietkami (badges):

```lua
local CombatCat = Tab:CreateCategory({
    Name = "Walka i Aimbot",
    Icon = "crosshair",
    Description = "Zaawansowane moduły namierzania przeciwników",
    Badge = "PVP",
    Side = "Left",          -- "Left" | "Right" | "Auto"
    Collapsible = true,     -- Możliwość zwijania kliknięciem w nagłówek
    DefaultOpen = true      -- Domyślnie rozwinięta
})

-- Dodawanie modułów i kontrolek bezpośrednio do kategorii:
local AimbotMod = CombatCat:CreateModule({
    Name = "Silent Aim",
    Default = false,
    DefaultKeybind = "C",
    Flag = "Combat_SilentAim",
    Callback = function(state) end
})

CombatCat:CreateSlider({
    Name = "Field of View (FOV)",
    Min = 10,
    Max = 180,
    Default = 90,
    Step = 1,
    Suffix = "°",
    Flag = "Combat_FOV",
    Callback = function(val) end
})

CombatCat:CreateToggle({
    Name = "Draw FOV Circle",
    Default = true,
    Flag = "Combat_DrawFOV",
    Callback = function(v) end
})
```

---

## 🌈 Żywe Animowane Motywy i Efekty Tła (Animated Themes & FX)

Menu posiada wbudowany silnik animacji tła w 60 FPS (`RunService.Heartbeat`), który tworzy płynne, holograficzne fale gradientu i poświaty:
- **Dostępne presety animacji**: `Aurora`, `Cyberpunk`, `Cosmic`, `Sunset`, `Emerald`, `None`.
- **Wbudowane motywy**: `dark`, `midnight`, `amethyst`, `cyberpunk`, `emerald`, `sunset`, `tokyo`, `light`.
- **Kontrola programowa**:
```lua
Window:SetAnimatedTheme("Cyberpunk", 0.15, 0.8) -- Tryb, intensywność poświaty (0.02 - 0.35), prędkość fal (0.1 - 2.5)
Window:SetGifBackground("rbxassetid://12345678", 0.85) -- Tło GIF / Spritesheet
```

---

## ⚙️ Pasek Profilu i Ustawienia (Discord-Style Settings)

Na dole paska bocznego (Sidebar) znajduje się panel profilu użytkownika:
- **Awatar**: Pobrany z miniaturki Roblox gracza (`rbxthumb://type=AvatarHeadShot`).
- **Nazwa Gracza**: Inteligentne wyświetlanie DisplayName / Username.
- **Zębatka Ustawień (`settings`)**:
  - Dedykowany przycisk po prawej stronie paska profilu.
  - Hover: subtelny obrót ikony o 25°.
  - Kliknięcie: płynnie otwiera pełną stronę **Settings** w głównym obszarze okna z obrotem zębatki do 60° i wyróżnieniem akcentu.
  - Ponowne kliknięcie zębatki lub kliknięcie w dowolną zakładkę (Dashboard, Player, Render) płynnie zamyka Ustawienia i przywraca aktywną zakładkę.

### Zawartość Panelu Ustawień:
1. **THEMES**:
   - Płynna lista rozwijana motywów (popover o wysokim ZIndex, który **nie przesuwa sekcji OPTIONS w dół** i animuje się z obrotem strzałki chevron).
   - Przycisk `Refresh Themes` z animacją obrotu.
2. **OPTIONS**:
   - `AntiAFK`: Domyślnie **automatycznie włączony** przy załadowaniu, chroni przed błędem 20 minut bezczynności Roblox.
   - `AntiFling`: Domyślnie **automatycznie włączony** przy załadowaniu (wzorowany na Infinite Yield `antifling` & `unfling`). Wyłącza kolizje fizyczne (`CanCollide = false`) u innych graczy na każdym kroku symulacji fizyki (`Stepped`) oraz stabilizuje prędkość Twojej postaci, uniemożliwiając innym graczom wyrzucenie Cię z mapy.
   - `Keybinds`: Włączanie/wyłączanie nakładki HUD ze zbindowanymi modułami.
   - `Menu Keybind`: Wizualny widget zmiany klawisza otwierania menu (kliknij, wciśnij klawisz, domyślnie `[K]`).
3. **CONFIGS**:
   - Zapisywanie i wczytywanie konfiguracji lokalnych (`Local Configs`) oraz przeglądanie gotowych konfiguracji publicznych z GitHuba (`Public Configs`).

---

## 🎨 System Motywów (Themes)

Biblioteka posiada wbudowany silnik `ThemeManager`, który natychmiast i bez przeładowania UI aktualizuje kolory wszystkich zarejestrowanych elementów (teksty, tła, ramki, moduły, kontrolki).

Wbudowane motywy:
- **`dark`**: Ciemny, grafitowy motyw z białymi akcentami (domyślny).
- **`light`**: Nowoczesny, czysty jasny motyw.
- **`midnight`**: Głęboki granat z neonowo-morskim akcentem.
- **`amethyst`**: Elegancki fioletowo-ametystowy styl.

---

## 📁 System Konfiguracji (Configs)

Konfiguracje są zapisywane w formacie JSON w folderze:
`MenuTest/configs/<GameId>/<NazwaConfigu>.json`

- **Automatyczny Zapis**: Wszystkie flagi modułów (`Flag`), ich stany (`state`), bindy (`<Flag>_Bind`) oraz wartości suwaków, dropdownów i kolorów zapisują się w wybranym configu.
- **Public Configs**: Automatycznie pobierane z repozytorium GitHub pod identyfikator gry.

---

## 🚀 Master Loader i Dodawanie Nowych Gier

Plik [Loader.lua](file:///C:/Users/kubak/Desktop/githubMenu/MenuTest/Loader.lua) to inteligentny punkt wejścia skryptu.

### Jak działa detekcja gier:
1. Sprawdza `game.PlaceId` oraz `game.GameId`.
2. Jeśli gra jest na liście w `Loader.lua`: uruchamia `Games/<PlaceId>/Script.lua`.
3. Jeśli gra nie jest zarejestrowana: uruchamia `Games/Universal.lua` (z kompletnym modułem Visuals & ESP).

### Jak dodać wsparcie dla nowej gry:
1. W pliku `Loader.lua` dodaj wpis do tabeli `Games`:
```lua
local Games = {
    [109949693269081] = "[UPD 3.1] Tycoon, but one dropper",
    [TWÓJ_PLACE_ID]   = "Nazwa Twojej Gry", -- <- tylko jedna linijka!
}
```
2. Utwórz folder `Games/<TWÓJ_PLACE_ID>/Script.lua`.

---

## 💻 Wzorcowy Skrypt Gry dla Agenta AI

Skopiuj poniższy szablon przy tworzeniu skryptu dla dowolnej nowej gry:

```lua
-- // ==========================================================================
-- // SKRYPT GRY DLA MENUTEST UI LIBRARY
-- // ==========================================================================

-- 1. Pobranie biblioteki
local MENU = (typeof(getgenv) == "function" and getgenv()._MenuTestLibrary) or _G._MenuTestLibrary
if not MENU then
    MENU = loadstring(game:HttpGet("https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua"))()
end

-- 2. Utworzenie okna
local Window = MENU:CreateWindow({
    Name = "CheatHub",
    Tittle = "My Game Automation",
    TittlePos = "Center",
    ToggleUIKeybind = "K",
    TestMobile = false,
    GameId = tostring(game.PlaceId)
})

-- 3. Utworzenie zakładek
local TabPlayer   = Window:CreateTab("Player", "user")
local TabAutoFarm = Window:CreateTab("AutoFarm", "zap")
local TabRender   = Window:CreateTab("Render", "eye")

-- 4. Moduły z automatycznymi keybindami (BRAK WŁASNEGO KODU NA BINDY!)
local speedActive = false
local speedValue = 50

local SpeedModule = TabPlayer:CreateModule({
    Name = "Speed",
    Description = "Zwiększa prędkość poruszania się",
    Default = false,
    DefaultKeybind = "Z", -- <- Biblioteka sama obsługuje klawisz 'Z' i HUD!
    Flag = "Player_Speed",
    Callback = function(state)
        speedActive = state
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = state and speedValue or 16 end
    end
})

SpeedModule:AddSlider({
    Name = "Wartość Prędkości",
    Min = 16,
    Max = 250,
    Default = 50,
    Suffix = " studs/s",
    Flag = "Player_SpeedSlider",
    Callback = function(val)
        speedValue = val
        if speedActive then
            local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    end
})

-- 5. Moduł AutoFarm
local autoFarmActive = false
local FarmModule = TabAutoFarm:CreateModule({
    Name = "Auto Collect",
    Description = "Automatycznie zbiera przedmioty",
    Default = false,
    DefaultKeybind = "X", -- <- Automatyczny bind 'X'!
    Flag = "Farm_AutoCollect",
    Callback = function(state)
        autoFarmActive = state
        if state then
            task.spawn(function()
                while autoFarmActive do
                    -- Logika zbierania
                    task.wait(0.1)
                end
            end)
        end
    end
})
```

---

## 👑 Uruchomienie (Master Loader)

Aby uruchomić skrypt z automatyczną detekcją gry w swoim executorze:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Loader.lua?t=" .. tostring(tick())))()
```
