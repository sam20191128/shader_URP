Shader "URP/RainDrop" //Shader路径名
{
    Properties //材质面板参数
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Size("Size", Range(0, 100)) = 1.0
        _T("Time", Float) = 1.0
        _Distortion("Distortion", Float) = -5
        _Blur("Blur", Range(0, 1)) = 0.0
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
            #pragma vertex vert     //顶点着色器
            #pragma fragment frag   //片元着色器

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)

            half _Size;
            half _T;
            half _Distortion;
            half _Blur;

            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct VertexInput //输入结构
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
            };

            struct VertexOutput //输出结构
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
            };

            VertexOutput vert(VertexInput v) //顶点shader
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(v.vertex);
                o.uv0 = v.uv0;
                return o;
            }

            // 求伪随机数
            half N21(half2 p)
            {
                p = frac(p * half2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x + p.y);
            }

            half3 layer(half2 UV, half T)
            {
                half t = fmod(_Time.y + T, 3600);
                half4 col = half4(0, 0, 0, 1.0);
                half2 aspect = half2(2, 1);
                half2 uv = UV * _Size * aspect;
                uv.y += t * 0.25;
                half2 gv = frac(uv) - 0.5; //-0.5，调整原点为中间
                half2 id = floor(uv);
                half n = N21(id); // 0 1
                t += n * 6.2831; //2PI

                half w = UV.y * 10;
                half x = (n - 0.5) * 0.8;
                x += (0.4 - abs(x)) * sin(3 * w) * pow(sin(w), 6) * 0.45;
                half y = -sin(t + sin(t + sin(t) * 0.5)) * 0.45;
                y -= (gv.x - x) * (gv.x - x);
                half2 dropPos = (gv - half2(x, y)) / aspect; //- half2(x,y) 为了移动
                half drop = smoothstep(0.05, 0.03, length(dropPos));

                half2 trailPos = (gv - half2(x, t * 0.25)) / aspect; //- half2(x,y) 为了移动
                trailPos.y = (frac(trailPos.y * 8) - 0.5) / 8;
                half trail = smoothstep(0.03, 0.01, length(trailPos));
                half fogTrail = smoothstep(-0.05, 0.05, dropPos.y); // 拖尾小水滴慢慢被拖掉了
                fogTrail *= smoothstep(0.5, y, gv.y); // 拖尾小水滴渐变消失
                fogTrail *= smoothstep(0.05, 0.04, abs(dropPos.x));
                trail *= fogTrail;
                //col += fogTrail * 0.5;
                //col += trail;
                //col += drop;
                //if(gv.x > 0.48 || gv.y > 0.49) col = half4(1.0, 0, 0, 1.0); // 辅助线
                half2 offset = drop * dropPos + trail * trailPos;
                return half3(offset, fogTrail);
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                half3 drops = layer(i.uv0, _T);
                drops += layer(i.uv0 * 1.25 + 7.52, _T);
                drops += layer(i.uv0 * 1.35 + 1.54, _T);
                drops += layer(i.uv0 * 1.57 - 7.52, _T);
                half blur = _Blur * 7 * (1 - drops.z);
                half4 col = SAMPLE_TEXTURE2D_LOD(_MainTex, sampler_MainTex, half4(i.uv0 + drops.xy * _Distortion, 0, blur), 0);
                return col;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}