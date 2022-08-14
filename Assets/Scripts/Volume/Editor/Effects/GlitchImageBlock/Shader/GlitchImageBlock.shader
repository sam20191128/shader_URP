Shader "Hidden/PostProcessing/Glitch/ImageBlock"
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

        float _Fade;
        float _TimeX;
        float _Offset;

        float _BlockLayer1_U;
        float _BlockLayer1_V;
        float _BlockLayer2_U;
        float _BlockLayer2_V;

        float _RGBSplit_Indensity;
        float _BlockLayer1_Indensity;
        float _BlockLayer2_Indensity;

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

        float randomNoise(float2 seed)
        {
            return frac(sin(dot(seed * floor(_TimeX * 30.0), float2(127.1, 311.7))) * 43758.5453123);
        }

        float randomNoise(float seed)
        {
            return randomNoise(float2(seed, 1.0));
        }

        //像素shader
        half4 Frag(VertexOutput i) : SV_Target
        {
            float2 uv = i.uv0.xy;

            //求解第一层blockLayer
            float2 blockLayer1 = floor(uv * float2(_BlockLayer1_U, _BlockLayer1_V));
            float2 blockLayer2 = floor(uv * float2(_BlockLayer2_U, _BlockLayer2_V));

            //return float4(blockLayer1, blockLayer2);

            float lineNoise1 = pow(randomNoise(blockLayer1), _BlockLayer1_Indensity);
            float lineNoise2 = pow(randomNoise(blockLayer2), _BlockLayer2_Indensity);
            float RGBSplitNoise = pow(randomNoise(5.1379), 7.1) * _RGBSplit_Indensity;
            float lineNoise = lineNoise1 * lineNoise2 * _Offset - RGBSplitNoise;

            float4 colorR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            float4 colorG = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(lineNoise * 0.05 * randomNoise(7.0), 0));
            float4 colorB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv - float2(lineNoise * 0.05 * randomNoise(23.0), 0));

            float4 result = float4(float3(colorR.x, colorG.y, colorB.z), colorR.a + colorG.a + colorB.a);
            result = lerp(colorR, result, _Fade);

            return result;
        }

        float4 Frag_Debug(VertexOutput i): SV_Target
        {
            float2 uv = i.uv0.xy;

            float2 blockLayer1 = floor(uv * float2(_BlockLayer1_U, _BlockLayer1_V));
            float2 blockLayer2 = floor(uv * float2(_BlockLayer2_U, _BlockLayer2_V));

            float lineNoise1 = pow(randomNoise(blockLayer1), _BlockLayer1_Indensity);
            float lineNoise2 = pow(randomNoise(blockLayer2), _BlockLayer2_Indensity);
            float RGBSplitNoise = pow(randomNoise(5.1379), 7.1) * _RGBSplit_Indensity;
            float lineNoise = lineNoise1 * lineNoise2 * _Offset - RGBSplitNoise;

            return float4(lineNoise, lineNoise, lineNoise, 1);
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