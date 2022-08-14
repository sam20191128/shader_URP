Shader "Hidden/PostProcessing/Glitch/ImageBlockV3"
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

        float _Speed;
        float _BlockSize;

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

        inline float randomNoise(float2 seed)
        {
            return frac(sin(dot(seed * floor(_Time.y * _Speed), float2(17.13, 3.71))) * 43758.5453123);
        }

        float rand(float2 n)
        {
            return frac(sin(dot(n, float2(12.9898, 78.233))) * 43758.5453);
        }

        inline float randomNoise(float seed)
        {
            return rand(float2(seed, 1.0));
        }


        //像素shader
        half4 Frag(VertexOutput i) : SV_Target
        {
            float2 block = randomNoise(floor(i.uv0 * _BlockSize));
            float displaceNoise = pow(block.x, 8.0) * pow(block.x, 3.0);

            half ColorR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0).r;
            half ColorG = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0 + float2(displaceNoise * 0.05 * randomNoise(7.0), 0.0)).g;
            half ColorB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0 - float2(displaceNoise * 0.05 * randomNoise(13.0), 0.0)).b;

            return half4(ColorR, ColorG, ColorB, 1.0);
        }

        float4 Frag_Debug(VertexOutput i): SV_Target
        {
            float2 block = randomNoise(floor(i.uv0 * _BlockSize));
            float displaceNoise = pow(block.x, 8.0) * pow(block.x, 3.0);

            return float4(displaceNoise, displaceNoise, displaceNoise, 1);
        }
        ENDHLSL

        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment Frag
            ENDHLSL
        }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment Frag_Debug
            ENDHLSL

        }
    }
}