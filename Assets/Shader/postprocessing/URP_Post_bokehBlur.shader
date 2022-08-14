Shader "URP/Post/broke blur"
{
    Properties
    {
        [HideinInspector] _MainTex("MainTex",2D)="white"{}
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Transparent"
        }

        Cull Off ZWrite Off ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_TexelSize;
        CBUFFER_END

        half _NearDis;
        half _FarDis;
        float _BlurSmoothness;
        float _loop;
        float _radius;

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        TEXTURE2D(_SourTex);
        SAMPLER(sampler_SourTex);

        SAMPLER(_CameraDepthTexture);

        struct a2v
        {
            float4 positionOS:POSITION;
            float2 texcoord:TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD;
        };
        ENDHLSL

        pass
        {
            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = i.texcoord;
                return o;
            }

            real4 FRAG(v2f i):SV_TARGET
            {
                float a = 2.3398;
                float2x2 rotate = float2x2(cos(a), -sin(a), sin(a), cos(a));
                float2 UVpos = float2(_radius, 0);
                float2 uv;
                float r;
                real4 tex = 0;

                for (int t = 1; t < _loop; t++)
                {
                    r = sqrt(t);
                    UVpos = mul(rotate, UVpos);
                    uv = i.texcoord + _MainTex_TexelSize.xy * UVpos * r;
                    tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                }
                return tex / (_loop - 1);
            }
            ENDHLSL
        }

        pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = i.texcoord;
                return o;
            }

            real4 frag(v2f i):SV_TARGET
            {
                float depth = Linear01Depth(tex2D(_CameraDepthTexture, i.texcoord).x, _ZBufferParams).x;
                real4 blur = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                real4 Sour = SAMPLE_TEXTURE2D(_SourTex, sampler_SourTex, i.texcoord);

                _NearDis *= _ProjectionParams.w;
                _FarDis *= _ProjectionParams.w;

                float dis = 1 - smoothstep(_NearDis, saturate(_NearDis + _BlurSmoothness), depth); //计算近处的

                dis += smoothstep(_FarDis, saturate(_FarDis + _BlurSmoothness), depth); //计算远处的

                real4 combine = lerp(Sour, blur, dis);

                return combine;
            }
            ENDHLSL
        }
    }
}