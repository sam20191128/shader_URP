Shader "URP/Matcap" //Shader路径名
{
    Properties //材质面板参数
    {
        _NormalMap ("法线贴图", 2D) = "bump" {}
        _Matcap ("Matcap", 2D) = "gray" {}
        _FresnelPow ("菲涅尔次幂", Range(0, 10)) = 1
        _EnvSpecInt ("环境镜面反射强度", Range(0, 5)) = 1
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //CBUFFER_START和CBUFFER_END,对于变量是单个材质独有的时候建议放在这里面，以提高性能。
            //CBUFFER(常量缓冲区)的空间较小，不适合存放纹理贴图这种大量数据的数据类型，适合存放float，half之类的不占空间的数据，关于它的官方文档在下有详细说明。
            //https://blogs.unity3d.com/2019/02/28/srp-batcher-speed-up-your-rendering
            CBUFFER_START(UnityPerMaterial) //缓冲区
            // 输入参数
            float _FresnelPow;
            float _EnvSpecInt;
            float4 _NormalMap_ST;
            CBUFFER_END

            //纹理采样
            //新的DXD11 HLSL贴图的采样函数和采样器函数，TEXTURE2D (_MainTex)和SAMPLER(sampler_MainTex)，
            //用来定义采样贴图和采样状态代替原来DXD9的sampler2D，在不同的平台有不同的变化，在GLcore库函数里定义。
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            TEXTURE2D(_Matcap);
            SAMPLER(sampler_Matcap);

            struct VertexInput //输入结构
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL; // 将模型法线信息输入进来
                float4 tangent : TANGENT; // 构建TBN矩阵 需要模型切线信息
                float2 uv0 : TEXCOORD0; // 需要UV坐标 采样法线贴图
            };

            struct VertexOutput //输出结构
            {
                float4 pos : SV_POSITION;
                float3 posWS : TEXCOORD0;
                float2 uv0 : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
                float3 tDirWS : TEXCOORD3; // 世界切线方向
                float3 bDirWS : TEXCOORD4; // 世界副切线方向
            };

            VertexOutput vert(VertexInput v) //顶点shader
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(v.vertex);
                o.uv0 = TRANSFORM_TEX(v.uv0, _NormalMap);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                o.tDirWS = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w);
                return o;
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                //向量准备
                float3 nDirTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_Matcap, i.uv0)).rgb;
                // 采样法线纹理并解码 切线空间nDir
                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS); // 构建TBN矩阵
                float3 nDirWS = normalize(mul(nDirTS, TBN)); // 世界空间nDir
                float3 nDirVS = mul(UNITY_MATRIX_V, float4(nDirWS, 0.0)); // 视空间nDir
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz); //计算菲涅尔

                //中间量准备
                float2 matcapUV = nDirVS.rg * 0.5 + 0.5;
                float ndotv = dot(nDirWS, vDirWS); //菲涅尔

                //光照模型
                float3 matcap = SAMPLE_TEXTURE2D(_Matcap, sampler_Matcap, matcapUV);
                float frensel = pow(1.0 - ndotv, _FresnelPow);
                float3 envSpecLighting = matcap * frensel * _EnvSpecInt;

                //返回结果
                return float4(envSpecLighting, 1.0);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}