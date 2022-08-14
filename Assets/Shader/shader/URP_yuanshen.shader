Shader "URP/yuanshen" //Shader路径名
{
    Properties //材质面板参数
    {
        [Header(ShaderEnum)]
        [Space(5)]
        [KeywordEnum(Base,Face,Hair)]_ShaderEnum("Shader枚举类型",int)=0
        [Toggle(IN_NIGHT)]_InNight ("是晚上吗", int) = 0

        [Header(BaseMap)]
        [Space(5)]
        _MainTex ("基础贴图", 2D) = "white" {}
        [HDR][MainColor]_MainColor ("基础色", Color) = (1, 1, 1, 1)
        [Space(30)]

        [Header(ParamTex)]
        [Space(5)]
        _ParamTex ("参数图（LightMap或FaceLightMap）", 2D) = "white" { }
        [Space(30)]

        [Header(ShadowRamp)]
        [Space(5)]
        _RampMap ("Ramp图", 2D) = "white" { }
        _RampMapYRange ("Ramp图要在Y轴哪个值采样", Range(0.0,0.5)) = 1.0
        [Space(30)]

        [Header(Specular)]
        [Space(5)]
        _Matcap ("Matcap图", 2D) = "white" { }
        _MetalColor("金属颜色",Color)= (1,1,1,1)//
        _HairSpecularIntensity("头发高光强度",Range(0.0,10)) = 0.5

        _HairSpecColor ("高光颜色",Color) = (1,1,1,1)
        _HairSpecularRange("头发高光范围",Float) =0.5
        _HairSpecularViewRange("头发高光视角范围",Float) =0.5
        [Space(30)]

        [Space(5)]
        _FaceShadowRangeSmooth ("脸部阴影转折要不要平滑", Range(0.01,1.0)) = 0.1
        [Space(30)]

        [Header(RimLight)]
        [Space(5)]
        _RimIntensity("边缘光亮度",Range(0.0,5.0)) = 0
        _RimRadius("边缘光范围",Range(0.0,1.0)) = 0.1
        [Space(30)]

        [Header(Emission)]
        [Space(5)]
        _EmissionIntensity("自发光强度",Range(0.0,25.0)) = 0.0//
        [Space(30)]


        [Header(Outline)]
        [Space(5)]
        _outlinecolor ("描边颜色", Color) = (0,0,0,1)
        _outlinewidth ("描边粗细", Range(0, 1)) = 0.01
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }

        //include
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        #pragma vertex vert
        #pragma fragment frag

        #pragma shader_feature _SHADERENUM_BASE _SHADERENUM_FACE _SHADERENUM_HAIR

        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile_fragment _ _SHADOWS_SOFT

        CBUFFER_START(UnityPerMaterial) //缓冲区

        float4 _MainTex_ST;
        float4 _MainColor;

        uniform float4 _ShadowMultColor; //阴影颜色
        uniform float4 _DarkShadowMultColor; //暗阴影颜色

        uniform int _InNight;

        uniform float _RimIntensity;
        uniform float _RimRadius;
        uniform float _RampMapYRange;

        uniform float _FaceShadowRangeSmooth;

        uniform float _HairSpecularIntensity;

        uniform float3 _HairSpecColor;
        uniform float _HairSpecularRange;
        uniform float _HairSpecularViewRange;

        uniform float _EmissionIntensity;

        uniform float4 _outlinecolor;
        uniform float _outlinewidth;

        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        TEXTURE2D(_ParamTex);
        SAMPLER(sampler_ParamTex);

        TEXTURE2D(_RampMap);
        SAMPLER(sampler_RampMap);

        uniform TEXTURE2D(_Matcap);
        uniform SAMPLER(sampler_Matcap);

        struct VertexInput //输入结构
        {
            float4 vertex : POSITION;
            float2 uv0 : TEXCOORD0;
            half4 color: COLOR;
            float4 normal : NORMAL;
        };

        struct VertexOutput //输出结构
        {
            float4 pos : POSITION;
            float2 uv0 : TEXCOORD0;
            float4 vertexColor: COLOR;
            float3 nDirWS : TEXCOORD1;
            float3 nDirVS : TEXCOORD2;
            float3 vDirWS : TEXCOORD3;
            float3 posWS : TEXCOORD4;
        };

        //阴影映射Ramp
        float3 NPR_Ramp(float NdotL, float _InNight, float _RampMapYRange)
        {
            float halfLambert = smoothstep(0.0, 0.5, NdotL); //只要halfLambert的一半映射Ramp
            /* 
            Skin = 255
            Silk = 160
            Metal = 128
            Soft = 78
            Hand = 0
            */
            //只保留0.0 - 0.5之间的，超出0.5的范围就强行改成1，一般ramp的明暗交界线是在贴图中间的，这样被推到贴图最右边的一个像素上
            if (_InNight > 0.0)
            {
                return SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(halfLambert, _RampMapYRange)).rgb; //晚上
            }
            else
            {
                return SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(halfLambert, _RampMapYRange + 0.5)).rgb; //白天
            }
        }

        //高光部分
        float3 NPR_Specular(float3 NdotH, float3 baseColor, float4 var_ParamTex)
        {
            #if  _SHADERENUM_HAIR
                float SpecularRadius = pow(NdotH, var_ParamTex.a * 50); //将金属通道作为高光的范围控制  金属的部分高光集中  非金属的部分高光分散
            #else
            float SpecularRadius = pow(NdotH, var_ParamTex.r * 50); //将金属通道作为高光的范围控制  金属的部分高光集中  非金属的部分高光分散
            #endif

            float3 SpecularColor = var_ParamTex.b * baseColor;

            #if  _SHADERENUM_HAIR
                return smoothstep(0.3, 0.4, SpecularRadius) * SpecularColor * lerp(_HairSpecularIntensity, 1, step(0.9, var_ParamTex.b)); //头发部分的高光强度自定
            #else
            return smoothstep(0.3, 0.4, SpecularRadius) * SpecularColor * var_ParamTex.b;
            #endif
        }

        //头发高光
        float3 NPR_Hair_Specular(float NdotH, float4 var_ParamTex)
        {
            //头发高光
            float SpecularRange = smoothstep(1 - _HairSpecularRange, 1, NdotH);
            float HairSpecular = var_ParamTex.b * SpecularRange;
            float3 hairSpec = HairSpecular * _HairSpecColor;
            return hairSpec;
        }

        //金属部分
        float3 NPR_Metal(float3 nDir, float4 var_ParamTex, float3 baseColor)
        {
            float3 viewNormal = normalize(mul(UNITY_MATRIX_V, nDir)); //视空间法线向量，用于MatCap的UV采样
            float var_Matcap = SAMPLE_TEXTURE2D(_Matcap, sampler_Matcap, viewNormal * 0.5 + 0.5) * 2;
            #if  _SHADERENUM_HAIR
                return var_Matcap * baseColor * var_ParamTex.a;
            #endif
            return var_Matcap * baseColor * var_ParamTex.r;
        }

        //边缘光
        float3 NPR_Rim(float NdotV, float NdotL, float4 baseColor)
        {
            float3 rim = (1 - smoothstep(_RimRadius, _RimRadius + 0.03, NdotV)) * _RimIntensity * (1 - (NdotL * 0.5 + 0.5)) * baseColor;
            //float3 rim = (1 - smoothstep(_RimRadius, _RimRadius + 0.03, NdotV)) * _RimIntensity * baseColor;
            return rim;
        }

        //自发光(带有呼吸效果)
        float3 NPR_Emission(float4 baseColor)
        {
            return baseColor.a * baseColor * _EmissionIntensity * abs((frac(_Time.y * 0.5) - 0.5) * 2);
        }

        //身体部分
        float3 NPR_Base(float NdotL, float NdotH, float NdotV, float3 nDir, float4 baseColor, float4 var_ParamTex, float _InNight, float _RampMapYRange)
        {
            float3 RampColor = NPR_Ramp(NdotL, _InNight, _RampMapYRange);
            float3 Albedo = baseColor * RampColor;
            float3 Specular = NPR_Specular(NdotH, baseColor, var_ParamTex);
            float3 Metal = NPR_Metal(nDir, var_ParamTex, baseColor);
            float3 RimLight = NPR_Rim(NdotV, NdotL, baseColor) * var_ParamTex.g;
            float3 Emission = NPR_Emission(baseColor);
            float3 FinalColor = Albedo * (1 - var_ParamTex.r) + Specular + Metal + RimLight + Emission;
            return FinalColor;
        }

        //脸部
        float3 NPR_Face(float4 baseColor, float4 var_ParamTex, float3 lDir, float _InNight, float _FaceShadowRangeSmooth, float _RampMapYRange)
        {
            //上方向
            float3 Up = float3(0.0, 1.0, 0.0);
            //角色朝向
            float3 Front = unity_ObjectToWorld._12_22_32;
            //角色右侧朝向
            float3 Right = cross(Up, Front);
            //阴影贴图左右正反切换的开关
            float switchShadow = dot(normalize(Right.xz), lDir.xz) * 0.5 + 0.5 < 0.5;
            //阴影贴图左右正反切换
            float FaceShadow = lerp(var_ParamTex, 1 - var_ParamTex, switchShadow);
            //脸部阴影切换的阈值
            float FaceShadowRange = dot(normalize(Front.xz), normalize(lDir.xz));
            //使用阈值来计算阴影
            float lightAttenuation = 1 - smoothstep(FaceShadowRange - _FaceShadowRangeSmooth, FaceShadowRange + _FaceShadowRangeSmooth, FaceShadow);
            //Ramp
            float3 rampColor = NPR_Ramp(lightAttenuation, _InNight, _RampMapYRange);
            return baseColor.rgb * rampColor;
        }

        //头发
        float3 NPR_Hair(float NdotL, float NdotH, float NdotV, float3 nDir, float4 baseColor, float4 var_ParamTex, float _InNight, float _RampMapYRange)
        {
            //头发的rampColor不应该把固定阴影的部分算进去，所以这里固定阴影给定0.5 到计算ramp的时候 *2 结果等于1
            float3 RampColor = NPR_Ramp(NdotL, _InNight, _RampMapYRange);
            float3 Albedo = baseColor * RampColor;

            //float HariSpecRadius = 0.25; //这里可以控制头发的反射范围
            //float HariSpecDir = normalize(mul(UNITY_MATRIX_V, nDir)) * 0.5 + 0.5;
            //float3 HariSpecular = smoothstep(HariSpecRadius, HariSpecRadius + 0.1, 1 - HariSpecDir) * smoothstep(HariSpecRadius, HariSpecRadius + 0.1, HariSpecDir) * NdotL; //利用屏幕空间法线 
            //float3 Specular = NPR_Specular(NdotH, baseColor, var_ParamTex) + HariSpecular * _HairSpecularIntensity * var_ParamTex.g * step(var_ParamTex.r, 0.1);
            float3 hairSpec = NPR_Hair_Specular(NdotH, var_ParamTex);

            float3 Metal = NPR_Metal(nDir, var_ParamTex, baseColor);
            float3 RimLight = NPR_Rim(NdotV, NdotL, baseColor);
            float3 finalRGB = Albedo + hairSpec * RampColor + Metal + RimLight;
            return finalRGB;
        }
        ENDHLSL

        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode"="UniversalForward"
                "RenderType"="Opaque"
            }

            Cull off

            HLSLPROGRAM
            VertexOutput vert(VertexInput v) //顶点shader
            {
                VertexOutput o = (VertexOutput)0; // 新建输出结构
                ZERO_INITIALIZE(VertexOutput, o); //初始化顶点着色器
                o.vertexColor = v.color;
                o.uv0 = v.uv0;
                o.uv0 = float2(o.uv0.x, 1 - o.uv0.y);
                o.pos = TransformObjectToHClip(v.vertex);
                o.posWS = TransformObjectToWorld(v.vertex);
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                o.nDirVS = TransformWorldToView(o.nDirWS);
                o.vDirWS = _WorldSpaceCameraPos.xyz - o.posWS;
                return o; // 返回输出结构
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                //各种贴图
                half4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0) * _MainColor;

                //#ifndef _SHADERENUM_FACE
                float4 var_ParamTex = SAMPLE_TEXTURE2D(_ParamTex, sampler_ParamTex, i.uv0);
                //#endif

                //灯光
                Light light = GetMainLight(TransformWorldToShadowCoord(i.posWS));

                //各种方向
                float3 nDir = normalize(i.nDirWS);
                float3 vDir = normalize(i.vDirWS);
                float3 lDir = normalize(light.direction);
                float3 halfDir = normalize(lDir + vDir); //半角向量

                // 准备点积结果
                float NdotL = dot(nDir, lDir);
                float NdotH = dot(nDir, halfDir); //高光
                float NdotV = dot(nDir, vDir); //菲涅尔

                //float halflambert = max(0.0, NdotL) * 0.5 + 0.5;

                //提前定义好最终输出
                float3 FinalColor = float3(0.0, 0.0, 0.0);

                #if _SHADERENUM_BASE
                    FinalColor = NPR_Base(NdotL, NdotH, NdotV, nDir, baseColor, var_ParamTex, _InNight, _RampMapYRange);
                #elif  _SHADERENUM_FACE
                    FinalColor = NPR_Face(baseColor, var_ParamTex, lDir, _InNight, _FaceShadowRangeSmooth, _RampMapYRange);
                #elif _SHADERENUM_HAIR
                    FinalColor = NPR_Hair(NdotL, NdotH, NdotV, nDir, baseColor, var_ParamTex, _InNight,_RampMapYRange);
                #endif

                return float4(FinalColor, 1.0);
            }
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            Tags
            {
            }
            Cull off
            ZWrite on
            Cull front

            HLSLPROGRAM
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                ZERO_INITIALIZE(VertexOutput, o); //初始化顶点着色器
                o.pos = TransformObjectToHClip(float4(v.vertex.xyz + v.normal * _outlinewidth, 1));
                o.uv0 = v.uv0;
                o.uv0 = float2(o.uv0.x, 1 - o.uv0.y);
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
                o.nDirWS = v.normal;
                return o;
            }

            float4 frag(VertexOutput i) : COLOR
            {
                float4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
                float4 FinalColor = _outlinecolor * var_MainTex;
                return FinalColor;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}