Shader "URP/ScreenWarp" //Shader路径名
{
    Properties //材质面板参数
    {
        _MainTex ("RGB：颜色 A：透贴", 2d) = "gray"{}
        _Opacity ("透明度", range(0, 1)) = 0.5
        _WarpMidVal ("扰动中间值", range(0, 1)) = 0.5
        _WarpInt ("扰动强度", range(0, 5)) = 1
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
            uniform half _Opacity;
            uniform half _WarpMidVal;
            uniform half _WarpInt;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            SAMPLER(_CameraOpaqueTexture);

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
                float2 uv0 : TEXCOORD0; // UV信息 采样贴图用
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(v.vertex.xyz.xyz); // 顶点位置 OS>CS
                o.uv0 = v.uv0; // UV信息

                return o;
            }

            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR
            {
                // 采样 基本纹理 RGB颜色 A透贴
                float4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);

                //屏幕背景纹理采样
                half2 screenUV = i.pos.xy / _ScreenParams.xy;
                screenUV += (var_MainTex.b - _WarpMidVal) * _WarpInt * _Opacity;
                half4 col = tex2D(_CameraOpaqueTexture, screenUV);

                // FinalRGB 不透明度
                half3 finalRGB = lerp(1.0, var_MainTex.rgb, _Opacity) * col;
                half opacity = var_MainTex.a * _Opacity;
                // 返回值
                return half4(finalRGB * opacity, opacity);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}