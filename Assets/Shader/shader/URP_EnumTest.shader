Shader "URP/EnumTest" //Shader路径名
{
    Properties //材质面板参数
    {
        _MainTex("MainTex",2D)="White"{}

        _BaseColor("BaseColor",Color)=(1,1,1,1)

        [Header(Stencil)]//模板测试
        [IntRange]_Stencil ("Stencil ID", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison比较操作", Float) = 8
        [IntRange]_StencilReadMask ("Stencil Read Mask读遮罩", Range(0,255)) = 255
        [IntRange]_StencilWriteMask ("Stencil Write Mask写入模板缓冲", Range(0,255)) = 255
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilPass ("Stencil Pass当模板测试（和深度测试）通过时", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilFail ("Stencil Fail当模板测试（和深度测试）失败时", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilZFail ("Stencil ZFail当模板测试通过而深度测试失败时", Float) = 0

        [Header(DepthTest)]//深度测试
        [Enum(Off, 0, On, 1)]_ZWriteMode ("ZWriteMode深度缓冲模式", float) = 1
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode ("CullMode剔除模式", float) = 2
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode ("ZTestMode深度测试模式", Float) = 4
        [Enum(UnityEngine.Rendering.ColorWriteMask)]_ColorMask ("ColorMask", Float) = 15

        [Header(Blend)]//混合模式
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("BlendOp混合算符", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend混合源乘子", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend混合目标乘子", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
        }

        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode"="UniversalForward"
            }

            Stencil//模板测试
            {
                Ref [_Stencil]//设定参考值referenceValue，这个值将用来与模板缓冲中的值进行比较
                Comp [_StencilComp]//定义参考值（referenceValue）与缓冲值（stencilBufferValue）比较的操作函数
                ReadMask [_StencilReadMask]//读遮罩
                WriteMask [_StencilWriteMask]//当写入模板缓冲时进行掩码操作
                Pass [_StencilPass]//定义当模板测试（和深度测试）通过时
                Fail [_StencilFail]//定义当模板测试（和深度测试）失败时
                ZFail [_StencilZFail]//定义当模板测试通过而深度测试失败时
            }


            ZWrite [_ZWriteMode]//深度缓冲模式
            ZTest [_ZTestMode]//深度测试模式
            Cull [_CullMode]//剔除模式
            ColorMask [_ColorMask]//指定将哪些颜色分量写入目标帧缓冲区

            BlendOp [_BlendOp]//混合算符
            Blend [_SrcBlend] [_DstBlend]//混合源乘子 混合目标乘子

            HLSLPROGRAM
            #pragma vertex vert     //顶点着色器
            #pragma fragment frag   //片元着色器

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
                o.nDirWS = TransformObjectToWorldNormal(v.normal, true); //变换法线信息并将其塞给输出结构
                return o; // 将输出结构 输出
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                float3 nDir = i.nDirWS; // 获取nDir

                Light mylight = GetMainLight();

                float4 LightColor = float4(mylight.color, 1);

                float3 lDir = normalize(mylight.direction);

                float nDotl = dot(nDir, lDir); // nDir点积lDir

                float lambert = max(0.0, nDotl); // 截断负值

                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0) * _BaseColor;

                return tex * lambert * LightColor;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}