
Uwzględniono wszystkie pliki C# w folderze Assets i osiem własnych shaderów z Assets/Shaders. Zewnętrzne shadery pakietu SineVFX pominięto. Każdy plik ma ten sam układ: efekt, sposób wykonania, regulowane wartości oraz niezbędne zależności.

# Skrypty C#

## MagicalGrassGeneratorEditor.cs
**Plik:** `Assets/Editor/MagicalGrassGeneratorEditor.cs`

### 1. Jaki efekt to daje?
Dodaje do panelu generatora trawy przyciski do jej tworzenia i usuwania. Nie wykonuje pracy samoczynnie.

### 2. Jak to jest zrobione?

Ten plik zmienia wygląd okna Inspector dla `MagicalGrassGenerator`. Przygotowuje dwa przyciski, które uruchamiają metody generatora.

#### W skrócie

Wyświetla ustawienia generatora trawy i dodaje przyciski, które uruchamiają generowanie albo usuwanie trawy.

#### Krok 1: pokazanie ustawień

```csharp
DrawDefaultInspector();
```

Unity wyświetla standardowe pola komponentu, takie jak teren, gęstość i materiał. Dzięki temu własny edytor nadal pozwala zmieniać ustawienia generatora.

#### Krok 2: pobranie edytowanego generatora

```csharp
MagicalGrassGenerator generator = (MagicalGrassGenerator)target;
```

`target` oznacza komponent, którego Inspector jest właśnie wyświetlany. Rzutowanie pozwala wywołać konkretne metody `MagicalGrassGenerator`.

#### Krok 3: obsługa przycisków

```csharp
if (GUILayout.Button("Generate Magical Grass", GUILayout.Height(34f)))
    generator.GenerateGrass();
if (GUILayout.Button("Clear Generated Grass", GUILayout.Height(30f)))
    generator.ClearGrass();
```

Pierwszy przycisk uruchamia generowanie trawy, a drugi usuwa wygenerowane fragmenty. Sam edytor nie tworzy geometrii — robi to `MagicalGrassGenerator`.

### 3. Jakie wartości można zmieniać?
Wysokości przycisków wpisane w kodzie to 34 i 30. Zmieniają tylko wygląd panelu. Parametry trawy znajdują się w komponencie `MagicalGrassGenerator`.

### 4. Dodatkowe informacje
**Rodzaj zastosowanej techniki:** Narzędzie edytora Unity; samo nie tworzy efektu wizualnego.

To narzędzie edytora, nie skrypt rozgrywki.

---

## CrystalFloat.cs
**Plik:** `Assets/Scripts/Effects/Crystals/CrystalFloat.cs`

### 1. Jaki efekt to daje?
Kryształ unosi się i opada, a opcjonalnie obraca się wokół własnej osi.

### 2. Jak to jest zrobione?

Skrypt zapamiętuje początkowe położenie kryształu, a potem w każdej klatce oblicza jego wysokość na podstawie fali sinusoidalnej. Opcjonalnie obraca go wokół własnej osi Y.

#### W skrócie

Zapamiętuje pozycję kryształu, unosi go sinusoidalnie wokół tego miejsca i opcjonalnie obraca.

#### Krok 1: przygotowanie animacji

W `Start()` skrypt zapisuje `transform.localPosition` jako `startPosition`. To punkt odniesienia: kryształ będzie unosił się względem niego, zamiast stopniowo oddalać się od miejsca startowego. `Random.Range(0f, Mathf.PI * 2f)` losuje `randomOffset`, więc kryształy mogą być w różnych fazach ruchu.

#### Krok 2: obliczenie unoszenia

```csharp
float offsetY = Mathf.Sin(
    Time.time * frequency * 2f * Mathf.PI + randomOffset
) * amplitude;
transform.localPosition = startPosition + Vector3.up * offsetY;
```

`Time.time` sprawia, że fala zmienia się w czasie. `frequency` określa tempo jej powtarzania, a `randomOffset` przesuwa kryształ do innego momentu cyklu. Sinus przyjmuje wartości od -1 do 1; pomnożenie przez `amplitude` ustala maksymalną odległość ruchu w górę i w dół. Wynik jest dodawany do zapamiętanej pozycji.

#### Krok 3: opcjonalny obrót

```csharp
if (rotate)
    transform.Rotate(Vector3.up, rotationSpeed * Time.deltaTime, Space.Self);
```

Jeśli `rotate` jest włączone, kryształ obraca się wokół własnej lokalnej osi Y. `Time.deltaTime` sprawia, że obrót zależy od czasu, a nie od liczby klatek. Wyłączenie `rotate` zatrzymuje tylko obrót — unoszenie nadal działa.

### 3. Jakie wartości można zmieniać?
- `amplitude = 0.2` — wysokość unoszenia; zwiększenie wzmacnia ruch.
- `frequency = 0.8` — tempo cyklu góra–dół.
- `rotate = true` — włącza lub wyłącza obrót.
- `rotationSpeed = 10` — stopnie obrotu na sekundę.
- `randomOffset` jest losowany od 0 do 2π przy starcie, aby kryształy nie poruszały się synchronicznie.

### 4. Dodatkowe informacje
**Rodzaj zastosowanej techniki:** Proceduralna animacja Transformu oparta na sinusoidzie; efekt geometryczny, nie wolumetryczny.

Skrypt zmienia Transform obiektu i nie steruje shaderem.

---

## MagicSpiral.cs
**Plik:** `Assets/Scripts/Effects/Crystals/MagicSpiral.cs`

### 1. Jaki efekt to daje?
Tworzy spiralę kulek wokół obiektu. Kulki obracają się, wznoszą, zawijają z powrotem na dół i pulsują. Mogą pojawiać się po zbliżeniu gracza.

### 2. Jak to jest zrobione?

Najprościej: skrypt sam tworzy wiele małych kulek, ustawia je wokół drzewa lub innego obiektu i przesuwa je w każdej klatce. Każda kulka dostaje inne początkowe położenie na okręgu, dlatego razem wyglądają jak wirująca spirala. Gdy gracz odejdzie od obiektu, kulki są ukrywane.

#### W skrócie

Tworzy kulki, rozkłada je po okręgu i w każdej klatce przesuwa po spirali, pulsując ich rozmiarem; może pokazywać je po zbliżeniu gracza.

#### Krok 1: przygotowanie kulek

W metodzie `Start()` skrypt najpierw sprawdza, czy w Inspectorze przypisano `particleMaterial`. Bez materiału kulek nie da się poprawnie wyświetlić, więc skrypt wypisuje błąd i wyłącza siebie:

```csharp
if (particleMaterial == null)
{
    Debug.LogError("MagicSpiral: assign a material to Particle Material.", this);
    enabled = false;
    return;
}
```

Następnie tworzy pusty obiekt `Generated Magic Spiral` jako wspólnego rodzica kulek. Rodzic jest ustawiony w miejscu obiektu, na którym znajduje się `MagicSpiral`. Dzięki temu łatwiej zarządzać całą grupą i usunąć ją po zniszczeniu obiektu.

Liczba kulek wynika z `particleCount`. Dla każdej z nich kod tworzy zwykłą sferę Unity:

```csharp
GameObject particle = GameObject.CreatePrimitive(PrimitiveType.Sphere);
particle.transform.SetParent(particleRoot, false);
```

Sfera utworzona przez `CreatePrimitive` ma collider, ale tutaj kulki są tylko ozdobą. Dlatego skrypt usuwa collider. Potem przypisuje im wspólny materiał `particleMaterial` i wyłącza rzucanie oraz odbieranie cieni. Każda kulka zostaje zapisana w tablicy `particles`, aby można było później przesuwać ją i zmieniać jej rozmiar.

#### Krok 2: rozłożenie kulek wokół okręgu

Przy tworzeniu każdej kulki skrypt zapisuje jej własne przesunięcie:

```csharp
offsets[i] = (float)i / particleCount;
```

Wartości te rozkładają kulki równomiernie: pierwsza zaczyna od jednego miejsca okręgu, następne od kolejnych. Dzięki temu wszystkie kulki nie nakładają się na siebie na starcie.

#### Krok 3: sprawdzenie, czy efekt ma być widoczny

