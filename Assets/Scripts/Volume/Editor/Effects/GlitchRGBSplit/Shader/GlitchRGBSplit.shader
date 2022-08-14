Shader "Hidden/PostProcessing/Glitch/RGBSplit"
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
        float _Speed;
        float _Fading;//衰减
        float _CenterFading;//中心的衰落
        float _TimeX;
        float _AmountR;
        float _AmountB;

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
            float2 uv = i.uv0.xy;
            half time = _TimeX * 6 * _Speed;
            half splitAmount = (1.0 + sin(time)) * 0.5;
            splitAmount *= 1.0 + sin(time * 2) * 0.5;
            splitAmount = pow(splitAmount, 3.0);
            splitAmount *= 0.05;
            float distance = length(uv - float2(0.5, 0.5));
            splitAmount *= _Fading * _Amount;
            splitAmount *= lerp(1, distance, _CenterFading);

            half3 colorR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x + splitAmount * _AmountR, uv.y)).rgb;
            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            half3 colorB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x - splitAmount * _AmountB, uv.y)).rgb;

            half3 splitColor = half3(colorR.r, sceneColor.g, colorB.b);
            half3 finalColor = lerp(sceneColor.rgb, splitColor, _Fading);

            return half4(finalColor, 1.0);
        }

        half4 Frag_Vertical(VertexOutput i) : SV_Target
        {
            float2 uv = i.uv0.xy;
            half time = _TimeX * 6 * _Speed;
            half splitAmount = (1.0 + sin(time)) * 0.5;
            splitAmount *= 1.0 + sin(time * 2) * 0.5;
            splitAmount = pow(splitAmount, 3.0);
            splitAmount *= 0.05;
            float distance = length(uv - float2(0.5, 0.5));
            splitAmount *= _Fading * _Amount;
            splitAmount *= _Fading * _Amount;

            half3 colorR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x , uv.y + splitAmount * _AmountR)).rgb;
            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            half3 colorB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x, uv.y - splitAmount * _AmountB)).rgb;

            half3 splitColor = half3(colorR.r, sceneColor.g, colorB.b);
            half3 finalColor = lerp(sceneColor.rgb, splitColor, _Fading);

            return half4(finalColor, 1.0);
        }

        half4 Frag_Horizontal_Vertical(VertexOutput i) : SV_Target
        {
            float2 uv = i.uv0.xy;
            half time = _TimeX * 6 * _Speed;
            half splitAmount = (1.0 + sin(time)) * 0.5;
            splitAmount *= 1.0 + sin(time * 2) * 0.5;
            splitAmount = pow(splitAmount, 3.0);
            splitAmount *= 0.05;
            float distance = length(uv - float2(0.5, 0.5));
            splitAmount *= _Fading * _Amount;
            splitAmount *= _Fading * _Amount;

            float splitAmountR = splitAmount * _AmountR;
            float splitAmountB = splitAmount * _AmountB;

            half3 colorR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x + splitAmountR, uv.y + splitAmountR)).rgb;
            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            half3 colorB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x - splitAmountB, uv.y - splitAmountB)).rgb;

            half3 splitColor = half3(colorR.r, sceneColor.g, colorB.b);
            half3 finalColor = lerp(sceneColor.rgb, splitColor, _Fading);

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