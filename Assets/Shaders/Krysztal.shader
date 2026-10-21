
Shader "MagicznyLas/Crystal Fresnel"
{
    Properties
    {
        [HDR] _CrystalColor ("Crystal Color", Color) = (0.15, 0.8, 1, 1)
        _Transparency ("Transparency", Range(0.05, 1)) = 0.4

        [HDR] _FresnelColor ("Fresnel Edge Color", Color) = (0.2, 0.9, 1, 1)
        _FresnelPower ("Fresnel Power", Range(0.5, 8)) = 3
        _FresnelStrength ("Fresnel Strength", Range(0, 5)) = 2

        _GlowStrength ("Glow Strength", Range(0, 10)) = 1.5
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "Crystal"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _CrystalColor;
                half _Transparency;
                half4 _FresnelColor;
                half _FresnelPower;
                half _FresnelStrength;
                half _GlowStrength;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs =
                    GetVertexPositionInputs(input.positionOS.xyz);

                output.positionHCS = positionInputs.positionCS;

                output.normalWS =
                    TransformObjectToWorldNormal(input.normalOS);

                output.viewDirWS =
                    GetWorldSpaceViewDir(positionInputs.positionWS);

                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half3 normal = normalize(input.normalWS);
                half3 viewDir = normalize(input.viewDirWS);

                // Fresnel: mocniejszy efekt na kraw?dziach.
                half fresnel = 1.0h - saturate(dot(normal, viewDir));
                fresnel = pow(fresnel, _FresnelPower);

                half3 baseColor = _CrystalColor.rgb;

                half3 fresnelEmission =
                    _FresnelColor.rgb
                    * fresnel
                    * _FresnelStrength
                    * _GlowStrength;

                half3 finalColor = baseColor + fresnelEmission;

                // Kraw?dzie staj? si? nieco mniej przezroczyste.
                half alpha = saturate(
                    _Transparency + fresnel * 0.35h
                );

                return half4(finalColor, alpha);
            }

            ENDHLSL
        }
    }

    FallBack Off
}
