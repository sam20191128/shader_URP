Shader "Hidden/PostProcessing/Glitch/ImageBlockV4"
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
        float _MaxRGBSplitX;
        float _MaxRGBSplitY;

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

        inline float randomNoise(float seed)
        {
            return randomNoise(float2(seed, 1.0));
        }


        //像素shader
        half4 Frag(VertexOutput i) : SV_Target
        {
            half2 block = randomNoise(floor(i.uv0 * _BlockSize));

            float displaceNoise = pow(block.x, 8.0) * pow(block.x, 3.0);
            float splitRGBNoise = pow(randomNoise(7.2341), 17.0);
            float offsetX = displaceNoise - splitRGBNoise * _MaxRGBSplitX;
            float offsetY = displaceNoise - splitRGBNoise * _MaxRGBSplitY;

            float noiseX = 0.05 * randomNoise(13.0);
            float noiseY = 0.05 * randomNoise(7.0);
            float2 offset = float2(offsetX * noiseX, offsetY * noiseY);

            half4 colorR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
            half4 colorG = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0 + offset);
            half4 colorB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0 - offset);

            return half4(colorR.r, colorG.g, colorB.z, (colorR.a + colorG.a + colorB.a));
        }

        float4 Frag_Debug(VertexOutput i): SV_Target
        {
            half2 block = randomNoise(floor(i.uv0 * _BlockSize));

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