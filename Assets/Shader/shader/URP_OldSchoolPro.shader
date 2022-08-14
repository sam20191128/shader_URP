Shader "URP/OldSchoolPro" //Shader路径名
{
    Properties //材质面板参数
    {
        [Header(Texture)][Space(50)]
        _MainTex ("RGB:基础颜色 A:环境遮罩", 2D) = "white" {}
        [NoScaleOffset][Normal] _NormTex ("RGB:法线贴图", 2D) = "bump" {}
        [NoScaleOffset] _SpecTex ("RGB:高光颜色 A:高光次幂", 2D) = "gray" {}
        [NoScaleOffset] _EmitTex ("RGB:环境贴图", 2D) = "black" {}
        [NoScaleOffset] _Cubemap ("RGB:环境贴图", cube) = "_Skybox" {}

        [Header(Diffuse)][Space(50)]
        _MainCol ("基本色", Color) = (0.5, 0.5, 0.5, 1.0)
        _EnvDiffInt ("环境漫反射强度", Range(0, 1)) = 0.2
        _NormalScale("NormalScale",Range(0,1))=1
        [HDR] _EnvUpCol ("环境天顶颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        [HDR] _EnvSideCol ("环境水平颜色", Color) = (0.5, 0.5, 0.5, 1.0)
        [HDR] _EnvDownCol ("环境地表颜色", Color) = (0.0, 0.0, 0.0, 0.0)

        [Header(Specular)][Space(50)]
        [PowerSlider(2)] _SpecPow ("高光次幂", Range(1, 90)) = 30
        _EnvSpecInt ("环境镜面反射强度", Range(0, 5)) = 0.2
        _FresnelPow ("菲涅尔次幂", Range(0, 5)) = 1
        _CubemapMip ("环境球Mip", Range(0, 7)) = 0

        [Header(Emission)][Space(50)]
        _EmitInt ("自发光强度", range(1, 10)) = 1

        [Header(Outline)][Space(50)]
        _outlinecolor ("outline color", Color) = (0,0,0,1)
        _outlinewidth ("outline width", Range(0, 1)) = 0.01
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
            #include "MyHlslinc.hlslinc"

            //CBUFFER_START和CBUFFER_END,对于变量是单个材质独有的时候建议放在这里面，以提高性能。
            //CBUFFER(常量缓冲区)的空间较小，不适合存放纹理贴图这种大量数据的数据类型，适合存放float，half之类的不占空间的数据，关于它的官方文档在下有详细说明。
            //https://blogs.unity3d.com/2019/02/28/srp-batcher-speed-up-your-rendering
            CBUFFER_START(UnityPerMaterial) //缓冲区
            // Texture
            uniform float4 _MainTex_ST;
            // Diffuse
            uniform float3 _MainCol;
            real _NormalScale;
            uniform float _EnvDiffInt;
            uniform float3 _EnvUpCol;
            uniform float3 _EnvSideCol;
            uniform float3 _EnvDownCol;
            // Specular
            uniform float _SpecPow;
            uniform float _FresnelPow;
            uniform float _EnvSpecInt;
            uniform float _CubemapMip;
            // Emission
            uniform float _EmitInt;
            CBUFFER_END

            //纹理采样
            //新的DXD11 HLSL贴图的采样函数和采样器函数，TEXTURE2D (_MainTex)和SAMPLER(sampler_MainTex)，
            //用来定义采样贴图和采样状态代替原来DXD9的sampler2D，在不同的平台有不同的变化，在GLcore库函数里定义。

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_NormTex);
            SAMPLER(sampler_NormTex);

            TEXTURE2D(_SpecTex);
            SAMPLER(sampler_SpecTex);

            TEXTURE2D(_EmitTex);
            SAMPLER(sampler_EmitTex);

            samplerCUBE _Cubemap;


            struct VertexInput //输入结构
            {
                float4 vertex : POSITION; // 顶点信息 Get✔
                float2 uv0 : TEXCOORD0; // UV信息 Get✔
                float4 normal : NORMAL; // 法线信息 Get✔
                float4 tangent : TANGENT; // 切线信息 Get✔
            };

            struct VertexOutput //输出结构
            {
                float4 pos : SV_POSITION; // 屏幕顶点位置
                float2 uv0 : TEXCOORD0; // UV0
                float4 posWS : TEXCOORD1; // 世界空间顶点位置
                float3 nDirWS : TEXCOORD2; // 世界空间法线方向
                float3 tDirWS : TEXCOORD3; // 世界空间切线方向
                float3 bDirWS : TEXCOORD4; // 世界空间副切线方向
            };

            //贴图的采用输出函数采用DXD11 HLSL下的   SAMPLE_TEXTURE2D(textureName, samplerName, coord2) ，
            //具有三个变量，分别是TEXTURE2D (_MainTex)的变量和SAMPLER(sampler_MainTex)的变量和uv，
            //用来代替原本DXD9的TEX2D(_MainTex,texcoord)。 

            VertexOutput vert(VertexInput v) //顶点shader
            {
                VertexOutput o = (VertexOutput)0; // 新建输出结构
                o.pos = TransformObjectToHClip(v.vertex); // 顶点位置 OS>CS
                o.uv0 = v.uv0 * _MainTex_ST.xy + _MainTex_ST.zw; // 传递UV
                o.posWS = mul(unity_ObjectToWorld, v.vertex); // 顶点位置 OS>WS
                o.nDirWS = TransformObjectToWorldNormal(v.normal); // 法线方向 OS>WS
                o.tDirWS = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz); // 切线方向 OS>WS
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w); // 副切线方向
                return o; // 返回输出结构
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                // 准备向量
                float3 nDirTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormTex, sampler_NormTex, i.uv0), _NormalScale);
                // 采样法线纹理并解码 切线空间nDir
                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                float3 nDirWS = normalize(mul(nDirTS, TBN));
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float3 vrDirWS = reflect(-vDirWS, nDirWS);

                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.posWS));
                float3 lDirWS = normalize(mylight.direction);
                float3 lrDirWS = reflect(-lDirWS, nDirWS);

                // 准备点积结果
                float ndotl = dot(nDirWS, lDirWS);
                float vdotr = dot(vDirWS, lrDirWS);
                float vdotn = dot(vDirWS, nDirWS);

                // 采样纹理
                float4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
                float4 var_SpecTex = SAMPLE_TEXTURE2D(_SpecTex, sampler_SpecTex, i.uv0);
                float3 var_EmitTex = SAMPLE_TEXTURE2D(_EmitTex, sampler_EmitTex, i.uv0).rgb;
                float3 var_Cubemap = texCUBElod(_Cubemap, float4(vrDirWS, lerp(_CubemapMip, 0.0, var_SpecTex.a))).rgb;
                // 采样Cubemap

                // 光照模型(直接光照部分)
                float3 baseCol = var_MainTex.rgb;
                float lambert = max(0.0, ndotl);

                float specCol = var_SpecTex.rgb;
                float specPow = lerp(1, _SpecPow, var_SpecTex.a);
                float phong = pow(max(0.0, vdotr), specPow);


                float3 dirLighting = baseCol * lambert * mylight.shadowAttenuation * mylight.color + specCol * phong *
                    mylight.shadowAttenuation;

                // 光照模型(环境光照部分)
                float3 envCol = TriColAmbient(nDirWS, _EnvUpCol, _EnvSideCol, _EnvDownCol);

                float fresnel = pow(max(0.0, 1.0 - vdotn), _FresnelPow); // 菲涅尔

                float occlusion = var_MainTex.a;

                float3 envLighting = (baseCol * envCol * _EnvDiffInt + var_Cubemap * fresnel * _EnvSpecInt * var_SpecTex
                    .a) * occlusion;

                // 光照模型(自发光部分)
                float3 emission = var_EmitTex * _EmitInt * (sin(_Time.z) * 0.5 + 0.5);

                // 返回结果
                float3 finalRGB = dirLighting + envLighting + emission;

                return half4(finalRGB, 1.0);
            }
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            Tags
            {
            }
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial) //缓冲区
            //Outline
            uniform float4 _outlinecolor;
            uniform float _outlinewidth;
            CBUFFER_END

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct VertexOutput
            {
                float4 pos : SV_POSITION;
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(float4(v.vertex.xyz + v.normal * _outlinewidth, 1));
                return o;
            }

            float4 frag(VertexOutput i) : COLOR
            {
                return float4(_outlinecolor.rgb, 0);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}