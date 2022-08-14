Shader "URP/HLSLmoban" //Shader路径名
{
    Properties //材质面板参数
    {
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


            CBUFFER_END

            struct VertexInput //输入结构
            {
                float4 vertex : POSITION;
            };

            struct VertexOutput //输出结构
            {
                float4 pos : SV_POSITION;
            };

            VertexOutput vert(VertexInput v) //顶点shader
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(v.vertex);
                return o;
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                return float4(0.1, 0.5, 0.1, 1.0);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}