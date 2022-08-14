Shader "URP/Sequence" //Shader路径名
{
    Properties //材质面板参数
    {
        _MainTex ("RGB：颜色 A：透贴", 2d) = "gray"{}
        _Opacity ("透明度", range(0, 1)) = 0.5
        _Sequence ("序列帧", 2d) = "gray"{}
        _RowCount ("行数", int) = 1
        _ColCount ("列数", int) = 1
        _Speed ("速度", range(-15.0, 15.0)) = 1
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
        //        Pass
        //        {
        //            Name "FORWARD_AB"
        //            Tags
        //            {
        //                "LightMode"="UniversalForward"
        //            }
        //            Blend One One // 修改混合方式One/SrcAlpha OneMinusSrcAlpha
        //
        //            HLSLPROGRAM
        //            #pragma vertex vert
        //            #pragma fragment frag
        //
        //            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        //            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        //            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影
        //
        //            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //
        //            CBUFFER_START(UnityPerMaterial) //缓冲区
        //            // 输入参数
        //            uniform half _Opacity;
        //            CBUFFER_END
        //
        //            TEXTURE2D(_MainTex);
        //            SAMPLER(sampler_MainTex);
        //
        //            // 输入结构
        //            struct VertexInput
        //            {
        //                float4 vertex : POSITION; // 顶点位置 总是必要
        //                float2 uv : TEXCOORD0; // UV信息 采样贴图用
        //            };
        //
        //            // 输出结构
        //            struct VertexOutput
        //            {
        //                float4 pos : SV_POSITION; // 顶点位置 总是必要
        //                float2 uv : TEXCOORD0; // UV信息 采样贴图用
        //            };
        //
        //            // 输入结构>>>顶点Shader>>>输出结构
        //            VertexOutput vert(VertexInput v)
        //            {
        //                VertexOutput o = (VertexOutput)0;
        //                o.pos = TransformObjectToHClip(v.vertex); // 顶点位置 OS>CS
        //                o.uv = v.uv; // UV信息 
        //                return o;
        //            }
        //
        //            // 输出结构>>>像素
        //            float4 frag(VertexOutput i) : COLOR
        //            {
        //                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv); // 采样贴图 RGB颜色 A透贴
        //                half3 finalRGB = var_MainTex.rgb;
        //                half opacity = var_MainTex.a * _Opacity;
        //                return half4(finalRGB * opacity, opacity); // 返回值
        //            }
        //            ENDHLSL
        //        }

        Pass
        {
            Name "FORWARD_AD"
            Tags
            {
                "LightMode"="UniversalForward"
            }
            Blend One One // 修改混合方式One/SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial) //缓冲区
            // 输入参数
            uniform float4 _Sequence_ST;
            uniform half _Opacity;
            uniform half _RowCount;
            uniform half _ColCount;
            uniform half _Speed;
            CBUFFER_END

            TEXTURE2D(_Sequence);
            SAMPLER(sampler_Sequence);

            // 输入结构
            struct VertexInput
            {
                float4 vertex : POSITION; // 顶点位置 总是必要
                float3 normal : NORMAL; //法线信息 挤出用
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
                v.vertex.xyz += v.normal * 0.01; // 顶点位置法向挤出
                o.pos = TransformObjectToHClip(v.vertex); // 顶点位置 OS>CS
                o.uv0 = TRANSFORM_TEX(v.uv0, _Sequence); // 前置UV ST操作
                float id = floor(_Time.z * _Speed); // 计算序列id
                float idV = floor(id / _ColCount); // 计算V轴id，商，从上往下第几排
                float idU = id - idV * _ColCount; // 计算U轴id, 余数，第几个
                float stepU = 1.0 / _ColCount; // 计算U轴步幅 1.0/横向几列
                float stepV = 1.0 / _RowCount; // 计算V轴步幅 1.0/竖向几行
                float2 initUV = o.uv0 * float2(stepU, stepV) + float2(0.0, stepV * (_ColCount - 1.0)); // 计算初始UV
                o.uv0 = initUV + float2(idU * stepU, -idV * stepV); // 计算序列帧UV
                return o;
            }

            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR
            {
                half4 var_Sequence = SAMPLE_TEXTURE2D(_Sequence, sampler_Sequence, i.uv0); // 采样贴图 RGB颜色 A透贴不必须
                half3 finalRGB = var_Sequence.rgb;
                //half opacity = var_Sequence.a;
                half opacity = var_Sequence.a * _Opacity;
                return half4(finalRGB * opacity, opacity); // 返回值
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}