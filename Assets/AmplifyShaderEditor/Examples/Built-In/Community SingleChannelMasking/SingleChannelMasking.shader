// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASESampleShaders/Community/SingleChannelMasking"
{
	Properties
	{
		_Mask("Mask", 2D) = "white" {}
		_Color01("Color 01", Color) = (1,0,0,0)
		_Color02("Color 02", Color) = (0,0.04827571,1,0)
		_Color03("Color 03", Color) = (1,0.6827588,0,0)
		_Color04("Color 04", Color) = (0.1376267,0.8676471,0,0)
		_Color05("Color 05", Color) = (0.8620691,0,1,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _Mask;
		uniform float4 _Mask_ST;
		uniform float4 _Color01;
		uniform float4 _Color02;
		uniform float4 _Color03;
		uniform float4 _Color04;
		uniform float4 _Color05;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv_Mask = i.uv_texcoord * _Mask_ST.xy + _Mask_ST.zw;
			float temp_output_25_0_g118 = 0.0;
			float temp_output_22_0_g118 = step( tex2D( _Mask, uv_Mask ).r , temp_output_25_0_g118 );
			float temp_output_25_0_g119 = ( temp_output_25_0_g118 + 0.2 );
			float temp_output_22_0_g119 = step( tex2D( _Mask, uv_Mask ).r , temp_output_25_0_g119 );
			float temp_output_25_0_g120 = ( temp_output_25_0_g119 + 0.2 );
			float temp_output_22_0_g120 = step( tex2D( _Mask, uv_Mask ).r , temp_output_25_0_g120 );
			float temp_output_25_0_g121 = ( temp_output_25_0_g120 + 0.2 );
			float temp_output_22_0_g121 = step( tex2D( _Mask, uv_Mask ).r , temp_output_25_0_g121 );
			float temp_output_25_0_g122 = ( temp_output_25_0_g121 + 0.2 );
			float temp_output_22_0_g122 = step( tex2D( _Mask, uv_Mask ).r , temp_output_25_0_g122 );
			o.Albedo = ( ( ( temp_output_22_0_g118 - 0 ) * _Color01 ) + ( ( temp_output_22_0_g119 - temp_output_22_0_g118 ) * _Color02 ) + ( _Color03 * ( temp_output_22_0_g120 - temp_output_22_0_g119 ) ) + ( _Color04 * ( temp_output_22_0_g121 - temp_output_22_0_g120 ) ) + ( _Color05 * ( temp_output_22_0_g122 - temp_output_22_0_g121 ) ) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=15204
1927;29;1906;1044;405.0664;1373.938;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;274;-358.7705,-1347.318;Float;False;3616.619;1259.05;Convert a single greyscale mask into 5 different B/W masks;12;241;235;204;205;253;268;99;312;311;310;309;313;Create colour masks;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;99;-337.2622,-1147.597;Float;False;415.1407;302.3209;Must be linear (untick sRGB in import settings);1;65;Main texture sample;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;65;-262.2622,-1083.597;Float;True;Property;_Mask;Mask;0;0;Create;True;0;0;False;0;ae0e8ec300b8a7c478936b1b33b60a38;ae0e8ec300b8a7c478936b1b33b60a38;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;253;-84.31908,-824.1495;Float;False;Constant;_Startclipvalue;Start clip value;8;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;313;164.6682,-1053.064;Float;True;MaskingFunction;-1;;118;571aab6f8c08f1c4d9bd4012d2958d88;0;3;21;FLOAT;0;False;30;FLOAT;0;False;25;FLOAT;0;False;3;FLOAT;0;FLOAT;32;FLOAT;28
Node;AmplifyShaderEditor.SamplerNode;205;297.7372,-1259.597;Float;True;Property;_Mask01Instance;Mask 01 (Instance);0;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Instance;65;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;309;681.7371,-1051.597;Float;True;MaskingFunction;-1;;119;571aab6f8c08f1c4d9bd4012d2958d88;0;3;21;FLOAT;0;False;30;FLOAT;0;False;25;FLOAT;0;False;3;FLOAT;0;FLOAT;32;FLOAT;28
Node;AmplifyShaderEditor.SamplerNode;204;809.7372,-1259.597;Float;True;Property;_Mask02Instance;Mask 02 (Instance);0;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Instance;65;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;235;1321.737,-1259.597;Float;True;Property;_Mask03Instance;Mask 03 (Instance);0;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Instance;65;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;268;183.7372,-637.5975;Float;False;2942;468;;20;87;88;90;86;85;83;84;96;89;264;267;259;262;97;266;265;260;263;261;82;Colour all the masks;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;310;1193.738,-1051.597;Float;True;MaskingFunction;-1;;120;571aab6f8c08f1c4d9bd4012d2958d88;0;3;21;FLOAT;0;False;30;FLOAT;0;False;25;FLOAT;0;False;3;FLOAT;0;FLOAT;32;FLOAT;28
Node;AmplifyShaderEditor.ColorNode;90;1753.738,-587.5977;Float;False;Property;_Color04;Color 04;4;0;Create;True;0;0;False;0;0.1376267,0.8676471,0,0;0.1376266,0.8676471,0,0;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;88;1257.738,-587.5977;Float;False;Property;_Color03;Color 03;3;0;Create;True;0;0;False;0;1,0.6827588,0,0;0.03448248,0,1,0;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;87;745.7371,-587.5977;Float;False;Property;_Color02;Color 02;2;0;Create;True;0;0;False;0;0,0.04827571,1,0;1,1,1,0;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;311;1705.738,-1051.597;Float;True;MaskingFunction;-1;;121;571aab6f8c08f1c4d9bd4012d2958d88;0;3;21;FLOAT;0;False;30;FLOAT;0;False;25;FLOAT;0;False;3;FLOAT;0;FLOAT;32;FLOAT;28
Node;AmplifyShaderEditor.ColorNode;86;233.7372,-587.5977;Float;False;Property;_Color01;Color 01;1;0;Create;True;0;0;False;0;1,0,0,0;1,0,0,0;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;241;1833.738,-1259.597;Float;True;Property;_Mask04Instance;Mask 04 (Instance);0;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Instance;65;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;89;2043.551,-555.5977;Float;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;96;2281.738,-571.5977;Float;False;Property;_Color05;Color 05;5;0;Create;True;0;0;False;0;0.8620691,0,1,0;1,0.5586207,0,0;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;85;1493.465,-562.8522;Float;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;84;1012.296,-569.7841;Float;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;83;487.6007,-573.4113;Float;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;312;2217.738,-1051.597;Float;True;MaskingFunction;-1;;122;571aab6f8c08f1c4d9bd4012d2958d88;0;3;21;FLOAT;0;False;30;FLOAT;0;False;25;FLOAT;0;False;3;FLOAT;0;FLOAT;32;FLOAT;28
Node;AmplifyShaderEditor.WireNode;259;751.1093,-323.1091;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;267;2258.375,-352.9496;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;97;2517.466,-570.4297;Float;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;264;1722.706,-333.5305;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;262;1257.334,-308.3474;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;265;2727.947,-414.9245;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;263;2701.777,-314.1035;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;261;2733.203,-292.5507;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;266;2704.783,-365.5042;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;260;2743.831,-255.1785;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;82;2889.738,-555.5977;Float;True;5;5;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;3335.267,-584.343;Float;False;True;2;Float;ASEMaterialInspector;0;0;Standard;ASESampleShaders/Community/SingleChannelMasking;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;0;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;0;4;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;0;0;False;0;0;0;False;-1;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;313;21;65;1
WireConnection;313;25;253;0
WireConnection;309;21;205;1
WireConnection;309;30;313;32
WireConnection;309;25;313;28
WireConnection;310;21;204;1
WireConnection;310;30;309;32
WireConnection;310;25;309;28
WireConnection;311;21;235;1
WireConnection;311;30;310;32
WireConnection;311;25;310;28
WireConnection;89;0;90;0
WireConnection;89;1;311;0
WireConnection;85;0;88;0
WireConnection;85;1;310;0
WireConnection;84;0;309;0
WireConnection;84;1;87;0
WireConnection;83;0;313;0
WireConnection;83;1;86;0
WireConnection;312;21;241;1
WireConnection;312;30;311;32
WireConnection;312;25;311;28
WireConnection;259;0;83;0
WireConnection;267;0;89;0
WireConnection;97;0;96;0
WireConnection;97;1;312;0
WireConnection;264;0;85;0
WireConnection;262;0;84;0
WireConnection;265;0;97;0
WireConnection;263;0;264;0
WireConnection;261;0;262;0
WireConnection;266;0;267;0
WireConnection;260;0;259;0
WireConnection;82;0;260;0
WireConnection;82;1;261;0
WireConnection;82;2;263;0
WireConnection;82;3;266;0
WireConnection;82;4;265;0
WireConnection;0;0;82;0
ASEEND*/
//CHKSM=47EE34B6E1AFDF53CCDAFEC74E54B2C71F44FE94
