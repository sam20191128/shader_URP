﻿

Shader "Hidden/PostProcessing/EdgeDetection/SobelNeon"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
    }
    
    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"

    half4 _Params;
    half4 _BackgroundColor;

    #define _EdgeWidth _Params.x
    #define _Brigtness _Params.y
    #define _BackgroundFade _Params.z
    

    float intensity(in float4 color)
    {
        return sqrt((color.x * color.x) + (color.y * color.y) + (color.z * color.z));
    }

    float sobel(float stepx, float stepy, float2 center)
    {
        // get samples around pixel
        float topLeft = intensity(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, center + float2(-stepx, stepy)));
        float midLeft = intensity(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, center + float2(-stepx, 0)));
        float bottomLeft = intensity(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, center + float2(-stepx, -stepy)));
        float midTop = intensity(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, center + float2(0, stepy)));
        float midBottom = intensity(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, center + float2(0, -stepy)));
        float topRight = intensity(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, center + float2(stepx, stepy)));
        float midRight = intensity(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, center + float2(stepx, 0)));
        float bottomRight = intensity(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, center + float2(stepx, -stepy)));

        // Sobel masks (see http://en.wikipedia.org/wiki/Sobel_operator)
        //        1 0 -1     -1 -2 -1
        //    X = 2 0 -2  Y = 0  0  0
        //        1 0 -1      1  2  1

        // Gx = sum(kernelX[i][j]*image[i][j])
        float Gx = topLeft + 2.0 * midLeft + bottomLeft - topRight - 2.0 * midRight - bottomRight;
        // Gy = sum(kernelY[i][j]*image[i][j]);
        float Gy = -topLeft - 2.0 * midTop - topRight + bottomLeft + 2.0 * midBottom + bottomRight;
        float sobelGradient = sqrt((Gx * Gx) + (Gy * Gy));
        return sobelGradient;
    }



    half4 Frag(VaryingsDefault i): SV_Target
    {

        half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

        float sobelGradient = sobel(_EdgeWidth / _ScreenParams.x, _EdgeWidth / _ScreenParams.y, i.uv);

        //BackgroundFading
        half4 backgroundColor = lerp(sceneColor, _BackgroundColor, _BackgroundFade);

        //Edge Opacity
        float3 edgeColor = lerp(backgroundColor.rgb, sceneColor.rgb, sobelGradient);

        return float4(edgeColor * _Brigtness, 1);
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