// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASESampleShaders/PlaneClip/PlaneClip"
{
	Properties
	{
		_CutoffColor("CutoffColor", Color) = (0,0,0,0)
		_Emission("Emission", Color) = (0,0,0,0)
		[Toggle]_ActivateClip("Activate Clip", Float) = 1
		_Textured_Course_AlbedoTransparency("Textured_Course_AlbedoTransparency", 2D) = "white" {}
		_Smoothness("Smoothness", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Off
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			half ASEVFace : VFACE;
			float2 uv_texcoord;
			float3 worldPos;
		};

		uniform sampler2D _Textured_Course_AlbedoTransparency;
		uniform float4 _Textured_Course_AlbedoTransparency_ST;
		uniform float _ActivateClip;
		uniform float4 _PlaneClipNormals;
		uniform float4 _CutoffColor;
		uniform float4 _Emission;
		uniform sampler2D _Smoothness;
		uniform float4 _Smoothness_ST;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float scaledFace15 = (i.ASEVFace*0.5 + 0.5);
			float2 uv_Textured_Course_AlbedoTransparency = i.uv_texcoord * _Textured_Course_AlbedoTransparency_ST.xy + _Textured_Course_AlbedoTransparency_ST.zw;
			float3 ase_worldPos = i.worldPos;
			float dotResult3 = dot( (_PlaneClipNormals).xyz , ase_worldPos );
			clip( (( _ActivateClip )?( -( dotResult3 + _PlaneClipNormals.w ) ):( 0.0 )) );
			o.Albedo = ( scaledFace15 * tex2D( _Textured_Course_AlbedoTransparency, uv_Textured_Course_AlbedoTransparency ) ).rgb;
			float4 lerpResult19 = lerp( _CutoffColor , _Emission , scaledFace15);
			o.Emission = lerpResult19.rgb;
			float2 uv_Smoothness = i.uv_texcoord * _Smoothness_ST.xy + _Smoothness_ST.zw;
			o.Smoothness = ( scaledFace15 * tex2D( _Smoothness, uv_Smoothness ).r );
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18600
284;92;935;451;1133.873;265.6574;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;28;-1658.633,674.9114;Inherit;False;1206.166;434.1638;;7;5;4;3;6;9;2;25;Check on which side of the plane this fragment is;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;24;-1627.325,189.0802;Inherit;False;635.6047;206;;3;13;15;14;Setting Face into a 0-1 range;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector4Node;2;-1610.308,894.3813;Inherit;False;Global;_PlaneClipNormals;_PlaneClipNormals;0;0;Create;True;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;4;-1210.031,840.0652;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SwizzleNode;5;-1124.266,724.9114;Inherit;False;FLOAT3;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FaceVariableNode;13;-1577.325,248.7613;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;25;-1033.95,1027.075;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;14;-1445.15,249.3713;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;3;-897.2635,745.9115;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;15;-1231.29,244.6511;Inherit;False;scaledFace;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;6;-769.2637,799.9117;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;26;-644.2332,305.7816;Inherit;False;538.6697;195.436;;2;22;23;To deactivate clip simply place 0 on its inputs;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;29;-787.487,-1042.634;Inherit;False;771.3237;567.4838;;3;16;17;30;Albedo;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;38;-769.4392,-403.7656;Inherit;False;771.3237;567.4838;;3;41;40;45;Smoothness;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;27;45.21743,578.6174;Inherit;False;574.2001;491.001;;4;21;20;19;18;Settting different emission colors according to face;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;40;-627.7026,-314.5509;Inherit;False;15;scaledFace;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;9;-616.4636,789.5126;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;17;-645.7505,-953.4194;Inherit;False;15;scaledFace;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;23;-594.2332,355.7819;Inherit;False;Constant;_Float0;Float 0;5;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;45;-606.2471,-161.9535;Inherit;True;Property;_Smoothness;Smoothness;4;0;Create;True;0;0;False;0;False;-1;None;7b705e3c0dd4d4240acdbee5cfcd62c8;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;30;-681.6594,-815.6607;Inherit;True;Property;_Textured_Course_AlbedoTransparency;Textured_Course_AlbedoTransparency;3;0;Create;True;0;0;False;0;False;-1;None;4926e29c8bd5a29479b03ae385fa85dd;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;16;-207.4592,-931.7012;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;22;-342.5636,363.2179;Inherit;False;Property;_ActivateClip;Activate Clip;2;0;Create;True;0;0;False;0;False;1;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;20;96,800;Inherit;False;Property;_Emission;Emission;1;0;Create;True;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;18;95.41743,628.6174;Inherit;False;Property;_CutoffColor;CutoffColor;0;0;Create;True;0;0;False;0;False;0,0,0,0;0.1333333,0.1176471,0.1019608,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;21;112,976;Inherit;False;15;scaledFace;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-199.4615,-302.8827;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;19;434.4174,686.6176;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClipNode;37;328.589,-61.33515;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClipNode;8;326.8383,-396.0188;Inherit;False;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;874.9093,60.70998;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;ASESampleShaders/PlaneClip/PlaneClip;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;5;0;2;0
WireConnection;25;0;2;4
WireConnection;14;0;13;0
WireConnection;3;0;5;0
WireConnection;3;1;4;0
WireConnection;15;0;14;0
WireConnection;6;0;3;0
WireConnection;6;1;25;0
WireConnection;9;0;6;0
WireConnection;16;0;17;0
WireConnection;16;1;30;0
WireConnection;22;0;23;0
WireConnection;22;1;9;0
WireConnection;41;0;40;0
WireConnection;41;1;45;1
WireConnection;19;0;18;0
WireConnection;19;1;20;0
WireConnection;19;2;21;0
WireConnection;37;0;41;0
WireConnection;37;1;22;0
WireConnection;8;0;16;0
WireConnection;8;1;22;0
WireConnection;0;0;8;0
WireConnection;0;2;19;0
WireConnection;0;4;37;0
ASEEND*/
//CHKSM=DB70569CDF4AF23BCB28E9D913661A90CA35ED56