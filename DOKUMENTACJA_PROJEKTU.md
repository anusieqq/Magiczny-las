
Uwzględniono wszystkie pliki C# w folderze Assets i osiem własnych shaderów z Assets/Shaders. Zewnętrzne shadery pakietu SineVFX pominięto. Każdy plik ma ten sam układ: efekt, sposób wykonania, regulowane wartości oraz niezbędne zależności.

# Skrypty C#

## MagicalGrassGeneratorEditor.cs
**Plik:** `Assets/Editor/MagicalGrassGeneratorEditor.cs`

### 1. Jaki efekt to daje?
Dodaje do panelu generatora trawy przyciski do jej tworzenia i usuwania. Nie wykonuje pracy samoczynnie.

### 2. Jak to jest zrobione?
```csharp
DrawDefaultInspector();
MagicalGrassGenerator generator = (MagicalGrassGenerator)target;
if (GUILayout.Button("Generate Magical Grass", GUILayout.Height(34f)))
    generator.GenerateGrass();
if (GUILayout.Button("Clear Generated Grass", GUILayout.Height(30f)))
    generator.ClearGrass();
```
Unity rysuje zwykłe ustawienia komponentu, a potem dwa przyciski. Kliknięcie przycisku wywołuje odpowiednią metodę generatora.

### 3. Jakie wartości można zmieniać?
Wysokości przycisków wpisane w kodzie to 34 i 30. Zmieniają tylko wygląd panelu. Parametry trawy znajdują się w komponencie `MagicalGrassGenerator`.

### 4. Dodatkowe informacje
To narzędzie edytora, nie skrypt rozgrywki.

---

## CrystalFloat.cs
**Plik:** `Assets/Scripts/Effects/Crystals/CrystalFloat.cs`

### 1. Jaki efekt to daje?
Kryształ unosi się i opada, a opcjonalnie obraca się wokół własnej osi.

### 2. Jak to jest zrobione?
```csharp
startPosition = transform.localPosition;
randomOffset = Random.Range(0f, Mathf.PI * 2f);
float offsetY = Mathf.Sin(Time.time * frequency * 2f * Mathf.PI + randomOffset) * amplitude;
transform.localPosition = startPosition + Vector3.up * offsetY;
if (rotate)
    transform.Rotate(Vector3.up, rotationSpeed * Time.deltaTime, Space.Self);
```
Na początku skrypt zapamiętuje lokalne położenie i losuje punkt startowy cyklu. Potem sinus wylicza łagodne przesunięcie w pionie, a amplituda ogranicza jego wysokość. Obrót jest niezależny od unoszenia.

### 3. Jakie wartości można zmieniać?
- `amplitude = 0.2` — wysokość unoszenia; zwiększenie wzmacnia ruch.
- `frequency = 0.8` — tempo cyklu góra–dół.
- `rotate = true` — włącza lub wyłącza obrót.
- `rotationSpeed = 10` — stopnie obrotu na sekundę.
- `randomOffset` jest losowany od 0 do 2π przy starcie, aby kryształy nie poruszały się synchronicznie.

### 4. Dodatkowe informacje
Skrypt zmienia Transform obiektu i nie steruje shaderem.

---

## MagicSpiral.cs
**Plik:** `Assets/Scripts/Effects/Crystals/MagicSpiral.cs`

### 1. Jaki efekt to daje?
Tworzy spiralę kulek wokół obiektu. Kulki obracają się, wznoszą, zawijają z powrotem na dół i pulsują. Mogą pojawiać się po zbliżeniu gracza.

### 2. Jak to jest zrobione?
```csharp
GameObject particle = GameObject.CreatePrimitive(PrimitiveType.Sphere);
particle.transform.SetParent(particleRoot, false);
Destroy(particle.GetComponent<Collider>());
offsets[i] = (float)i / particleCount;
float progress = Mathf.Repeat(offsets[i] + Time.time * upwardSpeed / height, 1f);
float angle = offsets[i] * Mathf.PI * 2f + Time.time * rotationSpeed;
float x = Mathf.Cos(angle) * radius;
float z = Mathf.Sin(angle) * radius;
float y = progress * height;
```
Skrypt tworzy sfery, usuwa collider, bo kulki są dekoracją, i rozsuwa je początkowo równomiernie. Sinus i cosinus wyznaczają okrąg, a powtarzany postęp wyznacza wysokość i powoduje cykliczny powrót na dół. Osobny sinus zmienia skalę, tworząc puls. Sprawdzanie odległości włącza lub ukrywa całą grupę.

### 3. Jakie wartości można zmieniać?
- `player` — obiekt, którego odległość aktywuje efekt.
- `particleMaterial` — materiał kulek; wymagany.
- `particleCount = 60` — liczba kulek; minimum 1.
- `radius = 1.2` — odsunięcie od środka; minimum 0.1.
- `height = 5` — wysokość spirali; minimum 0.5.
- `rotationSpeed = 2` — tempo obiegu; minimum 0.1.
- `upwardSpeed = 1.5` — tempo wznoszenia; minimum 0.1.
- `particleSize = 0.07` — rozmiar; minimum 0.01.
- `activationDistance = 5` — zasięg aktywacji; minimum 0.1.
- `alwaysActive = false` — włącza efekt bez sprawdzania zasięgu.
- Puls ma stały zakres skali 0.5–1 wartości bazowej; nie ma osobnych ustawień.

### 4. Dodatkowe informacje
To osobne obiekty sferyczne, nie wbudowany system cząsteczek Unity. Po zniszczeniu skrypt usuwa utworzoną grupę.

---

## ProceduralCrystalSparks.cs
**Plik:** `Assets/Scripts/Effects/Crystals/ProceduralCrystalSparks.cs`

### 1. Jaki efekt to daje?
Iskry krążą wokół kryształu, unoszą się, lekko zbaczają z toru, pulsują oraz pojawiają się i znikają. Są płaskimi kształtami zwróconymi do kamery.

### 2. Jak to jest zrobione?
```csharp
vertices = new Vector3[count * 4];
triangles = new int[count * 6];
float wobbleX = Mathf.Sin(Time.time * wobbleSpeed + spark.phase) * wobbleAmount;
float wobbleZ = Mathf.Cos(Time.time * wobbleSpeed * 0.8f + spark.phase) * wobbleAmount;
float normalizedAge = spark.age / spark.lifetime;
float fadeIn = Mathf.Clamp01(normalizedAge * 5f);
float fadeOut = Mathf.Clamp01((1f - normalizedAge) * 4f);
float alpha = fadeIn * fadeOut * pulse;
```
Każda iskra składa się z czterech wierzchołków i dwóch trójkątów. Wszystkie zapisane są w jednej siatce. Skrypt przechowuje kąt, wysokość, wiek, czas życia, promień, rozmiar, fazę i szybkość dla każdej iskry. Sinus i cosinus dodają kołysanie, a czas życia steruje narastaniem i zanikaniem przezroczystości. Każdą klatkę skrypt aktualizuje pozycje i kolory siatki.

