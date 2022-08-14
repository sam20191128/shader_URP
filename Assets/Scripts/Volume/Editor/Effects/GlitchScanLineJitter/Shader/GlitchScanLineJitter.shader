Shader "Hidden/PostProcessing/Glitch/ScanLineJitter"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }

    SubShader
    {
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        #pragma shader_feature USING_FREQUENCY_INFINITE

        CBUFFER_START(UnityPerMaterial)


        float _Amount;
        float _Threshold;
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

        float randomNoise(float x, float y)
        {
            return frac(sin(dot(float2(x, y), float2(12.9898, 78.233))) * 43758.5453);
        }

        //像素shader
        half4 Frag_Horizontal(VertexOutput i) : SV_Target
        {
            half strength = 0;
            #if USING_FREQUENCY_INFINITE
            strength = 1;
            #else
			strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
            #endif


            float jitter = randomNoise(i.uv0.y, _Time.x) * 2 - 1;
            jitter *= step(_Threshold, abs(jitter)) * _Amount * strength;

            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, frac(i.uv0 + float2(jitter, 0)));

            return sceneColor;
        }

        float4 Frag_Vertical(VertexOutput i): SV_Target
        {
            half strength = 0;
            #if USING_FREQUENCY_INFINITE
            strength = 1;
            #else
			strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
            #endif

            float jitter = randomNoise(i.uv0.x, _Time.x) * 2 - 1;
            jitter *= step(_Threshold, abs(jitter)) * _Amount * strength;

            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, frac(i.uv0 + float2(0, jitter)));

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