// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASESampleShaders/ImprovedReadFromAtlasTiled"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
		_Min("Min", Vector) = (0,0,0,0)
		_Max("Max", Vector) = (0,0,0,0)
		_TileSize("TileSize", Vector) = (2,2,0,0)
		_Atlas("Atlas", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _Atlas;
		uniform float4 _Atlas_TexelSize;
		uniform float2 _Min;
		uniform float4 _Atlas_ST;
		uniform float2 _TileSize;
		uniform float2 _Max;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 appendResult62 = (float2(_Atlas_TexelSize.x , _Atlas_TexelSize.y));
			float2 ScaledMin27 = ( appendResult62 * _Min );
			float2 uv_Atlas = i.uv_texcoord * _Atlas_ST.xy + _Atlas_ST.zw;
			float2 A61 = uv_Atlas;
			float2 invTileSize59 = ( float2( 1,1 ) / _TileSize );
			float2 B61 = invTileSize59;
			float2 localMyCustomExpression6161 = ( frac(A61/B61)*B61 );
			float2 ScaledMax26 = ( _Max * appendResult62 );
			float2 Size39 = ( ScaledMax26 - ScaledMin27 );
			float2 TiledVar55 = ( localMyCustomExpression6161 * Size39 );
			float2 finalUV60 = ( ScaledMin27 + ( TiledVar55 * _TileSize ) );
			o.Emission = tex2Dlod( _Atlas, float4( finalUV60, 0, 0.0) ).xyz;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=12003
0;92;1541;926;3030.459;1256.044;2.8;False;False
Node;AmplifyShaderEditor.TexelSizeNode;19;-2172.201,55.19999;Float;False;30;1;0;SAMPLER2D;;False;5;FLOAT4;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.Vector2Node;14;-1970.199,-60.79998;Float;False;Property;_Max;Max;1;0;0,0;0;3;FLOAT2;FLOAT;FLOAT
Node;AmplifyShaderEditor.DynamicAppendNode;62;-1938.199,83.19994;Float;False;FLOAT2;4;0;FLOAT;0.0;False;1;FLOAT;0.0;False;2;FLOAT;0.0;False;3;FLOAT;0.0;False;1;FLOAT2
Node;AmplifyShaderEditor.Vector2Node;13;-1970.199,211.1999;Float;False;Property;_Min;Min;0;0;0,0;0;3;FLOAT2;FLOAT;FLOAT
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;22;-1730.199,131.1999;Float;False;2;2;0;FLOAT2;0.0,0;False;1;FLOAT2;0,0;False;1;FLOAT2
Node;AmplifyShaderEditor.Vector2Node;56;-1565.199,-325.8001;Float;False;Constant;_Vector0;Vector 0;4;0;1,1;0;3;FLOAT2;FLOAT;FLOAT
Node;AmplifyShaderEditor.Vector2Node;50;-1565.199,-181.8;Float;False;Property;_TileSize;TileSize;3;0;2,2;0;3;FLOAT2;FLOAT;FLOAT
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;23;-1730.199,19.2;Float;False;2;2;0;FLOAT2;0.0,0;False;1;FLOAT2;0.0,0;False;1;FLOAT2
Node;AmplifyShaderEditor.SimpleDivideOpNode;54;-1357.199,-245.8001;Float;False;2;0;FLOAT2;0.0,0;False;1;FLOAT2;0.0,0;False;1;FLOAT2
Node;AmplifyShaderEditor.RegisterLocalVarNode;27;-1538.199,131.1999;Float;False;ScaledMin;-1;True;1;0;FLOAT2;0.0,0;False;1;FLOAT2
Node;AmplifyShaderEditor.RegisterLocalVarNode;26;-1538.199,19.2;Float;False;ScaledMax;-1;True;1;0;FLOAT2;0.0,0;False;1;FLOAT2
Node;AmplifyShaderEditor.RegisterLocalVarNode;59;-1221.199,-250.8001;Float;False;invTileSize;-1;True;1;0;FLOAT2;0.0;False;1;FLOAT2
Node;AmplifyShaderEditor.TextureCoordinatesNode;12;-1325.399,-501.4002;Float;False;0;30;2;3;2;SAMPLER2D;;False;0;FLOAT2;2,2;False;1;FLOAT2;0,0;False;5;FLOAT2;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.SimpleSubtractOpNode;38;-1298.199,67.19996;Float;False;2;0;FLOAT2;0.0,0;False;1;FLOAT2;0.0;False;1;FLOAT2
Node;AmplifyShaderEditor.CustomExpressionNode;61;-1019.058,-377.8445;Float;False;frac(A/B)*B;2;False;2;True;A;FLOAT2;0,0;In;True;B;FLOAT2;0,0;In;My Custom Expression;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2
Node;AmplifyShaderEditor.RegisterLocalVarNode;39;-1137.199,62.19997;Float;False;Size;0;True;1;0;FLOAT2;0.0,0;False;1;FLOAT2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;42;-790.6002,-207.8001;Float;False;2;2;0;FLOAT2;0.0,0;False;1;FLOAT2;0.0;False;1;FLOAT2
Node;AmplifyShaderEditor.RegisterLocalVarNode;55;-639.0001,-213.0001;Float;False;TiledVar;1;True;1;0;FLOAT2;0.0,0;False;1;FLOAT2
Node;AmplifyShaderEditor.GetLocalVarNode;41;-458.0991,-283.4985;Float;False;27;0;1;FLOAT2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;-383.6003,-138.2;Float;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0.0;False;1;FLOAT2
Node;AmplifyShaderEditor.SimpleAddOpNode;40;-204.5002,-267.0001;Float;False;2;2;0;FLOAT2;0.0,0;False;1;FLOAT2;0.0;False;1;FLOAT2
Node;AmplifyShaderEditor.RangedFloatNode;58;-16,-112;Float;False;Constant;_Float0;Float 0;4;0;0;0;0;0;1;FLOAT
Node;AmplifyShaderEditor.RegisterLocalVarNode;60;-64,-272;Float;False;finalUV;2;True;1;0;FLOAT2;0.0;False;1;FLOAT2
Node;AmplifyShaderEditor.SamplerNode;30;176,-304;Float;True;Property;_Atlas;Atlas;3;0;None;True;0;False;white;Auto;False;Object;-1;MipLevel;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;5;FLOAT4;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;546.5997,-353.9999;Float;False;True;2;Float;ASEMaterialInspector;0;Standard;ASESampleShaders/ImprovedReadFromAtlasTiled;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;0;False;0;0;Opaque;0.5;True;True;0;False;Opaque;Geometry;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;False;0;255;255;0;0;0;0;False;0;4;10;25;False;0.5;True;0;Zero;Zero;0;Zero;Zero;Add;Add;0;False;0;0,0,0,0;VertexOffset;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;0;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0.0;False;4;FLOAT;0.0;False;5;FLOAT;0.0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0.0;False;9;FLOAT;0.0;False;10;OBJECT;0.0;False;11;FLOAT3;0.0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;62;0;19;1
WireConnection;62;1;19;2
WireConnection;22;0;62;0
WireConnection;22;1;13;0
WireConnection;23;0;14;0
WireConnection;23;1;62;0
WireConnection;54;0;56;0
WireConnection;54;1;50;0
WireConnection;27;0;22;0
WireConnection;26;0;23;0
WireConnection;59;0;54;0
WireConnection;38;0;26;0
WireConnection;38;1;27;0
WireConnection;61;0;12;0
WireConnection;61;1;59;0
WireConnection;39;0;38;0
WireConnection;42;0;61;0
WireConnection;42;1;39;0
WireConnection;55;0;42;0
WireConnection;53;0;55;0
WireConnection;53;1;50;0
WireConnection;40;0;41;0
WireConnection;40;1;53;0
WireConnection;60;0;40;0
WireConnection;30;1;60;0
WireConnection;30;2;58;0
WireConnection;0;2;30;0
ASEEND*/
//CHKSM=0FF21583C22951D2EB8B4637F9BF9FF8415C9AA0