### 3. Jakie wartości można zmieniać?
- `crystal` — środek efektu; domyślnie używa rodzica albo własnego obiektu.
- `sparkMaterial` — materiał iskier.
- `sparkCount = 71` — liczba iskier, zakres 5–100.
- `orbitRadius = 1.55` — zasięg orbity.
- `sparkSize = 0.06` — wielkość iskry.
- `lifetime = 3` — bazowy czas życia; indywidualne czasy losowane są w zakresie 70–130% tej wartości.
- `orbitSpeed = 0.7` — szybkość obiegu.
- `riseSpeed = 0.3` — szybkość unoszenia.
- `wobbleAmount = 0.88` — wielkość bocznego odchylenia.
- `wobbleSpeed = 0.5` — tempo odchylenia.
- Stałe kodu: 4 wierzchołki na iskrę, mnożniki zanikania 5 i 4 oraz puls zależny od czasu i fazy.

### 4. Dodatkowe informacje
Kamera jest pobierana jako główna. Gdy jej nie ma, stosowane są osie świata. Siatka jest oznaczona jako często zmieniana i zwalniana przy niszczeniu obiektu.

---

## FogPlayerExclusion.cs
**Plik:** `Assets/Scripts/Environment/Fog/FogPlayerExclusion.cs`

### 1. Jaki efekt to daje?
Tworzy w dymie GroundFog rzadszą strefę wokół gracza. Strefa podąża za graczem.

### 2. Jak to jest zrobione?
```csharp
Vector3 playerPosition = player.position;
fogRenderer.GetPropertyBlock(properties);
properties.SetVector(PlayerPositionID,
    new Vector4(playerPosition.x, playerPosition.y, playerPosition.z, 1f));
fogRenderer.SetPropertyBlock(properties);
```
W każdej późnej aktualizacji skrypt pobiera pozycję gracza i przekazuje ją do renderera przez blok właściwości. GroundFog używa pozycji poziomej do obliczenia odległości każdej próbki dymu. Wewnątrz promienia ogranicza gęstość, a przy krawędzi stopniowo ją przywraca.

### 3. Jakie wartości można zmieniać?
- `player` — Transform gracza, wymagany do działania.
- Skrypt nie ma własnego promienia. W materiale GroundFog wartości `_ExclusionRadius` i `_ExclusionFeather` określają rozmiar strefy i szerokość przejścia.

### 4. Dodatkowe informacje
Wymaga renderera na tym samym obiekcie. W scenach `Scene1` i `SampleScene` renderer korzysta z `GroundFog_Mat`. Pozycja jest przekazywana do renderera bez tworzenia kopii materiału.

---

## GodRaysController.cs
**Plik:** `Assets/Scripts/Environment/Lighting/GodRaysController.cs`

### 1. Jaki efekt to daje?
Ustawia położenie źródła promieni na ekranie i płynnie reguluje ich intensywność. Światło za kamerą wyłącza efekt.

### 2. Jak to jest zrobione?
```csharp
Vector3 lightDirection = -directionalLight.transform.forward;
Vector3 lightPoint = targetCamera.transform.position + lightDirection * 1000f;
Vector3 screenPosition = targetCamera.WorldToViewportPoint(lightPoint);
float frontFactor = screenPosition.z > 0f ? 1f : 0f;
float heightFactor = Mathf.InverseLerp(0.0f, 0.8f, y);
heightFactor = Mathf.SmoothStep(0f, 1f, heightFactor);
currentIntensity = Mathf.Lerp(currentIntensity, targetIntensity,
    1f - Mathf.Exp(-speed * Time.deltaTime));
godRaysMaterial.SetFloat(RayIntensity, currentIntensity);
```
Kierunkowe światło nie ma jednego punktu w przestrzeni, dlatego skrypt tworzy punkt daleko w kierunku jego padania. Kamera przelicza go na położenie ekranowe. Wysokość tego miejsca wpływa na docelową intensywność, a światło za kamerą daje intensywność zerową. Funkcja wygładzająca stopniowo zbliża aktualną wartość do docelowej. Skrypt przekazuje pozycję i jasność materiałowi promieni.

### 3. Jakie wartości można zmieniać?
- `targetCamera`, `directionalLight`, `godRaysMaterial` — kamera, światło i materiał; wszystkie muszą być przypisane.
- `smoothSpeed = 1.5`, zakres 0.1–5 — szybkość wygładzania; większa wartość szybciej reaguje.
- `minimumIntensity = 0.2`, zakres 0–1 — minimalna intensywność przed uwzględnieniem położenia światła.
- W kodzie punkt jest odsunięty o 1000 jednostek; współrzędne ekranu ograniczane są do zakresu od -1 do 2. Wysokość mapowana jest w zakresie 0–0.8.

### 4. Dodatkowe informacje
`[ExecuteAlways]` uruchamia aktualizację także w edytorze. Brak którejkolwiek referencji pomija aktualizację. Shader GodRays dodatkowo ma własne ustawienia materiału.

---

## MagicalGrassGenerator.cs
**Plik:** `Assets/Scripts/Flora/MagicalGrassGenerator.cs`

### 1. Jaki efekt to daje?
Tworzy na terenie kępki trawy o zróżnicowanej wysokości, szerokości, kolorze i wygięciu.

### 2. Jak to jest zrobione?
```csharp
int countX = Mathf.CeilToInt(size.x / chunkSize);
int countZ = Mathf.CeilToInt(size.z / chunkSize);
float y = data.GetInterpolatedHeight(u, v);
Vector3 normal = data.GetInterpolatedNormal(u, v);
Vector3 secondDirection = Vector3.Cross(worldNormal, direction).normalized;
AddBladePlane(vertices, uvs, colors, triangles,
    worldPosition, worldNormal, direction, randomHeight, width, random);
AddBladePlane(vertices, uvs, colors, triangles,
    worldPosition, worldNormal, secondDirection, randomHeight, width, random);
```
Po sprawdzeniu terenu i materiału generator dzieli teren na fragmenty. W każdym losuje pozycje źdźbeł, pobiera wysokość i nachylenie gruntu, a potem losuje rozmiar, obrót i kolor. Każde źdźbło składa się z dwóch płaszczyzn ustawionych na krzyż. Każda płaszczyzna ma trzy odcinki, zwęża się ku górze i jest lekko wygięta. Gotowe dane są zapisywane w siatce przypisanej do obiektu fragmentu.

