# 💎 MenuTest UI Library

Nowoczesna, wysokowydajna i w pełni responsywna biblioteka interfejsu użytkownika dla środowiska **Roblox**. Zaprojektowana z myślą o maksymalnej płynności (błyskawiczne ładowanie z pamięci cache), estetyce dark-mode, systemie dynamicznych kart (modułów) oraz inteligentnym Master Loaderze z automatycznym wykrywaniem gier.

---

## 📑 Spis Treści
1. [Szybki Start (Quick Start)](#-szybki-start-quick-start)
2. [Główne Cechy Biblioteki](#-główne-cechy-biblioteki)
3. [Inicjalizacja Okna (CreateWindow)](#-inicjalizacja-okna-createwindow)
4. [Tworzenie Zakładek (Tabs & Ikony)](#-tworzenie-zakładek-tabs--ikony)
5. [System Modułów (Modules)](#-system-modułów-modules)
   - [Sterowanie Modułem (Myszka & Keybindy)](#sterowanie-modułem-myszka--keybindy)
   - [Dodawanie Opcji do Modułu](#dodawanie-opcji-do-modułu)
6. [Elementy Interfejsu (Kontrolki)](#-elementy-interfejsu-kontrolki)
   - [Toggle (Przełącznik)](#1-toggle-przełącznik)
   - [Slider (Suwak)](#2-slider-suwak)
   - [Dropdown (Lista rozwijana)](#3-dropdown-lista-rozwijana)
   - [ColorPicker (Wybór koloru)](#4-colorpicker-wybór-koloru)
   - [Input (Pole tekstowe)](#5-input-pole-tekstowe)
   - [Button (Przycisk)](#6-button-przycisk)
7. [System Dashboard, Motywy i Konfiguracje](#-system-dashboard-motywy-i-konfiguracje)
8. [Architektura Master Loadera i Dodawanie Gier](#-architektura-master-loadera-i-dodawanie-gier)
9. [Kompletny Przykładowy Skrypt](#-kompletny-przykładowy-skrypt)
10. [👑 Skrypt Autora](#-skrypt-autora)

---

## ⚡ Szybki Start (Quick Start)

Aby załadować bibliotekę bezpośrednio w swoim skrypcie:

```lua
local MENU = loadstring(game:HttpGet("https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/Main.lua"))()

local Window = MENU:CreateWindow({
    Name = "MyHub",
    Tittle = "My Super Cheat Hub",
    TittlePos = "Center",
    ToggleUIKeybind = "Insert",
    TestMobile = false,
    GameId = "109949693269081"
})

local Tab = Window:CreateTab("Main", "zap")
local MyModule = Tab:CreateModule({
    Name = "Speed",
    Description = "Zwiększa prędkość poruszania się",
    Default = false,
    DefaultKeybind = "X",
    Callback = function(state)
        print("Moduł Speed:", state)
    end
})
```

---

## 🌟 Główne Cechy Biblioteki

- **Błyskawiczny czas ładowania**: Współdzielona pamięć podręczna modułów eliminuje powtarzające się zapytania HTTP.
- **Responsywny 2-kolumnowy Grid**: Moduły i elementy automatycznie układają się w dwóch estetycznych kolumnach obok siebie.
- **Dynamiczne Karty (Moduły)**: Styl inspirowany nowoczesnymi klientami – karta posiada własny stan aktywności, animowane rozwijanie opcji oraz wbudowany system bindowania klawiszy.
- **Keybinds Overlay**: Pływający panel HUD pokazujący aktualnie zbindowane moduły i ich status (ON/OFF).
- **Zarządzanie Konfiguracjami**:
  - **Local Configs**: Zapisywane i wczytywane bezpośrednio z dysku użytkownika (`workspace/MenuTest_Configs/...`).
  - **Public Configs**: Konfiguracje online pobierane z repozytorium GitHub pod dane ID gry.
- **System Motywów**: Wbudowane wsparcie dla stylów `Dark` oraz `Light`.

---

## 🪟 Inicjalizacja Okna (`CreateWindow`)

```lua
local Window = MENU:CreateWindow({
    Name = "NazwaMenu",               -- Krótki identyfikator wyświetlany w lewym górnym rogu (max 16 znaków)
    Tittle = "Pełny Tytuł Hubu",      -- Główny tytuł widoczny na pasku okna
    TittlePos = "Center",             -- Pozycja tytułu: "Left", "Center", "Right"
    ToggleUIKeybind = "Insert",       -- Klawisz otwierania/zamykania okna ("Insert", "RightShift", etc.)
    TestMobile = false,               -- Włącza pływający przycisk toggle dla urządzeń mobilnych
    GameId = "109949693269081"        -- Identyfikator gry używany m.in. do profilowania konfiguracji
})
```

---

## 📑 Tworzenie Zakładek (`Tabs` & Ikony)

Zakładki tworzy się wywołując metodę `Window:CreateTab(name, icon, order)`.

```lua
local TabPlayer   = Window:CreateTab("Player", "user")
local TabAutoFarm = Window:CreateTab("AutoFarm", "zap")
local TabRender   = Window:CreateTab("Render", "eye")
local TabMisc     = Window:CreateTab("Misc", "wrench")
```

### Dostępne ikony (Lucide Icons):
Biblioteka posiada wbudowany moduł `Icons.lua`. Możesz używać popularnych nazw ikon, np.:
`"user"`, `"zap"`, `"eye"`, `"settings"`, `"layout-dashboard"`, `"shield"`, `"layers"`, `"wrench"`, `"crosshair"`, `"palette"`, `"chevron-down"`, `"check"`, itp.

---

## 📦 System Modułów (`Modules`)

Moduły są głównym budulcem funkcjonalności w menu (np. Fly, Speed, AutoFarm, ESP).

```lua
local FlyModule = TabPlayer:CreateModule({
    Name = "Fly",                      -- Zwięzła, czytelna nazwa modułu
    Description = "Latanie w powietrzu",-- Krótki opis działania
    Default = false,                   -- Domyślny stan (true = włączony, false = wyłączony)
    DefaultKeybind = "F",              -- Domyślny klawisz (opcjonalny)
    Flag = "Player_Fly",               -- Unikalna flaga do automatycznego zapisu konfiguracji
    Callback = function(state)         -- Callback wywoływany przy zmianie stanu (true / false)
        if state then
            print("Fly aktywowane!")
        else
            print("Fly wyłączone!")
        end
    end
})
```

### Sterowanie Modułem (Myszka & Keybindy):
- **LPM (Lewy Przycisk Myszy)**: Włącza / Wyłącza moduł (aktywuje animację akcentu i uruchamia `Callback(state)`).
- **PPM (Prawy Przycisk Myszy)**: Rozwija / Zwija dodatkowe opcje modułu (sub-kontrolki).
- **MouseButton3 (Kółko myszy / Scroll Click)** lub kliknięcie w **`[...]`**: Uruchamia tryb przypisywania klawisza.
  - Wciśnij dowolny klawisz, aby przypisać bind.
  - Wciśnij **Backspace** lub **Delete**, aby usunąć bind.

---

### Dodawanie Opcji do Modułu

Do każdego modułu można przypisać suwaki, przełączniki, listy wyboru czy próbniki kolorów:

```lua
-- 1. Suwak w module
FlyModule:AddSlider({
    Name = "Speed",
    Min = 10,
    Max = 300,
    Default = 50,
    Suffix = " studs",
    Flag = "Fly_Speed",
    Callback = function(val)
        flySpeed = val
    end
})

-- 2. Przełącznik w module
FlyModule:AddToggle({
    Name = "Noclip",
    Default = false,
    Flag = "Fly_Noclip",
    Callback = function(val)
        noclipEnabled = val
    end
})

-- 3. Lista wyboru w module
FlyModule:AddDropdown({
    Name = "Method",
    Options = {"Velocity", "CFrame", "BodyGyro"},
    Default = "Velocity",
    Flag = "Fly_Method",
    Callback = function(selected)
        flyMethod = selected
    end
})

-- 4. Wybór koloru w module
FlyModule:AddColorPicker({
    Name = "Glow Color",
    Default = Color3.fromRGB(0, 255, 170),
    Flag = "Fly_GlowColor",
    Callback = function(color)
        updateGlow(color)
    end
})

-- 5. Pole tekstowe w module
FlyModule:AddInput({
    Name = "Custom Tag",
    Placeholder = "Wpisz tag...",
    Default = "",
    Flag = "Fly_Tag",
    Callback = function(text)
        print("Tag:", text)
    end
})

-- 6. Przycisk w module
FlyModule:AddButton({
    Name = "Reset Flight",
    Callback = function()
        resetVelocity()
    end
})

-- Programowe ustawienie stanu modułu:
FlyModule:Set(true) -- Włącza moduł i wywołuje callback
```

---

## 🎛️ Elementy Interfejsu (Kontrolki)

Możesz także dodawać kontrolki bezpośrednio do zakładki (`Tab`), poza modułami:

### 1. Toggle (Przełącznik)
```lua
Tab:CreateToggle({
    Name = "Auto Collect",
    Default = false,
    Flag = "AutoCollect_Flag",
    Callback = function(state)
        print("Toggle:", state)
    end
})
```

### 2. Slider (Suwak)
```lua
Tab:CreateSlider({
    Name = "FOV",
    Min = 70,
    Max = 120,
    Default = 90,
    Suffix = "°",
    Flag = "Camera_FOV",
    Callback = function(val)
        workspace.CurrentCamera.FieldOfView = val
    end
})
```

### 3. Dropdown (Lista rozwijana)
```lua
Tab:CreateDropdown({
    Name = "Target Priority",
    Options = {"Najbliższy", "Najmniej HP", "Najwięcej Kasy"},
    Default = "Najbliższy",
    Flag = "Target_Priority",
    Callback = function(selected)
        print("Wybrano:", selected)
    end
})
```

### 4. ColorPicker (Wybór koloru)
```lua
Tab:CreateColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 50, 50),
    Flag = "ESP_Color",
    Callback = function(color)
        espColor = color
    end
})
```

### 5. Input (Pole tekstowe)
```lua
Tab:CreateInput({
    Name = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Default = "",
    Flag = "Webhook_URL",
    Callback = function(text)
        webhook = text
    end
})
```

### 6. Button (Przycisk)
```lua
Tab:CreateButton({
    Name = "Teleport do Spawn",
    Callback = function()
        game.Players.LocalPlayer.Character:MoveTo(Vector3.new(0, 50, 0))
    end
})
```

---

## 📊 System Dashboard, Motywy i Konfiguracje

Menu automatycznie generuje dwie zakładki systemowe:

### 1. Dashboard (`Dashboard.lua`)
- **Profil Gracza**: Awatar, nazwa użytkownika, DisplayName, wiek konta.
- **Diagnostyka na żywo**: Wykryty executor (np. Synapse, Wave, Solara, Krnl), aktualny Ping (ms) oraz FPS.
- **Statystyki**: Czas trwania bieżącej sesji, licznik aktywnych modułów.
- **Szybkie Akcje**: Bezpieczne zamykanie UI, przełączniki pomocnicze.

### 2. Settings (`Settings.lua`)
- **Opcje Główne**:
  - `AntiAFK`: Wbudowane zabezpieczenie przed rozłączeniem z serwerem po 20 minutach bezczynności.
  - `Keybinds Overlay`: Włączanie/wyłączanie HUD-u ze zbindowanymi klawiszami.
  - `Watermark`: Wyświetlanie znaku wodnego w rogu ekranu.
  - `Theme`: Wybór motywu wizualnego (`Dark` / `Light`).
- **Menedżer Konfiguracji (Configs)**:
  - **Local Configs**: Tworzenie nowych profili, zapisywanie, wczytywanie i usuwanie plików `.json`.
  - **Public Configs**: Przeglądanie i pobieranie gotowych profili z GitHuba pod dedykowane ID gry.

---

## 🚀 Architektura Master Loadera i Dodawanie Gier

Plik [Loader.lua](file:///C:/Users/kubak/Desktop/githubMenu/MenuTest/Loader.lua) to inteligentny skrypt startowy.

### Jak działa detekcja gier:
1. Pobiera identyfikator gry: `game.PlaceId` oraz `game.GameId`.
2. Sprawdza, czy ID znajduje się w tabeli `Games` w pliku `Loader.lua`.
3. **Jeśli gra jest zarejestrowana**: Uruchamia dedykowany skrypt z `Games/<ID_GRY>/Script.lua`.
4. **Jeśli gra NIE jest zarejestrowana**: Automatycznie uruchamia uniwersalny zestaw [Games/Universal.lua](file:///C:/Users/kubak/Desktop/githubMenu/MenuTest/Games/Universal.lua) (zawierający moduł **Render**: Player ESP, Boxy, Chams, Tracers).

### Jak dodać nową grę (w 2 prostych krokach):
1. Utwórz folder `Games/<ID_GRY>/` i umieść w nim `Script.lua`.
2. W pliku `Loader.lua` dopisz jedną linijkę do tabeli `Games`:
```lua
local Games = {
    [109949693269081] = "[UPD 3.1] Tycoon, but one dropper",
    [TWÓJ_NOWY_ID]    = "Nazwa Nowej Gry", -- <- tylko tyle!
}
```

---

## 💻 Kompletny Przykładowy Skrypt

```lua
-- Pobranie biblioteki MenuTest
local MENU = (typeof(getgenv) == "function" and getgenv()._MenuTestLibrary) or _G._MenuTestLibrary
if not MENU then
    MENU = loadstring(game:HttpGet("https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/Main.lua"))()
end

-- Tworzenie okna
local Window = MENU:CreateWindow({
    Name = "Cheats",
    Tittle = "Awesome Script Hub",
    TittlePos = "Center",
    ToggleUIKeybind = "Insert",
    TestMobile = false,
    GameId = tostring(game.PlaceId)
})

-- Zakładka Player
local TabPlayer = Window:CreateTab("Player", "user")

-- Moduł WalkSpeed
local speedEnabled = false
local speedValue = 16

local SpeedModule = TabPlayer:CreateModule({
    Name = "Speed",
    Description = "Zmienia prędkość gracza",
    Default = false,
    DefaultKeybind = "V",
    Callback = function(state)
        speedEnabled = state
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = state and speedValue or 16 end
    end
})

SpeedModule:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 250,
    Default = 50,
    Suffix = " studs/s",
    Callback = function(val)
        speedValue = val
        if speedEnabled then
            local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    end
})
```

---

## 👑 Skrypt Autora

Aby uruchomić skrypt z automatyczną detekcją gry i uniwersalnym wsparciem, wklej poniższy kod do swojego executora:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/Loader.lua?t=" .. tostring(tick())))()
```
