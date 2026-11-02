Shader "MagicznyLas/Distance Fog"
{
    Properties
    {
        [HDR] _FogColor ("Fog Color", Color) = (0.48, 0.66, 0.64, 1)
        _FogStart ("Fog Start Distance", Float) = 0
        _FogEnd ("Fog End Distance", Float) = 55
        _FogDensity ("Fog Density", Range(0.1, 8)) = 4.0
        _NearFogStrength ("Near Fog Strength", Range(0, 0.25)) = 0.06
        _SkyFogStrength ("Sky Fog Strength", Range(0, 0.5)) = 0.12
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Name "DistanceFog"
            ZWrite Off
            ZTest Always
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _FogColor;
                float _FogStart;
                float _FogEnd;
                float _FogDensity;
                float _NearFogStrength;
                float _SkyFogStrength;
            CBUFFER_END

            half4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;

                half4 sceneColor = SAMPLE_TEXTURE2D_X(
                    _BlitTexture,
                    sampler_LinearClamp,
                    uv
                );

                float rawDepth = SampleSceneDepth(uv);

                #if UNITY_REVERSED_Z
                    if (rawDepth <= 0.00001)
                        return half4(
                            lerp(sceneColor.rgb, _FogColor.rgb, _SkyFogStrength),
                            sceneColor.a
                        );
                #else
                    if (rawDepth >= 0.99999)
                        return half4(
                            lerp(sceneColor.rgb, _FogColor.rgb, _SkyFogStrength),
                            sceneColor.a
                        );
                #endif

                float3 worldPosition = ComputeWorldSpacePosition(
                    uv,
                    rawDepth,
                    UNITY_MATRIX_I_VP
                );

                float distanceToCamera = distance(
                    _WorldSpaceCameraPos,
                    worldPosition
                );

                float distanceFactor = saturate(
                    (distanceToCamera - _FogStart) /
                    max(_FogEnd - _FogStart, 0.001)
                );

                float denominator = max(1.0 - exp(-_FogDensity), 0.001);

                float distanceFog =
                    (1.0 - exp(-_FogDensity * distanceFactor)) /
                    denominator;

                float fogFactor = lerp(
                    _NearFogStrength,
                    1.0,
                    saturate(distanceFog)
                );

                half3 finalColor = lerp(
                    sceneColor.rgb,
                    _FogColor.rgb,
                    saturate(fogFactor)
                );

                return half4(finalColor, sceneColor.a);
            }

            ENDHLSL
        }
    }

    FallBack Off
}