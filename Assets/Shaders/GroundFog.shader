
Shader "MagicznyLas/Magic Smoke Volume"
{
    Properties
    {
        [HDR] _SmokeColor ("Smoke Color", Color) = (0.35, 0.45, 0.55, 1)
        [HDR] _GlowColor ("Glow Color", Color) = (0.25, 0.55, 0.8, 1)

        _Density ("Density", Range(0, 5)) = 1.5
        _SmokeScale ("Smoke Scale", Range(1, 20)) = 5
        _DetailScale ("Detail Scale", Range(1, 40)) = 15
        _WarpStrength ("Warp Strength", Range(0, 1)) = 0.12
        _Softness ("Softness", Range(0.01, 1)) = 0.25

        _RiseSpeed ("Rise Speed", Range(0, 2)) = 0.05
        _SwirlSpeed ("Swirl Speed", Range(0, 3)) = 0.15
        _GlowStrength ("Glow Strength", Range(0, 5)) = 1

        _PlayerPosition ("Player Position", Vector) = (0, 0, 0, 1)
        _ExclusionRadius ("Exclusion Radius", Range(0, 10)) = 2.5
        _ExclusionFeather ("Exclusion Feather", Range(0.01, 5)) = 1.5
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
            Name "MagicSmokeVolume"

            Cull Front
            ZWrite Off
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)

                float4 _SmokeColor;
                float4 _GlowColor;

                float _Density;
                float _SmokeScale;
                float _DetailScale;
                float _WarpStrength;
                float _Softness;

                float _RiseSpeed;
                float _SwirlSpeed;
                float _GlowStrength;

                float4 _PlayerPosition;
                float _ExclusionRadius;
                float _ExclusionFeather;

            CBUFFER_END

            #define STEPS 64

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionOS : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                output.positionCS =
                    TransformObjectToHClip(input.positionOS.xyz);

                output.positionOS = input.positionOS.xyz;

                return output;
            }

            // Hash 3D
            float Hash(float3 p)
            {
                p = frac(p * 0.3183099 + 0.1);
                p *= 17.0;

                return frac(
                    p.x * p.y * p.z *
                    (p.x + p.y + p.z)
                );
            }

            // 3D Noise
            float Noise3D(float3 p)
            {
                float3 i = floor(p);
                float3 f = frac(p);

                f = f * f * (3.0 - 2.0 * f);

                float n000 = Hash(i + float3(0, 0, 0));
                float n100 = Hash(i + float3(1, 0, 0));
                float n010 = Hash(i + float3(0, 1, 0));
                float n110 = Hash(i + float3(1, 1, 0));

                float n001 = Hash(i + float3(0, 0, 1));
                float n101 = Hash(i + float3(1, 0, 1));
                float n011 = Hash(i + float3(0, 1, 1));
                float n111 = Hash(i + float3(1, 1, 1));

                float x00 = lerp(n000, n100, f.x);
                float x10 = lerp(n010, n110, f.x);

                float x01 = lerp(n001, n101, f.x);
                float x11 = lerp(n011, n111, f.x);

                float y0 = lerp(x00, x10, f.y);
                float y1 = lerp(x01, x11, f.y);

                return lerp(y0, y1, f.z);
            }

            // Fractal Brownian Motion
            float FBM(float3 p)
            {
                float value = 0.0;
                float amplitude = 0.5;
                float frequency = 1.0;

                for (int i = 0; i < 4; i++)
                {
                    value += Noise3D(p * frequency) * amplitude;

                    frequency *= 2.0;
                    amplitude *= 0.5;
                }

                return value;
            }

            // Ray-box intersection
            bool RayBox(
                float3 origin,
                float3 direction,
                out float tNear,
                out float tFar
            )
            {
                float3 invDir = 1.0 / direction;

                float3 t0 = (-0.5 - origin) * invDir;
                float3 t1 = ( 0.5 - origin) * invDir;

                float3 tMin = min(t0, t1);
                float3 tMax = max(t0, t1);

                tNear = max(
                    max(tMin.x, tMin.y),
                    tMin.z
                );

                tFar = min(
                    min(tMax.x, tMax.y),
                    tMax.z
                );

                tNear = max(tNear, 0.0);

                return tFar > tNear;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                // Camera position
                float3 cameraWS = GetCameraPositionWS();
                float3 cameraOS = TransformWorldToObject(cameraWS);

                // Ray direction
                float3 rayDir = normalize(
                    input.positionOS - cameraOS
                );

                float tNear;
                float tFar;

                if (!RayBox(cameraOS, rayDir, tNear, tFar))
                    discard;

                float stepSize = (tFar - tNear) / STEPS;

                float accumulatedAlpha = 0.0;
                float3 accumulatedColor = 0.0;

                float time = _Time.y;

                // Ray Marching
                for (int i = 0; i < STEPS; i++)
                {
                    float t = tNear + (i + 0.5) * stepSize;

                    // Original position
                    float3 originalP = cameraOS + rayDir * t;

                    // Animated position
                    float3 p = originalP;

                    // Slower vertical movement.
                    // This prevents fine noise from moving too quickly.
                    float animationOffset =
                        time * _RiseSpeed /
                        max(_DetailScale, 1.0);

                    p.y -= animationOffset;

                    // Gentle swirling
                    float swirlTime = time * _SwirlSpeed * 0.25;

                    float originalX = p.x;

                    p.x += sin(
                        swirlTime + p.y * 3.0
                    ) * _WarpStrength;

                    p.z += cos(
                        swirlTime + originalX * 3.0
                    ) * _WarpStrength;

                    // Domain warping
                    float3 warp;

                    warp.x = FBM(p * _SmokeScale + 10.0);
                    warp.y = FBM(p * _SmokeScale + 20.0);
                    warp.z = FBM(p * _SmokeScale + 30.0);

                    float3 warpedP =
                        p + (warp - 0.5) * _WarpStrength;

                    // Main smoke shape
                    float broadShape =
                        FBM(warpedP * _SmokeScale);

                    // Fine details
                    float detail =
                        FBM(warpedP * _DetailScale);

                    float noiseValue =
                        broadShape * 0.75 +
                        detail * 0.25;

                    // Density
                    float density = smoothstep(
                        0.35,
                        0.35 + _Softness,
                        noiseValue
                    );

                    density *= smoothstep(
                        0.0,
                        0.2,
                        originalP.y + 0.5
                    );

                    // Original sample position in world space.
                    // It is deliberately not animated.
                    float3 sampleWorldPos =
                        TransformObjectToWorld(originalP);

                    // Circular exclusion in XZ plane
                    float playerDistance = distance(
                        sampleWorldPos.xz,
                        _PlayerPosition.xz
                    );

                    float playerMask = smoothstep(
                        _ExclusionRadius,
                        _ExclusionRadius + _ExclusionFeather,
                        playerDistance
                    );

                    density *= playerMask;

                    // Beer-Lambert inspired opacity
                    float alpha = 1.0 - exp(
                        -density * _Density * stepSize * 3.0
                    );

                    alpha = saturate(alpha);

                    // Color and glow
                    float glow = saturate(
                        noiseValue * _GlowStrength
                    );

                    float3 sampleColor = lerp(
                        _SmokeColor.rgb,
                        _GlowColor.rgb,
                        glow
                    );

                    // Front-to-back compositing
                    float remaining = 1.0 - accumulatedAlpha;

                    accumulatedColor +=
                        sampleColor * alpha * remaining;

                    accumulatedAlpha +=
                        alpha * remaining;

                    // Early termination
                    if (accumulatedAlpha > 0.98)
                        break;
                }

                if (accumulatedAlpha < 0.001)
                    discard;

                float3 finalColor =
                    accumulatedColor /
                    max(accumulatedAlpha, 0.001);

                return half4(
                    finalColor,
                    accumulatedAlpha
                );
            }

            ENDHLSL
        }
    }
}
