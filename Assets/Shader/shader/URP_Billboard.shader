Shader "URP/Billboard"
{
    Properties
    {

        _MainTex("MainTex",2D)="white"{}

        _BaseColor("BaseColor",Color)=(1,1,1,1)

        _Sheet("Sheet",Vector)=(1,1,1,1)

        _FrameRate("FrameRate",float)=25

        [KeywordEnum(LOCK_Z,FREE_Z)]_Z_STAGE("Z_Stage",float)=1//定义一个是否锁定Z轴

    }

    SubShader
    {

        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"

            "Queue"="Transparent"

            "RenderType"="Transparent"
        }

        pass
        {

            Tags
            {

                "LightMode"="UniversalForward"

            }

            ZWrite off

            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local _Z_STAGE_LOCK_Z
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _BaseColor;
            half4 _Sheet;
            float _FrameRate;

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
            };


            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;

                //先构建一个新的Z轴朝向相机的坐标系，这时我们需要在模型空间下计算新的坐标系的3个坐标基

                //由于三个坐标基两两垂直，故只需要计算2个即可叉乘得到第三个坐标基

                //先计算新坐标系的Z轴

                float3 newZ = TransformWorldToObject(_WorldSpaceCameraPos); //获得模型空间的相机坐标作为新坐标的z轴

                //判断是否开启了锁定Z轴

                #ifdef _Z_STAGE_LOCK_Z

                newZ.y = 0;

                #endif

                newZ = normalize(newZ);

                //根据Z的位置去判断x的方向

                float3 newX = abs(newZ.y) < 0.99 ? cross(float3(0, 1, 0), newZ) : cross(newZ, float3(0, 0, 1));

                newX = normalize(newX);


                float3 newY = cross(newZ, newX);

                newY = normalize(newY);

                float3x3 Matrix = {newX, newY, newZ}; //这里应该取矩阵的逆 但是hlsl没有取逆矩阵的函数

                float3 newpos = mul(i.vertex.xyz, Matrix); //故在mul函数里进行右乘 等同于左乘矩阵的逆（正交阵的转置等于逆）

                o.pos = TransformObjectToHClip(newpos);

                o.uv0 = TRANSFORM_TEX(i.uv0, _MainTex);

                return o;
            }

            half4 frag(VertexOutput i):SV_TARGET
            {
                float2 uv; //小方块的uv

                uv.x = i.uv0.x / _Sheet.x + frac(floor(_Time.y * _FrameRate) / _Sheet.x);

                uv.y = i.uv0.y / _Sheet.y + 1 - frac(floor(_Time.y * _FrameRate / _Sheet.x) / _Sheet.y);

                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}