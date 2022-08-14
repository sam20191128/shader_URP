Shader "Hidden/PostProcessing/Blur/TiltShiftBlurV2"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }

    SubShader
    {
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float _Radius;
        float _Iteration;
        float _Offset;
        float _Area;
        float _Spread;

        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct VertexInput //输入结构
        {
            float4 vertex : POSITION;
            float2 uv0 : TEXCOORD0;
        };

        struct VertexOutput //输出结构
        {
            float4 pos : SV_POSITION;
            float2 uv0 : TEXCOORD0;
        };

        //顶点shader
        VertexOutput VertDefault(VertexInput v)
        {
            VertexOutput o;
            o.pos = TransformObjectToHClip(v.vertex);
            o.uv0 = v.uv0;
            return o;
        }

        float TiltShiftMask(float2 uv)
        {
            float centerY = uv.y * 2.0 - 1.0 + _Offset; // [0,1] -> [-1,1]
            return pow(abs(centerY * _Area), _Spread);
        }

        //散景模糊
        half4 TiltShiftBlur(VertexOutput i)
        {
            //预计算旋转
            float c = cos(2.39996323f);
            float s = sin(2.39996323f);
            half4 _GoldenRot = half4(c, s, -s, c);

            half2x2 rot = half2x2(_GoldenRot);
            half4 accumulator = 0.0; //累加器
            half4 divisor = 0.0; //因子

            half r = 1.0;
            half2 angle = half2(0.0, _Radius * saturate(TiltShiftMask(i.uv0)));

            for (int j = 0; j < _Iteration; j ++)
            {
                r += 1.0 / r; //每次 + r分之一 1.1
                angle = mul(rot, angle);
                half4 bokeh = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv0 + (r - 1.0) * angle));
                accumulator += bokeh * bokeh;
                divisor += bokeh;
            }
            return half4(accumulator / divisor);
        }

        //像素shader
        half4 fragTiltShiftBlurV2(VertexOutput i) : SV_Target
        {
            return TiltShiftBlur(i);
        }

        half4 FragPreview(VertexOutput i): SV_Target
        {
            return TiltShiftMask(i.uv0);
        }
        ENDHLSL

        Cull Off ZWrite Off ZTest Always

        // Pass 0 - Tilt Shift
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment fragTiltShiftBlurV2
            ENDHLSL
        }

        // Pass 1 - Preview
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment FragPreview
            ENDHLSL

        }
    }
}