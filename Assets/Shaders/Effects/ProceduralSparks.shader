// Shader generujacy proceduralne blyski swietlne z miekkim halo
// i jasnym rdzeniem, wykorzystywane do tworzenia efektu magicznych iskier.
Shader "MagicznyLas/Procedural Spark"
{
    Properties
    {
        // Kolor iskry z obsluga wartosci HDR.
        [HDR] _SparkColor ("Spark Color", Color) = (0.1, 0.8, 1.0, 1.0)

        // Mnoznik kontrolujacy intensywnosc emitowanego swiatla.
        _Intensity ("Glow Intensity", Range(0, 10)) = 3

        // Parametr regulujacy rozmycie i szerokosc swietlnej poswiaty.
        _Softness ("Edge Softness", Range(0.05, 2)) = 0.7

        // Kontrola rozmiaru jasnego rdzenia iskry.
        _CoreSize ("Bright Core Size", Range(0.05, 0.8)) = 0.25
    }

    SubShader
    {
        Tags
        {
            // Shader przeznaczony do renderowania w Universal Render Pipeline.
            "RenderPipeline" = "UniversalPipeline"

            // Obiekt jest renderowany w kolejce elementow przezroczystych.
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Name "SparkUnlit"
            Tags { "LightMode" = "UniversalForward" }

            // Addytywne mieszanie powoduje nakladanie jasnosci iskry na tlo.
            Blend SrcAlpha One

            // Wylaczenie zapisu do bufora glebokosci dla efektu przezroczystego.
            ZWrite Off

            // Renderowanie obu stron powierzchni.
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.0

            // Biblioteka URP zawierajaca funkcje transformacji wspolrzednych.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Parametry materialu przekazywane do shadera z poziomu Unity.
            CBUFFER_START(UnityPerMaterial)
                half4 _SparkColor;
                float _Intensity;
                float _Softness;
                float _CoreSize;
            CBUFFER_END

            // Dane wejsciowe pobierane dla kazdego wierzcholka siatki.
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            // Dane przekazywane z vertex shadera do fragment shadera.
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // Vertex shader przeksztalca polozenie wierzcholkow
            // z przestrzeni lokalnej obiektu do przestrzeni projekcji kamery.
            Varyings Vert(Attributes input)
            {
                Varyings output;

                // Przeliczenie pozycji wierzcholka na wspolrzedne clip space.
                output.positionHCS =
                    TransformObjectToHClip(input.positionOS.xyz);

                // Przekazanie wspolrzednych UV do fragment shadera.
                output.uv = input.uv;

                return output;
            }

            // Fragment shader oblicza kolor i intensywnosc kazdego piksela iskry.
            half4 Frag(Varyings input) : SV_Target
            {
                // Przeksztalcenie wspolrzednych UV z zakresu 0-1 na zakres -1 do 1.
                // Pozwala to traktowac srodek powierzchni jako punkt (0, 0).
                float2 p = input.uv * 2.0 - 1.0;

                // Obliczenie odleglosci piksela od srodka powierzchni.
                float r = length(p);

                // Wyznaczenie miekkiej poswiaty o rozkladzie radialnym.
                // Funkcja exp powoduje stopniowe zmniejszanie intensywnosci
                // wraz ze wzrostem odleglosci od srodka iskry.
                float halo = exp(-r * r * (3.0 / max(_Softness, 0.05)));

                // Utworzenie jasnego rdzenia z wykorzystaniem smoothstep.
                // Funkcja zapewnia plynne przejscie pomiedzy jasnym srodkiem
                // a zewnetrzna czescia iskry.
                float core = 1.0 - smoothstep(
                    _CoreSize * 0.5,
                    _CoreSize,
                    r
                );

                // Polaczenie halo i rdzenia w jeden efekt swietlny.
                // Funkcja saturate ogranicza wynik do zakresu 0-1.
                float glow = saturate(halo * 0.65 + core);

                // Obliczenie koncowego koloru z uwzglednieniem intensywnosci swiecenia.
                half3 color = _SparkColor.rgb * _Intensity * glow;

                // Wyznaczenie przezroczystosci na podstawie intensywnosci efektu
                // oraz kanalu alfa przypisanego do koloru iskry.
                half alpha = saturate(glow * _SparkColor.a);

                // Zwrocenie koloru RGB i przezroczystosci piksela.
                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
}