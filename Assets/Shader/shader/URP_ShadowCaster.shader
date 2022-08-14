Shader "URP/ShadowCaster"
{
    Properties
    {
        _MainTex("MainTex",2D)="white"{}
        _BaseColor("BaseColor",Color)=(1,1,1,1)
        [HDR]_SpecularColor("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",Range(10,300))=50
        [KeywordEnum(OFF,ON)]_ADDLIGHT("Addlight",float)=1
        [KeywordEnum(OFF,ON)]_CUT("Cut",float)=1
        _Cutoff("Cutoff",Range(0,1))=0.5
    }

    SubShader
    {

        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        #pragma shader_feature_local _CUT_ON

        #pragma shader_feature_local _ADDLIGHT_ON

        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        real4 _SpecularColor;
        half _Gloss;
        float _Cutoff;
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
            float2 uv0:TEXCOORD0;
            float3 nDirWS:NORMAL;
            float3 vDirWS:TEXCOORD1;
            float3 posWS:TEXCOORD2;

            #ifdef _MAIN_LIGHT_SHADOWS
                float4 shadowcoord:TEXCOORD5;
            #endif
        };
        ENDHLSL

        pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }

            Cull off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;
                o.pos = TransformObjectToHClip(i.vertex.xyz);
                o.uv0 = TRANSFORM_TEX(i.uv0, _MainTex);
                o.posWS = TransformObjectToWorld(i.vertex.xyz);
                o.nDirWS = normalize(TransformObjectToWorldNormal(i.normal.xyz));
                o.vDirWS = normalize(_WorldSpaceCameraPos - TransformObjectToWorld(i.vertex.xyz));

                #ifdef _MAIN_LIGHT_SHADOWS
                    o.shadowcoord=TransformWorldToShadowCoord(o.posWS);
                #endif

                return o;
            }

            half4 frag(VertexOutput i):SV_TARGET
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0) * _BaseColor;

                #ifdef _CUT_ON
                    clip(tex.a-_Cutoff);
                #endif

                //main light
                #ifdef _MAIN_LIGHT_SHADOWS
                    Light mylight=GetMainLight(i.shadowcoord);
                #else
                Light mylight = GetMainLight();
                #endif

                float3 lDirWS = normalize(mylight.direction);

                real4 maincolor = (dot(i.nDirWS, lDirWS) * 0.5 + 0.5) * real4(mylight.color, 1) * mylight.shadowAttenuation;

                //addlights
                half4 addColor = half4(0, 0, 0, 1);

                #ifdef _ADDLIGHT_ON
                    int addcount = GetAdditionalLightsCount();
                    for (int t = 0; t < addcount; t++)
                    {
                        Light addlight = GetAdditionalLight(t, i.posWS);
                        float3 addlDirWS = normalize(addlight.direction);
                        //额外灯光就只计算一下半兰伯特模型（高光没计算，性能考虑）
                        addColor += (dot(addlDirWS, i.nDirWS) * 0.5 + 0.5) * half4(addlight.color, 1) * addlight.shadowAttenuation * addlight.distanceAttenuation;
                    }
                #endif

                return tex * (maincolor + addColor);
            }
            ENDHLSL
        }

        //UsePass "Universal Render Pipeline/Lit/ShadowCaster"

        pass
        {
            Tags
            {
                "LightMode"="ShadowCaster"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            half3 _LightDirection;

            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;
                o.uv0 = TRANSFORM_TEX(i.uv0, _MainTex);
                float3 posWS = TransformObjectToWorld(i.vertex.xyz);
                float3 nDirWS = normalize(TransformObjectToWorldNormal(i.normal.xyz));
                o.pos = TransformWorldToHClip(ApplyShadowBias(posWS, nDirWS, _LightDirection));

                #if UNITY_REVERSE_Z
                    o.pos.z=min(o.pos.z,o.pos.w*UNITY_NEAR_CLIP_VALUE);
                #else
                o.pos.z = max(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                return o;
            }

            half4 frag(VertexOutput i):SV_TARGET
            {
                #ifdef _CUT_ON
                    float alpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0).a * _BaseColor.a;
                    clip(alpha - _Cutoff);
                #endif

                return 0;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}