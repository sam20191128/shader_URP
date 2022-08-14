Shader "Hidden/PostProcessing/Glitch/ScreenJump"
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

        float _JumpIndensity;
        float _JumpTime;

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
            float jump = lerp(i.uv0.x, frac(i.uv0.x + _JumpTime), _JumpIndensity);
            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, frac(float2(jump, i.uv0.y)));
            return sceneColor;
        }

        float4 Frag_Vertical(VertexOutput i): SV_Target
        {
            float jump = lerp(i.uv0.y, frac(i.uv0.y + _JumpTime), _JumpIndensity);
            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, frac(float2(i.uv0.x, jump)));
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