Shader "URP/HalfLambert" //Shader路径名
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
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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
                float2 uv0:TEXCOORD0;
                float3 nDirWS : TEXCOORD1; // 由模型法线信息换算来的世界空间法线信息
            };

            VertexOutput vert(VertexInput v) //顶点shader
            {
                VertexOutput o = (VertexOutput)0; // 新建一个输出结构
                o.pos = TransformObjectToHClip(v.vertex); // 变换顶点信息 并将其塞给输出结构
                o.uv0 = TRANSFORM_TEX(v.uv0, _MainTex);
                o.nDirWS = TransformObjectToWorldNormal(v.normal, true); // 变换法线信息 并将其塞给输出结构
                return o; // 将输出结构 输出
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                float3 nDir = i.nDirWS; // 获取nDir

                Light mylight = GetMainLight();

                float4 LightColor = float4(mylight.color, 1);
                float3 lDir = normalize(mylight.direction);

                float nDotl = dot(nDir, lDir); // nDir点积lDir

                float halfLambert = nDotl * 0.5 + 0.5; // 半兰伯特

                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0) * _BaseColor;

                return tex * halfLambert * LightColor; //半兰伯特光照模型
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}