Shader "URP/UnlitShader" //Shader路径名
{
    Properties //材质面板参数
    {
        _MainTex("MainTex",2D)="White"{}

        _BaseColor("BaseColor",Color)=(1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
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
            #pragma vertex vert     //顶点着色器
            #pragma fragment frag   //片元着色器

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)

            float4 _MainTex_ST;
            half4 _BaseColor;

            CBUFFER_END

            TEXTURE2D(_MainTex);

            SAMPLER(sampler_MainTex);

            struct VertexInput //输入结构
            {
                float4 vertex : POSITION; // 将模型顶点信息输入进来
                float3 normal : NORMAL; // 将模型法线信息输入进来
                float2 uv0:TEXCOORD;
            };

            struct VertexOutput //输出结构
            {
                float4 pos : SV_POSITION; // 由模型顶点信息换算而来的顶点屏幕位置
                float2 uv0:TEXCOORD;
            };

            VertexOutput vert(VertexInput v) //顶点shader 
            {
                VertexOutput o = (VertexOutput)0; // 新建一个输出结构
                o.pos = TransformObjectToHClip(v.vertex); // 变换顶点信息 并将其塞给输出结构
                o.uv0 = TRANSFORM_TEX(v.uv0, _MainTex);
                return o; // 将输出结构 输出
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0) * _BaseColor;
                return tex; // 输出最终颜色
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}