W każdej klatce metoda `Update()` sprawdza ustawienia aktywacji. Jeśli `alwaysActive` jest włączone, efekt ma być aktywny bez względu na odległość. Jeśli przypisano `player`, skrypt mierzy odległość między graczem a obiektem z tym skryptem:

```csharp
float distance = Vector3.Distance(player.position, transform.position);
shouldBeActive |= distance <= activationDistance;
```

`Vector3.Distance` oblicza odległość między dwoma punktami w scenie. Gdy gracz znajdzie się w zasięgu `activationDistance`, kulki zostają włączone. Po odejściu poza ten zasięg skrypt je ukrywa. Widoczność jest zmieniana tylko wtedy, gdy stan aktywności rzeczywiście się zmienił. Jeśli `player` nie jest przypisany, a `alwaysActive` jest wyłączone, metoda kończy działanie i efekt pozostaje nieaktywny.

#### Krok 4: ruch tworzący spiralę

Gdy efekt jest aktywny, `Update()` przechodzi po wszystkich kulkach i oblicza ich nowe położenie. Wysokość każdej kulki wyznacza `progress`:

```csharp
float progress = Mathf.Repeat(
    offsets[i] + Time.time * upwardSpeed / height,
    1f
);
float y = progress * height;
```

`Time.time` oznacza czas od uruchomienia gry. Dodając go do `offsets[i]`, skrypt sprawia, że kulki stale przesuwają się do góry. `upwardSpeed` określa tempo tego ruchu, a `height` — wysokość całej spirali. `Mathf.Repeat(..., 1f)` zawija wynik z powrotem do zakresu od 0 do 1. Gdy kulka dojdzie na górę, jej położenie zaczyna się więc ponownie przy dole, zamiast zatrzymywać się.

Położenie wokół osi obiektu obliczają sinus i cosinus:

```csharp
float angle = offsets[i] * Mathf.PI * 2f + Time.time * rotationSpeed;
float x = Mathf.Cos(angle) * radius;
float z = Mathf.Sin(angle) * radius;
particles[i].localPosition = new Vector3(x, y, z);
```

Sinus i cosinus wyznaczają punkt na okręgu. `radius` ustala, jak daleko od środka znajdują się kulki. Czas oraz `rotationSpeed` stale zmieniają kąt, więc punkt przesuwa się wokół obiektu. Jednocześnie `y` rośnie i zawija się od góry do dołu. Połączenie ruchu dookoła i ruchu w górę tworzy spiralny tor.

Pozycja jest zapisywana jako `localPosition`, czyli względem obiektu nadrzędnego `particleRoot`, a nie jako pozycja niezależna od obiektu. W praktyce spirala porusza się razem z obiektem, do którego przypisano skrypt.

#### Krok 5: pulsowanie kulek

Rozmiar każdej kulki jest lekko zmieniany w czasie:

```csharp
float pulse = 0.75f + 0.25f * Mathf.Sin(Time.time * 4f + i);
particles[i].localScale = Vector3.one * particleSize * pulse;
```

`Mathf.Sin` daje powtarzającą się falę. Dodanie `i` powoduje, że kulki pulsują w różnych momentach, zamiast wszystkie równocześnie. Wynik `pulse` mieści się w przybliżeniu między 0.5 a 1, więc kulka zmniejsza się i wraca do swojego rozmiaru bazowego `particleSize`. Wartość `4f` ustala tempo pulsowania i jest wpisana bezpośrednio w kodzie.

#### Sprzątanie po efekcie

`SetParticlesVisible()` włącza lub wyłącza każdą utworzoną kulkę. `OnDestroy()` usuwa obiekt `particleRoot`, a wraz z nim całą wygenerowaną grupę.
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
**Rodzaj zastosowanej techniki:** Proceduralna animacja wielu obiektów sferycznych; geometria w ruchu, nie system cząsteczek ani efekt wolumetryczny.

To osobne obiekty sferyczne, nie wbudowany system cząsteczek Unity. Po zniszczeniu skrypt usuwa utworzoną grupę.

---

## ProceduralCrystalSparks.cs
**Plik:** `Assets/Scripts/Effects/Crystals/ProceduralCrystalSparks.cs`

### 1. Jaki efekt to daje?
Iskry krążą wokół kryształu, unoszą się, lekko zbaczają z toru, pulsują oraz pojawiają się i znikają. Są płaskimi kształtami zwróconymi do kamery.

### 2. Jak to jest zrobione?

Skrypt nie tworzy osobnego obiektu Unity dla każdej iskry. Buduje jedną siatkę z wielu małych czworokątów, a w każdej klatce zmienia ich położenie i przezroczystość.

#### W skrócie

Buduje jedną siatkę z czworokątów-iskier, porusza je wokół kryształu, kieruje ich powierzchnie do kamery i animuje ich widoczność.

#### Krok 1: wybór kryształu i materiału

W `Start()` skrypt korzysta z przypisanego `crystal`; jeśli pole jest puste, wybiera obiekt nadrzędny, a gdy go nie ma — własny obiekt. Pobiera `MeshFilter` i `MeshRenderer`. Materiał `sparkMaterial` przypisuje do renderera; brak materiału powoduje komunikat błędu.

#### Krok 2: zbudowanie jednej siatki

```csharp
vertices = new Vector3[count * 4];
triangles = new int[count * 6];
```

Każda iskra zajmuje cztery wierzchołki i dwa trójkąty, czyli sześć indeksów. Pętla w `CreateSparks()` wypełnia tablice wierzchołków, UV, kolorów i trójkątów. Dla każdej iskry tworzy też zestaw danych `Spark`: kąt, wysokość, wiek, czas życia, promień, rozmiar i wartości losowe sterujące jej ruchem. Na końcu dane trafiają do dynamicznej siatki przypisanej do `MeshFilter`.

#### Krok 3: losowe rozpoczęcie iskier

`ResetSpark()` losuje początkowy kąt i promień orbity, rozmiar, czas życia, fazę kołysania oraz mnożnik prędkości. Przy pierwszym uruchomieniu iskry dostają też losowy wiek i wysokość, żeby nie zaczynały wszystkie w tym samym miejscu. Po wygaśnięciu iskra jest ponownie inicjalizowana u dołu.

#### Krok 4: ruch wokół kryształu

W `LateUpdate()` każda iskra przesuwa się po kącie orbity i powoli wznosi. Gdy przekroczy górną granicę, wraca na dół. `Mathf.Sin` i `Mathf.Cos` dodają boczne wychylenia. Z kąta, promienia, wysokości i wychyleń powstaje lokalna pozycja, którą `crystal.TransformPoint()` przenosi do świata.

Czworokąty są billboardami: ich boki wyznacza się z osi `right` i `up` aktywnej kamery. Dzięki temu są skierowane do kamery, zamiast znikać z widoku przy patrzeniu z boku. Gdy kamera nie jest dostępna, skrypt używa osi świata.

#### Krok 5: pojawianie się, zanikanie i aktualizacja

```csharp
float normalizedAge = spark.age / spark.lifetime;
float fadeIn = Mathf.Clamp01(normalizedAge * 5f);
float fadeOut = Mathf.Clamp01((1f - normalizedAge) * 4f);
float alpha = fadeIn * fadeOut * pulse;
```

Wiek jest zamieniany na postęp od 0 do 1. `fadeIn` stopniowo zwiększa widoczność na początku, a `fadeOut` zmniejsza ją pod koniec życia. `pulse` dodaje zmianę jasności w czasie. Otrzymana wartość `alpha` jest zapisana w kolorze wszystkich czterech wierzchołków iskry. Na końcu `LateUpdate()` zaktualizowane wierzchołki i kolory są przekazywane do siatki, a jej granice są przeliczane.

#### Krok 6: zwolnienie siatki

`OnDestroy()` usuwa utworzoną siatkę, gdy znika obiekt ze skryptem.

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
**Rodzaj zastosowanej techniki:** Proceduralny efekt cząsteczkowy realizowany przez dynamiczną siatkę billboardów; nie jest wolumetryczny.

Kamera jest pobierana jako główna. Gdy jej nie ma, stosowane są osie świata. Siatka jest oznaczona jako często zmieniana i zwalniana przy niszczeniu obiektu.

