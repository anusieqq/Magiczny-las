Shader "MagicznyLas/Volumetric God Rays"
{
    Properties
    {
        [HDR] _RayColor ("Ray Color", Color) = (0.75, 0.85, 1.0, 1)

        _RayIntensity ("Ray Intensity", Range(0, 3)) = 1.0
        _RayDensity ("Ray Density", Range(0.1, 2)) = 1.0
        _RayWeight ("Ray Weight", Range(0.8, 0.999)) = 0.985

        _RaySamples ("Ray Samples", Range(8, 32)) = 24
        _RayThreshold ("Ray Threshold", Range(0, 0.95)) = 0.2
        _RayExposure ("Ray Exposure", Range(0, 3)) = 0.8

        _LightScreenPos ("Light Screen Position", Vector) = (0.5, 0.8, 0, 1)
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "VolumetricGodRays"

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
                half4 _RayColor;
                float _RayIntensity;
                float _RayDensity;
                float _RayWeight;
                float _RaySamples;
                float _RayThreshold;
                float _RayExposure;
                float4 _LightScreenPos;
            CBUFFER_END

            half4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;

                half4 sceneColor = SAMPLE_TEXTURE2D_X(
                    _BlitTexture,
                    sampler_LinearClamp,
                    uv
                );

              

                float2 lightUV = _LightScreenPos.xy;
                float2 rayVector = (lightUV - uv) * _RayDensity;

                int samples = clamp((int)_RaySamples, 8, 32);

                float illumination = 0.0;
                float weightSum = 0.0;
                float decay = 1.0;

                [loop]
                for (int i = 0; i < 32; i++)
                {
                    if (i >= samples)
                        break;

                    float t = (i + 0.5) / samples;
                    float2 sampleUV = uv + rayVector * t;

                    if (sampleUV.x < 0.0 || sampleUV.x > 1.0 ||
                        sampleUV.y < 0.0 || sampleUV.y > 1.0)
                        break;

                    float depth = SampleSceneDepth(sampleUV);

                    float skyMask;

                    #if UNITY_REVERSED_Z
                        skyMask = 1.0 - step(0.00001, depth);
                    #else
                        skyMask = step(0.99999, depth);
                    #endif

                    illumination += skyMask * decay;
                    weightSum += decay;

                    decay *= _RayWeight;
                }

                float visibility = illumination / max(weightSum, 0.0001);

                float rays = saturate(
                    (visibility - _RayThreshold) /
                    max(1.0 - _RayThreshold, 0.001)
                );

                rays = smoothstep(0.0, 1.0, rays);

                float rayStrength =
                    rays * _RayIntensity * _RayExposure;

                half3 finalColor =
                    sceneColor.rgb + _RayColor.rgb * rayStrength;

                return half4(finalColor, sceneColor.a);
            }

            ENDHLSL
        }
    }

    FallBack Off
}