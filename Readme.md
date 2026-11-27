# 💎 LuminaqHUB (MenuTest)

Prosty panel wyboru gry dla **Roblox**. Po uruchomieniu widzisz napis **„Welcome to LuminaqHub”**, wyszukiwarkę i listę gier, do których podpięty jest script. Nie ma detekcji gry, kategorii ani panelu opcji — grę wybierasz **manualnie**.

Repozytorium: `https://github.com/XxvoltikxX/MenuTest`

---

## ⚡ Szybki start

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Loader.lua?t="
    .. tostring(tick())
))()
```

`Loader.lua` **zawsze** uruchamia `Games/Universal.lua`, czyli panel wyboru gry. Nie wykrywa `PlaceId` ani `GameId`.

---

## 🪟 Tworzenie panelu (`CreateExplorer`)

```lua
local MENU = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua"
))()

local Explorer = MENU:CreateExplorer({
    Name            = "LuminaqHub",  -- nazwa w splashu (max 16 znaków)
    Games           = { ... },       -- lista gier (patrz niżej)
    BaseUrl         = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Games/",
    ToggleUIKeybind = "K",           -- klawisz ukrywania / pokazywania menu
    OnCleanup       = function()
        -- opcjonalne sprzątanie po zamknięciu menu
    end,
})
```

### Co zwraca `CreateExplorer`?

| Pole | Opis |
| --- | --- |
| `ScreenGui` | Główny `ScreenGui` menu |
| `MainFrame` | Ramka okna |
| `Games` | Znormalizowana lista gier |
| `Notify(text, success)` | Powiadomienie toast |
| `Refresh()` | Ponowne przefiltrowanie i narysowanie kart |
| `Launch(game)` | Uruchomienie wybranej gry (obiekt z `Games`) |
| `SetVisible(state)` | Pokazanie / ukrycie okna |
| `Cleanup()` | Zamknięcie menu i zwolnienie połączeń |

---

## 🎮 Rejestr gier

Każdy wpis w `Games` to jedna gra widoczna na liście:

```lua
{
    Id          = "1234567890",       -- folder w Games/ (wymagany)
    Name        = "Moja Gra",         -- nazwa wyświetlana
    Description = "Krótki opis",      -- opcjonalne
    Icon        = "gamepad-2",        -- ikona Lucide (opcjonalne)
    Tags        = { "pvp", "fps" },   -- opcjonalne
    Author      = "XxvoltikxX",       -- opcjonalne
}
```

### Jak uruchamiana jest gra?

1. Jeśli wpis ma `Run`, wywoływane jest `Run(game)`.
2. Jeśli wpis ma `Url`, pobierany jest ten adres (albo `BaseUrl .. Url`, gdy to ścieżka względna).
3. W przeciwnym razie pobierany jest `BaseUrl .. Folder .. "/Script.lua"`.

Pobrany kod jest kompilowany przez `loadstring` i uruchamiany. Po sukcesie panel chowa się, a użytkownik widzi grę. Wyszukiwarka filtruje po nazwie, opisie, tagach, autorze i `Id`.

---

## ➕ Dodawanie nowej gry

Dodawaj gry **stopniowo, po jednej**.

1. Utwórz plik `Games/<ID>/Script.lua`, np. `Games/1234567890/Script.lua`:

```lua
local MENU = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua"
))()

-- Zbuduj interfejs dla swojej gry (starsze API CreateWindow lub własny UI)
local Window = MENU:CreateWindow({
    Name = "MojaGra",
    ToggleUIKeybind = "K",
})

-- ... zakładki i moduły ...
```

2. Dodaj wpis w `Games/Universal.lua`:

```lua
local Games = {
    {
        Id = "1234567890",
        Name = "Moja Gra",
        Description = "Skrypt do mojej gry",
        Icon = "gamepad-2",
        Tags = { "pvp" },
        Author = "XxvoltikxX",
    },
}
```

3. Zacommituj i wypchnij zmiany na `main` — Loader pobiera pliki z `raw.githubusercontent.com`.

> `Games/Universal.lua` to teraz **rejestr gier**, a nie pakiet funkcji uniwersalnych. Ciche ochrony AntiAFK / AntiFling działają w tle i nie mają opcji w UI.

---

## 🎨 Motywy i sterowanie

- Ikona palety w prawym górnym rogu przełącza **Dark Obsidian** / **Light Pearl**.
- `[K]` (lub własny `ToggleUIKeybind`) ukrywa i pokazuje menu.
- Ikona `–` minimalizuje okno do pływającego przycisku `L`.
- Ikona `×` zamyka menu i uruchamia `OnCleanup`.
- Pole wyszukiwania filtruje gry na żywo; przycisk `×` w polu czyści zapytanie.
- Gdy lista jest pusta lub nic nie pasuje, pojawia się czytelny komunikat.

---

## 🗂️ Starsze API (`CreateWindow`)

`CreateWindow` wraz z zakładkami i modułami nadal istnieje w `Main.lua` dla kompatybilności wstecznej — używaj go wewnątrz `Games/<ID>/Script.lua`. Panel główny (`CreateExplorer`) służy wyłącznie do wyboru gry.

```lua
local Window = MENU:CreateWindow({
    Name            = "Universal",
    ToggleUIKeybind = "K",
    HideDashboard   = true, -- opcjonalnie: bez starej zakładki Dashboard
})