---

## FogPlayerExclusion.cs
**Plik:** `Assets/Scripts/Environment/Fog/FogPlayerExclusion.cs`

### 1. Jaki efekt to daje?
Tworzy w dymie GroundFog rzadszą strefę wokół gracza. Strefa podąża za graczem.

### 2. Jak to jest zrobione?

Ten skrypt sam nie rysuje mgły. Co klatkę przekazuje shaderowi aktualne położenie gracza, aby shader mógł osłabić mgłę w jego pobliżu.

#### W skrócie

Co klatkę przekazuje pozycję gracza do renderera, aby GroundFog mógł zmniejszyć gęstość mgły w pobliżu gracza.

#### Krok 1: przygotowanie renderera

W `Awake()` skrypt pobiera `Renderer` z tego samego obiektu i tworzy `MaterialPropertyBlock`. Ten blok pozwala przekazać ustawienie dla konkretnego renderera bez tworzenia osobnej kopii materiału. Atrybut `RequireComponent` wymaga, by obiekt miał `Renderer`.

#### Krok 2: pobranie pozycji gracza

W `LateUpdate()` skrypt kończy pracę, jeśli brakuje referencji do gracza albo renderera. W innym przypadku odczytuje `player.position`, czyli pozycję gracza w świecie.

#### Krok 3: przekazanie pozycji do renderera

```csharp
fogRenderer.GetPropertyBlock(properties);
properties.SetVector(PlayerPositionID,
    new Vector4(playerPosition.x, playerPosition.y, playerPosition.z, 1f));
fogRenderer.SetPropertyBlock(properties);
```

Najpierw pobierany jest aktualny blok, aby zachować inne ustawienia renderera. Potem pozycja gracza trafia do wektora `_PlayerPosition`, a `SetPropertyBlock` przekazuje blok z powrotem rendererowi. Dzieje się to w każdej późnej aktualizacji, więc shader otrzymuje aktualną pozycję.

#### Krok 4: wykorzystanie danych przez GroundFog

`GroundFog.shader` odczytuje `_PlayerPosition` i porównuje położenie próbek mgły z pozycją gracza. Wokół gracza osłabia gęstość mgły, a dalej od niego przywraca ją stopniowo. Promień oraz miękkość przejścia wynikają z parametrów shadera, nie z tego skryptu.

### 3. Jakie wartości można zmieniać?
- `player` — Transform gracza, wymagany do działania.
- Skrypt nie ma własnego promienia. W materiale GroundFog wartości `_ExclusionRadius` i `_ExclusionFeather` określają rozmiar strefy i szerokość przejścia.

### 4. Dodatkowe informacje
**Rodzaj zastosowanej techniki:** Skrypt interakcji sterujący maską w shaderze wolumetrycznego dymu; sam nie wykonuje renderowania wolumetrycznego.

Wymaga renderera na tym samym obiekcie. W scenach `Scene1` i `SampleScene` renderer korzysta z `GroundFog_Mat`. Pozycja jest przekazywana do renderera bez tworzenia kopii materiału.

---

## GodRaysController.cs
**Plik:** `Assets/Scripts/Environment/Lighting/GodRaysController.cs`

### 1. Jaki efekt to daje?
Ustawia położenie źródła promieni na ekranie i płynnie reguluje ich intensywność. Światło za kamerą wyłącza efekt.

### 2. Jak to jest zrobione?

Skrypt znajduje na ekranie kierunek, z którego pada światło kierunkowe, i przekazuje tę pozycję do materiału promieni. Równocześnie stopniowo zmienia intensywność efektu, aby nie skakała gwałtownie.

#### W skrócie

Oblicza ekranowe położenie światła i płynnie przekazuje shaderowi jego pozycję oraz aktualną intensywność promieni.

#### Krok 1: sprawdzenie potrzebnych obiektów

W `LateUpdate()` skrypt działa tylko wtedy, gdy przypisano kamerę `targetCamera`, światło `directionalLight` i materiał `godRaysMaterial`. Atrybut `[ExecuteAlways]` pozwala wykonywać aktualizację również poza trybem Play w edytorze.

#### Krok 2: ustalenie położenia światła na ekranie

```csharp
Vector3 lightDirection = -directionalLight.transform.forward;
Vector3 lightPoint = targetCamera.transform.position + lightDirection * 1000f;
Vector3 screenPosition = targetCamera.WorldToViewportPoint(lightPoint);
```

Światło kierunkowe nie ma jednego bliskiego punktu źródłowego, dlatego skrypt bierze przeciwny kierunek jego osi `forward` i tworzy umowny punkt daleko od kamery. `WorldToViewportPoint` przelicza go na współrzędne widoku: środek ma wartości około `(0.5, 0.5)`. Współrzędne X i Y są ograniczane do zakresu od `-1` do `2`, by pozycja mogła być poza ekranem bez nagłego skoku na jego krawędzi.

#### Krok 3: wyliczenie docelowej intensywności

`screenPosition.z` informuje, czy punkt jest przed kamerą. Jeśli jest za nią, `frontFactor` wynosi zero i efekt gaśnie. W przeciwnym razie wysokość ekranowa `y` jest przeliczana przez `Mathf.InverseLerp(0.0f, 0.8f, y)`, a następnie wygładzana przez `Mathf.SmoothStep`. Tak powstaje `heightFactor`, który wraz z `minimumIntensity` wyznacza `targetIntensity`.

#### Krok 4: wygładzenie i przesłanie wartości

```csharp
currentIntensity = Mathf.Lerp(
    currentIntensity,
    targetIntensity,
    1f - Mathf.Exp(-speed * Time.deltaTime));
godRaysMaterial.SetFloat(RayIntensity, currentIntensity);
```

`Mathf.Lerp` zbliża bieżącą intensywność do docelowej, a wyrażenie z `Mathf.Exp` wylicza tempo tego zbliżania w sposób zależny od czasu klatki. `smoothSpeed` kontroluje szybkość zmiany. Skrypt przekazuje do materiału `_LightScreenPos` oraz `_RayIntensity`; shader używa pozycji jako kierunku promieni, a intensywności jako ich siły.

### 3. Jakie wartości można zmieniać?
- `targetCamera`, `directionalLight`, `godRaysMaterial` — kamera, światło i materiał; wszystkie muszą być przypisane.
- `smoothSpeed = 1.5`, zakres 0.1–5 — szybkość wygładzania; większa wartość szybciej reaguje.
- `minimumIntensity = 0.2`, zakres 0–1 — minimalna intensywność przed uwzględnieniem położenia światła.
- W kodzie punkt jest odsunięty o 1000 jednostek; współrzędne ekranu ograniczane są do zakresu od -1 do 2. Wysokość mapowana jest w zakresie 0–0.8.

### 4. Dodatkowe informacje
**Rodzaj zastosowanej techniki:** Kontroler efektu ekranowego zależnego od położenia światła; sam nie oblicza wolumetrycznego oświetlenia.

`[ExecuteAlways]` uruchamia aktualizację także w edytorze. Brak którejkolwiek referencji pomija aktualizację. Shader GodRays dodatkowo ma własne ustawienia materiału.

---

## MagicalGrassGenerator.cs
**Plik:** `Assets/Scripts/Flora/MagicalGrassGenerator.cs`

### 1. Jaki efekt to daje?
Tworzy na terenie kępki trawy o zróżnicowanej wysokości, szerokości, kolorze i wygięciu.

### 2. Jak to jest zrobione?

Generator tworzy trawę jako własną geometrię, a nie jako obiekty sadzone pojedynczo. Dzieli teren na mniejsze części, w każdej losuje źdźbła, buduje ich siatki i przypisuje im materiał.

#### W skrócie

Dzieli teren na fragmenty, losuje i buduje w nich źdźbła jako siatki, po czym przypisuje im materiał trawy.

#### Krok 1: sprawdzenie ustawień i przygotowanie losowania

