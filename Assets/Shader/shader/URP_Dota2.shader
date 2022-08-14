Shader "URP/Dota2" //Shader路径名
{
    Properties //材质面板参数
    {
        [Header(Texture)][Space(50)]
        _MainTex ("RGB:颜色 A:透贴", 2d) = "white"{}
        _MaskTex ("R:高光强度 G:边缘光强度 B:高光染色 A:高光次幂", 2d) = "black"{}
        _NormTex ("RGB:法线贴图", 2d) = "bump"{}
        _MatelnessMask ("金属度遮罩", 2d) = "black"{}
        _EmissionMask ("自发光遮罩", 2d) = "black"{}
        _DiffWarpTex ("颜色Warp图", 2d) = "gray"{}
        _FresWarpTex ("菲涅尔Warp图", 2d) = "gray"{}
        _Cubemap ("环境球", cube) = "_Skybox"{}

        [Header(DirDiff)]
        _LightCol ("光颜色", color) = (1.0, 1.0, 1.0, 1.0)

        [Header(DirSpec)][Space(50)]
        _SpecPow ("高光次幂", range(0.0, 99.0)) = 5
        _SpecInt ("高光强度", range(0.0, 10.0)) = 5

        [Header(EnvDiff)][Space(50)]
        _EnvCol ("环境光颜色", color) = (1.0, 1.0, 1.0, 1.0)

        [Header(EnvSpec)][Space(50)]
        _EnvSpecInt ("环境镜面反射强度", range(0.0, 30.0)) = 0.5

        [Header(RimLight)][Space(50)]
        [HDR]_RimCol ("轮廓光颜色", color) = (1.0, 1.0, 1.0, 1.0)

        [Header(Emission)][Space(50)]
        _EmitInt ("自发光强度", range(0.0, 10.0)) = 1.0

        [HideInInspector]
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5

        [HideInInspector]
        _Color ("Main Color", Color) = (1.0, 1.0, 1.0, 1.0) //不声明，阴影错误

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
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            //CBUFFER_START和CBUFFER_END,对于变量是单个材质独有的时候建议放在这里面，以提高性能。
            //CBUFFER(常量缓冲区)的空间较小，不适合存放纹理贴图这种大量数据的数据类型，适合存放float，half之类的不占空间的数据，关于它的官方文档在下有详细说明。
            //https://blogs.unity3d.com/2019/02/28/srp-batcher-speed-up-your-rendering
            CBUFFER_START(UnityPerMaterial) //缓冲区
            // Texture
            uniform float4 _MainTex_ST;
            // DirDiff
            uniform half3 _LightCol;
            // DirSpec
            uniform half _SpecPow;
            uniform half _SpecInt;
            uniform half _CubemapMip;
            // EnvDiff
            uniform half3 _EnvCol;
            // EnvSpec
            uniform half _EnvSpecInt;
            // RimLight
            uniform half3 _RimCol;
            // Emission
            uniform half _EmitInt;
            // Other
            uniform half _Cutoff;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            TEXTURE2D(_MaskTex);
            TEXTURE2D(_NormTex);
            TEXTURE2D(_MatelnessMask);
            TEXTURE2D(_EmissionMask);
            TEXTURE2D(_DiffWarpTex);
            TEXTURE2D(_FresWarpTex);
            TEXTURE2D(_SpecTex);
            TEXTURE2D(_EmitTex);
            samplerCUBE _Cubemap;

            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_MaskTex);
            SAMPLER(sampler_NormTex);
            SAMPLER(sampler_MatelnessMask);
            SAMPLER(sampler_EmissionMask);
            SAMPLER(sampler_DiffWarpTex);
            SAMPLER(sampler_FresWarpTex);
            SAMPLER(sampler_SpecTex);
            SAMPLER(sampler_EmitTex);


            //输入结构
            struct VertexInput
            {
                float4 vertex : POSITION; // 顶点信息 Get✔
                float2 uv0 : TEXCOORD0; // UV信息 Get✔
                float4 normal : NORMAL; // 法线信息 Get✔
                float4 tangent : TANGENT; // 切线信息 Get✔
            };

            //输出结构
            struct VertexOutput
            {
                float4 pos : SV_POSITION; // 屏幕顶点位置
                float2 uv0 : TEXCOORD0; // UV0
                float4 posWS : TEXCOORD1; // 世界空间顶点位置
                float3 nDirWS : TEXCOORD2; // 世界空间法线方向
                float3 tDirWS : TEXCOORD3; // 世界空间切线方向
                float3 bDirWS : TEXCOORD4; // 世界空间副切线方向
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0; // 新建输出结构
                o.pos = TransformObjectToHClip(v.vertex); // 顶点位置 OS>CS
                //o.uv0 = v.uv0; // 传递UV
                o.uv0 = v.uv0 * _MainTex_ST.xy + _MainTex_ST.zw; // 传递UV
                o.posWS = mul(unity_ObjectToWorld, v.vertex); // 顶点位置 OS>WS
                o.nDirWS = TransformObjectToWorldNormal(v.normal); // 法线方向 OS>WS
                o.tDirWS = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz); // 切线方向 OS>WS
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w); // 副切线方向
                return o; // 返回输出结构
            }

            half4 frag(VertexOutput i) : COLOR //像素shader
            {
                // 向量准备
                half3 nDirTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormTex, sampler_NormTex, i.uv0));
                half3x3 TBN = half3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                half3 nDirWS = normalize(mul(nDirTS, TBN));
                half3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
                half3 vrDirWS = reflect(-vDirWS, nDirWS);
                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.posWS));
                float3 lDirWS = normalize(mylight.direction);
                half3 lrDirWS = reflect(-lDirWS, nDirWS);
                // 中间量准备
                half ndotl = dot(nDirWS, lDirWS);
                half ndotv = dot(nDirWS, vDirWS);
                half vdotr = dot(vDirWS, lrDirWS);
                // 采样纹理
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
                half4 var_MaskTex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv0);
                half var_MatelnessMask = SAMPLE_TEXTURE2D(_MatelnessMask, sampler_MatelnessMask, i.uv0).r;
                half var_EmissionMask = SAMPLE_TEXTURE2D(_EmissionMask, sampler_EmissionMask, i.uv0).r;
                half3 var_FresWarpTex = SAMPLE_TEXTURE2D(_FresWarpTex, sampler_FresWarpTex, ndotv);
                half3 var_Cubemap = texCUBElod(_Cubemap, float4(vrDirWS, lerp(8.0, 0.0, var_MaskTex.a))).rgb;
                // 提取信息
                half3 baseCol = var_MainTex.rgb;
                half opacity = var_MainTex.a;
                half specInt = var_MaskTex.r;
                half rimInt = var_MaskTex.g;
                half specTint = var_MaskTex.b;
                half specPow = var_MaskTex.a;
                half matellic = var_MatelnessMask;
                half emitInt = var_EmissionMask;
                half3 envCube = var_Cubemap;
                // 光照模型
                // 漫反射颜色 镜面反射颜色
                half3 diffCol = lerp(baseCol, half3(0.0, 0.0, 0.0), matellic);
                half3 specCol = lerp(baseCol, half3(0.3, 0.3, 0.3), specTint);
                // 菲涅尔
                half3 fresnel = lerp(var_FresWarpTex, 0.0, matellic);
                half fresnelCol = fresnel.r; // 无实际用途
                half fresnelRim = fresnel.g;
                half fresnelSpec = fresnel.b;
                // 光源漫反射
                half halfLambert = ndotl * 0.5 + 0.5;
                half3 var_DiffWarpTex = SAMPLE_TEXTURE2D(_DiffWarpTex, sampler_DiffWarpTex, half2(halfLambert, 0.2));
                half3 dirDiff = diffCol * var_DiffWarpTex * mylight.shadowAttenuation * mylight.color;
                // 光源镜面反射
                half phong = pow(max(0.0, vdotr), specPow * _SpecPow);
                half spec = phong * max(0.0, ndotl);
                spec = max(spec, fresnelSpec);
                spec = spec * _SpecInt;
                half3 dirSpec = specCol * spec * mylight.shadowAttenuation;
                // 环境漫反射
                half3 envDiff = diffCol * _EnvCol;
                // 环境镜面反射
                half reflectInt = max(fresnelSpec, matellic) * specInt;
                half3 envSpec = specCol * reflectInt * envCube * _EnvSpecInt;
                // 轮廓光
                half3 rimLight = _RimCol * fresnelRim * rimInt * max(0.0, nDirWS.g);
                // 自发光
                half3 emission = diffCol * emitInt * _EmitInt;
                // 混合
                half3 finalRGB = dirDiff + dirSpec + envDiff + envSpec + rimLight + emission;
                // 透明剪切
                clip(opacity - _Cutoff);
                // 返回值
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