### 3. Jakie wartości można zmieniać?
- `terrain` — teren docelowy.
- `density = 1.5` — liczba źdźbeł na jednostkę powierzchni; minimum 0.1.
- `chunkSize = 10` — rozmiar fragmentu terenu; minimum 1.
- `minHeight = 0.35`, `maxHeight = 0.8` — zakres wysokości; minimum dla obu 0.1.
- `bladeWidth = 0.09` — szerokość źdźbła; minimum 0.01.
- `curvature = 0.3` — stała siła wygięcia, zakres 0–1.
- `heightRandomness = 0.4`, `widthRandomness = 0.3` — losowe różnice wymiarów, zakres 0–1.
- `seed = 12345` — ziarno losowania; ta sama wartość daje powtarzalny układ przy tej samej kolejności obliczeń.
- `grassMaterial` — materiał, którym rysowana jest trawa.
- W kodzie: 3 segmenty na płaszczyznę; losowa zmienność koloru wierzchołków od 0.8 do 1.2; przy ponad 65535 wierzchołkach używany jest szerszy format indeksów.

### 4. Dodatkowe informacje
Generator uruchamia się z menu kontekstowego lub przycisku edytora, a nie automatycznie w czasie gry. Czyszczenie usuwa wyłącznie dzieci o nazwie zaczynającej się od `MagicalGrass_`.

---

## MagicTreeActivation.cs
**Plik:** `Assets/Scripts/Flora/MagicTreeActivation.cs`

### 1. Jaki efekt to daje?
Skrypt przygotowuje animację fali po zbliżeniu gracza do drzewa. Jednak shader liści nie odczytuje wartości fali, więc jej widoczny efekt nie jest potwierdzony.

### 2. Jak to jest zrobione?
```csharp
if (!active && distance <= activationDistance)
{
    active = true;
    waveHeight = transform.position.y;
    glowTimer = glowDuration;
}
waveHeight += waveSpeed * Time.deltaTime;
glowTimer -= Time.deltaTime;
block.SetFloat(WaveHeightID, waveHeight);
block.SetFloat(ActivationID, activation);
treeRenderer.SetPropertyBlock(block);
```
Skrypt mierzy odległość gracza. Po wejściu w zasięg rozpoczyna od wysokości podstawy drzewa. W każdej klatce przesuwa wartość wysokości w górę i zmniejsza siłę blasku. Przekazuje obie wartości rendererom drzewa. Po przekroczeniu zadanej wysokości wyłącza animację i zeruje siłę. Ten skrypt nie aktywuje pnączy — ich aktywację obsługuje osobny `MagicTreeVines`.

To działanie istnieje w skrypcie, ale w `TreeSpirals.shader` nie ma obliczeń używających wysokości ani siły fali. Samo wysyłanie wartości nie tworzy efektu, jeśli shader ich nie odczytuje.

### 3. Jakie wartości można zmieniać?
- `player` — obiekt gracza.
- `treeRenderers` — renderery drzewa; jeśli lista jest pusta, skrypt pobiera renderery dzieci.
- `activationDistance = 4` — zasięg uruchomienia, minimum 0.1.
- `waveSpeed = 3` — szybkość przesuwania wartości wysokości, minimum 0.1.
- `treeHeight = 6` — wysokość, przy której skrypt kończy animację, minimum 0.1.
- `glowDuration = 2` — czas wygaszania, minimum 0.
- Stałe zabezpieczające: dzielnik czasu nie może spaść poniżej 0.01, siła ograniczana jest do 0–1, a po zakończeniu wysokość ustawiana jest na -100.

### 4. Dodatkowe informacje
Wartości przekazywane są przez `MaterialPropertyBlock`, osobno dla każdego renderera i bez tworzenia kopii materiału. Materiały drzewa mają wpisy tych parametrów, ale shader ich nie używa.

---

## MagicTreeVines.cs
**Plik:** `Assets/Scripts/Flora/MagicTreeVines.cs`

### 1. Jaki efekt to daje?
Tworzy spiralne pnącza oplatające pień oraz świetliki krążące, unoszące się i pulsujące wokół drzewa.

### 2. Jak to jest zrobione?
```csharp
float angle = startAngle + t * turns * Mathf.PI * 2f;
float variation = Mathf.Sin(t * 17f + phase1) * irregularity
    + Mathf.Sin(t * 31f + phase2) * irregularity * 0.4f;
float x = Mathf.Cos(angle) * r;
float z = Mathf.Sin(angle) * r;
float y = vineHeight * t
    + Mathf.Sin(t * Mathf.PI * 2f + phase1) * 0.08f;
```
Punkty pnącza są obliczane raz na początku. Kąt i sinusy układają je w spiralę z nieregularnym promieniem i falującą wysokością. Potem LineRenderer pokazuje coraz dłuższy fragment tej ścieżki. Opóźnienie rozdziela w czasie wzrost kolejnych pnączy. Po dezaktywacji ich widoczna długość maleje.

Świetliki są sferami bez colliderów. Dla każdej wyliczana jest orbita i wysokość, a sinusy dodają boczne kołysanie. Puls zmienia ich rozmiar. Skala zależy również od tego, jak bardzo urosły pnącza.

### 3. Jakie wartości można zmieniać?
- `vineMaterial` — wymagany materiał pnączy; bez niego skrypt się wyłącza.
- `fireflyMaterial` — materiał świetlików; domyślnie używa materiału pnączy, jeśli nie przypisano osobnego.
- `player` — gracz do pomiaru zasięgu.
- `activationDistance = 5` — zasięg aktywacji gracza. `alwaysActive = true` jest wartością domyślną kodu; gdy jest włączone, pnącza rosną niezależnie od gracza. W `SampleScene` wartość jest ustawiona na `false`, więc pnącza reagują na wejście gracza w promień 5.
- `vineCount = 5`, `pointsPerVine = 100` — liczba linii i punktów; kod ogranicza je odpowiednio do minimum 1 i 10.
- `vineHeight = 4.5`, `trunkRadius = 0.65`, `vineWidth = 0.045`, `spiralTurns = 1.5` — wysokość, promień, grubość i liczba obrotów.
- `irregularity = 0.18`, `sway = 0.06` — siła nierówności i falowania.
- `growthDuration = 3`, minimum 0.1; `delayBetweenVines = 0.45` — czas wzrostu i przerwa między pnączami.
- `fireflyCount = 24`, minimum 0; `fireflyRadius = 1.5`; `fireflyHeight = 4.5`; `fireflySize = 0.055`; `fireflySpeed = 0.7`; `fireflyWobble = 0.18` — liczba i parametry ruchu świetlików.
- Fazy i początkowe kąty są losowane. Częstotliwości falowania i pulsowania są wartościami wpisanymi w kodzie.