`GenerateGrass()` sprawdza, czy przypisano teren z `TerrainData` oraz `grassMaterial`. Jeśli czegoś brakuje, wypisuje błąd i kończy działanie. Następnie ogranicza `density`, `chunkSize` i `bladeWidth` do minimalnych wartości, usuwa poprzednią trawę i tworzy generator pseudolosowy z `seed`. Ten sam seed pozwala odtworzyć podobny układ po ponownym wygenerowaniu.

#### Krok 2: podział terenu na fragmenty

Liczbę fragmentów w osiach X i Z wyznaczają `CeilToInt(size / chunkSize)`. Pętle wywołują `GenerateChunk()` dla każdego fragmentu. Ostatni fragment przy krawędzi jest przycinany do rozmiaru terenu.

#### Krok 3: losowanie miejsc i dopasowanie do podłoża

Liczba źdźbeł w fragmencie wynika z jego powierzchni pomnożonej przez `density`. Dla każdego źdźbła skrypt losuje X i Z, zamienia je na znormalizowane UV terenu i pobiera wysokość oraz normalną przez `GetInterpolatedHeight` i `GetInterpolatedNormal`. Dzięki temu źdźbło zaczyna się na powierzchni i uwzględnia jej nachylenie.

Skrypt losuje też wysokość w przedziale `minHeight`–`maxHeight`, jej dodatkowe zróżnicowanie `heightRandomness`, szerokość z uwzględnieniem `widthRandomness` i obrót wokół normalnej podłoża. `Vector3.ProjectOnPlane` usuwa z kierunku składową prostopadłą do gruntu, żeby źdźbło miało właściwą orientację.

#### Krok 4: zbudowanie źdźbła z dwóch płaszczyzn

```csharp
AddBladePlane(..., direction, randomHeight, width, random);
Vector3 secondDirection = Vector3.Cross(worldNormal, direction).normalized;
AddBladePlane(..., secondDirection, randomHeight, width, random);
```

Pierwsza płaszczyzna ustawia się losowo, druga jest do niej prostopadła. Skrzyżowanie dwóch płaskich kształtów sprawia, że źdźbło jest widoczne z większej liczby kierunków. `AddBladePlane()` dzieli je na trzy segmenty, zwęża ku górze i odchyla według `curvature`. Zapisuje wierzchołki, UV, kolory i trójkąty do list.

#### Krok 5: utworzenie siatki i obiektu sceny

Po zebraniu danych generator tworzy `Mesh`, wpisuje do niego wierzchołki, UV, kolory i trójkąty, a następnie przelicza normalne i granice. Dla dużej liczby wierzchołków włącza indeksowanie 32-bitowe. Siatka dostaje obiekt z `MeshFilter` i `MeshRenderer`, któremu przypisywany jest `grassMaterial`. Każdy fragment jest osobnym obiektem podrzędnym generatora.

#### Krok 6: usuwanie wygenerowanej trawy

`ClearGrass()` przechodzi po dzieciach generatora i usuwa tylko obiekty, których nazwa zaczyna się od `MagicalGrass_`. Najpierw odłącza i usuwa ich siatki, a potem obiekty. W trybie Play używa `Destroy`, a w edytorze `DestroyImmediate`.

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
**Rodzaj zastosowanej techniki:** Proceduralne generowanie geometrii na CPU; nie jest metodą wolumetryczną.

Generator uruchamia się z menu kontekstowego lub przycisku edytora, a nie automatycznie w czasie gry. Czyszczenie usuwa wyłącznie dzieci o nazwie zaczynającej się od `MagicalGrass_`.

---

## MagicTreeVines.cs
**Plik:** `Assets/Scripts/Flora/MagicTreeVines.cs`

### 1. Jaki efekt to daje?
Tworzy spiralne pnącza oplatające pień oraz świetliki krążące, unoszące się i pulsujące wokół drzewa.

### 2. Jak to jest zrobione?

Skrypt tworzy pnącza jako linie oplatające pień i świetliki jako małe sfery. Gdy efekt jest aktywny, pnącza stopniowo się wydłużają, a świetliki poruszają się wokół drzewa. Po wyłączeniu efektu pnącza się skracają.

#### W skrócie

Wyznacza spiralne trasy pnączy, odsłania je stopniowo przy aktywacji i animuje świetliki, których widoczność zależy od wzrostu pnączy.

#### Krok 1: przygotowanie efektu

W `Start()` wymagany jest `vineMaterial`. Jeśli go brakuje, skrypt zgłasza błąd i wyłącza się. Wartości takie jak `vineCount`, `pointsPerVine`, `fireflyCount` i `growthDuration` są ograniczane do bezpiecznych minimów. Potem wywoływane są `CreateVines()` i `CreateFireflies()`.

#### Krok 2: utworzenie tras pnączy

`CreateVines()` tworzy dla każdego pnącza osobny obiekt z `LineRenderer`. Renderer korzysta z lokalnych współrzędnych drzewa, z przypisanego materiału i zwęża się ku końcowi. `GenerateVinePath()` oblicza pełną trasę z `pointsPerVine` punktów. Kąt i sinusy rozmieszczają punkty spiralnie wokół pnia; `irregularity` i `sway` dodają nieregularne odchylenia. Wysokość rośnie wraz z parametrem `t`, więc trasa pnie się ku górze. Kolejne pnącza dostają opóźnienie `i * delayBetweenVines`.

#### Krok 3: utworzenie świetlików

`CreateFireflies()` tworzy grupę sfer. Usuwa ich collidery, wyłącza cienie i przypisuje `fireflyMaterial`; jeśli nie został ustawiony, używa `vineMaterial`. Każdy świetlik dostaje losowe przesunięcie i fazę, żeby nie poruszały się identycznie. Początkowa skala zero ukrywa je.

#### Krok 4: sprawdzenie aktywacji

W `Update()` efekt jest aktywny, jeśli `alwaysActive` jest włączone albo przypisany gracz znajduje się w odległości nie większej niż `activationDistance`. Przy przejściu z nieaktywnego stanu do aktywnego licznik `activationTimer` wraca do zera. Następnie skrypt aktualizuje pnącza i świetliki.

#### Krok 5: odsłanianie i chowanie pnączy

`UpdateVineGrowth()` zmienia postęp każdego pnącza w czasie. Podczas aktywacji wzrost zaczyna się po jego indywidualnym opóźnieniu; po dezaktywacji postęp maleje. `Mathf.Clamp01` utrzymuje go w zakresie 0–1.

`UpdateVineGeometry()` pokazuje tylko początkową część zapisanej trasy. Liczba punktów zależy od postępu, a `Vector3.Lerp` wylicza dokładne położenie końcówki między dwoma punktami. W efekcie pnącze wygląda, jakby rosło po przygotowanej ścieżce, a przy chowaniu znika od końca.

#### Krok 6: ruch świetlików

`UpdateFireflies()` wylicza dla każdej sfery kąt wokół drzewa, wysokość i boczne kołysanie za pomocą sinusów i cosinusów. Wysokość powtarza się cyklicznie dzięki `Mathf.Repeat`. Skala pulsuje, a jej wielkość jest mnożona przez największy postęp pnączy (`totalProgress`): świetliki zwiększają się wraz z pojawianiem się pnączy i maleją, kiedy te znikają.

#### Krok 7: sprzątanie

`OnDestroy()` usuwa obiekt nadrzędny świetlików wraz z jego dziećmi. Pnącza są osobnymi dziećmi obiektu drzewa.

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
**Rodzaj zastosowanej techniki:** Proceduralnie wyliczane ścieżki LineRenderer oraz animowane sfery; efekt geometryczny, nie wolumetryczny.

Pnącza i świetliki nie rzucają cieni. W `SampleScene` skrypt ma przypisanego gracza i `alwaysActive = false`: po zbliżeniu na 5 jednostek rozpoczyna wzrost, a po oddaleniu zwija pnącza. W prefabach `oak_tree (1)` i `sakura_tree` pole gracza jest puste, a stała aktywacja wyłączona; same prefaby bez przypisania gracza nie uruchomią efektu. Materiały przypisywane są w Inspectorze, a skrypt nie zmienia parametrów shaderów.

---

## PlayerMovement.cs
**Plik:** `Assets/Scripts/Gameplay/Player/PlayerMovement.cs`

