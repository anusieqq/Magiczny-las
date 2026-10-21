
Shader "MagicznyLas/Texture With Bloom"
{
    Properties
    {
        [MainTexture] _BaseMap ("Texture", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color", Color) = (1,1,1,1)

        [HDR] _GlowColor ("Glow Color", Color) = (1, 0.45, 0.08, 1)
        _GlowStrength ("Glow Strength", Range(0, 20)) = 3
        _BloomBoost ("Bloom Boost", Range(0, 10)) = 2

        _PulseSpeed ("Pulse Speed", Range(0, 8)) = 1
        _PulseAmount ("Pulse Amount", Range(0, 1)) = 0.2

        _ModelBottom ("Model Bottom Y", Float) = 0
        _ModelTop ("Model Top Y", Float) = 2
        _MaskHeight ("Glow Mask Height", Range(0, 1)) = 0.75
        _MaskFeather ("Mask Softness", Range(0.001, 0.5)) = 0.08

        _AlphaClip ("Alpha Clip", Range(0, 1)) = 0.3
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "TransparentCutout"
            "Queue" = "AlphaTest"
        }

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            Cull Off
            ZWrite On
            Blend Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

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

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float localHeight : TEXCOORD1;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                output.positionHCS =
                    TransformObjectToHClip(input.positionOS.xyz);

                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

                // Wysoko?? wierzcho?ka wzgl?dem zakresu modelu.
                float heightRange = max(_ModelTop - _ModelBottom, 0.0001);
                output.localHeight =
                    (input.positionOS.y - _ModelBottom) / heightRange;

                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half4 baseSample =
                    SAMPLE_TEXTURE2D(
                        _BaseMap,
                        sampler_BaseMap,
                        input.uv
                    ) * _BaseColor;

                clip(baseSample.a - _AlphaClip);

                // Maska w zakresie 0–1, niezale?na od skali obiektu.
                half mask = smoothstep(
                    _MaskHeight - _MaskFeather,
                    _MaskHeight + _MaskFeather,
                    input.localHeight
                );

                half pulse = 1.0h
                    - _PulseAmount * 0.5h
                    + _PulseAmount * 0.5h
                    * sin(_Time.y * _PulseSpeed);

                half3 emission = _GlowColor.rgb
                    * _GlowStrength
                    * _BloomBoost
                    * pulse
                    * mask;

                half3 finalColor = baseSample.rgb + emission;

                return half4(finalColor, baseSample.a);
            }

            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
