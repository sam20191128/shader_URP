Shader "URP/CyberPunk" //Shader路径名
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

        [Header(Effect)]
        _EffMap01 ("特效纹理1", 2D) = "gray" {}
        _EffMap02 ("特效纹理2", 2D) = "gray" {}
        [HDR]_EffCol ("光效颜色", color) = (0.0, 0.0, 0.0, 0.0)
        _EffParams ("X:波密度 Y:波速度 Z:混乱度 W:消散强度", vector) = (0.03, 3.0, 0.3, 2.5)
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
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

            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            // #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

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
            // Effect
            uniform float3 _EffCol;
            uniform float4 _EffParams;
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

            TEXTURE2D(_EffMap01);
            SAMPLER(sampler_EffMap01);

            TEXTURE2D(_EffMap02);
            SAMPLER(sampler_EffMap02);

            samplerCUBE _Cubemap;


            struct VertexInput //输入结构
            {
                float4 vertex : POSITION; // 顶点信息 Get✔
                float2 uv0 : TEXCOORD0; // UV信息 Get✔
                float2 uv1 : TEXCOORD1; // UV信息 Get✔
                float4 normal : NORMAL; // 法线信息 Get✔
                float4 tangent : TANGENT; // 切线信息 Get✔
                float4 color : COLOR; // 追加顶点色信息
            };

            struct VertexOutput //输出结构
            {
                float4 pos : SV_POSITION; // 屏幕顶点位置
                float2 uv0 : TEXCOORD0; // UV0
                float2 uv1 : TEXCOORD1; // UV1
                float4 posWS : TEXCOORD2; // 世界空间顶点位置
                float3 nDirWS : TEXCOORD3; // 世界空间法线方向
                float3 tDirWS : TEXCOORD4; // 世界空间切线方向
                float3 bDirWS : TEXCOORD5; // 世界空间副切线方向
                float4 effectMask : TEXCOORD6; // 追加effectMask输出
            };

            // 动画方法 inout顶点信息 返回effct相关遮罩
            float4 CyberpunkAnim(float noise, float mask, float3 normal, inout float3 vertex)
            {
                // 生成锯齿波Mask
                //vertex.y * _EffParams.x 波密度   * _EffParams.y 波速度
                float baseMask = abs(frac(vertex.y * _EffParams.x - _Time.x * _EffParams.y) - 0.5) * 2.0;
                baseMask = min(1.0, baseMask * 2.0); //让不透明更多，* 2.0 变成0到2，从1截断，变成1到2,此时为梯形波
                // 用Noise偏移锯齿波
                baseMask += (noise - 0.5) * _EffParams.z; //noise采出来是0到1，- 0.5变为-0.5到0.5，可以加减，* _EffParams.z 混乱度
                // SmoothStep出各级Mask，smoothstep可以把梯形波平滑，做出三个范围不同的波形
                float4 effectMask = float4(0.0, 0.0, 0.0, 0.0);
                effectMask.x = smoothstep(0.0, 0.9, baseMask);
                effectMask.y = smoothstep(0.2, 0.7, baseMask);
                effectMask.z = smoothstep(0.4, 0.5, baseMask);
                // 将顶点色遮罩存入EffectMask
                effectMask.w = mask;
                // 计算顶点动画
                vertex.xz += normal.xz * (1.0 - effectMask.y) * _EffParams.w * mask;
                //(1.0 - effectMask.y) mask反向，白色不膨胀，黑色膨胀
                // 返回EffectMask
                return effectMask;
            }

            //贴图的采用输出函数采用DXD11 HLSL下的   SAMPLE_TEXTURE2D(textureName, samplerName, coord2) ，
            //具有三个变量，分别是TEXTURE2D (_MainTex)的变量和SAMPLER(sampler_MainTex)的变量和uv，
            //用来代替原本DXD9的TEX2D(_MainTex,texcoord)。 

            VertexOutput vert(VertexInput v) //顶点shader
            {
                // 采样纹理
                float noise = SAMPLE_TEXTURE2D_LOD(_EffMap02, sampler_EffMap02, v.uv1, 0).r; //采样纹理的 mip 级别

                // 输出结构
                VertexOutput o = (VertexOutput)0;
                // 计算顶点动画 同时获取EffectMask
                o.effectMask = CyberpunkAnim(noise, v.color.r, v.normal.xyz, v.vertex.xyz);
                o.pos = TransformObjectToHClip(v.vertex); // 顶点位置 OS>CS
                o.uv0 = v.uv0 * _MainTex_ST.xy + _MainTex_ST.zw; // 传递UV
                o.uv1 = v.uv1;
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

                // 特效部分
                // 采样EffMap02
                float3 _EffMap01_var = SAMPLE_TEXTURE2D(_EffMap01, sampler_EffMap01, i.uv1).xyz;
                float meshMask = _EffMap01_var.x;
                float faceRandomMask = _EffMap01_var.y;
                float faceSlopeMask = _EffMap01_var.z;
                // 获取EffectMask
                float smallMask = i.effectMask.x;
                float midMask = i.effectMask.y;
                float bigMask = i.effectMask.z;
                float baseMask = i.effectMask.w;
                // 计算Opacity
                //（0到0.999999范围）+（0到1范围）=（0到1.999999范围），floor,小于1时为0，大于1时为1，要么透明，要么不透明
                float midOpacity = saturate(floor(min(faceRandomMask, 0.999999) + midMask));
                float bigOpacity = saturate(floor(min(faceSlopeMask, 0.999999) + bigMask));
                float opacity = lerp(1.0, min(bigOpacity, midOpacity), baseMask);
                // 叠加自发光
                float meshEmitInt = (bigMask - smallMask) * meshMask; //自发光强度
                meshEmitInt = meshEmitInt * meshEmitInt; //乘自己一遍，范围更集中
                emission += _EffCol * meshEmitInt * baseMask;
                // 返回结果
                float3 finalRGB = dirLighting + envLighting + emission;
                return float4(finalRGB * opacity, opacity);
            }
            ENDHLSL
        }

        //        Pass
        //        {
        //            Name "Outline"
        //            Tags
        //            {
        //            }
        //            Cull Front
        //
        //            HLSLPROGRAM
        //            #pragma vertex vert
        //            #pragma fragment frag
        //
        //            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //
        //            CBUFFER_START(UnityPerMaterial) //缓冲区
        //            //Outline
        //            uniform float4 _outlinecolor;
        //            uniform float _outlinewidth;
        //            CBUFFER_END
        //
        //            struct VertexInput
        //            {
        //                float4 vertex : POSITION;
        //                float3 normal : NORMAL;
        //            };
        //
        //            struct VertexOutput
        //            {
        //                float4 pos : SV_POSITION;
        //            };
        //
        //            VertexOutput vert(VertexInput v)
        //            {
        //                VertexOutput o = (VertexOutput)0;
        //                o.pos = TransformObjectToHClip(float4(v.vertex.xyz + v.normal * _outlinewidth, 1));
        //                return o;
        //            }
        //
        //            float4 frag(VertexOutput i) : COLOR
        //            {
        //                return float4(_outlinecolor.rgb, 0);
        //            }
        //            ENDHLSL
        //        }
        //
        //        Pass
        //        {
        //            Name "Shadow"
        //            Tags
        //            {
        //                "LightMode"="ShadowCaster"
        //            }
        //
        //            ZWrite On
        //            ZTest LEqual
        //            Cull[_Cull]
        //
        //            HLSLPROGRAM
        //            #pragma prefer_hlslcc gles
        //            #pragma exclude_renderers d3d11_9x
        //            #pragma target 3.0
        //
        //            #pragma shader_feature _ALPHATEST_ON
        //            #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA
        //
        //            #pragma multi_compile_instancing
        //
        //            #pragma vertex ShadowPassVertex
        //            #pragma fragment ShadowPassFragment
        //
        //            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
        //            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
        //            ENDHLSL
        //        }
        //        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}