### 1. Jaki efekt to daje?
Steruje ruchem gracza z pierwszej osoby: WASD, rozglądaniem myszą, grawitacją i blokowaniem kursora.

### 2. Jak to jest zrobione?

Skrypt odczytuje klawisze WASD i mysz z nowego Unity Input System. `CharacterController` przesuwa postać i pilnuje kolizji, a osobny obrót kamery pozwala rozglądać się w pionie i poziomie.

#### W skrócie

Odczytuje WASD i mysz, obraca gracza oraz kamerę, a CharacterController przesuwa postać z grawitacją i kolizjami.

#### Krok 1: pobranie komponentów i kamery

W `Awake()` skrypt pobiera `CharacterController`. Jeśli `cameraTransform` nie został przypisany, szuka kamery w obiektach podrzędnych. W `Start()` brak kamery powoduje błąd i wyłączenie skryptu. Początkowy kąt kamery jest zapisywany jako `cameraPitch`, a następnie sprowadzany z zakresu 0–360 do wartości ujemnej lub dodatniej.

#### Krok 2: przygotowanie kursora

Na starcie kursor jest blokowany na środku ekranu i ukrywany. W `Update()` skrypt najpierw sprawdza, czy dostępna jest klawiatura. Escape odblokowuje kursor i pokazuje go; kliknięcie lewym przyciskiem ponownie blokuje i ukrywa kursor. Ruch i obrót są wykonywane tylko przy zablokowanym kursorze.

#### Krok 3: obrót widoku myszą

`LookAround()` odczytuje przesunięcie myszy. Ruch poziomy obraca cały obiekt gracza wokół osi Y, więc zmienia kierunek poruszania. Ruch pionowy zmienia `cameraPitch`; `Mathf.Clamp` ogranicza go do `-maxLookAngle` i `maxLookAngle`. Ten kąt jest ustawiany na lokalnym obrocie kamery, więc patrzenie w górę i dół nie przechyla całej postaci.

#### Krok 4: zebranie kierunku ruchu

`Move()` dodaje lub odejmuje składowe wektora wejścia dla klawiszy WASD. `Vector2.ClampMagnitude(input, 1f)` ogranicza długość wektora, dlatego ruch po przekątnej nie jest szybszy. Składowe są łączone z `transform.right` i `transform.forward`, więc kierunek ruchu odpowiada temu, w którą stronę obrócony jest gracz.

#### Krok 5: grawitacja i przesunięcie

Gdy postać stoi na ziemi, ujemna prędkość pionowa jest ustawiana na `-2f`, żeby utrzymać kontakt z podłożem. Następnie `gravity * Time.deltaTime` aktualizuje prędkość pionową. Ruch poziomy i pionowy są łączone w `velocity`, a `CharacterController.Move(velocity * Time.deltaTime)` wykonuje przesunięcie z uwzględnieniem kolizji.

#### Krok 6: przywrócenie kursora

`OnDisable()` odblokowuje i pokazuje kursor, aby po wyłączeniu komponentu nie pozostał ukryty.

### 3. Jakie wartości można zmieniać?
- `moveSpeed = 5` — prędkość ruchu.
- `gravity = -9.81` — przyspieszenie w dół.
- `cameraTransform` — kamera; gdy nie jest przypisana, skrypt szuka kamery potomnej.
- `mouseSensitivity = 0.1` — czułość myszy.
- `maxLookAngle = 85` — maksymalne pochylenie w pionie.
- Wartość przyklejenia do ziemi wynosi -2. Skrypt nie ma skoku.

### 4. Dodatkowe informacje
**Rodzaj zastosowanej techniki:** Sterowanie rozgrywką i ruchem postaci; nie jest techniką renderowania.

Wymaga CharacterController i aktywnej klawiatury z Input System. Brak przypisanej lub znalezionej kamery powoduje wyłączenie skryptu.

---

## Krysztal.shader
**Plik:** `Assets/Shaders/Effects/Krysztal.shader`

### 1. Jaki efekt to daje?
Tworzy przezroczysty niebieski kryształ z jasnymi krawędziami. Krawędzie świecą mocniej, gdy patrzymy na powierzchnię pod ostrym kątem.

### 2. Jak to jest zrobione?

Shader oblicza kolor kryształu dla każdego piksela. Środek powierzchni pozostaje bardziej przezroczysty, a krawędzie zwrócone bokiem do kamery dostają mocniejszy blask.

#### W skrócie

Porównuje normalną powierzchni z kierunkiem kamery, aby dodać kryształowi przezroczystość i mocniejszą poświatę na krawędziach.

#### Krok 1: dane z modelu

Vertex shader `Vert` pobiera pozycję i normalną każdego wierzchołka. Przelicza pozycję do przestrzeni ekranu, a normalną i kierunek do kamery przekazuje dalej. Dzięki temu fragment shader może wykonać obliczenia dla widocznych pikseli.

#### Krok 2: sprawdzenie kąta patrzenia

```hlsl
half fresnel = 1.0h - saturate(dot(normal, viewDir));
fresnel = pow(fresnel, _FresnelPower);
```

Fragment shader normalizuje normalną powierzchni i kierunek do kamery. Iloczyn skalarny `dot` mówi, jak bardzo te kierunki są zgodne. Gdy kamera patrzy prosto na powierzchnię, wynik jest wysoki, a `1 - dot` daje mały efekt. Przy patrzeniu wzdłuż krawędzi zgodność maleje i wartość Fresnela rośnie. `pow` z `_FresnelPower` zmienia szerokość oraz skupienie tej krawędziowej poświaty.

#### Krok 3: dodanie koloru i blasku

```hlsl
half3 fresnelEmission = _FresnelColor.rgb * fresnel
    * _FresnelStrength * _GlowStrength;
half3 finalColor = baseColor + fresnelEmission;
```

Kolor krawędzi jest mnożony przez wartość Fresnela oraz dwa ustawienia siły, a następnie dodawany do `_CrystalColor`. Wartości HDR pozwalają uzyskać jasny kolor, który może współpracować z Bloom, jeśli jest włączony w post-processingu.

#### Krok 4: przezroczystość krawędzi

```hlsl
half alpha = saturate(_Transparency + fresnel * 0.35h);
return half4(finalColor, alpha);
```

Bazowa przezroczystość pochodzi z `_Transparency`. Przy krawędziach rośnie dodatkowo o część wartości Fresnela; `saturate` ogranicza ją do 0–1. Ustawienia `Blend SrcAlpha OneMinusSrcAlpha` mieszają kolor z tym, co znajduje się za kryształem. `ZWrite Off` oznacza, że shader nie zapisuje głębi, co jest typowe dla tej przezroczystej powierzchni.

### 3. Jakie wartości można zmieniać?
- `_CrystalColor` — HDR, domyślnie `(0.15, 0.8, 1, 1)`. Kolor bazowy.
- `_Transparency = 0.4`, zakres 0.05–1. Większa wartość czyni kryształ bardziej kryjącym.
- `_FresnelColor` — HDR, domyślnie `(0.2, 0.9, 1, 1)`. Kolor krawędzi.
- `_FresnelPower = 3`, zakres 0.5–8. Większa wartość skupia poświatę w węższym obszarze.
- `_FresnelStrength = 2`, zakres 0–5. Siła krawędzi.
- `_GlowStrength = 1.5`, zakres 0–10. Dodatkowy mnożnik jasności.
- Stałe w kodzie: krawędź może dodać do przezroczystości maksymalnie `0.35`.

### 4. Dodatkowe informacje
**Rodzaj zastosowanej techniki:** Shader przezroczystości z efektem Fresnela zależnym od kąta widzenia; powierzchniowy, nie wolumetryczny.

Shader URP miesza kolor z tłem, nie zapisuje głębi i renderuje przednie ściany modelu.

---

## ProceduralSparks.shader
**Plik:** `Assets/Shaders/Effects/ProceduralSparks.shader`

### 1. Jaki efekt to daje?
Nadaje iskrom jasny rdzeń i miękką poświatę. Iskra dodaje światło do obrazu zamiast całkowicie zasłaniać tło.

### 2. Jak to jest zrobione?

Shader rysuje na kwadracie okrągłą poświatę z jasnym środkiem. Nie potrzebuje tekstury: jasność każdego piksela wylicza z jego odległości od środka UV.

