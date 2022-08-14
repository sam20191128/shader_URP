Shader "URP/Rust"
{
    Properties
    {
        _ColorSmooth ("Color(Smooth)", Color) = (0.1490196,0.8509805,0.4313726,1)
        _ColorRough ("Color(Rough)", Color) = (0.482353,0.1607843,0.0627451,1)
        _MaskMap ("Mask Map", 2D) = "white" {}
        _MaskRange ("Mask Range", Range(0, 1)) = 0.4
        _MaskTile ("Mask Tile", Range(0, 1)) = 0.3
        _FresnalRange ("Fresnal Range", Range(0, 10)) = 10
        _SpecPow1 ("SpecPow1", Range(0, 100)) = 1
        _SpecPow2 ("SpecPow2", Range(0, 100)) = 10
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

            CBUFFER_START(UnityPerMaterial) //缓冲区
            uniform float4 _MaskMap_ST;
            uniform float4 _ColorSmooth;
            uniform float4 _ColorRough;
            uniform float _FresnalRange;
            uniform float _MaskTile;
            uniform float _MaskRange;
            uniform float _SpecPow1;
            uniform float _SpecPow2;
            CBUFFER_END

            //纹理采样
            TEXTURE2D(_MaskMap);
            SAMPLER(sampler_MaskMap);

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv0 : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWS : TEXCOORD1;
                float3 nDir : TEXCOORD2;
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = TRANSFORM_TEX(v.uv0, _MaskMap);
                o.nDir = TransformObjectToWorldNormal(v.normal);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.pos = TransformObjectToHClip(v.vertex);
                return o;
            }

            float4 frag(VertexOutput i) : COLOR
            {
                i.nDir = normalize(i.nDir);
                float3 lDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float3 nDir = i.nDir;
                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.posWS));
                float3 lightDirection = normalize(mylight.direction);
                float4 var_MaskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv0);
                float node_632 = dot(step(var_MaskMap.rgb, _MaskRange), float3(0.3, 0.59, 0.11));
                float3 emissive = ((pow(max(dot(reflect((lightDirection * (-1.0)), i.nDir), lDir), 0.0),
                                        lerp(_SpecPow1, _SpecPow2, node_632)) + (pow(
                    (1.0 - max(0, dot(nDir, lDir))), exp(_FresnalRange)) * (0.5 *
                    _ColorSmooth.rgb))) + (max(dot(i.nDir, lightDirection), 0.0) * lerp(
                    _ColorSmooth.rgb, _ColorRough.rgb, node_632)));
                float3 finalColor = emissive;
                return float4(finalColor, 1);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}