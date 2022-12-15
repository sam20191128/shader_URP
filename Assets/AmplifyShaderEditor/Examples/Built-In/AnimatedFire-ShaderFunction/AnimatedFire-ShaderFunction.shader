// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASESampleShaders/AnimatedFireShaderFunction"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
		[Header(Burn Effect)]
		_FireTexture("Fire Texture", 2D) = "white" {}
		_BurnMask("Burn Mask", 2D) = "white" {}
		_FireIntensity("Fire Intensity", Range( 0 , 2)) = 2
		_Albedo("Albedo", 2D) = "white" {}
		_Normals("Normals", 2D) = "bump" {}
		_Specular("Specular", 2D) = "white" {}
		_Smoothness("Smoothness", Float) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma surface surf StandardSpecular keepalpha addshadow fullforwardshadows vertex:vertexDataFunc 
		struct Input
		{
			float2 texcoord_0;
			float2 uv_texcoord;
		};

		uniform sampler2D _Normals;
		uniform sampler2D _Albedo;
		uniform sampler2D _BurnMask;
		uniform float4 _BurnMask_ST;
		uniform sampler2D _FireTexture;
		uniform float _FireIntensity;
		uniform sampler2D _Specular;
		uniform float _Smoothness;

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.texcoord_0.xy = v.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
		}

		void surf( Input i , inout SurfaceOutputStandardSpecular o )
		{
			o.Normal = UnpackNormal( tex2D( _Normals,i.texcoord_0) );
			o.Albedo = tex2D( _Albedo,i.texcoord_0).xyz;
			float2 uv_BurnMask = i.uv_texcoord * _BurnMask_ST.xy + _BurnMask_ST.zw;
			o.Emission = ( ( tex2D( _BurnMask,uv_BurnMask) * tex2D( _FireTexture,(abs( i.texcoord_0+_Time.x * float2(-1,0 )))) ) * ( _FireIntensity * ( _SinTime.w + 1.5 ) ) ).xyz;
			o.Specular = tex2D( _Specular,i.texcoord_0).xyz;
			o.Smoothness = _Smoothness;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=7206
796;92;1124;966;1213.376;278.8553;1.3;False;False
Node;AmplifyShaderEditor.RangedFloatNode;19;-855.2775,119.1449;Float;False;Property;_FireIntensity;Fire Intensity;4;0;2;0;2;0;1;FLOAT
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-1413.839,183.3731;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.SamplerNode;13;-535.8399,-92.72685;Float;True;Property;_Normals;Normals;6;0;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;1.0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;5;FLOAT3;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.FunctionNode;21;-541.476,199.8449;Float;False;Burn Effect;0;;2;2;0;FLOAT;0;False;1;FLOAT2;0.0,0;False;1;FLOAT4
Node;AmplifyShaderEditor.SamplerNode;17;-535.7401,-292.4268;Float;True;Property;_Albedo;Albedo;5;0;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;1.0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;5;FLOAT4;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;15;-9.840205,290.5776;Float;False;Property;_Smoothness;Smoothness;8;0;1;0;0;0;1;FLOAT
Node;AmplifyShaderEditor.SamplerNode;16;-520.8406,351.0728;Float;True;Property;_Specular;Specular;7;0;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;1.0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;5;FLOAT4;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;291.1997,-174.2;Float;False;True;2;Float;ASEMaterialInspector;0;StandardSpecular;ASESampleShaders/AnimatedFireShaderFunction;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;0;False;0;0;Opaque;0.5;True;True;0;False;Opaque;Geometry;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;False;0;255;255;0;0;0;0;False;0;4;10;25;False;0.5;True;0;Zero;Zero;0;Zero;Zero;Add;Add;0;False;0;0,0,0,0;VertexOffset;False;Cylindrical;Relative;0;;-1;-1;-1;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0.0;False;5;FLOAT;0.0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0.0;False;9;FLOAT;0.0;False;10;OBJECT;0.0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;13;OBJECT;0.0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;13;1;4;0
WireConnection;21;0;19;0
WireConnection;21;1;4;0
WireConnection;17;1;4;0
WireConnection;16;1;4;0
WireConnection;0;0;17;0
WireConnection;0;1;13;0
WireConnection;0;2;21;0
WireConnection;0;3;16;0
WireConnection;0;4;15;0
ASEEND*/
//CHKSM=EDF930C79FDA46758F6BA9A9F205BA1B206358E2
