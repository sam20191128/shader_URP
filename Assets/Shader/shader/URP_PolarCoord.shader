Shader "URP/PolarCoord" //Shader路径名
{
    Properties //材质面板参数
    {
        _MainTex ("RGB：颜色 A：透贴", 2d) = "gray"{}
        _Opacity ("透明度", range(0, 1)) = 0.5
        [HDR]_Color ("混合颜色", color) = (1.0, 1.0, 1.0, 1.0)
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

            // 输入参数
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform half _Opacity;
            uniform half3 _Color;

            // 输入结构
            struct VertexInput
            {
                float4 vertex : POSITION; // 顶点位置 总是必要
                float2 uv0 : TEXCOORD0; // UV信息 采样贴图用
                float4 color : COLOR; //顶点色
            };

            // 输出结构
            struct VertexOutput
            {
                float4 pos : SV_POSITION; // 顶点位置 总是必要
                float2 uv0 : TEXCOORD0; // UV信息 采样贴图用
                float4 color : COLOR; //顶点色
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(v.vertex); // 顶点位置 OS>CS
                o.uv0 = v.uv0; // UV信息 
                o.color = v.color;
                return o;
            }

            // 直角坐标转极坐标方法
            float2 RectToPolar(float2 uv, float2 centerUV)
            {
                uv = uv - centerUV;
                float theta = atan2(uv.y, uv.x); // atan()值域[-π/2, π/2]一般不用; atan2()值域[-π, π]
                float r = length(uv);
                return float2(theta, r);
            }

            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR
            {
                // 直角坐标转极坐标
                float2 thetaR = RectToPolar(i.uv0, float2(0.5, 0.5));
                // 极坐标转纹理采样UV
                float2 polarUV = float2(
                    thetaR.x / 3.141593 * 0.5 + 0.5, // θ映射到[0, 1]
                    thetaR.y + frac(_Time.x * 3.0) // r随时间流动
                );
                // 采样MainTex
                half4 var_MainTex = tex2D(_MainTex, polarUV);
                // 处理最终输出
                half3 finalRGB = var_MainTex.rgb * _Color;
                half opacity = var_MainTex.a * _Opacity * i.color.r;
                // 返回值
                return half4(finalRGB * opacity, opacity);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}