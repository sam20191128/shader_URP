Shader "URP/MainLightShadow"
{
    Properties
    {
        _MainTex("MainTex",2D)="white"{}
        _BaseColor("BaseColor",Color)=(1,1,1,1)
        _Gloss("gloss",Range(10,300))=20
        _SpecularColor("SpecularColor",Color )=(1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        half _Gloss;
        float4 _SpecularColor;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct VertexInput
        {
            float4 vertex:POSITION;

            float4 normal:NORMAL;

            float2 uv0:TEXCOORD;
        };

        struct VertexOutput
        {
            float4 pos:SV_POSITION;

            float2 uv0:TEXCOORD;

            float3 posWS:TEXCOORD1;

            float3 nDirWS:NORMAL;
        };
        ENDHLSL

        pass
        {
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

            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;
                o.pos = TransformObjectToHClip(i.vertex.xyz);
                o.uv0 = TRANSFORM_TEX(i.uv0, _MainTex);
                o.posWS = TransformObjectToWorld(i.vertex.xyz);
                o.nDirWS = TransformObjectToWorldNormal(i.normal);
                return o;
            }

            half4 frag(VertexOutput i):SV_TARGET
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0) * _BaseColor;

                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.posWS));
                float3 lDirWS = normalize(mylight.direction);

                float3 nDirWS = normalize(i.nDirWS);
                float3 vDirWS = normalize(_WorldSpaceCameraPos - i.posWS);

                float3 hDir = normalize(vDirWS + lDirWS);

                tex *= (dot(lDirWS, nDirWS) * 0.5 + 0.5) * mylight.shadowAttenuation * float4(mylight.color, 1);

                float4 Specular = pow(max(dot(nDirWS, hDir), 0), _Gloss) * _SpecularColor * mylight.shadowAttenuation;

                return tex + Specular;
            }
            ENDHLSL

        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}