local Tab = Window:CreateTab("Visuals", "eye", 1)
```

### Tło menu (`SetMenuBackground`)

Silnik okna obsługuje tło obrazkowe. Roblox nie ma natywnych GIF-ów, więc tryb **GIF** to animowany pokaz slajdów (crossfade co 4 s) między standardowymi wyglądami.

```lua
Window:SetMenuBackground("Pictures", "Aurora Flow", 0.30)
Window:SetMenuBackground("GIF")            -- animowany slideshow
Window:CycleMenuBackground()               -- następny wygląd
Window:GetBackgroundPresets()              -- lista nazw wyglądów
```

Tryby: `"Pictures"`, `"GIF"`, `"Animowany"`. Standardowe wyglądy: `Aurora Flow`, `Neon Grid`, `Deep Space`, `Sunset Haze`, `Emerald Mist`, `Crimson Pulse`, `Tokyo Night`, `Frost`, `Mono`.

### Bind menu

```lua
Window:SetMenuKeybind("K")
print(Window:GetMenuKeybind()) -- "K"
```

### Gry: Strike Force (pierwsza) i Universal

**Strike Force** to pierwsza karta w panelu — korzysta z tego samego skryptu co Universal
(`Folder = "Universal"`) i ma własną klasę ochrony z opcjami **Protect Kick** i **AntiBan**.

`Games/Universal/Script.lua` to kompletny przykład menu gry:

- **Visuals**: ESP, Tracers, Nametag, Head ESP (kolory + rozmiar).
- **Combat**:
  - **Aimbot** — bind aktywacji, tryb `Toggle` / `Hold`, cel `Head` / `Body`,
    suwaki **Czułość** i **Intensywność** (tempo i siła ruchu myszy — płynniej i trudniej do wykrycia),
    opcjonalny **Jitter** (mikro-drgania imitujące rękę).
  - **FOV** — promień obszaru wyszukiwania celu (40–600 px), kolor i podgląd okręgu.
- **Movement**: WalkSpeed z trybami `Velocity` / `CFrame` i suwakiem prędkości.
- **HUD**:
  - **Arraylist** — lista włączonych modułów w prawym górnym rogu (aktualizuje się na żywo).
  - **Toggle Info** — krótki komunikat `ON` / `OFF` na dole ekranu przy każdym przełączeniu modułu.
  - Oba elementy można **przeciągnąć** myszą lub palcem w dowolne miejsce ekranu —
    pozycja jest zapamiętywana w sesji (`getgenv()._0x5a17.hud`) i odtwarzana przy starcie.
  - **Ustaw pozycję HUD** (Settings) pokazuje podgląd toggle info na 8 s, żeby wygodnie
    ustawić jego miejsce; **Reset pozycji HUD** przywraca domyślne pozycje.
  - Oba elementy można wyłączyć w zakładce **Settings**.
- **Settings**: bind menu, tryb tła (`Pictures` / `GIF`), wygląd, przezroczystość.

### Ukrywanie GUI (Stealth)

`src/Stealth.lua` ogranicza wykrywanie menu po stronie klienta:

- **`gethui()`** (jeśli executor go udostępnia) → `CoreGui`; **nigdy `PlayerGui`**, gdzie gra najczęściej skanuje GUI.
- **`protect_gui` / `syn.protect_gui`** — dodatkowa ochrona, jeśli dostępna.
- **Losowe nazwy** `ScreenGui` — bez sygnatur `Luminaq`, `ESP`, `Universal`.
- **Losowa nazwa** `RunService:BindToRenderStep` (zamiast `LuminaqAim`).
- **Wspólny magazyn sesji** `getgenv()._0x5a17` zamiast jawnych kluczy `_Voltik*`.
- **Cisza w produkcji** — `print`/`warn` są wyłączone, chyba że ustawisz `getgenv()._MenuTestDevMode = true`.

W skrypcie gry możesz użyć tego samego mechanizmu:

```lua
local Stealth = MENU.Stealth
local overlay = Stealth.NewScreenGui({ DisplayOrder = 5, IgnoreGuiInset = true })
```

To **nie ukryje** faktu użycia executora (`HttpGet`, `loadstring`, `gethui`, `mousemoverel`) ani zachowania serwerowego (WalkSpeed, statystyki, aimbot). Jeśli gra już oznaczyła sesję, zmiana nazw GUI nie cofnie flagi — pomóc może tylko nowa sesja i mniej agresywne funkcje.

### Ochrony per gra (Protections)

Każda gra ma **osobną klasę ochrony** w `src/protections/<Gra>.lua` — nic nie jest
wrzucone do jednego wspólnego worka. Panel wyboru gier pokazuje osobną kartę dla
każdej klasy, a w niej przełączniki jej opcji.

- `src/protections/Core.lua` — wspólny silnik: jeden hook `__namecall` + `__index`
  (`hookmetamethod`) i rejestr handlerów per gra.
- `src/protections/StrikeForce.lua` — klasa Strike Force:
  - **Protect Kick** — blokuje `Player:Kick` / `player.Kick` po stronie klienta.
  - **AntiBan** — blokuje `Kick`, `game:Shutdown` oraz teleport na inny `PlaceId`
    (typowa droga do „ban place”). Teleporty w obrębie tego samego miejsca przechodzą.
- `src/protections/Universal.lua` — klasa Universal z własnym **Protect Kick**.

Gra deklaruje swoje klasy w rejestrze:

```lua
{
    Id          = "StrikeForce",
    -- ...
    Protections = { "StrikeForce" }, -- plik src/protections/StrikeForce.lua
}
```

Stan przełączników jest pamiętany w sesji (`getgenv()._0x5a17.protections`)
pod kluczem `Gra.Opcja`, np. `StrikeForce.AntiBan`.

Własną listę ochron możesz też przekazać bezpośrednio do `CreateExplorer`:

```lua
MENU:CreateExplorer({
    -- ...
    Protections = {
        {
            Id   = "StrikeForce",
            Name = "Strike Force",
            Options = {
                {
                    Id = "Kick",
                    Name = "Protect Kick",
                    OnToggle = function(state)
                        return MENU.ProtectCore.SetNamecall("MojaGra.Kick", function(self, method)
                            if state and method == "Kick" and self == MENU.ProtectCore.LocalPlayer then
                                return true, nil
                            end
                            return false
                        end)
                    end,
                },
            },
        },
    },
})
```

> Kick/ban wysłany bezpośrednio z serwera **nie da się zablokować po stronie klienta**.
> Protect Kick i AntiBan chronią tylko przed wywołaniami po stronie klienta.
> Jeśli executor nie udostępnia `hookmetamethod`, przełącznik pokaże błąd zamiast
> udawać, że ochrona działa.

---

## 🧩 Ikony

Panel korzysta z ikon Lucide (`src/Icons.lua`). Przykłady:

`gamepad-2`, `gamepad`, `joystick`, `search`, `play`, `palette`, `minus`, `x`, `sparkles`, `layout-grid`, `library`, `box`, `zap`, `shield`.

Nieznana nazwa ikony nie zatrzyma menu — po prostu pozostawi pusty obrazek.

---

## 📁 Struktura projektu

```
Main.lua                 -- biblioteka, CreateWindow + CreateExplorer
Loader.lua               -- zawsze uruchamia panel wyboru gry
Games/Universal.lua      -- rejestr gier (Strike Force + Universal) + ciche AntiAFK / AntiFling
Games/Universal/Script.lua -- menu gry: ESP / Aimbot / FOV / WalkSpeed
Games/<ID>/Script.lua    -- skrypt wybranej gry
src/Explorer.lua         -- panel "Welcome to LuminaqHub" + wyszukiwarka gier
src/Stealth.lua          -- ukrywanie GUI (gethui / CoreGui, losowe nazwy, ochrona)
src/protections/Core.lua -- wspólny silnik hooków ochron
src/protections/*.lua    -- osobne klasy ochron per gra (StrikeForce, Universal)
src/Window.lua           -- starszy silnik okna (CreateWindow + tło GIF/Pictures)
src/Icons.lua            -- ikony Lucide
src/elements/            -- kontrolki (Slider, Toggle, Dropdown, ...)
src/tabs/                -- Dashboard i Settings starego okna
```