#### W skrócie

Z UV kwadratu wylicza odległość od środka i na jej podstawie tworzy miękkie halo oraz jasny rdzeń iskry.

#### Krok 1: przekazanie pozycji i UV

Vertex shader `Vert` przelicza wierzchołek kwadratu do przestrzeni projekcyjnej kamery i przekazuje jego UV do fragment shadera. UV określają, gdzie dany piksel leży na kwadracie.

#### Krok 2: odległość od środka

```hlsl
float2 p = input.uv * 2.0 - 1.0;
float r = length(p);
```

UV z zakresu 0–1 zostaje przekształcone do zakresu -1–1, dzięki czemu środek kwadratu ma współrzędne `(0, 0)`. `length` oblicza odległość piksela od tego środka. Im większe `r`, tym dalej od centrum iskry.

#### Krok 3: utworzenie halo i rdzenia

```hlsl
float halo = exp(-r * r * (3.0 / max(_Softness, 0.05)));
float core = 1.0 - smoothstep(_CoreSize * 0.5, _CoreSize, r);
float glow = saturate(halo * 0.65 + core);
```

`halo` opada stopniowo wraz z odległością i tworzy miękką poświatę; `_Softness` zmienia jej rozłożenie. `core` tworzy mniejszy, jaśniejszy środek, a `_CoreSize` reguluje jego rozmiar. Shader łączy obie warstwy i ogranicza wynik do 0–1.

#### Krok 4: kolor i mieszanie z obrazem

```hlsl
half3 color = _SparkColor.rgb * _Intensity * glow;
half alpha = saturate(glow * _SparkColor.a);
return half4(color, alpha);
```

Wynik poświaty mnoży kolor i intensywność materiału. Alfa wynika z jasności oraz kanału alfa koloru. Ustawienie `Blend SrcAlpha One` dodaje jasność iskry do tła. Shader nie zapisuje głębi (`ZWrite Off`) i rysuje obie strony kwadratu (`Cull Off`). Ruch, rozmiar wierzchołków oraz zanikanie iskier wykonuje skrypt `ProceduralCrystalSparks`, nie ten shader.

### 3. Jakie wartości można zmieniać?
- `_SparkColor` — HDR, domyślnie `(0.1, 0.8, 1, 1)`. Kolor i alfa.
- `_Intensity = 3`, zakres 0–10. Jasność iskry.
- `_Softness = 0.7`, zakres 0.05–2. Większa wartość poszerza poświatę.
- `_CoreSize = 0.25`, zakres 0.05–0.8. Rozmiar jasnego środka.
- Stała `0.65` określa udział poświaty przy łączeniu jej z rdzeniem.

### 4. Dodatkowe informacje
**Rodzaj zastosowanej techniki:** Proceduralny radialny blask obliczany na powierzchni kwadratu; nie jest wolumetryczny.

Używa addytywnego mieszania z tłem, nie zapisuje głębi i renderuje obie strony kwadratu.

---

## Fog.shader
**Plik:** `Assets/Shaders/Environment/Fog.shader`

### 1. Jaki efekt to daje?
Dodaje mgłę zależną od odległości od kamery. Dalekie obiekty mieszają się z kolorem mgły; niebo otrzymuje osobną, łagodniejszą mgłę.

### 2. Jak to jest zrobione?

To shader pełnoekranowy: bierze już wyrenderowany obraz i zmienia kolor jego pikseli. Odległe obiekty są coraz bardziej mieszane z kolorem mgły. Niebo, rozpoznawane po braku geometrii w głębi, dostaje osobną siłę mgły.

#### W skrócie

Odczytuje kolor i głębię obrazu, wylicza odległość obiektów od kamery i miesza ich kolor z kolorem mgły.

#### Krok 1: pobranie obrazu i głębi

Dla każdego piksela shader pobiera kolor z `_BlitTexture` oraz wartość z tekstury głębi. Głębia mówi, jak daleko znajduje się widoczna powierzchnia. Kod sprawdza też konwencję `UNITY_REVERSED_Z`, bo na niektórych platformach wartości głębi są zapisane w odwrotnym kierunku. Wartość graniczna oznacza niebo; wtedy kolor sceny jest od razu mieszany z `_FogColor` według `_SkyFogStrength`.

#### Krok 2: odtworzenie odległości obiektu

Jeżeli piksel należy do geometrii, `ComputeWorldSpacePosition` odtwarza pozycję tej powierzchni w świecie z UV, głębi i odwrotnej macierzy widoku/projekcji. Shader mierzy odległość tej pozycji od `_WorldSpaceCameraPos`.

#### Krok 3: przeliczenie odległości na siłę mgły

```hlsl
float distanceFactor = saturate(
    (distanceToCamera - _FogStart) /
    max(_FogEnd - _FogStart, 0.001));
float distanceFog = (1.0 - exp(-_FogDensity * distanceFactor)) / denominator;
```

`_FogStart` i `_FogEnd` określają zakres odległości, w którym mgła narasta. `saturate` ogranicza obliczony czynnik do 0–1. Funkcja wykładnicza sprawia, że narastanie nie jest liniowe; mianownik normalizuje wynik i ma zabezpieczenie przed dzieleniem przez zero.

#### Krok 4: zmieszanie koloru

```hlsl
float fogFactor = lerp(_NearFogStrength, 1.0, saturate(distanceFog));
half3 finalColor = lerp(sceneColor.rgb, _FogColor.rgb, saturate(fogFactor));
```

Nawet blisko kamery może pozostać niewielka mgła ustawiona przez `_NearFogStrength`. Im dalej leży obiekt, tym bardziej jego kolor zbliża się do `_FogColor`. Shader zachowuje alfę oryginalnego obrazu. `ZTest Always` pozwala przetworzyć każdy piksel obrazu, a `ZWrite Off` nie zapisuje nowej głębi.

### 3. Jakie wartości można zmieniać?
- `_FogColor` — HDR, domyślnie `(0.48, 0.66, 0.64, 1)`. Kolor mgły.
- `_FogStart = 0`. Odległość rozpoczęcia narastania.
- `_FogEnd = 55`. Odległość, przy której mgła osiąga pełną siłę.
- `_FogDensity = 4`, zakres 0.1–8. Większa wartość szybciej wzmacnia mgłę.
- `_NearFogStrength = 0.06`, zakres 0–0.25. Minimalna mgła na geometrii blisko kamery.
- `_SkyFogStrength = 0.12`, zakres 0–0.5. Mgła na niebie.
- Zabezpieczenia w kodzie używają minimum `0.001` dla dzielników.

### 4. Dodatkowe informacje
**Rodzaj zastosowanej techniki:** Ekranowa mgła zależna od głębi i odległości; post-process, nie wolumetryczna objętość.

To ekranowy efekt URP korzystający z głębi obrazu. Nie jest dymem w przestrzeni i nie korzysta z pozycji gracza. Mgłę przy graczu tworzy osobny `GroundFog.shader`. W `Assets/Settings/PC_Renderer.asset` znajduje się aktywna funkcja Renderer Feature o nazwie `Fog`, której materiałem przebiegu jest `FogMat`. `PC_RPAsset` wskazuje ten renderer.

---

## GodRays.shader
**Plik:** `Assets/Shaders/Environment/GodRays.shader`

### 1. Jaki efekt to daje?
Dodaje na obrazie promienie wychodzące z miejsca światła widocznego na ekranie. Są silniejsze, gdy w kierunku światła widoczne jest niebo, i słabsze, gdy drogę zasłania obiekt.

### 2. Jak to jest zrobione?

Shader dodaje do gotowego obrazu ekranowe smugi skierowane od pozycji światła. W każdej pozycji ekranu sprawdza próbki głębi wzdłuż linii prowadzącej do światła i wykorzystuje widoczne obszary nieba do budowania promieni. Mimo nazwy `Volumetric God Rays` nie wykonuje ray marchingu przez rzeczywistą objętość świata — jest to efekt ekranowy.

#### W skrócie

Próbkuje głębię po ekranowej linii od piksela do światła i na podstawie widocznego nieba dodaje promienie do obrazu.