### 4. Dodatkowe informacje
Pnącza i świetliki nie rzucają cieni. W `SampleScene` skrypt ma przypisanego gracza i `alwaysActive = false`: po zbliżeniu na 5 jednostek rozpoczyna wzrost, a po oddaleniu zwija pnącza. W prefabach `oak_tree (1)` i `sakura_tree` pole gracza jest puste, a stała aktywacja wyłączona; same prefaby bez przypisania gracza nie uruchomią efektu. Materiały przypisywane są w Inspectorze, a skrypt nie zmienia parametrów shaderów.

---

## PlayerMovement.cs
**Plik:** `Assets/Scripts/Gameplay/Player/PlayerMovement.cs`

### 1. Jaki efekt to daje?
Steruje ruchem gracza z pierwszej osoby: WASD, rozglądaniem myszą, grawitacją i blokowaniem kursora.

### 2. Jak to jest zrobione?
```csharp
input = Vector2.ClampMagnitude(input, 1f);
Vector3 direction = transform.right * input.x
    + transform.forward * input.y;
if (characterController.isGrounded && verticalVelocity < 0f)
    verticalVelocity = -2f;
verticalVelocity += gravity * Time.deltaTime;
Vector3 velocity = direction * moveSpeed + Vector3.up * verticalVelocity;
characterController.Move(velocity * Time.deltaTime);
```
Skrypt zbiera wciśnięte klawisze i zamienia je na kierunek względem obrotu gracza. Ograniczenie długości kierunku zapobiega szybszemu ruchowi po przekątnej. Grawitacja zwiększa prędkość pionową. Na ziemi ustawiana jest niewielka prędkość w dół, aby utrzymać kontakt z podłożem. CharacterController przesuwa postać i uwzględnia kolizje.

Mysz obraca postać w poziomie i kamerę w pionie. Pochylenie kamery jest ograniczone. Escape pokazuje kursor, a kliknięcie ponownie go chowa i blokuje.

### 3. Jakie wartości można zmieniać?
- `moveSpeed = 5` — prędkość ruchu.
- `gravity = -9.81` — przyspieszenie w dół.
- `cameraTransform` — kamera; gdy nie jest przypisana, skrypt szuka kamery potomnej.
- `mouseSensitivity = 0.1` — czułość myszy.
- `maxLookAngle = 85` — maksymalne pochylenie w pionie.
- Wartość przyklejenia do ziemi wynosi -2. Skrypt nie ma skoku.

### 4. Dodatkowe informacje
Wymaga CharacterController i aktywnej klawiatury z Input System. Brak przypisanej lub znalezionej kamery powoduje wyłączenie skryptu.

---

## ReadmeEditor.cs
**Plik:** `Assets/TutorialInfo/Scripts/Editor/ReadmeEditor.cs`

### 1. Jaki efekt to daje?
Pokazuje instrukcję projektu w Inspectorze: ikonę, tytuł, nagłówki, tekst i klikalne linki.

### 2. Jak to jest zrobione?
```csharp
foreach (var section in readme.sections)
{
    if (!string.IsNullOrEmpty(section.heading))
        GUILayout.Label(section.heading, HeadingStyle);
    if (!string.IsNullOrEmpty(section.text))
        GUILayout.Label(section.text, BodyStyle);
    if (!string.IsNullOrEmpty(section.linkText))
    {
        if (LinkLabel(new GUIContent(section.linkText)))
            Application.OpenURL(section.url);
    }
}
```
Skrypt przechodzi po sekcjach instrukcji i rysuje tylko niepuste elementy. Kliknięcie linku otwiera zapisany adres. Style tekstu tworzone są raz i używane ponownie. Pozostałe metody zaznaczają asset Readme, rysują nagłówek, przygotowują wygląd etykiet i mogą odtworzyć układ okien edytora.

### 3. Jakie wartości można zmieniać?
Nie ma pól efektu w Inspectorze. Treść pochodzi z Readme. Rozmiary tekstu ustawione w kodzie to 14, tytułu 26 i nagłówka 18; odstęp między częściami to 16. Kolor linku jest stały.

### 4. Dodatkowe informacje
To skrypt edytora, nie gry. Przywracanie układu korzysta z wewnętrznej funkcji Unity przez Reflection i może zależeć od wersji edytora.

---

## Readme.cs
**Plik:** `Assets/TutorialInfo/Scripts/Readme.cs`

### 1. Jaki efekt to daje?
Nie zmienia sceny. Przechowuje dane instrukcji wyświetlanej przez `ReadmeEditor`.

### 2. Jak to jest zrobione?
```csharp
public Texture2D icon;
public string title;
public Section[] sections;
public bool loadedLayout;

[Serializable]
public class Section
{
    public string heading, text, linkText, url;
}
```
To asset Unity z ikoną, tytułem, listą sekcji i informacją o układzie edytora. Każda sekcja może zawierać nagłówek, tekst i link z adresem.

### 3. Jakie wartości można zmieniać?
- `icon`, `title`, `sections`, `loadedLayout` — dane głównego assetu.
- `heading`, `text`, `linkText`, `url` — dane pojedynczej sekcji.
- Kod nie przypisuje tym polom wartości początkowych.

### 4. Dodatkowe informacje
To element tutorialu edytora, a nie system rozgrywki.

# Shadery

## Krysztal.shader
**Plik:** `Assets/Shaders/Effects/Krysztal.shader`

### 1. Jaki efekt to daje?
Tworzy przezroczysty niebieski kryształ z jasnymi krawędziami. Krawędzie świecą mocniej, gdy patrzymy na powierzchnię pod ostrym kątem.

### 2. Jak to jest zrobione?
```hlsl
half fresnel = 1.0h - saturate(dot(normal, viewDir));
fresnel = pow(fresnel, _FresnelPower);
half3 fresnelEmission = _FresnelColor.rgb * fresnel
    * _FresnelStrength * _GlowStrength;
half3 finalColor = baseColor + fresnelEmission;
half alpha = saturate(_Transparency + fresnel * 0.35h);
```
Wierzchołek przekazuje kierunek normalnej powierzchni i kierunek do kamery. Shader porównuje te kierunki. Patrząc prosto na ścianę kryształu, widzimy głównie kolor bazowy. Patrząc wzdłuż krawędzi, pojawia się więcej poświaty. Potęga zmienia szerokość tego przejścia. Poświata jest dodawana do koloru kryształu, a przezroczystość lekko rośnie przy krawędziach.

