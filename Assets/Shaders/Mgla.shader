
Shader "MagicznyLas/Magic Smoke Volume"
{
    Properties
    {
        [HDR] _SmokeColor ("Smoke Color", Color) = (0.18, 0.65, 0.85, 1)
        [HDR] _GlowColor ("Glow Color", Color) = (0.25, 0.8, 1, 1)

        _Density ("Smoke Density", Range(0.1, 4)) = 1.5
        _SmokeScale ("Puff Size", Range(2, 12)) = 5
        _DetailScale ("Smoke Detail", Range(3, 20)) = 9
        _WarpStrength ("Swirl Strength", Range(0, 2)) = 0.65
        _Softness ("Puff Softness", Range(0.05, 0.8)) = 0.35

        _RiseSpeed ("Rise Speed", Range(0, 1)) = 0.15
        _SwirlSpeed ("Swirl Speed", Range(0, 2)) = 0.3
        _GlowStrength ("Glow Strength", Range(0, 3)) = 0.25

        _PlayerPosition ("Player Position", Vector) = (0, 0, 0, 0)
        _ExclusionRadius ("Player Clear Radius", Range(0, 10)) = 2.0
        _ExclusionFeather ("Player Clear Transition", Range(0.1, 10)) = 2.0
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
            Name "SmokeVolume"
            Tags { "LightMode" = "UniversalForward" }

            Cull Front
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)

                half4 _SmokeColor;
                half4 _GlowColor;

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

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionOS : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                output.positionHCS =
                    TransformObjectToHClip(input.positionOS.xyz);

                output.positionOS = input.positionOS.xyz;

                return output;
            }

            float Hash(float3 p)
            {
                p = frac(p * 0.1031);
                p += dot(p, p.yxz + 33.33);

                return frac((p.x + p.y) * p.z);
            }

            float Noise3D(float3 p)
            {
                float3 i = floor(p);
                float3 f = frac(p);

                f = f * f * (3.0 - 2.0 * f);

                float n000 = Hash(i);
                float n100 = Hash(i + float3(1, 0, 0));
                float n010 = Hash(i + float3(0, 1, 0));
                float n110 = Hash(i + float3(1, 1, 0));

                float n001 = Hash(i + float3(0, 0, 1));
                float n101 = Hash(i + float3(1, 0, 1));
                float n011 = Hash(i + float3(0, 1, 1));
                float n111 = Hash(i + float3(1, 1, 1));

                float nx00 = lerp(n000, n100, f.x);
                float nx10 = lerp(n010, n110, f.x);
                float nx01 = lerp(n001, n101, f.x);
                float nx11 = lerp(n011, n111, f.x);

                return lerp(
                    lerp(nx00, nx10, f.y),
                    lerp(nx01, nx11, f.y),
                    f.z
                );
            }

            float FBM(float3 p)
            {
                float value = 0.0;
                float amplitude = 0.5;

                [unroll]
                for (int i = 0; i < 4; i++)
                {
                    value += Noise3D(p) * amplitude;
                    p = p * 2.03 + 17.1;
                    amplitude *= 0.5;
                }

                return value / 0.9375;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                // Kamera i promie? w lokalnej przestrzeni Cube'a.
                float3 cameraOS =
                    TransformWorldToObject(_WorldSpaceCameraPos);

                float3 rayOrigin = cameraOS;

                float3 rayDir =
                    normalize(input.positionOS - cameraOS);

                // Zabezpieczenie przed dzieleniem przez zero.
                float3 safeDir =
                    (lerp(-1.0, 1.0, step(0.0, rayDir))) *
                    max(abs(rayDir), float3(0.0001, 0.0001, 0.0001));

                // Przeci?cie promienia z lokalnymi granicami Cube'a.
                float3 t0 = (-0.5 - rayOrigin) / safeDir;
                float3 t1 = ( 0.5 - rayOrigin) / safeDir;

                float3 tMin = min(t0, t1);
                float3 tMax = max(t0, t1);

                float tNear =
                    max(max(tMin.x, tMin.y), tMin.z);

                float tFar =
                    min(min(tMax.x, tMax.y), tMax.z);

                tNear = max(tNear, 0.0);

                if (tFar <= tNear)
                    discard;

                const int STEPS = 64;

                float stepSize = (tFar - tNear) / STEPS;

                float accumulatedAlpha = 0.0;
                float3 accumulatedColor = 0.0;

                float time = _Time.y;

                [loop]
                for (int i = 0; i < STEPS; i++)
                {
                    float t = tNear + (i + 0.5) * stepSize;

                    if (t > tFar || accumulatedAlpha > 0.97)
                        break;

                    float3 p = rayOrigin + rayDir * t;

                    // Animacja unoszenia si? i wirowania mg?y.
                    p.y -= time * _RiseSpeed;

                    p.x += sin(
                        p.y * 3.0 + time * _SwirlSpeed
                    ) * 0.08;

                    p.z += cos(
                        p.y * 2.5 + time * _SwirlSpeed
                    ) * 0.08;

                    float3 samplePos = p * _SmokeScale;

                    // Zniekszta?cenie szumu tworz?ce k??by.
                    float3 warp = float3(
                        FBM(samplePos + float3(0, 2.1, 5.7)),
                        FBM(samplePos + float3(8.2, 1.3, 2.4)),
                        FBM(samplePos + float3(3.5, 7.1, 0.6))
                    );

                    float3 warpedPos =
                        samplePos + (warp - 0.5) *
                        _WarpStrength * 3.0;

                    float broadShape = FBM(warpedPos);

                    float detail = Noise3D(
                        p * _DetailScale +
                        float3(0, -time * _RiseSpeed, 0)
                    );

                    float smokeShape = lerp(
                        broadShape,
                        broadShape * 0.75 + detail * 0.25,
                        0.35
                    );

                    // Podstawowa g?sto?? proceduralnej mg?y.
                    float density = smoothstep(
                        0.34 - _Softness * 0.25,
                        0.62 + _Softness * 0.2,
                        smokeShape
                    );

                    density *= smoothstep(
                        0.12, 0.4, broadShape
                    );

                    // Przeliczenie próbki na pozycj? w ?wiecie.
                    // Dzi?ki temu strefa pod??a za graczem.
                    float3 sampleWorldPos =
                        TransformObjectToWorld(p);

                    // Odleg?o?? próbki mg?y od ?rodka gracza.
                    float playerDistance = distance(
                        sampleWorldPos,
                        _PlayerPosition.xyz
                    );

                    // Brak mg?y w promieniu wykluczenia,
                    // a nast?pnie mi?kkie przej?cie.
                    float playerMask = smoothstep(
                        _ExclusionRadius,
                        _ExclusionRadius + _ExclusionFeather,
                        playerDistance
                    );

                    density *= playerMask;

                    // Obliczanie przezroczysto?ci próbki.
                    float sampleAlpha =
                        1.0 - exp(
                            -density * _Density * stepSize * 3.0
                        );

                    sampleAlpha = saturate(sampleAlpha);

                    // Kolor mg?y i delikatna emisja.
                    half3 sampleColor =
                        _SmokeColor.rgb +
                        _GlowColor.rgb *
                        (_GlowStrength * density);

                    // Front-to-back compositing.
                    accumulatedColor +=
                        (1.0 - accumulatedAlpha) *
                        sampleColor * sampleAlpha;

                    accumulatedAlpha +=
                        (1.0 - accumulatedAlpha) *
                        sampleAlpha;
                }

                if (accumulatedAlpha < 0.005)
                    discard;

                half3 finalColor =
                    accumulatedColor /
                    max(accumulatedAlpha, 0.001);

                return half4(finalColor, accumulatedAlpha);
            }

            ENDHLSL
        }
    }

    FallBack Off
}
