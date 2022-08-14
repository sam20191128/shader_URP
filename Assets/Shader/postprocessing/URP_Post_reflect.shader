Shader "URP/reflect"
{

    Properties

    {

        _MainTex("MainTex",2D)="white"{}

        _BaseColor("BaseColor",Color)=(1,1,1,1)

    }

    SubShader

    {

        Tags
        {

            "RenderPipeline"="UniversalRenderPipeline"

            "Queue"="Overlay"

        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;

        half4 _BaseColor;

        CBUFFER_END

        TEXTURE2D(_MainTex);


        SAMPLER(sampler_MainTex);


        TEXTURE2D(_ReflectColor);

        sampler LinearClampSampler;

        struct a2v

        {
            float4 positionOS:POSITION;

            float4 normalOS:NORMAL;

            float2 texcoord:TEXCOORD;
        };

        struct v2f

        {
            float4 positionCS:SV_POSITION;

            float2 texcoord:TEXCOORD;

            float4 screenPos:TEXCOORD1;

            float3 posWS:TEXCOORD2;
        };
        ENDHLSL



        pass

        {

            Tags
            {

                "LightMode"="UniversalForward"

                "RenderType"="Overlay"

            }

            HLSLPROGRAM
            #pragma vertex vert

            #pragma fragment frag


            v2f vert(a2v i)

            {
                v2f o;

                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                //OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap)+ _Time.y*_UV_MoveSpeed;

                o.screenPos = ComputeScreenPos(o.positionCS);

                return o;
            }


            half4 frag(v2f i) : SV_Target

            {
                half2 screenUV = i.screenPos.xy / i.screenPos.w;

                float4 SSPRResult = SAMPLE_TEXTURE2D(_ReflectColor, LinearClampSampler, screenUV);

                SSPRResult.xyz *= SSPRResult.w;


                return SSPRResult;
            }
            ENDHLSL
        }
    }
}
