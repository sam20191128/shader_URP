Shader "URP/Post/Kawaseblur"
{
    Properties
    {
        _MainTex("MainTex",2D)="white"{}
        //_Blur("Blur",float)=2
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
        }

        Cull Off ZWrite Off ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float _Blur;

        float4 _MainTex_TexelSize;

        CBUFFER_END

        TEXTURE2D(_MainTex);

        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 positionOS:POSITION;
            float2 texcoord:TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD;
        };

        v2f VERT(a2v i) //水平方向的采样
        {
            v2f o;
            o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
            o.texcoord = i.texcoord;
            return o;
        }

        half4 FRAG(v2f i):SV_TARGET
        {
            float4 col;

            half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(-1,-1)*_MainTex_TexelSize.xy*_Blur);

            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(1,-1)*_MainTex_TexelSize.xy*_Blur);

            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(-1,1)*_MainTex_TexelSize.xy*_Blur);

            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(1,1)*_MainTex_TexelSize.xy*_Blur);

            return tex / 5.0;
        }
        ENDHLSL

        pass
        {

            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG
            ENDHLSL
        }
    }
}