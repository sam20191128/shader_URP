Shader "URP/GhostFlow" //Shader路径名
{
    Properties //材质面板参数
    {
        _MainTex ("RGB：颜色 A：透贴", 2d) = "gray"{}
        _Opacity ("透明度", range(0, 1)) = 0.5
        _NoiseTex ("噪声图", 2d) = "gray"{}
        _NoiseInt ("噪声强度", range(0, 5)) = 0.5
        _FlowSpeed ("流动速度", range(0, 10)) = 5
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
            uniform float4 _NoiseTex_ST;
            uniform half _NoiseInt;
            uniform half _FlowSpeed;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

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
                float2 uv0 : TEXCOORD0; // UV 采样MainTex用
                float2 uv1 : TEXCOORD1; // UV 采样NoiseTex用
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(v.vertex); // 顶点位置 OS>CS
                o.uv0 = v.uv0;
                o.uv1 = TRANSFORM_TEX(v.uv0, _NoiseTex); // UV1支持TilingOffset
                o.uv1.y = o.uv1.y + frac(-_Time.x * _FlowSpeed); // UV1 V轴流动
                return o;
            }

            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR
            {
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0); // RGB颜色 A透贴
                half var_NoiseTex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv1).r; // 噪声图

                half3 finalRGB = var_MainTex.rgb;
                half noise = lerp(1.0, var_NoiseTex * 2.0, _NoiseInt); // Remap噪声
                noise = max(0.0, noise); // 截去负值
                half opacity = var_MainTex.a * _Opacity * noise;
                return half4(finalRGB * opacity, opacity); // 返回值
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}