### 3. Jakie wartości można zmieniać?
- `_CrystalColor` — HDR, domyślnie `(0.15, 0.8, 1, 1)`. Kolor bazowy.
- `_Transparency = 0.4`, zakres 0.05–1. Większa wartość czyni kryształ bardziej kryjącym.
- `_FresnelColor` — HDR, domyślnie `(0.2, 0.9, 1, 1)`. Kolor krawędzi.
- `_FresnelPower = 3`, zakres 0.5–8. Większa wartość skupia poświatę w węższym obszarze.
- `_FresnelStrength = 2`, zakres 0–5. Siła krawędzi.
- `_GlowStrength = 1.5`, zakres 0–10. Dodatkowy mnożnik jasności.
- Stałe w kodzie: krawędź może dodać do przezroczystości maksymalnie `0.35`.

### 4. Dodatkowe informacje
Shader URP miesza kolor z tłem, nie zapisuje głębi i renderuje przednie ściany modelu.

---

## ProceduralSparks.shader
**Plik:** `Assets/Shaders/Effects/ProceduralSparks.shader`

### 1. Jaki efekt to daje?
Nadaje iskrom jasny rdzeń i miękką poświatę. Iskra dodaje światło do obrazu zamiast całkowicie zasłaniać tło.

### 2. Jak to jest zrobione?
```hlsl
float2 p = input.uv * 2.0 - 1.0;
float r = length(p);
float halo = exp(-r * r * (3.0 / max(_Softness, 0.05)));
float core = 1.0 - smoothstep(_CoreSize * 0.5, _CoreSize, r);
float glow = saturate(halo * 0.65 + core);
half3 color = _SparkColor.rgb * _Intensity * glow;
```
Współrzędne kwadratu są przeliczane tak, aby jego środek był punktem zero. Odległość od środka określa jasność. Jedno obliczenie tworzy szeroką miękką poświatę, drugie mniejszy jasny rdzeń. Ich suma jest ograniczana do poprawnego zakresu i mnożona przez kolor oraz intensywność materiału. Ruch i zanikanie iskier wykonuje `ProceduralCrystalSparks`, a ten shader tworzy tylko ich świetlny wygląd.

### 3. Jakie wartości można zmieniać?
- `_SparkColor` — HDR, domyślnie `(0.1, 0.8, 1, 1)`. Kolor i alfa.
- `_Intensity = 3`, zakres 0–10. Jasność iskry.
- `_Softness = 0.7`, zakres 0.05–2. Większa wartość poszerza poświatę.
- `_CoreSize = 0.25`, zakres 0.05–0.8. Rozmiar jasnego środka.
- Stała `0.65` określa udział poświaty przy łączeniu jej z rdzeniem.

### 4. Dodatkowe informacje
Używa addytywnego mieszania z tłem, nie zapisuje głębi i renderuje obie strony kwadratu.

---

## Fog.shader
**Plik:** `Assets/Shaders/Environment/Fog.shader`

### 1. Jaki efekt to daje?
Dodaje mgłę zależną od odległości od kamery. Dalekie obiekty mieszają się z kolorem mgły; niebo otrzymuje osobną, łagodniejszą mgłę.

### 2. Jak to jest zrobione?
```hlsl
float distanceFactor = saturate(
    (distanceToCamera - _FogStart) /
    max(_FogEnd - _FogStart, 0.001));
float distanceFog =
    (1.0 - exp(-_FogDensity * distanceFactor)) / denominator;
float fogFactor = lerp(_NearFogStrength, 1.0, saturate(distanceFog));
half3 finalColor = lerp(sceneColor.rgb, _FogColor.rgb, saturate(fogFactor));
```
Shader pobiera gotowy kolor sceny oraz mapę głębokości. Głębia pozwala odtworzyć położenie widocznego obiektu i zmierzyć jego odległość od kamery. Odległość jest przeliczana na stopień zamglenia, po czym kolor obiektu jest mieszany z kolorem mgły. Niebo rozpoznawane jest po braku geometrii w mapie głębokości i ma osobną siłę. Wartości graniczne zabezpieczają obliczenia przed dzieleniem przez zero.

### 3. Jakie wartości można zmieniać?
- `_FogColor` — HDR, domyślnie `(0.48, 0.66, 0.64, 1)`. Kolor mgły.
- `_FogStart = 0`. Odległość rozpoczęcia narastania.
- `_FogEnd = 55`. Odległość, przy której mgła osiąga pełną siłę.
- `_FogDensity = 4`, zakres 0.1–8. Większa wartość szybciej wzmacnia mgłę.
- `_NearFogStrength = 0.06`, zakres 0–0.25. Minimalna mgła na geometrii blisko kamery.
- `_SkyFogStrength = 0.12`, zakres 0–0.5. Mgła na niebie.
- Zabezpieczenia w kodzie używają minimum `0.001` dla dzielników.

### 4. Dodatkowe informacje
To ekranowy efekt URP korzystający z głębi obrazu. Nie jest dymem w przestrzeni i nie korzysta z pozycji gracza. Mgłę przy graczu tworzy osobny `GroundFog.shader`.

---

## GodRays.shader
**Plik:** `Assets/Shaders/Environment/GodRays.shader`

### 1. Jaki efekt to daje?
Dodaje na obrazie promienie wychodzące z miejsca światła widocznego na ekranie. Są silniejsze, gdy w kierunku światła widoczne jest niebo, i słabsze, gdy drogę zasłania obiekt.

### 2. Jak to jest zrobione?
```hlsl
float2 rayVector = (lightUV - uv) * _RayDensity;
int samples = clamp((int)_RaySamples, 8, 32);
float t = (i + 0.5) / samples;
float2 sampleUV = uv + rayVector * t;
illumination += skyMask * decay;
weightSum += decay;
decay *= _RayWeight;
float visibility = illumination / max(weightSum, 0.0001);
```
Dla każdego piksela shader wyznacza kierunek do pozycji światła przekazanej przez `GodRaysController`. Wzdłuż tego kierunku sprawdza kilka miejsc mapy głębokości. Miejsca będące niebem dodają wkład do wyniku, a kolejne próbki mają coraz mniejszą wagę. Wynik jest uśredniany i porównywany z progiem. Jeśli jest wystarczająco wysoki, shader dodaje do obrazu kolor promieni.

