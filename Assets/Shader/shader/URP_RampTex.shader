Shader "URP/RampTex" //Shader路径名
{
    Properties

    {

        _MainTex("RAMP",2D)="White"{}

        _BaseColor("BaseColor",Color)=(1,1,1,1)

    }

    SubShader

    {

        Tags
        {

            "RenderPipeline"="UniversalRenderPipeline"

            "RenderType"="Opaque"

        }
        pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _BaseColor;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct VertexInput
            {
                float4 vertex:POSITION;

                float3 normal:NORMAL;
            };

            struct VertexOutput
            {
                float4 pos:SV_POSITION;

                float3 nDirWS:NORMAL;
            };


            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0; // 新建输出结构

                o.pos = TransformObjectToHClip(v.vertex.xyz);

                o.nDirWS = normalize(TransformObjectToWorldNormal(v.normal));

                return o;
            }

            half4 frag(VertexOutput i): COLOR
            {
                real3 lighdir = normalize(GetMainLight().direction);

                float dott = dot(i.nDirWS, lighdir) * 0.5 + 0.5;

                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(dott, 0.5)) * _BaseColor;

                return tex;
            }
            ENDHLSL
        }


        Pass
        {
            Name "Outline"
            Tags
            {
            }
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial) //缓冲区
            //Outline
            uniform float4 _outlinecolor;
            uniform float _outlinewidth;
            CBUFFER_END

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct VertexOutput
            {
                float4 pos : SV_POSITION;
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(float4(v.vertex.xyz + v.normal * _outlinewidth, 1));
                return o;
            }

            float4 frag(VertexOutput i) : COLOR
            {
                return float4(_outlinecolor.rgb, 0);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}