Shader "Hidden/PostProcessing/Glitch/RGBSplitV2"
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

        float _Amount;
        float _Amplitude;
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

        //像素shader
        half4 Frag_Horizontal(VertexOutput i) : SV_Target
        {
            float splitAmout = (1.0 + sin(_TimeX * 6.0)) * 0.5;
            splitAmout *= 1.0 + sin(_TimeX * 16.0) * 0.5;
            splitAmout *= 1.0 + sin(_TimeX * 19.0) * 0.5;
            splitAmout *= 1.0 + sin(_TimeX * 27.0) * 0.5;
            splitAmout = pow(splitAmout, _Amplitude);
            splitAmout *= (0.05 * _Amount);

            half3 finalColor;
            finalColor.r = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, half2(i.uv0.x + splitAmout, i.uv0.y)).r;
            finalColor.g = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0).g;
            finalColor.b = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, half2(i.uv0.x - splitAmout, i.uv0.y)).b;

            finalColor *= (1.0 - splitAmout * 0.5);

            return half4(finalColor, 1.0);
        }

        half4 Frag_Vertical(VertexOutput i) : SV_Target
        {
            float splitAmout = (1.0 + sin(_TimeX * 6.0)) * 0.5;
            splitAmout *= 1.0 + sin(_TimeX * 16.0) * 0.5;
            splitAmout *= 1.0 + sin(_TimeX * 19.0) * 0.5;
            splitAmout *= 1.0 + sin(_TimeX * 27.0) * 0.5;
            splitAmout = pow(splitAmout, _Amplitude);
            splitAmout *= (0.05 * _Amount);

            half3 finalColor;
            finalColor.r = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, half2(i.uv0.x , i.uv0.y +splitAmout)).r;
            finalColor.g = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0).g;
            finalColor.b = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, half2(i.uv0.x, i.uv0.y - splitAmout)).b;

            finalColor *= (1.0 - splitAmout * 0.5);

            return half4(finalColor, 1.0);
        }

        half4 Frag_Horizontal_Vertical(VertexOutput i) : SV_Target
        {
            float splitAmout = (1.0 + sin(_TimeX * 6.0)) * 0.5;
            splitAmout *= 1.0 + sin(_TimeX * 16.0) * 0.5;
            splitAmout *= 1.0 + sin(_TimeX * 19.0) * 0.5;
            splitAmout *= 1.0 + sin(_TimeX * 27.0) * 0.5;
            splitAmout = pow(splitAmout, _Amplitude);
            splitAmout *= (0.05 * _Amount);

            half3 finalColor;
            finalColor.r = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, half2(i.uv0.x+splitAmout, i.uv0.y + splitAmout)).r;
            finalColor.g = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0).g;
            finalColor.b = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, half2(i.uv0.x - splitAmout, i.uv0.y + splitAmout)).b;

            finalColor *= (1.0 - splitAmout * 0.5);

            return half4(finalColor, 1.0);
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