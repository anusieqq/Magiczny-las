// Shader odpowiedzialny za przezroczysty wyglad krysztalow
// z efektem Fresnela podswietlajacym ich krawedzie.
Shader "MagicznyLas/Crystal Fresnel"
{
    Properties
    {
        // Podstawowy kolor krysztalu z obsluga wartosci HDR.
        [HDR] _CrystalColor ("Crystal Color", Color) = (0.15, 0.8, 1, 1)

        // Kontrola przezroczystosci podstawowej powierzchni krysztalu.
        _Transparency ("Transparency", Range(0.05, 1)) = 0.4

        // Kolor poswiaty widocznej na krawedziach obiektu.
        [HDR] _FresnelColor ("Fresnel Edge Color", Color) = (0.2, 0.9, 1, 1)

        // Wykladnik okreslajacy intensywnosc i szerokosc efektu Fresnela.
        _FresnelPower ("Fresnel Power", Range(0.5, 8)) = 3

        // Mnoznik kontrolujacy sile podswietlenia krawedzi.
        _FresnelStrength ("Fresnel Strength", Range(0, 5)) = 2

        // Dodatkowy mnoznik intensywnosci emisji swiatla.
        _GlowStrength ("Glow Strength", Range(0, 10)) = 1.5
    }

    SubShader
    {
        Tags
        {
            // Shader jest przeznaczony do renderowania w Universal Render Pipeline.
            "RenderPipeline" = "UniversalPipeline"

            // Oznaczenie materialu jako przezroczystego.
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "Crystal"
            Tags { "LightMode" = "UniversalForward" }

            // Standardowe mieszanie koloru z przezroczystoscia z tlem.
            Blend SrcAlpha OneMinusSrcAlpha

            // Wylaczenie zapisu do bufora glebokosci dla przezroczystej powierzchni.
            ZWrite Off

            // Renderowanie tylko przednich scian modelu.
            Cull Back

            HLSLPROGRAM

            // Wskazanie funkcji odpowiedzialnych za przetwarzanie wierzcholkow i pikseli.
            #pragma vertex Vert
            #pragma fragment Frag

            // Biblioteka URP udostepniajaca funkcje transformacji i obliczen przestrzennych.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Parametry materialu przekazywane do shadera z poziomu Unity.
            // Umieszczenie ich w CBUFFER jest zgodne z wymaganiami SRP Batcher.
            CBUFFER_START(UnityPerMaterial)
                half4 _CrystalColor;
                half _Transparency;
                half4 _FresnelColor;
                half _FresnelPower;
                half _FresnelStrength;
                half _GlowStrength;
            CBUFFER_END

            // Dane wejsciowe pobierane dla kazdego wierzcholka modelu.
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            // Dane przekazywane z vertex shadera do fragment shadera.
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
            };

            // Vertex shader przelicza polozenie i wektor normalny
            // z przestrzeni lokalnej modelu na wspolrzedne swiata i ekranu.
            Varyings Vert(Attributes input)
            {
                Varyings output;

                // Wyznaczenie pozycji wierzcholka w przestrzeni swiata i przestrzeni kamery.
                VertexPositionInputs positionInputs =
                    GetVertexPositionInputs(input.positionOS.xyz);

                // Przekazanie pozycji wierzcholka w przestrzeni clip space
                // wymaganej przez etap rasteryzacji.
                output.positionHCS = positionInputs.positionCS;

                // Przeksztalcenie normalnej do przestrzeni swiata.
                // Wektor ten jest potrzebny do obliczenia efektu Fresnela.
                output.normalWS =
                    TransformObjectToWorldNormal(input.normalOS);

                // Obliczenie kierunku od powierzchni obiektu do kamery.
                output.viewDirWS =
                    GetWorldSpaceViewDir(positionInputs.positionWS);

                return output;
            }

            // Fragment shader oblicza koncowy kolor i przezroczystosc kazdego piksela.
            half4 Frag(Varyings input) : SV_Target
            {
                // Normalizacja wektorow zapewnia ich jednostkowa dlugosc,
                // co jest istotne przy obliczaniu iloczynu skalarnego.
                half3 normal = normalize(input.normalWS);
                half3 viewDir = normalize(input.viewDirWS);

                // Efekt Fresnela zalezy od kata pomiedzy normalna powierzchni
                // a kierunkiem patrzenia kamery.
                // Im bardziej powierzchnia jest zwrocona bokiem do kamery,
                // tym wieksza wartosc otrzymuje efekt.
                half fresnel = 1.0h - saturate(dot(normal, viewDir));

                // Potegowanie kontroluje rozklad efektu na powierzchni.
                fresnel = pow(fresnel, _FresnelPower);

                // Pobranie podstawowego koloru krysztalu.
                half3 baseColor = _CrystalColor.rgb;

                // Obliczenie dodatkowej emisji swiatla na krawedziach.
                // Jej intensywnosc zalezy od efektu Fresnela oraz parametrow materialu.
                half3 fresnelEmission =
                    _FresnelColor.rgb
                    * fresnel
                    * _FresnelStrength
                    * _GlowStrength;

                // Polaczenie podstawowego koloru z podswietleniem krawedzi.
                half3 finalColor = baseColor + fresnelEmission;

                // Zwiekszenie przezroczystosci na krawedziach poprawia czytelnosc ksztaltu.
                half alpha = saturate(
                    _Transparency + fresnel * 0.35h
                );

                // Zwrocenie koncowego koloru RGB oraz wartosci alfa.
                return half4(finalColor, alpha);
            }

            ENDHLSL
        }
    }

    // Brak dodatkowego shadera zastepczego dla platform nieobslugujacych tego shadera.
    FallBack Off
}