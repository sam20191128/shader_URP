Shader "Hidden/PostProcessing/Glitch/RGBSplitV4"
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

        float _Indensity;
        float _TimeX;

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
            float splitAmount = _Indensity * randomNoise(_TimeX, 2);

            half4 ColorR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv0.x + splitAmount, i.uv0.y));
            half4 ColorG = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
            half4 ColorB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv0.x - splitAmount, i.uv0.y));

            return half4(ColorR.r, ColorG.g, ColorB.b, 1);
        }

        half4 Frag_Vertical(VertexOutput i) : SV_Target
        {
            float splitAmount = _Indensity * randomNoise(_TimeX, 2);

            half4 ColorR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
            half4 ColorG = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv0.x, i.uv0.y + splitAmount));
            half4 ColorB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv0.x, i.uv0.y - splitAmount));

            return half4(ColorR.r, ColorG.g, ColorB.b, 1);
        }

        half4 Frag_Horizontal_Vertical(VertexOutput i) : SV_Target
        {
            float splitAmount = _Indensity * randomNoise(_TimeX, 2);

            half4 ColorR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
            half4 ColorG = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv0.x + splitAmount, i.uv0.y + splitAmount));
            half4 ColorB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv0.x - splitAmount, i.uv0.y - splitAmount));

            return half4(ColorR.r, ColorG.g, ColorB.b, 1);
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

        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment Frag_Horizontal_Vertical
            ENDHLSL

        }
    }
}