#### Krok 1: pobranie obrazu i pozycji światła

Shader pobiera kolor sceny i teksturę głębi. Pozycję światła na ekranie odczytuje z `_LightScreenPos`, którą ustawia `GodRaysController`. UV aktualnego piksela i UV światła wyznaczają kierunek próbkowania.

#### Krok 2: wyznaczenie linii próbek

```hlsl
float2 rayVector = (lightUV - uv) * _RayDensity;
int samples = clamp((int)_RaySamples, 8, 32);
float t = (i + 0.5) / samples;
float2 sampleUV = uv + rayVector * t;
```

`rayVector` prowadzi od badanego piksela w stronę światła; `_RayDensity` skaluje długość tej drogi. Pętla dzieli ją na próbki, a `t` ustala położenie każdej z nich. Liczba próbek jest ograniczona do 8–32, niezależnie od ustawienia materiału.

#### Krok 3: sprawdzenie nieba i zsumowanie światła

Dla każdej pozycji shader odczytuje głębię i tworzy maskę nieba z uwzględnieniem reversed Z. Próbki nieba dodają wkład do `illumination`, ważony przez `decay`. Po każdym kroku `decay` jest mnożone przez `_RayWeight`, więc kolejne próbki mają stopniowo mniejszy wpływ. `weightSum` pozwala znormalizować sumę.

#### Krok 4: nałożenie promieni na scenę

```hlsl
float visibility = illumination / max(weightSum, 0.0001);
```

Po normalizacji shader porównuje wynik z `_RayThreshold`. Widoczność, `_RayIntensity`, `_RayExposure` i `_RayColor` określają końcowy wkład promieni do obrazu. Materiał jest nakładany jako przebieg pełnoekranowy; `ZTest Always` przetwarza cały obraz, a `ZWrite Off` nie zmienia jego głębi.

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
**Rodzaj zastosowanej techniki:** Ekranowy efekt promieni wyliczany przez próbkowanie głębi w kierunku światła; nie jest wolumetryczny.

To efekt ekranowy, nie rzeczywiste światło wolumetryczne. Shader korzysta z obrazu i głębi sceny, nie zapisuje własnej głębi. W `Assets/Settings/PC_Renderer.asset` znajduje się aktywna funkcja Renderer Feature o nazwie `GodRays`, której materiałem przebiegu jest `GodRays_Mat`. `PC_RPAsset` wskazuje ten renderer. W konfiguracji `Mobile_Renderer` lista Renderer Features jest pusta, więc ta informacja dotyczy renderera PC.

---

## GroundFog.shader
**Plik:** `Assets/Shaders/Environment/GroundFog.shader`

### 1. Jaki efekt to daje?
Tworzy półprzezroczysty, animowany obłok dymu z większymi plamami, drobnymi detalami, unoszeniem i wirowaniem. Dym jest rzadszy blisko gracza.

### 2. Jak to jest zrobione?

Ten shader tworzy dym wewnątrz bryły, przez którą patrzy kamera. Zamiast obliczyć jeden kolor na powierzchni, przechodzi promieniem kamery przez wnętrze obłoku i wielokrotnie sprawdza, ile dymu znajduje się na jego drodze. To rzeczywisty efekt wolumetryczny liczony metodą ray marchingu.

#### W skrócie

Przechodzi promieniem kamery przez bryłę mgły, oblicza szum i gęstość w wielu punktach oraz osłabia dym blisko pozycji gracza.

#### Krok 1: znalezienie odcinka promienia wewnątrz bryły

Dla piksela shader wyznacza promień od kamery i sprawdza, gdzie przecina on ograniczającą bryłę. Jeśli nie przecina bryły, piksel jest odrzucany. Głębia sceny pozwala skrócić promień do najbliższej widocznej powierzchni, żeby dym nie pojawiał się za terenem lub innymi obiektami.

#### Krok 2: podział drogi na próbki

```hlsl
#define STEPS 32
float stepSize = (tFar - tNear) / STEPS;
```

Odcinek od `tNear` do `tFar` jest dzielony na 32 równe kroki. W każdej iteracji pętli shader bierze środek kolejnego kroku i oblicza tam lokalną gęstość oraz kolor dymu.

#### Krok 3: animacja i nieregularny kształt dymu

Współrzędne próbki są przesuwane w pionie przez `_RiseSpeed`, co sprawia, że wzór wygląda na unoszący się. Sinus i cosinus z `_SwirlSpeed` oraz `_WarpStrength` delikatnie odchylają współrzędne, tworząc skręt. Następnie kilka wywołań `Noise3D` tworzy wektor zniekształcenia. To **domain warping**: szum przesuwa współrzędne, z których dopiero potem pobierane są kolejne warstwy szumu.

`FBM` jest liczone osobno dla dużych form (`_SmokeScale`) i drobnych szczegółów (`_DetailScale`). Wyniki łączą się z wagami `0.75` i `0.25`. Funkcja `smoothstep` zamienia szum w miękką maskę gęstości zamiast ostrego progu.

#### Krok 4: wygładzenie granic i wykluczenie przy graczu

Maski `bottomFade` i `topFade` zmniejszają gęstość przy dolnej i górnej granicy bryły. Potem shader przelicza pozycję próbki na świat i mierzy jej poziomą odległość od `_PlayerPosition`. `smoothstep` tworzy miękką granicę obszaru wykluczenia: blisko gracza dym jest osłabiony, a dalej stopniowo odzyskuje gęstość. Pozycję gracza przekazuje `FogPlayerExclusion` przez `MaterialPropertyBlock`.

#### Krok 5: obliczenie przezroczystości i koloru próbki

```hlsl
float alpha = 1.0 - exp(-density * _Density * stepSize * 3.0);
float3 sampleColor = lerp(_SmokeColor.rgb, _GlowColor.rgb, glow);
```

Gęstość, `_Density` i długość kroku określają, jak bardzo pojedyncza próbka zasłania to, co za nią. Wzór wykładniczy nawiązuje do tłumienia światła w ośrodku. Wartość szumu steruje przejściem między kolorem dymu a kolorem rozświetlenia.

#### Krok 6: składanie próbek w końcowy obłok

Każda próbka jest dodawana od przodu do tyłu z uwzględnieniem przezroczystości, która jeszcze pozostała. Gdy zgromadzona alfa przekroczy `0.98`, pętla się kończy, bo dalsze próbki prawie nie zmienią wyniku. Jeśli dym jest prawie niewidoczny, piksel jest odrzucany; w przeciwnym razie shader zwraca skumulowany kolor i alfę.

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
**Rodzaj zastosowanej techniki:** Wolumetryczny ray marching połączony z proceduralnym szumem 3D, FBM i domain warping.

Shader jest przezroczysty, korzysta z głębi, rysuje wewnętrzne powierzchnie bryły i nie zapisuje głębi. Koszt zależy od liczby pikseli obłoku i 32 próbek. Materiał `GroundFog_Mat` jest użyty na rendererach ze skryptem wykluczenia w scenach `Scene1` i `SampleScene`.

## Grass.shader
**Plik:** `Assets/Shaders/Flora/Grass.shader`

### 1. Jaki efekt to daje?
Nadaje źdźbłom gradient od ciemnej zieleni przy ziemi do turkusu na końcach. Końcówki świecą, a źdźbła poruszają się jak na wietrze.

### 2. Jak to jest zrobione?

Generator przygotowuje źdźbła jako siatkę, a shader w czasie renderowania porusza jej wierzchołkami i dobiera kolor według wysokości. W ten sposób ta sama geometria może falować na wietrze bez przesuwania całego źdźbła jako obiektu.

#### W skrócie

Przesuwa wierzchołki źdźbeł sinusoidalnym wiatrem, dobiera kolor według wysokości i rozjaśnia ich końcówki emisją.

#### Krok 1: przygotowanie pozycji i wysokości

Vertex shader przelicza pozycje źdźbła do przestrzeni świata. Wysokość wierzchołka jest używana jako informacja, czy znajduje się blisko podstawy, czy końcówki. Wierzchołki i kolory początkowe przygotowuje `MagicalGrassGenerator`.

#### Krok 2: przesunięcie wierzchołków przez wiatr

