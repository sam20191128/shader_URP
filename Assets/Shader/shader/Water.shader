Shader "URP/Water" //Shader路径名
{
    Properties //材质面板参数
    {
        [Header(Diffuse)][Space(10)]
        _MainCol ("基础颜色", color) =(1.0,1.0,1.0,1.0)
        _Transparency ("透明度", Range(0, 1)) = 0.75

        [Header(Foam)][Space(10)]
        _FoamCol ("泡沫颜色", color) =(1.0,1.0,1.0,1.0)
        _FoamAmount("泡沫量", Float) = 1
        _FoamNoiseTex("泡沫噪声图", 2D) = "white" {}
        _FoamParams ("泡沫参数 X：大小 Y：流速X Z：流速Y ", vector) = (1.0, 1.0, 1.0, 1.0)

        [Header(Specular)][Space(10)]
        _SpecularPow ("高光次幂", Range(1,90)) =30
        _SpecularCol ("高光颜色", color) =(1.0,1.0,1.0,1.0)

        [Header(Fresnel)][Space(10)]
        _FresnelColor ("菲涅尔颜色", color) =(1.0,1.0,1.0,1.0)
        _FresnelPow ("菲涅尔次幂", Range(0, 5)) = 1

        [Header(Depth)][Space(10)]
        _DepthGradientShallow("深度渐变浅", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep("深度渐变深", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("深度最大距离", Float) = 1

        [Header(Normal)][Space(10)]
        [NoScaleOffset][Normal] _NormTex ("法线贴图", 2D) = "bump" {}
        _normalParams ("常规法线参数 X：大小 Y：流速X Z：流速Y W：强度", vector) = (1.0, 1.0, 0.5, 1.0)

        [Header(Warp)][Space(10)]
        _WarpTex ("扰动图", 2d) = "gray"{}
        _Warp1Params ("扰动法线1参数 X：大小 Y：流速X Z：流速Y W：强度", vector) = (1.0, 1.0, 0.5, 1.0)
        _Warp2Params ("扰动法线1参数 X：大小 Y：流速X Z：流速Y W：强度", vector) = (2.0, 0.5, 0.5, 1.0)

        [Header(Wavesstrength)][Space(10)]
        _WavesStrength ("顶点波纹上下浮动强度", Range(0, 1)) = 0.66

        [Header(Environment)][Space(10)]
        [NoScaleOffset] _Cubemap ("RGB:环境贴图", cube) = "_Skybox" {}
        _CubemapMip ("环境球Mip", Range(0, 7)) = 0

        [Header(Emission)][Space(10)]
        _EmitCol ("自发光颜色", color) =(1.0,1.0,1.0,1.0)
        _EmitInt ("自发光强度", range(0, 10)) = 1
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

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)

            // Diffuse
            uniform float4 _MainCol; //基础颜色
            uniform float _Transparency; //透明度
            //Foam
            uniform float4 _FoamCol; //泡沫颜色
            uniform float _FoamAmount; //泡沫量
            uniform float4 _FoamNoiseTex_ST; //泡沫噪声图ST
            uniform float4 _FoamParams; //泡沫参数
            // Specular
            uniform float4 _SpecularCol; //高光颜色
            uniform float _SpecularPow; //高光次幂
            //Depth
            uniform float4 _DepthGradientShallow; //深度渐变浅
            uniform float4 _DepthGradientDeep; //深度渐变深
            uniform float _DepthMaxDistance; //深度最大距离
            // Texture
            uniform float4 _normalParams; //常规法线参数
            uniform float4 _Warp1Params; //扰动1参数
            uniform float4 _Warp2Params; //扰动2参数
            uniform float _WavesStrength; //顶点波纹上下浮动强度
            //Fresnel
            uniform float3 _FresnelColor; //菲涅尔颜色
            uniform float _FresnelPow; //菲涅尔强度
            //_Cubemap
            uniform float _CubemapMip; //环境球Mip
            // Emission
            uniform float4 _EmitCol; //自发光颜色
            uniform float _EmitInt; //自发光强度

            CBUFFER_END

            // Texture
            TEXTURE2D(_FoamNoiseTex); //泡沫噪声图
            SAMPLER(sampler_FoamNoiseTex);

            TEXTURE2D(_NormTex); //法线贴图
            SAMPLER(sampler_NormTex);

            TEXTURE2D(_WarpTex); //扰动图
            SAMPLER(sampler_WarpTex);

            // DepthTexture
            TEXTURE2D_X_FLOAT(_CameraDepthTexture); //深度图
            SAMPLER(sampler_CameraDepthTexture);

            //_Cubemap
            samplerCUBE _Cubemap; //环境球

            struct VertexInput //输入结构
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 uv0 : TEXCOORD0;
            };

            struct VertexOutput //输出结构
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0; //默认UV
                float2 uv1 : TEXCOORD1; //扰动UV1
                float2 uv2 : TEXCOORD2; //扰动UV2
                float2 uv3 : TEXCOORD3; //泡沫UV
                float2 screenUV : TEXCOORD4; //屏幕空间UV

                float4 posWS : TEXCOORD5; // 世界空间顶点位置
                float3 nDirWS : TEXCOORD6; // 世界空间法线方向
                float3 tDirWS : TEXCOORD7; // 世界空间切线方向
                float3 bDirWS : TEXCOORD8; // 世界空间副切线方向
                float4 scrPos : TRXCOORD9; //屏幕空间顶点位置

                float3 normal : TRXCOORD10; //临时储存顶点里采样的法线
            };

            VertexOutput vert(VertexInput v) //顶点shader
            {
                VertexOutput o = (VertexOutput)0;

                //顶点
                o.pos = TransformObjectToHClip(v.vertex); // 顶点位置 OS>CS
                o.posWS = mul(unity_ObjectToWorld, v.vertex); // 顶点位置 OS>WS

                //TBN
                o.nDirWS = TransformObjectToWorldNormal(v.normal); // 法线方向 OS>WS
                o.tDirWS = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz); // 切线方向 OS>WS
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w); // 副切线方向

                //各种UV
                o.uv0 = v.uv0 * _normalParams.x - frac(_Time.x * _normalParams.yz); //常规UV
                o.uv1 = v.uv0 * _Warp1Params.x - frac(_Time.x * _Warp1Params.yz); // 扰动UV1 X：大小 Y：流速X Z：流速Y W：强度
                o.uv2 = v.uv0 * _Warp2Params.x - frac(_Time.x * _Warp2Params.yz); // 扰动UV2 X：大小 Y：流速X Z：流速Y W：强度
                o.uv3 = v.uv0 * _FoamParams.x - frac(_Time.x * _FoamParams.yz); // 泡沫 X：大小 Y：流速X Z：流速Y 

                //扰动
                half2 var_Warp1 = SAMPLE_TEXTURE2D_LOD(_WarpTex, sampler_WarpTex, o.uv1, 0); // 扰动1
                half2 var_Warp2 = SAMPLE_TEXTURE2D_LOD(_WarpTex, sampler_WarpTex, o.uv2, 0); // 扰动2
                half2 warp = (var_Warp1.xy - 0.5) * _Warp1Params.w + (var_Warp2.xy - 0.5) * _Warp2Params.w; // 扰动混合,采样出来的是0到1，- 0.5后变成-0.5到0.5，有正有负，有前有后
                float2 warpUV = o.uv0 + warp; // 扰动UV

                //在扰动UV上采样常规法线
                float3 var_NormTex = UnpackNormal(SAMPLE_TEXTURE2D_LOD(_NormTex, sampler_NormTex, warpUV, 0));

                //顶点偏移
                o.pos.xyz += v.normal * var_NormTex * _WavesStrength;

                //屏幕顶点位置-黑盒版
                // VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                // o.scrPos = ComputeScreenPos(vertexInput.positionCS);

                //屏幕顶点位置
                o.scrPos = o.pos * 0.5f; //xyzw都÷2，找到中点位置
                o.scrPos.xy = float2(o.scrPos.x, o.scrPos.y * _ProjectionParams.x) + o.scrPos.w;
                o.scrPos.zw = o.pos.zw;
                o.screenUV = o.scrPos.xy / o.scrPos.w;

                //传递采样法线
                o.normal = var_NormTex; //常规法线

                return o;
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                float3 nDirTS = i.normal; //顶点采样的法线传递过来

                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS); //TBN矩阵
                float3 nDirWS = normalize(mul(nDirTS, TBN)); //法线方向
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz); //视方向
                float3 vrDirWS = reflect(-vDirWS, nDirWS); //反射方向

                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.posWS)); //获取灯光
                float3 lDirWS = normalize(mylight.direction); //灯光方向
                float3 hDir = normalize(vDirWS + lDirWS); //半角向量

                // 准备点积结果
                float ndotl = dot(nDirWS, lDirWS); //lambert=dot(法线方向, 灯光方向)
                float vdotn = dot(vDirWS, nDirWS); //dot(视方向, 法线方向)——用于菲涅尔
                float nDoth = dot(nDirWS, hDir); //dot(法线方向, 半角向量)——用于blinnPhong

                // 采样纹理
                float4 var_FoamNoiseTex = SAMPLE_TEXTURE2D(_FoamNoiseTex, sampler_FoamNoiseTex, i.uv3);

                // 采样Cubemap
                float3 var_Cubemap = texCUBElod(_Cubemap, float4(vrDirWS, _CubemapMip)).rgb;

                // 光照模型(直接光照部分)
                float lambert = max(0.0, ndotl);
                float blinnPhong = pow(max(0.0, nDoth), _SpecularPow); // 高光
                float3 dirLighting = _MainCol * lambert * mylight.shadowAttenuation * mylight.color * _Transparency + _SpecularCol * blinnPhong * mylight.shadowAttenuation;

                // 光照模型(环境光照部分)
                float fresnel = pow(max(0.0, 1.0 - vdotn), _FresnelPow); // 菲涅尔系数

                float3 envLighting = var_Cubemap * fresnel + _FresnelColor * fresnel; // Cubemap × 菲涅尔系数 + 菲涅尔颜色 × 菲涅尔系数

                //深度渐变开始
                float depth0 = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, i.screenUV).r; // 采样深度值
                float depth = LinearEyeDepth(depth0, _ZBufferParams); // 线性深度
                float depthDifference = depth - i.scrPos.w; // 不同深度值
                //将颜色值规范到0~1之间时，saturate函数saturate(x)的作用是如果x取值小于0，则返回值为0。如果x取值大于1，则返回值为1。若x在0到1之间，则直接返回x的值.
                float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance); //规范到0~1之间，不同深度值/深度最大距离=深度百分比
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference01); // lerp(深度渐变浅, 深度渐变深, 深度百分比)

                //泡沫
                float waterDepthDifference02 = saturate(depthDifference / _FoamAmount); //规范到0~1之间，不同深度值/深度最大距离=深度百分比
                float foamAlpha = mul(step(waterDepthDifference02, var_FoamNoiseTex), _FoamCol.a);
                float4 waterColor2 = lerp(waterColor, _FoamCol, foamAlpha); // lerp(深度渐变浅, 泡沫颜色, 泡沫alpha)

                // 光照模型(自发光部分)
                //float3 emission = waterColor * _EmitCol * _EmitInt * (sin(_Time.z) * 0.5 + 0.5); //动态发光版
                float3 emission = waterColor * _EmitCol * _EmitInt;

                // 返回结果
                float3 finalRGB = dirLighting + envLighting + waterColor2 + emission; //  直接光照部分 + 环境光照部分 + 泡沫 + 自发光部分

                return float4(finalRGB, _Transparency);
            }
            ENDHLSL
        }
        //UsePass "Universal Render Pipeline/Lit/DepthOnly"
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}