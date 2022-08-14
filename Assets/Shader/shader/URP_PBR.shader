Shader "URP/PBR"//Shader路径名
{
    Properties//材质面板参数

    {

        _BaseColor("BaseColor",Color)=(1,1,1,1)

        _BaseMap("BaseMap",2D)="white"{}

        [NoScaleOffset]_MaskMap("MaskMap",2D)="white"{} //R通道为金属，G通道为AO，A为光滑度

        [NoScaleOffset][Normal]_NormalMap("NormalMap",2D)="Bump"{}

        _NormalScale("NormalScale",Range(0,1))=0

    }

    SubShader

    {

        Tags
        {

            "RenderPipeline"="UniversalRenderPipeline"

        }
        pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
                "RenderType"="Opaque"
            }

            HLSLPROGRAM
            #pragma vertex vert

            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "PbrFunction.hlsl"

            CBUFFER_START(UnityPerMaterial) //缓冲区

            float4 _BaseMap_ST;

            real4 _BaseColor;

            float _NormalScale;

            CBUFFER_END

            //纹理采样
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_MaskMap);
            SAMPLER(sampler_MaskMap);

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            //输入结构
            struct VertexInput
            {
                float4 vertex:POSITION;

                float4 normal:NORMAL;

                float2 uv0:TEXCOORD;

                float4 tangent:TANGENT;

                float2 lightmapUV:TEXCOORD2; //一般来说是2uv是lightmap 这里取3uv比较保险
            };

            //输出结构
            struct VertexOutput
            {
                float4 pos:SV_POSITION;

                float4 uv0:TEXCOORD;

                float4 nDirWS:NORMAL;

                float4 tDirWS:TANGENT;

                float4 bDirWS:TEXCOORD1;

                float4 posWS : TEXCOORD2; // 世界空间顶点位置
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;

                o.pos = TransformObjectToHClip(v.vertex.xyz);

                o.uv0.xy = TRANSFORM_TEX(v.uv0, _BaseMap);

                o.uv0.zw = v.lightmapUV;

                o.nDirWS.xyz = normalize(TransformObjectToWorldNormal(v.normal.xyz));

                o.tDirWS.xyz = normalize(TransformObjectToWorldDir(v.tangent.xyz));

                o.bDirWS.xyz = cross(o.nDirWS.xyz, o.tDirWS.xyz) * v.tangent.w * unity_WorldTransformParams.
                    w;

                //float3 posWS = TransformObjectToWorld(v.positionOS.xyz);
                o.posWS = mul(unity_ObjectToWorld, v.vertex); // 顶点位置 OS>WS

                o.nDirWS.w = o.posWS.x;

                o.tDirWS.w = o.posWS.y;

                o.bDirWS.w = o.posWS.z;


                return o;
            }

            //像素shader
            real4 frag(VertexOutput i):COLOR
            {
                //法线部分得到世界空间法线

                float4 nortex = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv0.xy);

                float3 norTS = UnpackNormalScale(nortex, _NormalScale);

                norTS.z = sqrt(1 - saturate(dot(norTS.xy, norTS.xy)));

                float3x3 T2W = {i.tDirWS.xyz, i.bDirWS.xyz, i.nDirWS.xyz};

                T2W = transpose(T2W);

                float3 N = NormalizeNormalPerPixel(mul(T2W, norTS));

                //return float4(N,1);

                //计算一些可能会用到的杂七杂八的东西

                float3 positionWS = float3(i.nDirWS.w, i.tDirWS.w, i.bDirWS.w);

                real3 Albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv0.xy).xyz * _BaseColor.xyz;

                float4 Mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv0.xy);

                float Metallic = Mask.r;

                float AO = Mask.g;

                float smoothness = Mask.a;

                float TEMProughness = 1 - smoothness; //中间粗糙度

                float roughness = pow(TEMProughness, 2); // 粗糙度

                float3 F0 = lerp(0.04, Albedo, Metallic);

                Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.posWS));

                float3 L = normalize(mainLight.direction);

                float3 V = SafeNormalize(_WorldSpaceCameraPos - positionWS);

                float3 H = normalize(V + L);

                float NdotV = max(saturate(dot(N, V)), 0.000001); //不取0 避免除以0的计算错误

                float NdotL = max(saturate(dot(N, L)), 0.000001);

                float HdotV = max(saturate(dot(H, V)), 0.000001);

                float NdotH = max(saturate(dot(H, N)), 0.000001);

                float LdotH = max(saturate(dot(H, L)), 0.000001);

                //直接光部分

                //直接光的高光部分:我们把D,G,F代入公式，先计算出高光部分。注意这里经过半球积分后会乘PI，不要丢了;
                //注意这里并未再次乘KS，因为KS=F，已经计算过了一次不需要重复计算。

                float D = D_Function(NdotH, roughness);

                //return D;

                float G = G_Function(NdotL, NdotV, roughness);

                //return G;

                float3 F = F_Function(LdotH, F0);

                //return float4(F,1);

                float3 BRDFSpeSection = D * G * F / (4 * NdotL * NdotV);

                float3 DirectSpeColor = BRDFSpeSection * mainLight.shadowAttenuation * mainLight.color * NdotL * PI;

                //return float4(DirectSpeColor,1);

                //高光部分完成
                //后面是漫反射

                //根据上面的能量守恒关系，可以先计算镜面反射部分，此部分等于入射光线被反射的能量所占的百分比。
                //而折射部分可以由镜面反射部分计算得出。

                float3 KS = F; //反射/入射光线

                float3 KD = (1 - KS) * (1 - Metallic); //(1 - KS)=折射/入射光线,镜面反射部分与漫反射部分的和肯定不会超过1.0，从而近似达到能量守恒的目的。

                float3 DirectDiffColor = KD * Albedo * mainLight.shadowAttenuation * mainLight.color * NdotL;
                //分母要除PI 但是积分后乘PI 就没写

                //return float4(DirectDiffColor,1);

                float3 DirectColor = DirectSpeColor + DirectDiffColor; //漫反射部分

                //return float4(DirectColor,1);

                //间接光部分

                float3 SHcolor = SH_IndirectionDiff(N) * AO;

                float3 IndirKS = IndirF_Function(NdotV, F0, roughness);

                float3 IndirKD = (1 - IndirKS) * (1 - Metallic);

                float3 IndirDiffColor = SHcolor * IndirKD * Albedo;

                //return float4(IndirDiffColor,1);

                //漫反射部分完成
                //后面是高光

                //高光反射和IBL
                //间接光照的高光反射本质是对于反射探针(360全景相机)拍的一张图进行采样，把采样到的颜色当成光照去进行计算，
                //这种光照称为基于图像的光照IBL(lmage-BasedLighting)，前面的漫反射也是IBL。

                float3 IndirSpeCubeColor = IndirSpeCube(N, V, roughness, AO); //间接光高光反射探针

                //return float4(IndirSpeCubeColor,1);

                float3 IndirSpeCubeFactor = IndirSpeFactor(roughness, smoothness, BRDFSpeSection, F0, NdotV); //间接高光曲线拟合放弃LUT采样而使用曲线拟合

                float3 IndirSpeColor = IndirSpeCubeColor * IndirSpeCubeFactor; //

                //return float4(IndirSpeColor,1);

                float3 IndirColor = IndirSpeColor + IndirDiffColor; //间接光部分：间接高光+间接颜色

                //return float4(IndirColor,1);

                //间接光部分计算完成

                float3 Color = IndirColor + DirectColor; //间接光部分+漫反射部分

                return float4(Color, 1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // -------------------------------------
            // Universal Pipeline keywords

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }

}