### 3. Jakie wartości można zmieniać?
- `_RayColor` — HDR `(0.75, 0.85, 1, 1)`. Kolor promieni.
- `_RayIntensity = 1`, zakres 0–3. Intensywność; jest też regulowana przez skrypt.
- `_RayDensity = 1`, zakres 0.1–2. Długość odcinka próbkowania.
- `_RayWeight = 0.985`, zakres 0.8–0.999. Jak szybko słabnie wkład kolejnych próbek.
- `_RaySamples = 24`, zakres 8–32. Liczba próbek; więcej daje gładszy wynik, ale zwiększa koszt.
- `_RayThreshold = 0.2`, zakres 0–0.95. Próg widoczności nieba potrzebny do pojawienia się promieni.
- `_RayExposure = 0.8`, zakres 0–3. Dodatkowa jasność.
- `_LightScreenPos = (0.5, 0.8, 0, 1)`. Pozycja światła na ekranie; aktualizuje ją kontroler.
- Pętla ma limit 32 próbek, niezależnie od wartości materiału.

### 4. Dodatkowe informacje
To efekt ekranowy, nie rzeczywiste światło wolumetryczne. Shader korzysta z obrazu i głębi sceny, nie zapisuje własnej głębi.

---

## GroundFog.shader
**Plik:** `Assets/Shaders/Environment/GroundFog.shader`

### 1. Jaki efekt to daje?
Tworzy półprzezroczysty, animowany obłok dymu z większymi plamami, drobnymi detalami, unoszeniem i wirowaniem. Dym jest rzadszy blisko gracza.

### 2. Jak to jest zrobione?
```hlsl
#define STEPS 32
float broadShape = FBM(warpedP * _SmokeScale);
float detail = FBM(warpedP * _DetailScale);
float noiseValue = broadShape * 0.75 + detail * 0.25;
float density = smoothstep(0.35, 0.35 + _Softness, noiseValue);
float playerDistance = distance(sampleWorldPos.xz, _PlayerPosition.xz);
float playerMask = smoothstep(_ExclusionRadius,
    _ExclusionRadius + _ExclusionFeather, playerDistance);
density *= playerMask;
float alpha = 1.0 - exp(-density * _Density * stepSize * 3.0);
```
Kamera patrzy przez bryłę obłoku. Shader wyznacza, gdzie promień kamery wchodzi do bryły i ją opuszcza, a mapę głębokości wykorzystuje, by nie rysować dymu przed najbliższym obiektem. Pozostały odcinek dzieli na 32 próbki.

W każdej próbce kilka warstw proceduralnego szumu tworzy nieregularne obłoki i szczegóły. Przesuwanie i zniekształcanie współrzędnych daje unoszenie i wir. Miękkie progi zamieniają szum na gęstość, a maski pionowe wygładzają dół i górę obłoku.

Dla każdej próbki shader porównuje położenie na płaszczyźnie poziomej z pozycją gracza przekazaną przez `FogPlayerExclusion`. W promieniu gracza gęstość maleje; na krawędzi wraca stopniowo. Potem każda próbka dodaje kolor i przezroczystość do wyniku. Gdy obłok jest prawie kryjący, shader kończy liczenie wcześniejszym wyjściem z pętli.

### 3. Jakie wartości można zmieniać?
- `_SmokeColor` — HDR `(0.35, 0.45, 0.55, 1)`. Główny kolor dymu.
- `_GlowColor` — HDR `(0.25, 0.55, 0.8, 1)`. Kolor jaśniejszych fragmentów.
- `_Density = 1.5`, zakres 0–5. Gęstość i kryjący wygląd.
- `_SmokeScale = 5`, zakres 1–20. Skala dużych kształtów.
- `_DetailScale = 15`, zakres 1–40. Skala drobnych szczegółów.
- `_WarpStrength = 0.12`, zakres 0–1. Siła zniekształceń i falowania.
- `_Softness = 0.25`, zakres 0.01–1. Łagodność przejścia między dymem a pustym miejscem.
- `_VerticalFade = 0.12`, zakres 0.01–0.5. Szerokość zanikania na górze i dole.
- `_RiseSpeed = 0.05`, zakres 0–2. Szybkość unoszenia wzoru.
- `_SwirlSpeed = 0.15`, zakres 0–3. Szybkość wirowania.
- `_GlowStrength = 1`, zakres 0–5. Siła jaśniejszych fragmentów.
- `_PlayerPosition` — początkowo `(0, 0, 0, 1)`, ustawiana przez skrypt gracza.
- `_ExclusionRadius = 2.5`, zakres 0–10. Promień rzadszej strefy.
- `_ExclusionFeather = 1.5`, zakres 0.01–5. Szerokość jej miękkiego przejścia.
- Stałe kodu: 32 kroki, udział dużych kształtów 0.75, detali 0.25, próg szumu 0.35 i mnożnik przezroczystości 3.

### 4. Dodatkowe informacje
Shader jest przezroczysty, korzysta z głębi, rysuje wewnętrzne powierzchnie bryły i nie zapisuje głębi. Koszt zależy od liczby pikseli obłoku i 32 próbek. Materiał `GroundFog_Mat` jest użyty na rendererach ze skryptem wykluczenia w scenach `Scene1` i `SampleScene`.

## Grass.shader
**Plik:** `Assets/Shaders/Flora/Grass.shader`

### 1. Jaki efekt to daje?
Nadaje źdźbłom gradient od ciemnej zieleni przy ziemi do turkusu na końcach. Końcówki świecą, a źdźbła poruszają się jak na wietrze.

### 2. Jak to jest zrobione?
```hlsl
float wind = sin(_Time.y * _WindSpeed
    + positionWS.x * _WindScale
    + positionWS.z * _WindScale);
float bend = height * height;
positionWS.x += wind * _WindStrength * bend;
positionWS.z += cos(_Time.y * _WindSpeed * 0.7
    + positionWS.x * _WindScale) * _WindStrength * bend * 0.5;

float3 baseToMiddle = lerp(_BaseColor.rgb, _MiddleColor.rgb,
    smoothstep(0.0, 0.65, height));
float3 grassColor = lerp(baseToMiddle, _TipColor.rgb,
    smoothstep(0.65, 1.0, height));
float3 emission = _TipColor.rgb * tipMask * _EmissionStrength;
```
Shader przelicza wierzchołki do przestrzeni świata. Wysokość źdźbła jest podnoszona do kwadratu przed zastosowaniem wiatru, więc podstawa prawie się nie rusza, a końcówka mocniej się wychyla. Sinus i cosinus poruszają źdźbło w dwóch kierunkach. Położenie w świecie różnicuje fazę wiatru w różnych częściach łąki.

