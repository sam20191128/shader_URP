Shader "Hidden/PostProcessing/Glitch/WaveJitter"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }

    SubShader
    {
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        #pragma shader_feature JITTER_DIRECTION_HORIZONTAL
        #pragma shader_feature USING_FREQUENCY_INFINITE

        CBUFFER_START(UnityPerMaterial)

        half2 _Resolution;

        float _Frequency;
        float _RGBSplit;
        float _Speed;
        float _Amount;

        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct VertexInput //输入结构
        {
            float4 vertex : POSITION;
            float2 uv0 : TEXCOORD0;
        };

        struct VertexOutput //输出结构
        {
            float4 pos : SV_POSITION;
            float2 uv0 : TEXCOORD0;
        };

        //顶点shader
        VertexOutput VertDefault(VertexInput v)
        {
            VertexOutput o;
            o.pos = TransformObjectToHClip(v.vertex);
            o.uv0 = v.uv0;
            return o;
        }

        #define NOISE_SIMPLEX_1_DIV_289 0.00346020761245674740484429065744f

        float2 mod289(float2 x)
        {
            return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
        }

        float3 mod289(float3 x)
        {
            return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
        }

        float3 permute(float3 x)
        {
            return mod289(x * x * 34.0 + x);
        }

        float3 taylorInvSqrt(float3 r)
        {
            return 1.79284291400159 - 0.85373472095314 * r;
        }

        float snoise(float2 v)
        {
            const float4 C = float4(0.211324865405187, // (3.0-sqrt(3.0))/6.0
                                    0.366025403784439, // 0.5*(sqrt(3.0)-1.0)
                                    - 0.577350269189626, // -1.0 + 2.0 * C.x
                                    0.024390243902439); // 1.0 / 41.0
            // First corner
            float2 i = floor(v + dot(v, C.yy));
            float2 x0 = v - i + dot(i, C.xx);

            // Other corners
            float2 i1;
            i1.x = step(x0.y, x0.x);
            i1.y = 1.0 - i1.x;

            // x1 = x0 - i1  + 1.0 * C.xx;
            // x2 = x0 - 1.0 + 2.0 * C.xx;
            float2 x1 = x0 + C.xx - i1;
            float2 x2 = x0 + C.zz;

            // Permutations
            i = mod289(i); // Avoid truncation effects in permutation
            float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0))
                + i.x + float3(0.0, i1.x, 1.0));

            float3 m = max(0.5 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
            m = m * m;
            m = m * m;

            // Gradients: 41 points uniformly over a line, mapped onto a diamond.
            // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
            float3 x = 2.0 * frac(p * C.www) - 1.0;
            float3 h = abs(x) - 0.5;
            float3 ox = floor(x + 0.5);
            float3 a0 = x - ox;

            // Normalise gradients implicitly by scaling m
            m *= taylorInvSqrt(a0 * a0 + h * h);

            // Compute final noise value at P
            float3 g;
            g.x = a0.x * x0.x + h.x * x0.y;
            g.y = a0.y * x1.x + h.y * x1.y;
            g.z = a0.z * x2.x + h.z * x2.y;
            return 130.0 * dot(m, g);
        }

        //像素shader
        half4 Frag_Vertical(VertexOutput i) : SV_Target
        {
            half strength = 0.0;
            #if USING_FREQUENCY_INFINITE
            strength = 1;
            #else
            strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
            #endif

            // Prepare UV
            float uv_x = i.uv0.x * _Resolution.x;
            float noise_wave_1 = snoise(float2(uv_x * 0.01, _Time.y * _Speed * 20)) * (strength * _Amount * 32.0);
            float noise_wave_2 = snoise(float2(uv_x * 0.02, _Time.y * _Speed * 10)) * (strength * _Amount * 4.0);
            float noise_wave_y = noise_wave_1 * noise_wave_2 / _Resolution.x;
            float uv_y = i.uv0.y + noise_wave_y;

            float rgbSplit_uv_y = (_RGBSplit * 50 + (20.0 * strength + 1.0)) * noise_wave_y / _Resolution.y;

            // Sample RGB Color
            half4 colorG = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv0.x, uv_y));
            half4 colorRB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv0.x, uv_y + rgbSplit_uv_y));

            return half4(colorRB.r, colorG.g, colorRB.b, colorRB.a + colorG.a);
        }

        float4 Frag_Horizontal(VertexOutput i): SV_Target
        {
            half strength = 0.0;
            #if USING_FREQUENCY_INFINITE
            strength = 1;
            #else
            strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
            #endif

            // Prepare UV
            float uv_y = i.uv0.y * _Resolution.y;
            float noise_wave_1 = snoise(float2(uv_y * 0.01, _Time.y * _Speed * 20)) * (strength * _Amount * 32.0);
            float noise_wave_2 = snoise(float2(uv_y * 0.02, _Time.y * _Speed * 10)) * (strength * _Amount * 4.0);
            float noise_wave_x = noise_wave_1 * noise_wave_2 / _Resolution.x;
            float uv_x = i.uv0.x + noise_wave_x;

            float rgbSplit_uv_x = (_RGBSplit * 50 + (20.0 * strength + 1.0)) * noise_wave_x / _Resolution.x;

            // Sample RGB Color-
            half4 colorG = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv_x, i.uv0.y));
            half4 colorRB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv_x + rgbSplit_uv_x, i.uv0.y));

            return half4(colorRB.r, colorG.g, colorRB.b, colorRB.a + colorG.a);
        }
        ENDHLSL

        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment Frag_Horizontal
            ENDHLSL
        }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment Frag_Vertical
            ENDHLSL

        }
    }
}