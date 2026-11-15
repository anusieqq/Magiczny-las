// Shader nadajacy obiektom teksture, kolor oraz animowany efekt emisji swiatla.
// Wykorzystuje maske wysokosci do ograniczenia swiecenia do wybranej czesci modelu.
// Zmienna intensywnosc emisji pozwala uzyskac pulsujacy efekt wspolpracujacy z Bloom.
Shader "MagicznyLas/Texture With Bloom"
{
    Properties
    {
        // Tekstura podstawowa obiektu.
        [MainTexture] _BaseMap ("Texture", 2D) = "white" {}

        // Kolor nakladany na teksture podstawowa.
        [MainColor] _BaseColor ("Base Color", Color) = (1,1,1,1)

        // Kolor emisji swiatla z obsluga wartosci HDR.
        [HDR] _GlowColor ("Glow Color", Color) = (1, 0.45, 0.08, 1)

        // Intensywnosc emitowanego swiatla.
        _GlowStrength ("Glow Strength", Range(0, 20)) = 3

        // Dodatkowy mnoznik wzmacniajacy jasnosc emisji.
        _BloomBoost ("Bloom Boost", Range(0, 10)) = 2

        // Predkosc animacji pulsowania swiatla.
        _PulseSpeed ("Pulse Speed", Range(0, 8)) = 1

        // Amplituda zmian intensywnosci podczas pulsowania.
        _PulseAmount ("Pulse Amount", Range(0, 1)) = 0.2

        // Dolna granica modelu w lokalnej przestrzeni Y.
        _ModelBottom ("Model Bottom Y", Float) = 0

        // Gorna granica modelu w lokalnej przestrzeni Y.
        _ModelTop ("Model Top Y", Float) = 2

        // Wysokosc, od ktorej zaczyna sie maska emisji.
        _MaskHeight ("Glow Mask Height", Range(0, 1)) = 0.75

        // Szerokosc gladkiego przejscia maski emisji.
        _MaskFeather ("Mask Softness", Range(0.001, 0.5)) = 0.08

        // Prog przezroczystosci wykorzystywany do odrzucania fragmentow tekstury.
        _AlphaClip ("Alpha Clip", Range(0, 1)) = 0.3
    }

    SubShader
    {
        Tags
        {
            // Shader przeznaczony do Universal Render Pipeline.
            "RenderPipeline" = "UniversalPipeline"

            // Typ renderowania z odrzucaniem fragmentow na podstawie alfy.
            "RenderType" = "TransparentCutout"

            // Kolejka renderowania przeznaczona dla materialow typu AlphaTest.
            "Queue" = "AlphaTest"
        }

        Pass
        {
            Name "ForwardUnlit"

            // Przekazanie informacji o przebiegu do systemu renderowania URP.
            Tags { "LightMode" = "UniversalForward" }

            // Renderowanie obu stron powierzchni.
            Cull Off

            // Zapis do bufora glebokosci.
            ZWrite On

            // Wylaczenie standardowego mieszania przezroczystosci.
            Blend Off

            HLSLPROGRAM

            // Funkcje przetwarzajace wierzcholki i piksele.
            #pragma vertex Vert
            #pragma fragment Frag

            // Obsluga GPU Instancing, czyli renderowania wielu instancji tego samego obiektu.
            #pragma multi_compile_instancing

            // Podstawowe funkcje i transformacje przestrzenne URP.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Deklaracja tekstury podstawowej i jej samplera.
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            // Parametry materialu przekazywane z poziomu Unity.
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half4 _GlowColor;
                half _GlowStrength;
                half _BloomBoost;
                half _PulseSpeed;
                half _PulseAmount;
                float _ModelBottom;
                float _ModelTop;
                half _MaskHeight;
                half _MaskFeather;
                half _AlphaClip;
            CBUFFER_END

            // Dane wejsciowe pojedynczego wierzcholka siatki.
            struct Attributes
            {
                // Pozycja wierzcholka w przestrzeni lokalnej obiektu.
                float4 positionOS : POSITION;

                // Wspolrzedne UV wykorzystywane do probkowania tekstury.
                float2 uv : TEXCOORD0;

                // Dane identyfikujace instancje podczas GPU Instancing.
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // Dane przekazywane z vertex shadera do fragment shadera.
            struct Varyings
            {
                // Pozycja wierzcholka w przestrzeni jednorodnej.
                float4 positionHCS : SV_POSITION;

                // Wspolrzedne UV po uwzglednieniu ustawien tekstury.
                float2 uv : TEXCOORD0;

                // Znormalizowana wysokosc wierzcholka w lokalnej przestrzeni modelu.
                float localHeight : TEXCOORD1;

                // Dane identyfikujace instancje podczas GPU Instancing.
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // Vertex shader przygotowujacy dane geometryczne do renderowania.
            Varyings Vert(Attributes input)
            {
                // Wyzerowanie struktury wyjsciowej.
                Varyings output = (Varyings)0;

                // Pobranie identyfikatora aktualnej instancji.
                UNITY_SETUP_INSTANCE_ID(input);

                // Przekazanie identyfikatora instancji do kolejnego etapu renderowania.
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                // Przeksztalcenie pozycji wierzcholka z przestrzeni lokalnej
                // do przestrzeni przycinania.
                output.positionHCS =
                    TransformObjectToHClip(input.positionOS.xyz);

                // Przeksztalcenie wspolrzednych UV zgodnie z ustawieniami tekstury.
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

                // Obliczenie zakresu wysokosci modelu.
                // Zabezpieczenie zapobiega dzieleniu przez zero.
                float heightRange = max(_ModelTop - _ModelBottom, 0.0001);

                // Normalizacja wysokosci wierzcholka do zakresu wzglednego.
                // Wartosc 0 odpowiada dolnej granicy, a 1 gornej granicy modelu.
                output.localHeight =
                    (input.positionOS.y - _ModelBottom) / heightRange;

                return output;
            }

            // Fragment shader obliczajacy koncowy wyglad kazdego piksela obiektu.
            half4 Frag(Varyings input) : SV_Target
            {
                // Przygotowanie identyfikatora instancji dla fragmentu.
                UNITY_SETUP_INSTANCE_ID(input);

                // Pobranie koloru z tekstury i przemnozenie go przez kolor materialu.
                half4 baseSample =
                    SAMPLE_TEXTURE2D(
                        _BaseMap,
                        sampler_BaseMap,
                        input.uv
                    ) * _BaseColor;

                // Odrzucenie fragmentow, ktorych przezroczystosc jest nizsza od ustawionego progu.
                // Pozwala zachowac wyciete obszary tekstury bez standardowego blendingu alfa.
                clip(baseSample.a - _AlphaClip);

                // MASKA WYSOKOSCI
                // Wyznaczenie obszaru modelu, w ktorym ma pojawic sie emisja swiatla.
                // smoothstep zapewnia gladkie przejscie pomiedzy obszarem bez emisji
                // a obszarem obj?tym efektem swiecenia.
                half mask = smoothstep(
                    _MaskHeight - _MaskFeather,
                    _MaskHeight + _MaskFeather,
                    input.localHeight
                );

                // ANIMACJA PULSOWANIA
                // Funkcja sinusoidalna zmienia intensywnosc emisji w czasie.
                // Wartosc bazowa pozostaje dodatnia, a Pulse Amount okresla
                // zakres zmian jasnosci.
                half pulse = 1.0h
                    - _PulseAmount * 0.5h
                    + _PulseAmount * 0.5h
                    * sin(_Time.y * _PulseSpeed);

                // OBLICZENIE EMISJI
                // Polaczenie koloru, intensywnosci, dodatkowego wzmocnienia,
                // animacji pulsowania oraz maski wysokosci.
                half3 emission = _GlowColor.rgb
                    * _GlowStrength
                    * _BloomBoost
                    * pulse
                    * mask;

                // Dodanie emisji swiatla do koloru podstawowego tekstury.
                half3 finalColor = baseSample.rgb + emission;

                // Zwrocenie koncowego koloru z zachowaniem alfy tekstury.
                return half4(finalColor, baseSample.a);
            }

            ENDHLSL
        }
    }

    // Shader zastepczy wykorzystywany, gdy ten shader nie jest obslugiwany.
    FallBack "Universal Render Pipeline/Unlit"
}