Kolor zależy od wysokości: shader miesza kolor podstawy ze środkowym, a potem dodaje kolor końcówki. Kolor wierzchołków przygotowany przez generator lekko rozjaśnia lub przyciemnia wynik. Osobna maska obejmuje końcówkę, gdzie dodawana jest emisja.

### 3. Jakie wartości można zmieniać?
- `_BaseColor` — `(0.025, 0.12, 0.045, 1)`. Kolor nasady.
- `_MiddleColor` — `(0.08, 0.55, 0.18, 1)`. Kolor środka.
- `_TipColor` — `(0, 0.9, 0.85, 1)`. Kolor i emisja końcówek.
- `_EmissionStrength = 3`, zakres 0–10. Siła świecenia końców.
- `_WindStrength = 0.15`, zakres 0–1. Wielkość wygięcia przez wiatr.
- `_WindSpeed = 1.5`, zakres 0–5. Tempo wiatru.
- `_WindScale = 1`, zakres 0–5. Wpływ położenia na różnice fazy wiatru.
- `_BladeCurve = 0.25`, zakres 0–1. Stałe wygięcie niezależne od wiatru.
- Stałe w kodzie: gradient przechodzi przez wysokości 0.65, maska końców zaczyna się przy 0.72, a jasność koloru wierzchołka zmienia się od 0.85 do 1.15.

### 4. Dodatkowe informacje
Shader URP rysuje obie strony źdźbeł i zapisuje głębię. Geometrię i kolor wierzchołków przygotowuje `MagicalGrassGenerator`; ruch wiatru oraz gradient wykonuje shader.

---

## Grzyby.shader
**Plik:** `Assets/Shaders/Flora/Grzyby.shader`

### 1. Jaki efekt to daje?
Nakłada teksturę na model, wycina jej przezroczyste fragmenty i dodaje pulsujący blask w górnej części. Materiały `grzybyMat` i `grzyby2Mat` korzystają z tego shadera.

### 2. Jak to jest zrobione?
```hlsl
half4 baseSample = SAMPLE_TEXTURE2D(
    _BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
clip(baseSample.a - _AlphaClip);
half mask = smoothstep(
    _MaskHeight - _MaskFeather,
    _MaskHeight + _MaskFeather,
    input.localHeight);
half pulse = 1.0h - _PulseAmount * 0.5h
    + _PulseAmount * 0.5h * sin(_Time.y * _PulseSpeed);
half3 emission = _GlowColor.rgb * _GlowStrength
    * _BloomBoost * pulse * mask;
```
Wierzchołki dostają pozycję w modelu, współrzędne tekstury i względną wysokość. Dla każdego piksela shader pobiera teksturę i nakłada kolor materiału. Przezroczyste fragmenty poniżej progu są odrzucane, co tworzy wycięte brzegi bez standardowego mieszania przezroczystości.

Wysokość modelu określa obszar świecenia, a miękkie przejście ogranicza ostrą granicę. Sinus zmienia jasność w czasie. Emisja miesza kolor blasku, jego siłę, pulsowanie, wzmocnienie Bloom i maskę wysokości. Na końcu emisja jest dodawana do koloru tekstury.

### 3. Jakie wartości można zmieniać?
- `_BaseMap` — tekstura obiektu; domyślnie biała.
- `_BaseColor` — domyślnie biały; mnoży kolor tekstury.
- `_GlowColor` — HDR, `(1, 0.45, 0.08, 1)`, pomarańczowy kolor blasku.
- `_GlowStrength = 3`, zakres 0–20. Siła emisji.
- `_BloomBoost = 2`, zakres 0–10. Dodatkowe wzmocnienie jasności.
- `_PulseSpeed = 1`, zakres 0–8. Tempo pulsowania.
- `_PulseAmount = 0.2`, zakres 0–1. Wielkość zmian jasności.
- `_ModelBottom = 0`, `_ModelTop = 2`. Dół i góra modelu w jego lokalnym układzie.
- `_MaskHeight = 0.75`, zakres 0–1. Wysokość początku blasku.
- `_MaskFeather = 0.08`, zakres 0.001–0.5. Szerokość miękkiego przejścia.
- `_AlphaClip = 0.3`, zakres 0–1. Większa wartość wycina więcej części tekstury.
- W kodzie pulsowanie ma wartość bazową `1 - PulseAmount/2` i amplitudę `PulseAmount/2`.

### 4. Dodatkowe informacje
Shader URP renderuje obie strony, zapisuje głębię i odrzuca piksele na podstawie alfy. Bloom widoczny wokół modelu zależy także od ustawień post-processingu.

---

## TreeSpirals.shader
**Plik:** `Assets/Shaders/Flora/TreeSpirals.shader`

### 1. Jaki efekt to daje?
Nadaje liściom proceduralne różnice kolorów, główną żyłkę i żyłki boczne. Materiały `TreeSpirals_Mat1`, `TreeSpirals_Mat2` i `TreeSpirals_Mat3` korzystają z tego shadera.

### 2. Jak to jest zrobione?
```hlsl
float pattern = sin(uv.y * 31.0 + sin(uv.x * 17.0) * 1.7)
    * sin(uv.y * 11.0 + uv.x * 9.0);
pattern = pattern * 0.5 + 0.5;
float3 color = lerp(_DarkColor.rgb, _LightColor.rgb, pattern);
color = lerp(_BaseColor.rgb, color, _Variation);
float centerVein = 1.0 - smoothstep(
    0.0, 0.10, abs(uv.x - 0.5));
```
Shader nie pobiera tekstury wzoru liścia. Na podstawie położenia na powierzchni oblicza kilka fal, które tworzą nieregularne plamy. Wynik miesza ciemny, jasny i bazowy kolor. Odległość od środka współrzędnych liścia tworzy główną żyłkę; dodatkowe falowanie i maski tworzą żyłki boczne. Ich kolor nakładany jest na powierzchnię.

Następnie shader przelicza normalną liścia i porównuje ją z kierunkiem głównego światła, dodaje światło otoczenia oraz skupione odbicie. Liście są nieprzezroczyste i renderowane z obu stron. Skrypt `MagicTreeActivation` wysyła temu rendererowi wartości opisujące falę, lecz shader nie deklaruje ani nie odczytuje tych wartości. Widoczna fala nie jest więc potwierdzona przez implementację tego shadera.

