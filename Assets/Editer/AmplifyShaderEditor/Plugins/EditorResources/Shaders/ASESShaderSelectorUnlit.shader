Shader "Hidden/ASESShaderSelectorUnlit"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct VertexOutput
			{
				float4 vertex : SV_POSITION;
			};
			
			uniform fixed4 _Color;

			VertexOutput vert (appdata v)
			{
				VertexOutput o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (VertexOutput i) : SV_Target
			{
				return _Color;
			}
			ENDCG
		}
	}
}