```hlsl
float wind = sin(_Time.y * _WindSpeed
    + positionWS.x * _WindScale
    + positionWS.z * _WindScale);
float bend = height * height;
positionWS.x += wind * _WindStrength * bend;
```

`_Time.y` zmienia falę w czasie, `_WindSpeed` steruje jej tempem, a współrzędne świata sprawiają, że wiatr ma różną fazę w różnych miejscach. `height * height` sprawia, że podstawa prawie się nie rusza, a wyżej położone wierzchołki wychylają się mocniej. Druga składowa oparta na cosinusie dodaje ruch w osi Z.

#### Krok 3: utworzenie gradientu koloru

Shader miesza `_BaseColor` z `_MiddleColor`, a potem ze `_TipColor`, korzystając z wysokości i `smoothstep`. Dzięki miękkim przejściom dół, środek i końcówka źdźbła nie mają ostrych granic. Kolor wierzchołka dostarczony przez generator dodaje niewielkie zróżnicowanie między źdźbłami.

#### Krok 4: rozświetlenie końcówek

Maska `tipMask` obejmuje końcową część źdźbła. Shader mnoży ją przez kolor końcówki i `_EmissionStrength`, a następnie dodaje emisję do koloru. Wiatr, gradient i emisja są obliczane w shaderze; ustawienia renderowania decydują m.in. o tym, że źdźbła są widoczne z obu stron.

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
**Rodzaj zastosowanej techniki:** Animacja wierzchołków przez ich przesuwanie, gradient kolorów i emisja; nie jest wolumetryczny.

Shader URP rysuje obie strony źdźbeł i zapisuje głębię. Geometrię i kolor wierzchołków przygotowuje `MagicalGrassGenerator`; ruch wiatru oraz gradient wykonuje shader.

---

## Grzyby.shader
**Plik:** `Assets/Shaders/Flora/Grzyby.shader`

### 1. Jaki efekt to daje?
Nakłada teksturę na model, wycina jej przezroczyste fragmenty i dodaje pulsujący blask w górnej części. Materiały `grzybyMat` i `grzyby2Mat` korzystają z tego shadera.

### 2. Jak to jest zrobione?

Shader pobiera teksturę grzyba, usuwa z obrazu piksele przezroczyste i dodaje pulsującą poświatę do wybranego obszaru modelu. Poświata jest liczona osobno dla każdego piksela na podstawie jego wysokości.

#### W skrócie

Nakłada teksturę, odrzuca przezroczyste piksele i dodaje pulsującą emisję do określonej wysokości modelu.

#### Krok 1: pobranie tekstury i koloru

Vertex shader przekazuje do fragment shadera UV tekstury oraz wysokość w lokalnych współrzędnych modelu. Fragment shader pobiera `_BaseMap` w tym miejscu i mnoży próbkę przez `_BaseColor`.

#### Krok 2: wycięcie przezroczystych fragmentów

```hlsl
clip(baseSample.a - _AlphaClip);
```

Jeśli alfa tekstury jest poniżej progu `_AlphaClip`, `clip` odrzuca piksel. Dzięki temu kształt grzyba może mieć wycięte brzegi z tekstury bez klasycznego półprzezroczystego mieszania.

#### Krok 3: wyznaczenie miejsca świecenia

```hlsl
half mask = smoothstep(
    _MaskHeight - _MaskFeather,
    _MaskHeight + _MaskFeather,
    input.localHeight);
```

`_MaskHeight` ustala wysokość, przy której zaczyna się maska emisji. `_MaskFeather` określa szerokość miękkiego przejścia. Poniżej maski wkład poświaty jest mniejszy, powyżej większy.

#### Krok 4: pulsowanie i dodanie emisji

```hlsl
half pulse = 1.0h - _PulseAmount * 0.5h
    + _PulseAmount * 0.5h * sin(_Time.y * _PulseSpeed);
half3 emission = _GlowColor.rgb * _GlowStrength
    * _BloomBoost * pulse * mask;
```

Sinus zmienia jasność w czasie: `_PulseSpeed` steruje tempem, a `_PulseAmount` zakresem pulsowania. Kolor `_GlowColor`, `_GlowStrength` i `_BloomBoost` określają siłę rozświetlenia; wynik jest ograniczony maską wysokości. Emisja zostaje dodana do koloru tekstury. Efekt Bloom wokół grzyba zależy dodatkowo od konfiguracji post-processingu.

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
**Rodzaj zastosowanej techniki:** Shader teksturowany z odrzucaniem alfa i animowaną emisją maskowaną wysokością; efekt powierzchniowy.

Shader URP renderuje obie strony, zapisuje głębię i odrzuca piksele na podstawie alfy. Bloom widoczny wokół modelu zależy także od ustawień post-processingu.

---

## TreeSpirals.shader
**Plik:** `Assets/Shaders/Flora/TreeSpirals.shader`

### 1. Jaki efekt to daje?
Nadaje liściom proceduralne różnice kolorów, główną żyłkę i żyłki boczne. Materiały `TreeSpirals_Mat1`, `TreeSpirals_Mat2` i `TreeSpirals_Mat3` korzystają z tego shadera.

### 2. Jak to jest zrobione?

Shader oblicza wzór liści bez osobnej tekstury: wykorzystuje UV modelu, czyli położenie fragmentu na powierzchni. Z tych współrzędnych tworzy plamy i żyłki, a potem oblicza kolor powierzchni z uwzględnieniem światła.

#### W skrócie

Z UV oblicza wzór plam i żyłek liścia, a następnie uwzględnia światło przy wyznaczaniu jego koloru.

#### Krok 1: utworzenie plam na liściu

```hlsl
float pattern = sin(uv.y * 31.0 + sin(uv.x * 17.0) * 1.7)
    * sin(uv.y * 11.0 + uv.x * 9.0);
pattern = pattern * 0.5 + 0.5;
float3 color = lerp(_DarkColor.rgb, _LightColor.rgb, pattern);
color = lerp(_BaseColor.rgb, color, _Variation);
```

Dwie fale sinusoidalne, w tym jedna zniekształcona przez drugą, dają nieregularny wzór. Pierwsze przekształcenie przenosi wynik do zakresu użytecznego jako waga koloru. `lerp` miesza kolor ciemny z jasnym, a `_Variation` określa, jak mocno wzór różni się od `_BaseColor`.

#### Krok 2: dodanie żyłek

Shader mierzy odległość `uv.x` od środka liścia i przez `smoothstep` tworzy główną żyłkę. Podobne maski i fale wyznaczają żyłki boczne. Ich kolory są nakładane na wcześniej obliczony kolor plam. Położenie i szerokość tych elementów wynikają z UV oraz stałych zapisanych w shaderze.

#### Krok 3: oświetlenie powierzchni

Vertex shader przekazuje normalną liścia i dane potrzebne do obliczenia kierunku światła oraz kamery. Fragment shader porównuje normalną z kierunkiem głównego światła, dodaje światło otoczenia i oblicza skupione odbicie. Wynik oświetlenia wpływa na jasność wzoru.

Shader nie korzysta z tekstury wzoru, jest nieprzezroczysty i renderuje obie strony liścia. Nie zawiera animacji fali ani nie odczytuje pozycji gracza; aktywację pnączy obsługuje osobny `MagicTreeVines`.

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
**Rodzaj zastosowanej techniki:** Proceduralny wzór liści liczony ze współrzędnych UV oraz oświetlenie powierzchniowe; nie jest wolumetryczny.

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

**Połączenie efektów:** pnącza aktywują się na podstawie odległości gracza w skrypcie `MagicTreeVines`. Shader liści odpowiada za ich kolor i żyłki; nie steruje aktywacją pnączy.

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

Najlepiej zbudować prezentację wokół trzech łatwych do pokazania przykładów: kryształu z Fresnelem jako efektu materiałowego, iskier jako efektu dynamicznego oraz GroundFog jako zaawansowanego efektu reagującego na gracza. Pokazują one kolejne poziomy trudności i mają konkretne potwierdzenie w kodzie projektu. Pnącza można pokazać jako efekt aktywowany przez zbliżenie gracza: `MagicTreeVines` sprawdza odległość i rozpoczyna ich wzrost.








