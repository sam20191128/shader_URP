Shader "Hidden/PostProcessing/Glitch/RGBSplitV3"
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
        float _Frequency; //频率
        float _Speed;

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

        float4 RGBSplit_Horizontal(float2 uv, float Amount, float time)
        {
            Amount *= 0.001;
            float3 splitAmountX = float3(uv.x, uv.x, uv.x);
            splitAmountX.r += sin(time * 0.2) * Amount;
            splitAmountX.g += sin(time * 0.1) * Amount;
            half4 splitColor = half4(0.0, 0.0, 0.0, 0.0);
            splitColor.r = (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(splitAmountX.r, uv.y)).rgb).x;
            splitColor.g = (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(splitAmountX.g, uv.y)).rgb).y;
            splitColor.b = (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(splitAmountX.b, uv.y)).rgb).z;
            splitColor.a = 1;
            return splitColor;
        }

        float4 RGBSplit_Vertical(float2 uv, float Amount, float time)
        {
            Amount *= 0.001;
            float3 splitAmountY = float3(uv.y, uv.y, uv.y);
            splitAmountY.r += sin(time * 0.2) * Amount;
            splitAmountY.g += sin(time * 0.1) * Amount;
            half4 splitColor = half4(0.0, 0.0, 0.0, 0.0);
            splitColor.r = (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x, splitAmountY.r)).rgb).x;
            splitColor.g = (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x, splitAmountY.g)).rgb).y;
            splitColor.b = (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x, splitAmountY.b)).rgb).z;
            splitColor.a = 1;
            return splitColor;
        }

        float4 RGBSplit_Horizontal_Vertical(float2 uv, float Amount, float time)
        {
            Amount *= 0.001;
            //float3 splitAmount = float3(uv.y, uv.y, uv.y);
            float splitAmountR = sin(time * 0.2) * Amount;
            float splitAmountG = sin(time * 0.1) * Amount;
            half4 splitColor = half4(0.0, 0.0, 0.0, 0.0);
            splitColor.r = (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x + splitAmountR,uv.y +splitAmountR)).rgb).x;
            splitColor.g = (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x , uv.y)).rgb).y;
            splitColor.b = (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x + splitAmountG, uv.y + splitAmountG)).rgb).z;
            splitColor.a = 1;
            return splitColor;
        }

        //像素shader
        half4 Frag_Horizontal(VertexOutput i) : SV_Target
        {
            half strength = 0;
            #if USING_Frequency_INFINITE
			    strength = 1;
            #else
                strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
            #endif
            half3 color = RGBSplit_Horizontal(i.uv0.xy, _Amount * strength, _Time.y * _Speed).rgb;

            return half4(color, 1);
        }

        half4 Frag_Vertical(VertexOutput i) : SV_Target
        {
            half strength = 0;
            #if USING_Frequency_INFINITE
			    strength = 1;
            #else
                strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
            #endif
            half3 color = RGBSplit_Vertical(i.uv0.xy, _Amount * strength, _Time.y * _Speed).rgb;

            return half4(color, 1);
        }

        half4 Frag_Horizontal_Vertical(VertexOutput i) : SV_Target
        {
            half strength = 0;
            #if USING_Frequency_INFINITE
			    strength = 1;
            #else
                strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
            #endif
            half3 color = RGBSplit_Horizontal_Vertical(i.uv0.xy, _Amount * strength, _Time.y * _Speed).rgb;

            return half4(color, 1);
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