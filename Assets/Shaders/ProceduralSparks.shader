
Shader "MagicznyLas/Procedural Spark"
{
    Properties
    {
        [HDR] _SparkColor ("Spark Color", Color) = (0.1, 0.8, 1.0, 1.0)
        _Intensity ("Glow Intensity", Range(0, 10)) = 3
        _Softness ("Edge Softness", Range(0.05, 2)) = 0.7
        _CoreSize ("Bright Core Size", Range(0.05, 0.8)) = 0.25
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Name "SparkUnlit"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha One
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _SparkColor;
                float _Intensity;
                float _Softness;
                float _CoreSize;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionHCS =
                    TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float2 p = input.uv * 2.0 - 1.0;
                float r = length(p);

                float halo = exp(-r * r * (3.0 / max(_Softness, 0.05)));
                float core = 1.0 - smoothstep(
                    _CoreSize * 0.5,
                    _CoreSize,
                    r
                );

                float glow = saturate(halo * 0.65 + core);
                half3 color = _SparkColor.rgb * _Intensity * glow;
                half alpha = saturate(glow * _SparkColor.a);

                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
}
