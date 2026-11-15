// Shader nakladajacy mgle dystansowa na obraz sceny.
// Intensywnosc efektu zalezy od odleglosci obiektow od kamery.
Shader "MagicznyLas/Distance Fog"
{
    Properties
    {
        // Kolor mgly z obsluga wartosci HDR.
        [HDR] _FogColor ("Fog Color", Color) = (0.48, 0.66, 0.64, 1)

        // Odleglosc od kamery, od ktorej zaczyna sie narastanie mgly.
        _FogStart ("Fog Start Distance", Float) = 0

        // Odleglosc, przy ktorej efekt mgly osiaga pelna intensywnosc.
        _FogEnd ("Fog End Distance", Float) = 55

        // Parametr kontrolujacy tempo narastania gestosci mgly.
        _FogDensity ("Fog Density", Range(0.1, 8)) = 4.0

        // Minimalna intensywnosc mgly widocznej w poblizu kamery.
        _NearFogStrength ("Near Fog Strength", Range(0, 0.25)) = 0.06

        // Intensywnosc mgly nakladanej na obszary nieba.
        _SkyFogStrength ("Sky Fog Strength", Range(0, 0.5)) = 0.12
    }

    SubShader
    {
        // Shader przeznaczony do URP, przetwarzajacy gotowy obraz sceny.
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Name "DistanceFog"

            // Wylaczenie zapisu do bufora glebokosci.
            ZWrite Off

            // Test glebokosci jest zawsze zaliczany, aby shader mogl
            // przetworzyc wszystkie piksele obrazu sceny.
            ZTest Always

            // Wylaczenie odrzucania scian.
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            // Biblioteka podstawowych funkcji URP.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Funkcje i struktury wykorzystywane podczas przetwarzania obrazu przez Blitter.
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            // Dostep do tekstury glebokosci sceny.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            // Parametry materialu przekazywane do shadera.
            CBUFFER_START(UnityPerMaterial)
                half4 _FogColor;
                float _FogStart;
                float _FogEnd;
                float _FogDensity;
                float _NearFogStrength;
                float _SkyFogStrength;
            CBUFFER_END

            // Fragment shader analizuje kazdy piksel obrazu i naklada na niego mgle.
            half4 Frag(Varyings input) : SV_Target
            {
                // Wspolrzedne UV okreslaja polozenie aktualnego piksela na ekranie.
                float2 uv = input.texcoord;

                // Pobranie oryginalnego koloru piksela z obrazu renderowanej sceny.
                half4 sceneColor = SAMPLE_TEXTURE2D_X(
                    _BlitTexture,
                    sampler_LinearClamp,
                    uv
                );

                // Odczyt wartosci glebokosci dla aktualnego piksela.
                // Na jej podstawie mozna odtworzyc polozenie obiektu w przestrzeni swiata.
                float rawDepth = SampleSceneDepth(uv);

                // Obsluga platform korzystajacych z odwroconego bufora glebokosci.
                // Wartosc graniczna oznacza brak geometrii w danym pikselu, czyli niebo.
                #if UNITY_REVERSED_Z
                    if (rawDepth <= 0.00001)
                        return half4(
                            lerp(sceneColor.rgb, _FogColor.rgb, _SkyFogStrength),
                            sceneColor.a
                        );
                #else
                    // W standardowym buforze glebokosci wartosc bliska 1 oznacza niebo.
                    if (rawDepth >= 0.99999)
                        return half4(
                            lerp(sceneColor.rgb, _FogColor.rgb, _SkyFogStrength),
                            sceneColor.a
                        );
                #endif

                // Odtworzenie pozycji fragmentu w przestrzeni swiata
                // na podstawie wspolrzednych ekranu, glebokosci i macierzy odwrotnej VP.
                float3 worldPosition = ComputeWorldSpacePosition(
                    uv,
                    rawDepth,
                    UNITY_MATRIX_I_VP
                );

                // Obliczenie odleglosci obiektu od kamery.
                float distanceToCamera = distance(
                    _WorldSpaceCameraPos,
                    worldPosition
                );

                // Przeksztalcenie odleglosci na zakres 0-1.
                // Obiekty blizsze Fog Start otrzymuja nizsza wartosc,
                // a obiekty znajdujace sie przy Fog End zblizaja sie do 1.
                float distanceFactor = saturate(
                    (distanceToCamera - _FogStart) /
                    max(_FogEnd - _FogStart, 0.001)
                );

                // Zabezpieczenie mianownika przed dzieleniem przez zero.
                float denominator = max(1.0 - exp(-_FogDensity), 0.001);

                // Obliczenie nieliniowego narastania mgly.
                // Normalizacja sprawia, ze na koncu zakresu odleglosci
                // efekt osiaga pelna intensywnosc.
                float distanceFog =
                    (1.0 - exp(-_FogDensity * distanceFactor)) /
                    denominator;

                // Uwzglednienie minimalnej intensywnosci mgly w poblizu kamery.
                // Dla wiekszych odleglosci wartosc stopniowo zbliza sie do 1.
                float fogFactor = lerp(
                    _NearFogStrength,
                    1.0,
                    saturate(distanceFog)
                );

                // Polaczenie koloru sceny z kolorem mgly.
                // Waga mieszania zalezy od obliczonej intensywnosci efektu.
                half3 finalColor = lerp(
                    sceneColor.rgb,
                    _FogColor.rgb,
                    saturate(fogFactor)
                );

                // Zwrocenie zmodyfikowanego koloru z zachowaniem
                // oryginalnej wartosci przezroczystosci obrazu.
                return half4(finalColor, sceneColor.a);
            }

            ENDHLSL
        }
    }

    // Brak dodatkowego shadera zastepczego.
    FallBack Off
}