﻿

Shader "Hidden/PostProcessing/Pixelate/PixelizeCircle"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
    }
    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"

    half4 _Params;
    half2 _Params2;
    half4 _BackgroundColor;

    #define _PixelIntervalX _Params2.x
    #define _PixelIntervalY _Params2.y

    
    float4 CirclePixelize(float2 uv)
    {
        float pixelScale = 1.0 / _Params.x;

        float ratio = _ScreenParams.y / _ScreenParams.x;
        uv.x = uv.x / ratio;

        //x和y坐标分别除以缩放系数，在用floor向下取整，再乘以缩放系数，得到分段UV
        float2 coord = half2(_PixelIntervalX * floor(uv.x / (pixelScale * _PixelIntervalX)), (_PixelIntervalY) * floor(uv.y / (pixelScale * _PixelIntervalY)));

        //求解圆心坐标
        float2 circleCenter = coord * pixelScale + pixelScale * 0.5;

        //计算当前uv值隔圆心的距离，并乘以缩放系数
        float dist = length(uv - circleCenter) * _Params.x;
        //圆心坐标乘以缩放系数
        circleCenter.x *= ratio;

        //采样
        float4 screenColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, circleCenter);

        //对于距离大于半径的像素，替换为背景色
        if (dist > _Params.z)  screenColor = _BackgroundColor;

        return screenColor;
    }

    float4 Frag(VaryingsDefault i): SV_Target
    {

        return CirclePixelize(i.uv);
    }
    
    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        
        Cull Off
        ZWrite Off
        ZTest Always

        
        Pass
        {
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment Frag

            ENDHLSL

        }
    }
}
