Shader "Hidden/PostProcessing/Glitch/DigitalStripe"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }

    SubShader
    {
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        #pragma shader_feature NEED_TRASH_FRAME

        CBUFFER_START(UnityPerMaterial)

        float _Indensity;
        half4 _StripColorAdjustColor;
        half _StripColorAdjustIndensity;

        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        TEXTURE2D(_NoiseTex);
        SAMPLER(sampler_NoiseTex);

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
        half4 Frag(VertexOutput i) : SV_Target
        {
            // 基础数据准备
            half4 stripNoise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv0);
            half threshold = 1.001 - _Indensity * 1.001;

            // uv偏移
            half uvShift = step(threshold, pow(abs(stripNoise.x), 3));
            float2 uv = frac(i.uv0 + stripNoise.yz * uvShift);
            half4 source = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);

            #ifndef NEED_TRASH_FRAME
            return source;
            #endif

            // 基于废弃帧插值
            half stripIndensity = step(threshold, pow(abs(stripNoise.w), 3)) * _StripColorAdjustIndensity;
            half3 color = lerp(source, _StripColorAdjustColor, stripIndensity).rgb;
            return float4(color, source.a);
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
    }
}