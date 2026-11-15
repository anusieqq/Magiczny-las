// Shader proceduralnej trawy z animacja wiatru i gradientem kolorow.
// Wykorzystuje wysokosc wierzcholkow do sterowania wygieciem,
// kolorystyka oraz emisja swiatla na koncowkach zdzbel.
Shader "Custom/MagicalGrass"
{
    Properties
    {
        // Kolor podstawowy trawy przy jej nasadzie.
        _BaseColor ("Base Color", Color) = (0.025, 0.12, 0.045, 1)

        // Kolor posredni wykorzystywany w centralnej czesci zdzbla.
        _MiddleColor ("Middle Color", Color) = (0.08, 0.55, 0.18, 1)

        // Kolor koncowek zdzbel, nadajacy trawie magiczny wyglad.
        _TipColor ("Magical Tip Color", Color) = (0.0, 0.9, 0.85, 1)

        // Intensywnosc emisji swiatla na koncowkach trawy.
        _EmissionStrength ("Emission Strength", Range(0, 10)) = 3

        // Maksymalna sila wygiecia zdzbel pod wplywem wiatru.
        _WindStrength ("Wind Strength", Range(0, 1)) = 0.15

        // Predkosc animacji ruchu wiatru.
        _WindSpeed ("Wind Speed", Range(0, 5)) = 1.5

        // Skala przestrzenna animacji wiatru.
        _WindScale ("Wind Scale", Range(0, 5)) = 1

        // Dodatkowe stale wygiecie zdzbla niezalezne od animacji wiatru.
        _BladeCurve ("Blade Curve", Range(0, 1)) = 0.25
    }

    SubShader
    {
        Tags
        {
            // Shader przeznaczony do Universal Render Pipeline.
            "RenderPipeline" = "UniversalPipeline"

            // Material wykorzystuje przezroczystosc typu cutout.
            "RenderType" = "TransparentCutout"

            // Kolejka renderowania przeznaczona dla obiektow z testem alfa.
            "Queue" = "AlphaTest"
        }

        // Renderowanie obu stron geometrii, co jest istotne dla cienkich zdzbel.
        Cull Off

        // Zapis do bufora glebokosci wlaczony.
        ZWrite On

        Pass
        {
            HLSLPROGRAM

            // Funkcje odpowiedzialne za przetwarzanie wierzcholkow i pikseli.
            #pragma vertex vert
            #pragma fragment frag

            // Podstawowe funkcje i transformacje przestrzenne URP.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Parametry materialu przekazywane z poziomu Unity.
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _MiddleColor;
                float4 _TipColor;
                float _EmissionStrength;
                float _WindStrength;
                float _WindSpeed;
                float _WindScale;
                float _BladeCurve;
            CBUFFER_END

            // Dane wejsciowe pojedynczego wierzcholka siatki.
            struct Attributes
            {
                // Pozycja wierzcholka w przestrzeni lokalnej obiektu.
                float4 positionOS : POSITION;

                // Wspolrzedne UV wykorzystywane m.in. do okreslenia wysokosci zdzbla.
                float2 uv : TEXCOORD0;

                // Kolor wierzcholka wykorzystywany do indywidualnego roznicowania trawy.
                float4 color : COLOR;
            };

            // Dane przekazywane z vertex shadera do fragment shadera.
            struct Varyings
            {
                // Pozycja wierzcholka w przestrzeni jednorodnej.
                float4 positionHCS : SV_POSITION;

                // Wspolrzedne UV wykorzystywane do obliczenia gradientu koloru.
                float2 uv : TEXCOORD0;

                // Kolor wierzcholka przekazywany do fragment shadera.
                float4 color : COLOR;
            };

            // Vertex shader odpowiadajacy za deformacje geometrii trawy.
            Varyings vert(Attributes input)
            {
                Varyings output;

                // Przeksztalcenie pozycji wierzcholka z przestrzeni lokalnej do swiata.
                // Dzieki temu sasiednie fragmenty trawy moga korzystac ze spojnego pola wiatru.
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);

                // Wysokosc wierzcholka odczytana ze wspolrzednej UV.
                // Przyjmuje wartosci od 0 przy nasadzie do 1 na koncowce zdzbla.
                float height = input.uv.y;

                // Obliczenie animacji wiatru za pomoca funkcji sinus.
                // Pozycja w przestrzeni swiata wplywa na faze animacji,
                // dzieki czemu zdzbla w roznych miejscach poruszaja sie z roznymi fazami.
                float wind = sin(
                    _Time.y * _WindSpeed +
                    positionWS.x * _WindScale +
                    positionWS.z * _WindScale
                );

                // Kwadrat wysokosci sprawia, ze nasada pozostaje stabilna,
                // a wygiecie stopniowo zwieksza sie w kierunku koncowki.
                float bend = height * height;

                // Wygiecie w osi X pod wplywem animacji wiatru.
                positionWS.x += wind * _WindStrength * bend;

                // Dodatkowe wygiecie w osi Z, oparte na funkcji cosinus.
                // Wprowadza ruch w drugim kierunku przestrzennym.
                positionWS.z += cos(_Time.y * _WindSpeed * 0.7 +
                    positionWS.x * _WindScale) * _WindStrength * bend * 0.5;

                // Dodanie stalej krzywizny zdzbla niezaleznej od wiatru.
                // Efekt narasta wraz z wysokoscia wierzcholka.
                positionWS.x += _BladeCurve * bend * 0.15;

                // Przeksztalcenie zmodyfikowanej pozycji ze swiata do przestrzeni przycinania.
                output.positionHCS = TransformWorldToHClip(positionWS);

                // Przekazanie wspolrzednych UV i koloru wierzcholka do fragment shadera.
                output.uv = input.uv;
                output.color = input.color;

                return output;
            }

            // Fragment shader obliczajacy kolor kazdego piksela trawy.
            half4 frag(Varyings input) : SV_Target
            {
                // Ograniczenie wysokosci do zakresu 0-1.
                float height = saturate(input.uv.y);

                // GRADIENT KOLORU
                // Przejscie od ciemnej zieleni przy nasadzie do jasniejszej zieleni.
                // smoothstep zapewnia gladkie przejscie pomiedzy kolorami.
                float3 baseToMiddle = lerp(
                    _BaseColor.rgb,
                    _MiddleColor.rgb,
                    smoothstep(0.0, 0.65, height)
                );

                // Dodanie turkusowego koloru na koncowkach zdzbel.
                float3 grassColor = lerp(
                    baseToMiddle,
                    _TipColor.rgb,
                    smoothstep(0.65, 1.0, height)
                );

                // Indywidualne zroznicowanie jasnosci na podstawie kanalu czerwonego
                // koloru wierzcholka.
                grassColor *= lerp(0.85, 1.15, input.color.r);

                // Maska obejmujaca gorna czesc zdzbla.
                // Kontroluje obszar, w ktorym pojawia sie emisja swiatla.
                float tipMask = smoothstep(0.72, 1.0, height);

                // Obliczenie koloru emisyjnego.
                // Emisja jest najsilniejsza na samych koncowkach zdzbel.
                float3 emission = _TipColor.rgb * tipMask * _EmissionStrength;

                // Polaczenie koloru podstawowego z emisja swiatla.
                // Alfa ustawiona na 1 oznacza pelna nieprzezroczystosc.
                return half4(grassColor + emission, 1);
            }

            ENDHLSL
        }
    }
}