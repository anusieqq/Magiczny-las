
Shader "MagicForest/NaturalVine"
{
    Properties
    {
        _BaseColor ("Podstawowy kolor", Color) = (0.10, 0.16, 0.045, 1)
        _LightColor ("Ja?niejsza ziele?", Color) = (0.19, 0.25, 0.075, 1)
        _DarkColor ("Ciemniejsze fragmenty", Color) = (0.055, 0.085, 0.025, 1)
        _VeinColor ("Kolor ?y?ek", Color) = (0.25, 0.30, 0.12, 1)
        _Variation ("Zró?nicowanie koloru", Range(0, 1)) = 0.3
        _VeinStrength ("Widoczno?? ?y?ek", Range(0, 1)) = 0.2
        _Smoothness ("G?adko?? powierzchni", Range(0, 1)) = 0.18
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Cull Off
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _LightColor;
                float4 _DarkColor;
                float4 _VeinColor;
                float _Variation;
                float _VeinStrength;
                float _Smoothness;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs pos =
                    GetVertexPositionInputs(IN.positionOS.xyz);

                OUT.positionHCS = pos.positionCS;
                OUT.positionWS = pos.positionWS;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv;

                // Subtelne, nieregularne plamy koloru.
                float pattern =
                    sin(uv.y * 31.0 + sin(uv.x * 17.0) * 1.7)
                    * sin(uv.y * 11.0 + uv.x * 9.0);

                pattern = pattern * 0.5 + 0.5;

                float3 color = lerp(
                    _DarkColor.rgb,
                    _LightColor.rgb,
                    pattern);

                color = lerp(
                    _BaseColor.rgb,
                    color,
                    _Variation);

                // Centralna ?y?ka wzd?u? ?odygi.
                float centerVein = 1.0 - smoothstep(
                    0.0, 0.10, abs(uv.x - 0.5));

                // Drobne, uko?ne ?y?ki po obu stronach.
                float veinPattern =
                    sin(uv.y * 65.0 + abs(uv.x - 0.5) * 30.0);

                float sideVeins =
                    smoothstep(0.78, 0.96, veinPattern)
                    * smoothstep(0.04, 0.13, abs(uv.x - 0.5))
                    * (1.0 - smoothstep(
                        0.25, 0.43, abs(uv.x - 0.5)));

                float veins = saturate(
                    centerVein * 0.25 + sideVeins);

                color = lerp(
                    color,
                    _VeinColor.rgb,
                    veins * _VeinStrength);

                float3 normalWS = normalize(IN.normalWS);
                Light mainLight = GetMainLight();

                float NdotL = saturate(
                    dot(normalWS, normalize(mainLight.direction)));

                float3 ambient = SampleSH(normalWS);
                float3 lighting =
                    ambient + mainLight.color * NdotL;

                // Delikatny, naturalny po?ysk.
                float3 viewDir = normalize(
                    GetWorldSpaceViewDir(IN.positionWS));

                float3 halfDir = normalize(
                    normalize(mainLight.direction) + viewDir);

                float specular = pow(
                    saturate(dot(normalWS, halfDir)), 48.0)
                    * _Smoothness * NdotL;

                float3 finalColor =
                    color * lighting + mainLight.color * specular;

                return half4(finalColor, 1.0);
            }

            ENDHLSL
        }
    }

    FallBack Off
}
