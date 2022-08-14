Shader "Hidden/PostProcessing/Glitch/ScreenShake"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }

    SubShader
    {
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float _ScreenShake;

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
            return frac(sin(dot(float2(x, y), float2(127.1, 311.7))) * 43758.5453);
        }

        //像素shader
        half4 Frag_Horizontal(VertexOutput i) : SV_Target
        {
            float shake = (randomNoise(_Time.x, 2) - 0.5) * _ScreenShake;

            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, frac(float2(i.uv0.x + shake, i.uv0.y)));

            return sceneColor;
        }

        float4 Frag_Vertical(VertexOutput i): SV_Target
        {
            float shake = (randomNoise(_Time.x, 2) - 0.5) * _ScreenShake;

            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, frac(float2(i.uv0.x, i.uv0.y + shake)));

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