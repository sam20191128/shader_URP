Shader "URP/Halftone"
{
    Properties
    {
        _outlinecolor ("outline color", Color) = (0,0,0,1)
        _outlinewidth ("outline width", Range(0, 1)) = 0.01
        _pow ("_pow", Range(1, 100)) = 5
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"

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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial) //缓冲区
            uniform float _pow;
            CBUFFER_END

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct VertexOutput
            {
                float4 pos : SV_POSITION;
                float4 posWS : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
                float4 sspos : TEXCOORD2;
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.nDirWS = normalize(TransformObjectToWorldNormal(v.normal));
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.pos = TransformObjectToHClip(v.vertex);
                //屏幕坐标sspos，xy保存为未透除的屏幕uv，zw不变
                o.sspos.xy = o.pos.xy * 0.5 + 0.5 * float2(o.pos.w, o.pos.w);
                o.sspos.zw = o.pos.zw;
                return o;
            }

            float4 frag(VertexOutput i) : COLOR
            {
                i.nDirWS = normalize(i.nDirWS);
                float2 sceneUVs = (i.sspos.xy / i.sspos.w);
                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.pos));
                float3 lDir = normalize(mylight.direction);
                float attenuation = mylight.shadowAttenuation;
                ////// Emissive:
                //圆点 程序纹理
                float color =
                    round
                    (
                        pow
                        (
                            //圆点 程序纹理
                            length
                            (
                                frac
                                (
                                    float2(
                                        (sceneUVs.x * 2 - 1) * (_ScreenParams.r / _ScreenParams.g),
                                        sceneUVs.y * 2 - 1
                                    ).rg * _pow
                                ) * 1.0 - 0.5
                            ),
                            //重新映射 反向
                            dot(i.nDirWS, lDir) * attenuation * -2.5 + 2.0
                        )
                    ); // 非白即黑
                float3 emissive = float3(color, color, color);
                float3 finalColor = emissive;
                return float4(finalColor, 1);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}