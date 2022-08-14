Shader "URP/Cubemap" //Shader路径名
{
    Properties //材质面板参数
    {
        _Cubemap ("环境球", Cube) = "_Skybox" {}
        _NormalMap ("法线贴图", 2D) = "bump" {}
        _CubemapMip ("环境球Mip", Range(0, 7)) = 0
        _FresnelPow ("菲涅尔次幂", Range(0, 10)) = 1
        _EnvSpecInt ("环境镜面反射强度", Range(0, 5)) = 1
        _Occlusion ("AO图", 2D) = "white" {}
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

            CBUFFER_START(UnityPerMaterial) //缓冲区
            // 输入参数
            uniform float _CubemapMip;
            uniform float _FresnelPow;
            uniform float _EnvSpecInt;
            CBUFFER_END

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            TEXTURE2D(_Occlusion);
            SAMPLER(sampler_Occlusion);

            samplerCUBE _Cubemap;

            struct VertexInput //输入结构
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; // 切线信息
                float2 uv0 : TEXCOORD0;
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
                o.uv0 = v.uv0;
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                o.tDirWS = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w);
                return o;
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                //向量准备
                float3 nDirTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv0)).rgb; // 采样法线纹理并解码 切线空间nDir
                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS); // 构建TBN矩阵
                float3 nDirWS = normalize(mul(nDirTS, TBN)); // 世界空间nDir
                float3 nDirVS = mul(UNITY_MATRIX_V, float4(nDirWS, 0.0)); // 视空间nDir
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz); //计算菲涅尔
                float3 vrDirWS = reflect(-vDirWS, nDirWS);
                //中间量准备
                float ndotv = dot(nDirWS, vDirWS); //菲涅尔

                //光照模型
                float3 occlusion = SAMPLE_TEXTURE2D(_Occlusion, sampler_Occlusion, i.uv0).r;
                float3 cubemap = texCUBElod(_Cubemap, float4(vrDirWS, _CubemapMip));
                float frensel = pow(1.0 - ndotv, _FresnelPow);
                float3 envSpecLighting = cubemap * frensel * _EnvSpecInt * occlusion;

                //返回结果
                return float4(envSpecLighting, 1.0);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}