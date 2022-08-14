Shader "Hidden/PostProcessing/Glitch/TileJitter"
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

        float _SplittingNumber;
        float _JitterAmount;
        float _JitterSpeed;
        float _Frequency;

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

        float randomNoise(float2 c)
        {
            return frac(sin(dot(c.xy, float2(12.9898, 78.233))) * 43758.5453);
        }


        //像素shader
        half4 Frag_Vertical(VertexOutput i) : SV_Target
        {
            float2 uv = i.uv0.xy;
            half strength = 1.0;
            half pixelSizeX = 1.0 / _ScreenParams.x;

            // --------------------------------Prepare Jitter UV--------------------------------
            #if USING_FREQUENCY_INFINITE
            strength = 1;
            #else
            strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
            #endif

            if (fmod(uv.x * _SplittingNumber, 2) < 1.0)
            {
                #if JITTER_DIRECTION_HORIZONTAL
                uv.x += pixelSizeX * cos(_Time.y * _JitterSpeed) * _JitterAmount * strength;
                #else
                uv.y += pixelSizeX * cos(_Time.y * _JitterSpeed) * _JitterAmount * strength;
                #endif
            }

            // -------------------------------Final Sample------------------------------
            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            return sceneColor;
        }

        float4 Frag_Horizontal(VertexOutput i): SV_Target
        {
            float2 uv = i.uv0.xy;
            half strength = 1.0;
            half pixelSizeX = 1.0 / _ScreenParams.x;

            // --------------------------------Prepare Jitter UV--------------------------------
            #if USING_FREQUENCY_INFINITE
            strength = 1;
            #else
            strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
            #endif
            if (fmod(uv.y * _SplittingNumber, 2) < 1.0)
            {
                #if JITTER_DIRECTION_HORIZONTAL
                uv.x += pixelSizeX * cos(_Time.y * _JitterSpeed) * _JitterAmount * strength;
                #else
                uv.y += pixelSizeX * cos(_Time.y * _JitterSpeed) * _JitterAmount * strength;
                #endif
            }

            // -------------------------------Final Sample------------------------------
            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            return sceneColor;
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