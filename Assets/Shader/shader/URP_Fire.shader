Shader "URP/Fire" //Shader路径名
{
    Properties //材质面板参数
    {
        _Mask ("R:外焰 G:内焰 B:透贴", 2d) = "blue"{}
        _Noise ("R:噪声1 G:噪声2", 2d) = "gray"{}
        _Noise1Params ("噪声1 X:大小 Y:流速 Z:强度", vector) = (1.0, 0.2, 0.2, 1.0)
        _Noise2Params ("噪声2 X:大小 Y:流速 Z:强度", vector) = (1.0, 0.2, 0.2, 1.0)
        [HDR]_Color1 ("外焰颜色", color) = (1,1,1,1)
        [HDR]_Color2 ("内焰颜色", color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Transparent" // 调整渲染顺序
            "RenderType"="Transparent" // 对应改为Cutout
            "ForceNoShadowCasting"="True" // 关闭阴影投射
            "IgnoreProjector"="True" // 不响应投射器
        }
        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode"="UniversalForward"
            }
            Blend One OneMinusSrcAlpha // 修改混合方式One/SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial) //缓冲区
            // 输入参数
            uniform float4 _Mask_ST;
            uniform half3 _Noise1Params;
            uniform half3 _Noise2Params;
            uniform half3 _Color1;
            uniform half3 _Color2;
            CBUFFER_END

            TEXTURE2D(_Mask);
            SAMPLER(sampler_Mask);

            TEXTURE2D(_Noise);
            SAMPLER(sampler_Noise);

            // 输入结构
            struct VertexInput
            {
                float4 vertex : POSITION; // 顶点位置 总是必要
                float2 uv0 : TEXCOORD0; // UV信息 采样贴图用
            };

            // 输出结构
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
                o.uv0 = TRANSFORM_TEX(v.uv0, _Mask);
                o.uv1 = v.uv0 * _Noise1Params.x - float2(0.0, frac(_Time.x * _Noise1Params.y));
                o.uv2 = v.uv0 * _Noise2Params.x - float2(0.0, frac(_Time.x * _Noise2Params.y));
                return o;
            }

            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR
            {
                // 扰动遮罩
                half warpMask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, i.uv0).b;
                // 噪声1
                half var_Noise1 = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, i.uv1).r;
                // 噪声2
                half var_Noise2 = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, i.uv2).g;
                // 噪声混合
                half noise = var_Noise1 * _Noise1Params.z + var_Noise2 * _Noise2Params.z;
                // 扰动UV
                float2 warpUV = i.uv0 - float2(0.0, noise) * warpMask;
                // 采样Mask
                half3 var_Mask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, warpUV);
                // 计算FinalRGB 不透明度
                half3 finalRGB = _Color1 * var_Mask.r + _Color2 * var_Mask.g;
                half opacity = var_Mask.r + var_Mask.g;
                return half4(finalRGB, opacity); // 返回值
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}