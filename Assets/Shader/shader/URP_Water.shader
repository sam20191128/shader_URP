Shader "URP/Water" //Shader路径名
{
    Properties //材质面板参数
    {
        _MainTex ("颜色贴图", 2d) = "white"{}
        _WarpTex ("扰动图", 2d) = "gray"{}
        _Speed ("X：流速X Y：流速Y", vector) = (1.0, 1.0, 0.5, 1.0)
        _Warp1Params ("X：大小 Y：流速X Z：流速Y W：强度", vector) = (1.0, 1.0, 0.5, 1.0)
        _Warp2Params ("X：大小 Y：流速X Z：流速Y W：强度", vector) = (2.0, 0.5, 0.5, 1.0)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }

        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial) //缓冲区
            uniform float4 _MainTex_ST;
            uniform half2 _Speed;
            uniform half4 _Warp1Params;
            uniform half4 _Warp2Params;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_WarpTex);
            SAMPLER(sampler_WarpTex);

            // 输入结构
            struct VertexInput
            {
                float4 vertex : POSITION; // 顶点位置 总是必要
                float2 uv0 : TEXCOORD0; // UV信息 采样贴图用
            };

            //输出结构
            struct VertexOutput
            {
                float4 pos : SV_POSITION; // 顶点位置 总是必要
                float2 uv0 : TEXCOORD0; // UV信息 采样Mask
                float2 uv1 : TEXCOORD1; // UV信息 采样Noise1
                float2 uv2 : TEXCOORD2; // UV信息 采样Noise2
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(v.vertex); // 顶点位置 OS>CS
                o.uv0 = v.uv0 - frac(_Time.x * _Speed);
                o.uv1 = v.uv0 * _Warp1Params.x - frac(_Time.x * _Warp1Params.yz); // 扰动1 Y：流速X Z：流速Y
                o.uv2 = v.uv0 * _Warp2Params.x - frac(_Time.x * _Warp2Params.yz); // 扰动2 Y：流速X Z：流速Y
                return o;
            }

            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR
            {
                half3 var_Warp1 = SAMPLE_TEXTURE2D(_WarpTex, sampler_WarpTex, i.uv1).rgb; // 扰动1
                half3 var_Warp2 = SAMPLE_TEXTURE2D(_WarpTex, sampler_WarpTex, i.uv2).rgb; // 扰动2
                // 扰动混合,采样出来的是0到1，- 0.5后变成-0.5到0.5，有正有负，有前有后
                half2 warp = (var_Warp1.xy - 0.5) * _Warp1Params.w + (var_Warp2.xy - 0.5) * _Warp2Params.w;
                // 扰动UV
                float2 warpUV = i.uv0 + warp;
                // 采样MainTex
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, warpUV);

                return float4(var_MainTex.xyz, 1.0);
            }
            ENDHLSL
        }
    }
}