### 3. Jakie wartości można zmieniać?
- `_BaseColor` — `(0.10, 0.16, 0.045, 1)`. Podstawowy kolor liścia.
- `_LightColor` — `(0.19, 0.25, 0.075, 1)`. Jasne obszary wzoru.
- `_DarkColor` — `(0.055, 0.085, 0.025, 1)`. Ciemne obszary wzoru.
- `_VeinColor` — `(0.25, 0.30, 0.12, 1)`. Kolor żyłek.
- `_Variation = 0.3`, zakres 0–1. Siła różnicowania koloru.
- `_VeinStrength = 0.2`, zakres 0–1. Widoczność żyłek.
- `_Smoothness = 0.18`, zakres 0–1. Siła gładkiego odbicia.
- W kodzie zapisane są częstotliwości wzorów, szerokość głównej żyłki `0.10`, potęga odbicia `48` i stałe mnożniki składowych oświetlenia.
- Materiały zawierają również `_WaveHeight` i `_Activation`, lecz ten shader ich nie używa.

### 4. Dodatkowe informacje
Shader jest przeznaczony dla URP. Używa przebiegu oświetlanego, zapisuje głębię i nie odrzuca tylnej strony liścia.




# Notatka: efekty a proponowane oceny

Poniższa ocena wskazuje, które elementy projektu pasują do podanych kryteriów. To argumenty do prezentacji, a nie gwarancja oceny — prowadzący ocenia także jakość wykonania i pokazanie efektu w scenie.

## 3.0 — własne shadery materiałów

**Najlepsze przykłady:**
- **Kryształ z efektem Fresnela** — własny shader rozjaśnia krawędzie zależnie od kąta patrzenia kamery. To konkretny, widoczny efekt materiałowy.
- **Pulsujące świecenie modelu** — shader grzybów nakłada teksturę, wycina jej przezroczyste piksele i animuje emisję w górnej części modelu.
- **Trawa** — własny shader animuje zgięcie źdźbeł jak na wietrze, tworzy gradient kolorów i dodaje emisję na końcach.

**Dlaczego pasuje:** to więcej niż dwa własne efekty materiałowe, a każdy ma zastosowanie w leśnej scenie. W prezentacji warto pokazać te materiały na modelach i wyjaśnić, co zmieniają ich ustawienia.

## 3.5 — dynamiczne efekty

**Najlepsze przykłady:**
- **Dym przy ziemi** — shader wylicza i animuje przestrzenny obłok w czasie.
- **Iskry kryształu** — skrypt co klatkę przemieszcza iskry, zmienia ich przezroczystość i aktualizuje ich wspólną siatkę.
- **Pnącza i świetliki** — pnącza rosną i zwijają się, a świetliki krążą i pulsują.
- **Spirala kulek i unoszący się kryształ** — położenie obiektów zmienia się w czasie.

**Dlaczego pasuje:** efekty są animowane podczas działania sceny i mają wygląd pasujący do magicznego lasu. W scenach `Scene1` i `SampleScene` potwierdzono komponenty dymu przy graczu i proceduralnych iskier.

## 4.0 — reakcja na elementy sceny

**Najmocniejszy przykład:** **dym reagujący na pozycję gracza**. Skrypt śledzi gracza, a shader zmniejsza gęstość dymu w jego pobliżu i stopniowo przywraca ją dalej. To bezpośrednia reakcja efektu na obiekt w scenie.

**Drugi przykład:** **promienie zależne od kamery i światła**. Kontroler wylicza ekranowe położenie światła kierunkowego, wygładza jasność i wyłącza ją, gdy światło jest za kamerą. W `Scene1` znaleziono ten kontroler.

**Ograniczenie do uczciwego wyjaśnienia:** skrypt aktywacji drzewa wysyła dane o fali, ale shader liści ich nie odczytuje. Nie należy przedstawiać tego jako działającego połączenia efektu.

**Ocena kryterium:** projekt ma konkretne przykłady reakcji na pozycję gracza oraz układ światła i kamery. Efekty współdziałają z elementami sceny, choć nie wszystkie tworzą jeden wspólny system.

## 4.5 — atmosfera i sposób prezentacji sceny

**Najlepsze przykłady:**
- **GroundFog** tworzy przestrzenny, przezroczysty dym i ogranicza jego widoczność zależnie od głębi sceny.
- **Mgła dystansowa** miesza obraz z kolorem mgły w zależności od odległości obiektów od kamery.
- **God Rays** dodaje ekranowe promienie powiązane z pozycją światła.

**Dlaczego pasuje:** te efekty zmieniają odbiór większej części obrazu i budują atmosferę sceny. Najmocniejszy, potwierdzony w scenach przykład to GroundFog współpracujący z pozycją gracza. Przed prezentacją warto sprawdzić, czy mgła dystansowa i promienie są włączone w używanej konfiguracji renderera.

## 5.0 — zaawansowana technika renderowania

**Najmocniejszy przykład:** własny shader GroundFog wykorzystuje **ray marching**, czyli sprawdzanie wielu punktów wzdłuż promienia widzenia kamery. W projekcie nie jest to tylko gotowa opcja Unity: shader sam przecina promień z bryłą dymu, ogranicza go głębią sceny, wykonuje 32 próbki, oblicza proceduralny szum i składa przezroczystość próbek.

Kształt dymu powstaje z kilku warstw szumu o różnej skali. Shader odkształca ich współrzędne, animuje unoszenie i wir, wygasza górę oraz dół bryły, a następnie zmniejsza gęstość przy graczu. Dzięki temu zaawansowane obliczenia tworzą efekt używany w scenie i reagujący na jej obiekt.

**Dlaczego to jest mocny argument:** implementacja łączy ray marching, proceduralne tworzenie kształtu dymu, głębię sceny, przezroczystość i pozycję gracza. To bezpośrednio odpowiada przykładom zaawansowanych efektów wolumetrycznych i ray marchingu z kryterium. Warto podczas obrony wyjaśnić, że większa liczba próbek może poprawić gładkość, ale podnosi koszt obliczeń.

## Krótka rekomendacja do prezentacji

Najlepiej zbudować prezentację wokół trzech łatwych do pokazania przykładów: kryształu z Fresnelem jako efektu materiałowego, iskier jako efektu dynamicznego oraz GroundFog jako zaawansowanego efektu reagującego na gracza. Pokazują one kolejne poziomy trudności i mają konkretne potwierdzenie w kodzie projektu. Nie opieraj argumentacji na fali świetlnej z `MagicTreeActivation`, bo shader liści jej nie obsługuje. Pnącza można natomiast pokazać jako osobny efekt aktywowany przez zbliżenie gracza.

