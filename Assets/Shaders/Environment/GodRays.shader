// Shader generujacy efekt promieni swietlnych (God Rays),
// ktore rozchodza sie od pozycji zrodla swiatla na ekranie.
Shader "MagicznyLas/Volumetric God Rays"
{
    Properties
    {
        // Kolor promieni swietlnych z obsluga wartosci HDR.
        [HDR] _RayColor ("Ray Color", Color) = (0.75, 0.85, 1.0, 1)

        // Mnoznik kontrolujacy ogolna intensywnosc promieni.
        _RayIntensity ("Ray Intensity", Range(0, 3)) = 1.0

        // Parametr regulujacy dlugosc i rozciagniecie promieni.
        _RayDensity ("Ray Density", Range(0.1, 2)) = 1.0

        // Wspolczynnik zanikania wkladu kolejnych probek.
        _RayWeight ("Ray Weight", Range(0.8, 0.999)) = 0.985

        // Liczba probek analizowanych wzdluz kierunku do zrodla swiatla.
        _RaySamples ("Ray Samples", Range(8, 32)) = 24

        // Prog okreslajacy minimalna widocznosc nieba potrzebna do wygenerowania promieni.
        _RayThreshold ("Ray Threshold", Range(0, 0.95)) = 0.2

        // Dodatkowy mnoznik ekspozycji kontrolujacy jasnosc efektu.
        _RayExposure ("Ray Exposure", Range(0, 3)) = 0.8

        // Pozycja zrodla swiatla w przestrzeni ekranu, wyrazona wspolrzednymi UV.
        _LightScreenPos ("Light Screen Position", Vector) = (0.5, 0.8, 0, 1)
    }

    SubShader
    {
        // Shader przeznaczony do przetwarzania obrazu w Universal Render Pipeline.
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "VolumetricGodRays"

            // Wylaczenie zapisu do bufora glebokosci.
            ZWrite Off

            // Shader przetwarza wszystkie piksele obrazu niezaleznie od ich glebokosci.
            ZTest Always

            // Wylaczenie odrzucania scian.
            Cull Off

            HLSLPROGRAM

            // Funkcje odpowiedzialne za przetwarzanie wierzcholkow i pikseli.
            #pragma vertex Vert
            #pragma fragment Frag

            // Biblioteka podstawowych funkcji Universal Render Pipeline.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Funkcje wykorzystywane do przetwarzania obrazu wejsciowego.
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            // Dostep do tekstury glebokosci sceny.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            // Parametry materialu przekazywane do shadera z poziomu Unity.
            CBUFFER_START(UnityPerMaterial)
                half4 _RayColor;
                float _RayIntensity;
                float _RayDensity;
                float _RayWeight;
                float _RaySamples;
                float _RayThreshold;
                float _RayExposure;
                float4 _LightScreenPos;
            CBUFFER_END

            // Fragment shader oblicza intensywnosc promieni dla kazdego piksela obrazu.
            half4 Frag(Varyings input) : SV_Target
            {
                // Pobranie wspolrzednych UV aktualnego piksela.
                float2 uv = input.texcoord;

                // Odczyt oryginalnego koloru sceny z tekstury obrazu wejsciowego.
                half4 sceneColor = SAMPLE_TEXTURE2D_X(
                    _BlitTexture,
                    sampler_LinearClamp,
                    uv
                );

                // Pobranie pozycji zrodla swiatla w przestrzeni ekranu.
                float2 lightUV = _LightScreenPos.xy;

                // Wyznaczenie wektora prowadzacego od aktualnego piksela
                // w kierunku zrodla swiatla.
                // Parametr Ray Density skaluje dlugosc analizowanego odcinka.
                float2 rayVector = (lightUV - uv) * _RayDensity;

                // Ustalenie liczby probek z ograniczeniem do zakresu 8-32.
                int samples = clamp((int)_RaySamples, 8, 32);

                // Zmienne przechowujace sume oswietlenia i sume wag probek.
                float illumination = 0.0;
                float weightSum = 0.0;

                // Poczatkowa waga probki, stopniowo zmniejszana podczas przechodzenia petli.
                float decay = 1.0;

                // Probkowanie obrazu wzdluz kierunku prowadzacego do zrodla swiatla.
                // Analizowane sa maksymalnie 32 punkty, zgodnie z ustawiona liczba probek.
                [loop]
                for (int i = 0; i < 32; i++)
                {
                    // Zakonczenie petli po osiagnieciu wymaganej liczby probek.
                    if (i >= samples)
                        break;

                    // Wyznaczenie polozenia probki wzdluz odcinka do zrodla swiatla.
                    // Przesuniecie o 0.5 pozwala umiescic probke w srodku przedzialu.
                    float t = (i + 0.5) / samples;
                    float2 sampleUV = uv + rayVector * t;

                    // Przerwanie probkowania, gdy kolejny punkt znajduje sie poza ekranem.
                    if (sampleUV.x < 0.0 || sampleUV.x > 1.0 ||
                        sampleUV.y < 0.0 || sampleUV.y > 1.0)
                        break;

                    // Odczyt glebokosci sceny w aktualnym punkcie probkowania.
                    float depth = SampleSceneDepth(sampleUV);

                    float skyMask;

                    // Rozpoznawanie pikseli nieba na podstawie wartosci bufora glebokosci.
                    // Sposob interpretacji glebokosci zalezy od konwencji uzywanej przez platforme.
                    #if UNITY_REVERSED_Z
                        skyMask = 1.0 - step(0.00001, depth);
                    #else
                        skyMask = step(0.99999, depth);
                    #endif

                    // Dodanie wkladu probki do oswietlenia.
                    // Piksele nieba zwiekszaja wynik, natomiast geometria sceny go nie zwieksza.
                    illumination += skyMask * decay;

                    // Sumowanie wag wykorzystywane pozniej do normalizacji wyniku.
                    weightSum += decay;

                    // Stopniowe zmniejszanie znaczenia kolejnych probek.
                    decay *= _RayWeight;
                }

                // Normalizacja zgromadzonego oswietlenia przez sume wag.
                // Zabezpieczenie zapobiega dzieleniu przez zero.
                float visibility = illumination / max(weightSum, 0.0001);

                // Przeksztalcenie widocznosci nieba na wartosc promieni w zakresie 0-1.
                // Wartosc ponizej progu nie generuje widocznego efektu.
                float rays = saturate(
                    (visibility - _RayThreshold) /
                    max(1.0 - _RayThreshold, 0.001)
                );

                // Wyg?adzenie przejscia intensywnosci promieni.
                rays = smoothstep(0.0, 1.0, rays);

                // Obliczenie koncowej intensywnosci z uwzglednieniem
                // parametrow intensywnosci i ekspozycji.
                float rayStrength =
                    rays * _RayIntensity * _RayExposure;

                // Dodanie promieni swietlnych do oryginalnego koloru sceny.
                half3 finalColor =
                    sceneColor.rgb + _RayColor.rgb * rayStrength;

                // Zwrocenie zmodyfikowanego koloru z zachowaniem oryginalnej alfy.
                return half4(finalColor, sceneColor.a);
            }

            ENDHLSL
        }
    }

    // Brak dodatkowego shadera zastepczego.
    FallBack Off
}