// Shader generujacy proceduralna, animowana objetosc magicznego dymu.
// Wykorzystuje ray marching, szum 3D, domain warping oraz przezroczyste mieszanie probek.
Shader "MagicznyLas/Magic Smoke Volume"
{
    Properties
    {
        // Kolor podstawowy dymu z obsluga wartosci HDR.
        [HDR] _SmokeColor ("Smoke Color", Color) = (0.35, 0.45, 0.55, 1)

        // Kolor dodatkowego swiatla nadajacego dymowi efekt wewnetrznego rozswietlenia.
        [HDR] _GlowColor ("Glow Color", Color) = (0.25, 0.55, 0.8, 1)

        // Ogolna gestosc dymu.
        _Density ("Density", Range(0, 5)) = 1.5

        // Skala szumu odpowiedzialnego za glowny ksztalt dymu.
        _SmokeScale ("Smoke Scale", Range(1, 20)) = 5

        // Skala szumu odpowiedzialnego za drobne detale.
        _DetailScale ("Detail Scale", Range(1, 40)) = 15

        // Sila deformacji wspolrzednych przestrzennych.
        _WarpStrength ("Warp Strength", Range(0, 1)) = 0.12

        // Kontrola lagodnosci przejsc pomiedzy obszarami dymu i pustej przestrzeni.
        _Softness ("Softness", Range(0.01, 1)) = 0.25

        // Szerokosc zanikania dymu przy dolnej i gornej granicy objetosci.
        _VerticalFade ("Vertical Fade", Range(0.01, 0.5)) = 0.12

        // Predkosc unoszenia sie wzoru dymu.
        _RiseSpeed ("Rise Speed", Range(0, 2)) = 0.05

        // Predkosc animacji ruchu wirowego.
        _SwirlSpeed ("Swirl Speed", Range(0, 3)) = 0.15

        // Intensywnosc efektu rozswietlenia dymu.
        _GlowStrength ("Glow Strength", Range(0, 5)) = 1

        // Pozycja gracza w przestrzeni swiata.
        _PlayerPosition ("Player Position", Vector) = (0, 0, 0, 1)

        // Promien obszaru, w ktorym dym jest calkowicie ograniczany.
        _ExclusionRadius ("Exclusion Radius", Range(0, 10)) = 2.5

        // Szerokosc stopniowego przejscia pomiedzy obszarem bez dymu a pelna gestoscia.
        _ExclusionFeather ("Exclusion Feather", Range(0.01, 5)) = 1.5
    }

    SubShader
    {
        Tags
        {
            // Shader przeznaczony do Universal Render Pipeline.
            "RenderPipeline" = "UniversalPipeline"

            // Obiekt jest renderowany w kolejce elementow przezroczystych.
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Name "MagicSmokeVolume"

            // Renderowanie wewnetrznych powierzchni obiektu ograniczajacego objetosc.
            Cull Front

            // Wylaczenie zapisu do bufora glebokosci.
            ZWrite Off

            // Ray marcher sam ogranicza dlugosc promienia na podstawie glebokosci sceny.
            // Pozwala to poprawnie mieszac dym z terenem i innymi widocznymi obiektami.
            ZTest Always

            // Standardowe mieszanie alfa: kolor zrodlowy jest laczony z kolorem tla.
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            // Funkcje przetwarzajace wierzcholki i piksele.
            #pragma vertex Vert
            #pragma fragment Frag

            // Shader Model 3.0 wymagany przez wykorzystywane operacje shaderowe.
            #pragma target 3.0

            // Podstawowe funkcje i transformacje przestrzenne URP.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Dostep do tekstury glebokosci sceny.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            // Parametry materialu przekazywane z poziomu Unity.
            CBUFFER_START(UnityPerMaterial)

                float4 _SmokeColor;
                float4 _GlowColor;

                float _Density;
                float _SmokeScale;
                float _DetailScale;
                float _WarpStrength;
                float _Softness;
                float _VerticalFade;

                float _RiseSpeed;
                float _SwirlSpeed;
                float _GlowStrength;

                float4 _PlayerPosition;
                float _ExclusionRadius;
                float _ExclusionFeather;

            CBUFFER_END

            // Stala liczba probek wykorzystywanych podczas ray marchingu.
            // Ogranicza koszt obliczeniowy renderowania objetosci.
            #define STEPS 32

            // Dane wejsciowe wierzcholka.
            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            // Dane przekazywane z vertex shadera do fragment shadera.
            struct Varyings
            {
                // Pozycja wierzcholka w przestrzeni przycinania.
                float4 positionCS : SV_POSITION;

                // Pozycja wierzcholka w przestrzeni lokalnej obiektu.
                float3 positionOS : TEXCOORD0;

                // Dane wymagane do obslugi renderowania stereo.
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // Vertex shader przeksztalcajacy wierzcholki objetosci.
            Varyings Vert(Attributes input)
            {
                Varyings output;

                // Przeksztalcenie pozycji lokalnej do przestrzeni przycinania.
                output.positionCS =
                    TransformObjectToHClip(input.positionOS.xyz);

                // Przekazanie pozycji lokalnej do fragment shadera.
                output.positionOS = input.positionOS.xyz;

                // Inicjalizacja danych renderowania stereo.
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                return output;
            }

            // Funkcja Hash generujaca pseudolosowa wartosc na podstawie pozycji 3D.
            // Wykorzystywana jako podstawa do budowania szumu proceduralnego.
            float Hash(float3 p)
            {
                // Przeksztalcenie wspolrzednych do zakresu ulamkowego.
                p = frac(p * 0.3183099 + 0.1);
                p *= 17.0;

                // Polaczenie skladowych pozycji w celu uzyskania pseudolosowej wartosci.
                return frac(
                    p.x * p.y * p.z *
                    (p.x + p.y + p.z)
                );
            }

            // Generowanie gladkiego szumu proceduralnego w przestrzeni 3D.
            float Noise3D(float3 p)
            {
                // Wyznaczenie komorki siatki oraz lokalnej pozycji wewnatrz komorki.
                float3 i = floor(p);
                float3 f = frac(p);

                // Wyg?adzenie interpolacji, aby ograniczyc widoczne granice komorek.
                f = f * f * (3.0 - 2.0 * f);

                // Obliczenie pseudolosowych wartosci w osmiu naroznikach komorki.
                float n000 = Hash(i + float3(0, 0, 0));
                float n100 = Hash(i + float3(1, 0, 0));
                float n010 = Hash(i + float3(0, 1, 0));
                float n110 = Hash(i + float3(1, 1, 0));

                float n001 = Hash(i + float3(0, 0, 1));
                float n101 = Hash(i + float3(1, 0, 1));
                float n011 = Hash(i + float3(0, 1, 1));
                float n111 = Hash(i + float3(1, 1, 1));

                // Interpolacja wartosci wzdluz osi X.
                float x00 = lerp(n000, n100, f.x);
                float x10 = lerp(n010, n110, f.x);

                float x01 = lerp(n001, n101, f.x);
                float x11 = lerp(n011, n111, f.x);

                // Interpolacja wynikow wzdluz osi Y.
                float y0 = lerp(x00, x10, f.y);
                float y1 = lerp(x01, x11, f.y);

                // Interpolacja wzdluz osi Z i zwrocenie koncowej wartosci szumu.
                return lerp(y0, y1, f.z);
            }

            // Fractal Brownian Motion (FBM).
            // Laczy kilka warstw szumu o roznych czestotliwosciach i amplitudach.
            // Pozwala uzyskac bardziej zlozone i naturalne struktury dymu.
            float FBM(float3 p)
            {
                float value = 0.0;

                // Poczatkowa amplituda i czestotliwosc pierwszej warstwy szumu.
                float amplitude = 0.5;
                float frequency = 1.0;

                // Polaczenie czterech oktaw szumu.
                for (int i = 0; i < 4; i++)
                {
                    // Dodanie kolejnej warstwy szumu do wyniku.
                    value += Noise3D(p * frequency) * amplitude;

                    // Zwiekszenie szczegolowosci kolejnej warstwy.
                    frequency *= 2.0;

                    // Zmniejszenie wplywu kolejnej warstwy na wynik.
                    amplitude *= 0.5;
                }

                return value;
            }

            // Obliczenie przeciecia promienia z jednostkowym prostopadloscianem.
            // Zwraca odleglosci wejscia i wyjscia promienia z objetosci.
            bool RayBox(
                float3 origin,
                float3 direction,
                out float tNear,
                out float tFar
            )
            {
                // Zabezpieczenie przed dzieleniem przez zero dla promieni
                // rownoleglych do scian prostopadloscianu.
                float3 directionSign = lerp(
                    -1.0,
                    1.0,
                    step(0.0, direction)
                );

                float3 safeDirection = directionSign
                    * max(abs(direction), 1e-6);

                // Odwrotnosc skladowych kierunku promienia.
                float3 invDir = 1.0 / safeDirection;

                // Odleglosci przeciecia promienia z parami przeciwleglych scian.
                float3 t0 = (-0.5 - origin) * invDir;
                float3 t1 = ( 0.5 - origin) * invDir;

                // Uporzadkowanie odleglosci wejscia i wyjscia dla kazdej osi.
                float3 tMin = min(t0, t1);
                float3 tMax = max(t0, t1);

                // Najwieksza z odleglosci wejscia wyznacza poczatek przeciecia.
                tNear = max(
                    max(tMin.x, tMin.y),
                    tMin.z
                );

                // Najmniejsza z odleglosci wyjscia wyznacza koniec przeciecia.
                tFar = min(
                    min(tMax.x, tMax.y),
                    tMax.z
                );

                // Odrzucenie fragmentu objetosci znajdujacego sie za kamera.
                tNear = max(tNear, 0.0);

                // Przeciecie istnieje, gdy koniec odcinka znajduje sie za jego poczatkiem.
                return tFar > tNear;
            }

            // Fragment shader obliczajacy wyglad objetosci dymu dla aktualnego piksela.
            half4 Frag(Varyings input) : SV_Target
            {
                // Inicjalizacja danych renderowania stereo dla aktualnego fragmentu.
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // Pobranie pozycji kamery w przestrzeni swiata i przeksztalcenie
                // jej do przestrzeni lokalnej objetosci dymu.
                float3 cameraWS = GetCameraPositionWS();
                float3 cameraOS = TransformWorldToObject(cameraWS);

                // Wyznaczenie znormalizowanego kierunku promienia od kamery
                // do interpolowanej pozycji na powierzchni objetosci.
                float3 rayDir = normalize(
                    input.positionOS - cameraOS
                );

                float tNear;
                float tFar;

                // Wyznaczenie odcinka, na ktorym promien przecina objetosc.
                // Jesli promien nie przecina prostopadloscianu, fragment jest odrzucany.
                if (!RayBox(cameraOS, rayDir, tNear, tFar))
                    discard;

                // Ograniczenie probkowania do pierwszej nieprzezroczystej powierzchni sceny.
                // Zapobiega renderowaniu dymu za terenem i innymi obiektami.
                float2 screenUV = GetNormalizedScreenSpaceUV(input.positionCS);
                float rawDepth = SampleSceneDepth(screenUV);

                // Sprawdzenie, czy pobrana glebokosc odpowiada geometrii sceny,
                // z uwzglednieniem konwencji reversed Z.
                #if UNITY_REVERSED_Z
                    bool hasSceneDepth = rawDepth > 1e-5;
                #else
                    bool hasSceneDepth = rawDepth < 0.99999;
                #endif

                if (hasSceneDepth)
                {
                    // Odtworzenie pozycji widocznej powierzchni sceny w przestrzeni swiata.
                    float3 scenePositionWS = ComputeWorldSpacePosition(
                        screenUV,
                        rawDepth,
                        UNITY_MATRIX_I_VP
                    );

                    // Przeksztalcenie pozycji sceny do przestrzeni lokalnej objetosci.
                    float3 scenePositionOS = TransformWorldToObject(scenePositionWS);

                    // Obliczenie odleglosci powierzchni sceny wzdluz kierunku promienia.
                    float sceneRayDistance = dot(
                        scenePositionOS - cameraOS,
                        rayDir
                    );

                    // Ograniczenie konca promienia do pierwszej widocznej powierzchni.
                    tFar = min(tFar, sceneRayDistance);
                }

                // Odrzucenie fragmentu, jesli po uwzglednieniu glebokosci
                // pozostaje zbyt krotki odcinek do probkowania.
                if (tFar <= tNear + 1e-4)
                    discard;

                // Wyznaczenie odleglosci pomiedzy kolejnymi probkami ray marchingu.
                float stepSize = (tFar - tNear) / STEPS;

                // Zmienne przechowujace skumulowany kolor i przezroczystosc dymu.
                float accumulatedAlpha = 0.0;
                float3 accumulatedColor = 0.0;

                // Aktualny czas wykorzystywany do animowania wzoru dymu.
                float time = _Time.y;

                // RAY MARCHING
                // Przejscie wzdluz promienia i wielokrotne obliczanie gestosci dymu.
                for (int i = 0; i < STEPS; i++)
                {
                    // Polozenie probki w srodku kolejnego przedzialu promienia.
                    float t = tNear + (i + 0.5) * stepSize;

                    // Oryginalna pozycja probki w przestrzeni lokalnej.
                    float3 originalP = cameraOS + rayDir * t;

                    // Pozycja wykorzystywana do obliczen animowanego szumu.
                    float3 p = originalP;

                    // ANIMACJA UNOSZENIA
                    // Przesuniecie wzoru szumu w pionie symuluje unoszenie sie dymu.
                    // Dzielenie przez skale detali spowalnia ruch drobnych struktur.
                    float animationOffset =
                        time * _RiseSpeed /
                        max(_DetailScale, 1.0);

                    p.y -= animationOffset;

                    // ANIMACJA WIROWA
                    // Delikatne deformowanie wspolrzednych X i Z za pomoca funkcji sinus
                    // i cosinus tworzy wrazenie powolnego wirowania dymu.
                    float swirlTime = time * _SwirlSpeed * 0.25;

                    float originalX = p.x;

                    p.x += sin(
                        swirlTime + p.y * 3.0
                    ) * _WarpStrength;

                    p.z += cos(
                        swirlTime + originalX * 3.0
                    ) * _WarpStrength;

                    // DOMAIN WARPING
                    // Generowanie trzech skladowych szumu, ktore deformuja
                    // wspolrzedne wykorzystywane do dalszego probkowania.
                    float3 warp;

                    // Jedna warstwa szumu dla kazdej skladowej wektora deformacji.
                    warp.x = Noise3D(p * _SmokeScale + 10.0);
                    warp.y = Noise3D(p * _SmokeScale + 20.0);
                    warp.z = Noise3D(p * _SmokeScale + 30.0);

                    // Przesuniecie wspolrzednych na podstawie obliczonego szumu.
                    // Dzieki temu struktura dymu jest mniej regularna.
                    float3 warpedP =
                        p + (warp - 0.5) * _WarpStrength;

                    // GLOWNY KSZTALT DYMU
                    // Szum o nizszej czestotliwosci odpowiada za duze struktury dymu.
                    float broadShape =
                        FBM(warpedP * _SmokeScale);

                    // DROBNE SZCZEGOLY
                    // Szum o wyzszej czestotliwosci dodaje lokalne zroznicowanie.
                    float detail =
                        FBM(warpedP * _DetailScale);

                    // Polaczenie glownego ksztaltu i drobnych detali.
                    // Wiekszy udzial ma szum odpowiedzialny za ogolna strukture.
                    float noiseValue =
                        broadShape * 0.75 +
                        detail * 0.25;

                    // GESTOSC DYMU
                    // Przeksztalcenie wartosci szumu na maske gestosci.
                    // Funkcja smoothstep zapewnia lagodne przejscie pomiedzy
                    // obszarami zawierajacymi dym i obszarami pustymi.
                    float density = smoothstep(
                        0.35,
                        0.35 + _Softness,
                        noiseValue
                    );

                    // Zanikanie gestosci przy dolnej granicy objetosci.
                    float heightFromVolumeBase = originalP.y + 0.5;
                    float bottomFade = smoothstep(
                        0.0,
                        _VerticalFade,
                        heightFromVolumeBase
                    );

                    // Zanikanie gestosci przy gornej granicy objetosci.
                    float topFade = 1.0 - smoothstep(
                        1.0 - _VerticalFade,
                        1.0,
                        heightFromVolumeBase
                    );

                    // Polaczenie obu masek ogranicza widoczne krawedzie objetosci.
                    density *= bottomFade * topFade;

                    // Pozycja probki w przestrzeni swiata.
                    // Wykorzystywana do wyznaczenia odleglosci od gracza.
                    // Nie uwzglednia deformacji animacyjnej szumu.
                    float3 sampleWorldPos =
                        TransformObjectToWorld(originalP);

                    // OBSZAR WYKLUCZENIA WOKOL GRACZA
                    // Odleglosc obliczana jest w plaszczyznie XZ, bez uwzgledniania wysokosci.
                    float playerDistance = distance(
                        sampleWorldPos.xz,
                        _PlayerPosition.xz
                    );

                    // Maska stopniowo przywracajaca gestosc wraz ze wzrostem
                    // odleglosci od gracza.
                    float playerMask = smoothstep(
                        _ExclusionRadius,
                        _ExclusionRadius + _ExclusionFeather,
                        playerDistance
                    );

                    // Ograniczenie gestosci dymu w poblizu pozycji gracza.
                    density *= playerMask;

                    // MODEL PRZEZROCZYSTOSCI INSPIROWANY PRAWEM BEERA-LAMBERTA
                    // Gestosc, intensywnosc oraz dlugosc kroku okreslaja
                    // przezroczystosc pojedynczej probki.
                    float alpha = 1.0 - exp(
                        -density * _Density * stepSize * 3.0
                    );

                    // Ograniczenie przezroczystosci do zakresu 0-1.
                    alpha = saturate(alpha);

                    // KOLOR I ROZSWIETLENIE
                    // Wartosc szumu steruje przejsciem pomiedzy kolorem dymu
                    // a kolorem dodatkowego rozswietlenia.
                    float glow = saturate(
                        noiseValue * _GlowStrength
                    );

                    float3 sampleColor = lerp(
                        _SmokeColor.rgb,
                        _GlowColor.rgb,
                        glow
                    );

                    // MIESZANIE PRZOD-TYL (FRONT-TO-BACK COMPOSITING)
                    // Obliczenie pozostalej przezroczystosci przed dodaniem kolejnej probki.
                    float remaining = 1.0 - accumulatedAlpha;

                    // Dodanie koloru probki z uwzglednieniem jej przezroczystosci
                    // oraz ilosci swiatla pozostajacego z tylu.
                    accumulatedColor +=
                        sampleColor * alpha * remaining;

                    // Aktualizacja skumulowanej przezroczystosci.
                    accumulatedAlpha +=
                        alpha * remaining;

                    // Wczesne zakonczenie obliczen, gdy objetosc jest juz niemal nieprzezroczysta.
                    // Kolejne probki mialyby wtedy bardzo maly wplyw na wynik.
                    if (accumulatedAlpha > 0.98)
                        break;
                }

                // Odrzucenie fragmentu, jesli zebrana przezroczystosc jest pomijalna.
                if (accumulatedAlpha < 0.001)
                    discard;

                // Normalizacja koloru przez skumulowana przezroczystosc.
                // Zabezpieczenie chroni przed dzieleniem przez wartosc bliska zeru.
                float3 finalColor =
                    accumulatedColor /
                    max(accumulatedAlpha, 0.001);

                // Zwrocenie koncowego koloru i przezroczystosci objetosci dymu.
                return half4(
                    finalColor,
                    accumulatedAlpha
                );
            }

            ENDHLSL
        }
    }
}