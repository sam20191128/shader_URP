
Shader "Hidden/nTools/UvInspector/UvPreview"
{ 
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
	}

	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

		Pass
		{
			Blend off
			ZWrite off
			ZTest off
			Cull off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature _ _UV1 _UV2 _UV3
			#pragma shader_feature _VERTEX_COLORS

			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				#if _UV3
				float2 texcoord : TEXCOORD3;
				#elif _UV2
				float2 texcoord : TEXCOORD2;
				#elif _UV1
				float2 texcoord : TEXCOORD1;
				#else
				float2 texcoord : TEXCOORD0;
				#endif
			};

			struct VertexOutput {				
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
			};

			fixed4 _Color;

			VertexOutput vert (appdata_t v)
			{
				VertexOutput o;
				v.vertex.x = v.texcoord.x;
				v.vertex.y = v.texcoord.y;
				v.vertex.z = 0;
				o.vertex = UnityObjectToClipPos(v.vertex);
				#if _VERTEX_COLORS
				o.color = v.color;
				#else
				o.color = _Color;
				#endif
				return o;
			}

			fixed4 frag (VertexOutput i) : SV_Target
			{
				return i.color;
			}
			ENDCG  
		}  
	}
}
