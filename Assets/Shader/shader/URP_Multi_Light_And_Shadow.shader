Shader "URP/Multi_Light_And_Shadow"
{
    Properties
    {
        _MainTex("MainTex",2D)="white"{}
        _BaseColor("BaseColor",Color)=(1,1,1,1)
        [KeywordEnum(ON,OFF)]_ADD_LIGHT("AddLight",float)=1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }

        HLSLINCLUDE
        #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
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
            float3 nDirWS:NORMAL;
            float3 vDirWS:TEXCOORD1;
            float3 posWS:TEXCOORD2;
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
            #pragma shader_feature _ADD_LIGHT_ON _ADD_LIGHT_OFF

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;
                o.pos = TransformObjectToHClip(i.vertex.xyz);
                o.uv0 = TRANSFORM_TEX(i.uv0, _MainTex);
                o.nDirWS = normalize(TransformObjectToWorldNormal(i.normal.xyz));
                o.vDirWS = normalize(_WorldSpaceCameraPos - TransformObjectToWorld(i.vertex.xyz));
                o.posWS = TransformObjectToWorld(i.vertex.xyz);
                return o;
            }

            half4 frag(VertexOutput i):SV_TARGET
            {
                //Properties need
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0) * _BaseColor;

                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.posWS));
                float3 lDirWS = normalize(mylight.direction);

                float3 nDirWS = i.nDirWS;
                float3 vDirWS = i.vDirWS;
                float3 posWS = i.posWS;
                float3 hDirWS = normalize(vDirWS + lDirWS);

                //mainlight
                float4 finalColor = (dot(lDirWS, nDirWS) * 0.5 + 0.5) * tex * float4(mylight.color, 1) * mylight.shadowAttenuation;;

                //addlight
                half4 addcolor = half4(0, 0, 0, 1);

                #if _ADD_LIGHT_ON
                //定义在lighting库函数的方法返回一个额外灯光的数量
                int addLightsCount = GetAdditionalLightsCount();

                for (int i = 0; i < addLightsCount; i++)
                {
                    //定义在lightling库里的方法返回一个灯光类型的数据
                    Light addlight = GetAdditionalLight(i, posWS, half4(1, 1, 1, 1));

                    float3 addlDirWS = normalize(addlight.direction);

                    addcolor += (dot(nDirWS, addlDirWS) * 0.5 + 0.5) * half4(addlight.color, 1) * tex * addlight.distanceAttenuation * addlight.shadowAttenuation;
                }
                #else
                    addcolor = half4(0, 0, 0, 1);
                #endif

                return finalColor + addcolor;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}