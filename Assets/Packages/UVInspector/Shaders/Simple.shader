
Shader "Hidden/nTools/UvInspector/Simple"
{ 
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (1,1,1,1)		
		_SrcBlend ("__src", Float) = 1.0
		_DstBlend ("__dst", Float) = 0.0
	}

	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

		Pass
		{
			Blend [_SrcBlend] [_DstBlend]
			ZWrite off
			ZTest off
			Cull off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _COLOR_MASK			

			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct VertexOutput {				
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			sampler2D _MainTex;
			fixed4 _Color;			

			VertexOutput vert (appdata_t v)
			{
				VertexOutput o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color * _Color;
				o.texcoord = v.texcoord;
				return o;
			}

			fixed4 frag (VertexOutput i) : SV_Target
			{
			#if _NORMALMAP
				fixed4 tex = fixed4((UnpackNormal(tex2D(_MainTex, i.texcoord)) + 1) * 0.5, 1); 
			#else
				fixed4 tex = tex2D(_MainTex, i.texcoord);
			#endif
			
			#if _COLOR_MASK
				fixed4 c = _Color * tex;
				float sum = c.r + c.g + c.b + c.a;
				return fixed4(sum, sum, sum, 1);
			#else
				return i.color * tex;
			#endif
			}
			ENDCG  
		}  
	}
}
