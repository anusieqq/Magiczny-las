
Shader "Custom/MagicalGrass"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.025, 0.12, 0.045, 1)
        _MiddleColor ("Middle Color", Color) = (0.08, 0.55, 0.18, 1)
        _TipColor ("Magical Tip Color", Color) = (0.0, 0.9, 0.85, 1)

        _EmissionStrength ("Emission Strength", Range(0, 10)) = 3
        _WindStrength ("Wind Strength", Range(0, 1)) = 0.15
        _WindSpeed ("Wind Speed", Range(0, 5)) = 1.5
        _WindScale ("Wind Scale", Range(0, 5)) = 1

        _BladeCurve ("Blade Curve", Range(0, 1)) = 0.25
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "TransparentCutout"
            "Queue" = "AlphaTest"
        }

        Cull Off
        ZWrite On

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);

                float height = input.uv.y;

                float wind = sin(
                    _Time.y * _WindSpeed +
                    positionWS.x * _WindScale +
                    positionWS.z * _WindScale
                );

                float bend = height * height;

                positionWS.x += wind * _WindStrength * bend;
                positionWS.z += cos(_Time.y * _WindSpeed * 0.7 +
                    positionWS.x * _WindScale) * _WindStrength * bend * 0.5;

                positionWS.x += _BladeCurve * bend * 0.15;

                output.positionHCS = TransformWorldToHClip(positionWS);
                output.uv = input.uv;
                output.color = input.color;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float height = saturate(input.uv.y);

                float3 baseToMiddle = lerp(
                    _BaseColor.rgb,
                    _MiddleColor.rgb,
                    smoothstep(0.0, 0.65, height)
                );

                float3 grassColor = lerp(
                    baseToMiddle,
                    _TipColor.rgb,
                    smoothstep(0.65, 1.0, height)
                );

                grassColor *= lerp(0.85, 1.15, input.color.r);

                float tipMask = smoothstep(0.72, 1.0, height);
                float3 emission = _TipColor.rgb * tipMask * _EmissionStrength;

                return half4(grassColor + emission, 1);
            }

            ENDHLSL
        }
    }
}
