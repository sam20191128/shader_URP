Shader "URP/halfLambert+Phong" //Shader路径名
{
    Properties //材质面板参数
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainCol ("颜色", color) =(1.0,1.0,1.0,1.0)
        _SpecularPow ("高光次幂", Range(1,90)) =30
        _SpecularCol ("高光颜色", color) =(1.0,1.0,1.0,1.0)
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

            float4 _MainCol;

            float _SpecularPow;

            float4 _SpecularCol;

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
                float4 pos : SV_POSITION; // 齐次裁剪空间（屏幕空间）顶点位置
                float4 posWS : TEXCOORD0; // 世界空间顶点位置
                float3 nDirWS : TEXCOORD1; // 世界空间法线方向
                float2 uv0:TEXCOORD2;
            };

            VertexOutput vert(VertexInput v) //顶点shader
            {
                VertexOutput o = (VertexOutput)0; // 新建输出结构
                o.pos = TransformObjectToHClip(v.vertex); // 变换顶点位置 OS>CS
                o.posWS = mul(unity_ObjectToWorld, v.vertex); // 变换顶点位置 OS>WS
                o.nDirWS = TransformObjectToWorldNormal(v.normal); // 变换法线方向 OS>WS
                o.uv0 = TRANSFORM_TEX(v.uv0, _MainTex);
                return o; // 返回输出结构
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                //准备向量
                float3 nDir = i.nDirWS; // 获取nDir
                Light mylight = GetMainLight();
                float3 lDir = normalize(mylight.direction); // 获取lDir
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS); // 获取vDir
                float3 rDir = reflect(-lDir, nDir); // 获取rDir
                //准备点积结果
                float nDotl = dot(nDir, lDir); // nDir点积lDir
                float vDotr = dot(rDir, vDir);
                //光照模型
                float halfLambert = nDotl * 0.5 + 0.5; // 半兰伯特
                float Phong = pow(max(0.0, vDotr), _SpecularPow); // 高光
                float3 finalRGB = (_MainCol * halfLambert * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0) +
                    _SpecularCol * Phong) * mylight.color;
                //返回结果
                return float4(finalRGB, 1.0); // 输出最终颜色
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}