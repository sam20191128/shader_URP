Shader "Hidden/PostProcessing/Glitch/AnalogNoise"
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
        float _Fading;
        float _LuminanceJitterThreshold;
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

        float randomNoise(float2 c)
        {
            return frac(sin(dot(c.xy, float2(12.9898, 78.233))) * 43758.5453);
        }

        //像素shader
        half4 Frag(VertexOutput i) : SV_Target
        {
            half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
            half4 noiseColor = sceneColor;

            half luminance = dot(noiseColor.rgb, half3(0.22, 0.707, 0.071));
            if (randomNoise(float2(_TimeX * _Speed, _TimeX * _Speed)) > _LuminanceJitterThreshold)
            {
                noiseColor = float4(luminance, luminance, luminance, luminance);
            }

            float noiseX = randomNoise(_TimeX * _Speed + i.uv0 / float2(-213, 5.53));
            float noiseY = randomNoise(_TimeX * _Speed - i.uv0 / float2(213, -5.53));
            float noiseZ = randomNoise(_TimeX * _Speed + i.uv0 / float2(213, 5.53));

            noiseColor.rgb += 0.25 * float3(noiseX, noiseY, noiseZ) - 0.125;

            noiseColor = lerp(sceneColor, noiseColor, _Fading);

            return noiseColor;
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