// Shader nadajacy pnaczom naturalny wyglad lisci poprzez proceduralne generowanie
// zroznicowania kolorow, wzoru unerwienia oraz oswietlenia powierzchni.
// Nie wymaga tekstury, poniewaz wzory lisci sa obliczane matematycznie w shaderze.
Shader "MagicForest/NaturalVine"
{
    Properties
    {
        // Podstawowy kolor powierzchni liscia.
        _BaseColor ("Base Color", Color) = (0.10, 0.16, 0.045, 1)

        // Jasniejszy kolor wykorzystywany do tworzenia zroznicowania powierzchni.
        _LightColor ("Light Color", Color) = (0.19, 0.25, 0.075, 1)

        // Ciemniejszy kolor odpowiadajacy za obszary cienia i zroznicowanie liscia.
        _DarkColor ("Shadow Color", Color) = (0.055, 0.085, 0.025, 1)

        // Kolor wykorzystywany do symulowania unerwienia liscia.
        _VeinColor ("Vein Color", Color) = (0.25, 0.30, 0.12, 1)

        // Intensywnosc proceduralnego zroznicowania kolorow powierzchni.
        _Variation ("Color Variation", Range(0, 1)) = 0.3

        // Sila wizualnego efektu unerwienia liscia.
        _VeinStrength ("Vein Strength", Range(0, 1)) = 0.2

        // Intensywnosc powierzchniowego odbicia swiatla.
        _Smoothness ("Specular Smoothness", Range(0, 1)) = 0.18
    }

    SubShader
    {
        Tags
        {
            // Shader przeznaczony do Universal Render Pipeline.
            "RenderPipeline" = "UniversalPipeline"

            // Material nie wykorzystuje przezroczystosci.
            "RenderType" = "Opaque"

            // Obiekt renderowany w standardowej kolejce geometrii.
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardLit"

            // Przebieg renderowania z oswietleniem w URP.
            Tags { "LightMode" = "UniversalForward" }

            // Renderowanie obu stron powierzchni, rowniez od tylu liscia.
            Cull Off

            // Zapis glebokosci renderowanej geometrii.
            ZWrite On

            HLSLPROGRAM

            // Funkcje przetwarzajace wierzcholki i piksele.
            #pragma vertex vert
            #pragma fragment frag

            // Biblioteka podstawowych funkcji i transformacji przestrzennych URP.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Biblioteka funkcji zwiazanych z oswietleniem.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // Parametry materialu przekazywane z poziomu Unity.
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _LightColor;
                float4 _DarkColor;
                float4 _VeinColor;
                float _Variation;
                float _VeinStrength;
                float _Smoothness;
            CBUFFER_END

            // Dane wejsciowe pojedynczego wierzcholka siatki.
            struct Attributes
            {
                // Pozycja wierzcholka w przestrzeni lokalnej obiektu.
                float4 positionOS : POSITION;

                // Normalna wykorzystywana podczas obliczania oswietlenia.
                float3 normalOS : NORMAL;

                // Wspolrzedne UV wykorzystywane do generowania wzorow liscia.
                float2 uv : TEXCOORD0;
            };

            // Dane przekazywane z vertex shadera do fragment shadera.
            struct Varyings
            {
                // Pozycja wierzcholka w przestrzeni przycinania.
                float4 positionHCS : SV_POSITION;

                // Pozycja wierzcholka w przestrzeni swiata.
                float3 positionWS : TEXCOORD0;

                // Normalna powierzchni w przestrzeni swiata.
                float3 normalWS : TEXCOORD1;

                // Wspolrzedne UV powierzchni.
                float2 uv : TEXCOORD2;
            };

            // Vertex shader przeksztalcajacy geometrie i przygotowujacy dane
            // potrzebne do obliczenia koloru oraz oswietlenia w fragment shaderze.
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Pobranie pozycji wierzcholka w przestrzeni przycinania i swiata.
                VertexPositionInputs pos =
                    GetVertexPositionInputs(IN.positionOS.xyz);

                // Zapis pozycji wykorzystywanej przez rasteryzator.
                OUT.positionHCS = pos.positionCS;

                // Przekazanie pozycji w przestrzeni swiata do obliczen oswietlenia.
                OUT.positionWS = pos.positionWS;

                // Przeksztalcenie normalnej z przestrzeni lokalnej do przestrzeni swiata.
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

                // Przekazanie wspolrzednych UV do fragment shadera.
                OUT.uv = IN.uv;

                return OUT;
            }

            // Fragment shader obliczajacy kolor i oswietlenie kazdego piksela.
            half4 frag(Varyings IN) : SV_Target
            {
                // Pobranie wspolrzednych UV powierzchni liscia.
                float2 uv = IN.uv;

                // PROCEDURALNE ZROZNICOWANIE KOLORU
                // Polaczenie dwoch fal sinusoidalnych tworzy nieregularny wzor
                // kolorystyczny na powierzchni liscia.
                float pattern =
                    sin(uv.y * 31.0 + sin(uv.x * 17.0) * 1.7)
                    * sin(uv.y * 11.0 + uv.x * 9.0);

                // Przeskalowanie wyniku z zakresu -1 do 1 na zakres 0 do 1.
                pattern = pattern * 0.5 + 0.5;

                // Mieszanie ciemnego i jasnego koloru na podstawie wzoru.
                float3 color = lerp(
                    _DarkColor.rgb,
                    _LightColor.rgb,
                    pattern);

                // Polaczenie wygenerowanego wzoru z kolorem podstawowym.
                // Parametr Variation kontroluje intensywnosc zroznicowania.
                color = lerp(
                    _BaseColor.rgb,
                    color,
                    _Variation);

                // UNERWIENIE LIScia
                // Utworzenie glownej zyly biegnacej wzdluz srodka liscia.
                // Odleglosc od srodka UV.x = 0.5 okresla jej polozenie.
                float centerVein = 1.0 - smoothstep(
                    0.0, 0.10, abs(uv.x - 0.5));

                // Wygenerowanie wzoru falowego odpowiadajacego zylkom bocznym.
                // Wzor zalezy od polozenia wzdluz liscia i odleglosci od jego srodka.
                float veinPattern =
                    sin(uv.y * 65.0 + abs(uv.x - 0.5) * 30.0);

                // Ograniczenie wzoru do obszaru bocznych zylek.
                // Dodatkowe maski kontroluja ich polozenie i zasieg na lisciu.
                float sideVeins =
                    smoothstep(0.78, 0.96, veinPattern)
                    * smoothstep(0.04, 0.13, abs(uv.x - 0.5))
                    * (1.0 - smoothstep(
                        0.25, 0.43, abs(uv.x - 0.5)));

                // Polaczenie glownej zyly i zylek bocznych.
                // saturate ogranicza wynik do zakresu 0-1.
                float veins = saturate(
                    centerVein * 0.25 + sideVeins);

                // Nalozenie koloru unerwienia na powierzchnie liscia.
                // Vein Strength kontroluje widocznosc wygenerowanych zylek.
                color = lerp(
                    color,
                    _VeinColor.rgb,
                    veins * _VeinStrength);

                // OSWIETLENIE POWIERZCHNI
                // Normalizacja normalnej w przestrzeni swiata.
                float3 normalWS = normalize(IN.normalWS);

                // Pobranie danych glownego zrodla swiatla w scenie.
                Light mainLight = GetMainLight();

                // Obliczenie iloczynu skalarnego normalnej i kierunku swiatla.
                // Wartosci ujemne sa ograniczane do zera, aby powierzchnia
                // nie otrzymywala bezposredniego oswietlenia od tylu.
                float NdotL = saturate(
                    dot(normalWS, normalize(mainLight.direction)));

                // Obliczenie oswietlenia otoczenia na podstawie
                // sond harmonijnych sferycznych (Spherical Harmonics).
                float3 ambient = SampleSH(normalWS);

                // Polaczenie oswietlenia otoczenia z oswietleniem glownym.
                float3 lighting =
                    ambient + mainLight.color * NdotL;

                // ODBICIE SPECULAR
                // Wyznaczenie kierunku od powierzchni do kamery.
                float3 viewDir = normalize(
                    GetWorldSpaceViewDir(IN.positionWS));

                // Wyznaczenie kierunku polowicznego pomiedzy swiatlem a kamera.
                // Jest wykorzystywany w modelu odbicia Blinn-Phong.
                float3 halfDir = normalize(
                    normalize(mainLight.direction) + viewDir);

                // Obliczenie intensywnosci odbicia specular.
                // Potega 48 okresla skupienie refleksu, a Smoothness
                // kontroluje jego intensywnosc.
                float specular = pow(
                    saturate(dot(normalWS, halfDir)), 48.0)
                    * _Smoothness * NdotL;

                // Polaczenie koloru powierzchni z oswietleniem rozproszonym
                // oraz dodatkowym odbiciem specular.
                float3 finalColor =
                    color * lighting + mainLight.color * specular;

                // Zwrocenie koncowego koloru z pelna nieprzezroczystoscia.
                return half4(finalColor, 1.0);
            }

            ENDHLSL
        }
    }

    // Brak shadera zastepczego.
    FallBack Off
}