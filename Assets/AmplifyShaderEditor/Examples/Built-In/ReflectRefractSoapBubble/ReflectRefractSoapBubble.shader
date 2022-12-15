// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASESampleShaders/ReflectRefractSoapBubble"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
		_Opacity("Opacity", Range( 0 , 1)) = 0
		_SoapAmount("Soap Amount", Range( 0 , 1)) = 0
		_Specular("Specular", Range( 0 , 1)) = 0
		_IndexofRefraction("Index of Refraction", Range( -3 , 4)) = 1
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.8
		_Foam("Foam", 2D) = "white" {}
		_TextureSample3("Texture Sample 3", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[Header(Refraction)]
		_ChromaticAberration("Chromatic Aberration", Range( 0 , 0.3)) = 0.1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Transparent+0" }
		Cull Back
		GrabPass{ "RefractionGrab0" }
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float2 uv_texcoord;
			float4 screenPos;
		};

		uniform float _Specular;
		uniform sampler2D _TextureSample3;
		uniform sampler2D _Foam;
		uniform float4 _Foam_ST;
		uniform float _SoapAmount;
		uniform float _Smoothness;
		uniform float _Opacity;
		uniform sampler2D RefractionGrab0;
		uniform float _ChromaticAberration;
		uniform float _IndexofRefraction;

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 temp_cast_0 = ( ( cos( ( ( 5.0 * v.vertex.y ) + _Time.y ) ) * 0.015 ) + ( sin( ( ( 5.0 * v.vertex.y ) + _Time.y ) ) * 0.005 ) );
			v.vertex.xyz += temp_cast_0;
		}

		inline float4 Refraction( Input i, SurfaceOutputStandardSpecular o, float indexOfRefraction, float chomaticAberration ) {
			float3 worldNormal = o.Normal;
			float4 screenPos = i.screenPos;
			#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
			#else
				float scale = 1.0;
			#endif
			float halfPosW = screenPos.w * 0.5;
			screenPos.y = ( screenPos.y - halfPosW ) * _ProjectionParams.x * scale + halfPosW;
			#if SHADER_API_D3D9 || SHADER_API_D3D11
				screenPos.w += 0.0000001;
			#endif
			float2 projScreenPos = ( screenPos / screenPos.w ).xy;
			float3 worldViewDir = normalize( UnityWorldSpaceViewDir( i.worldPos ) );
			float3 refractionOffset = ( ( ( ( indexOfRefraction - 1.0 ) * mul( UNITY_MATRIX_V, float4( worldNormal, 0.0 ) ) ) * ( 1.0 / ( screenPos.z + 1.0 ) ) ) * ( 1.0 - dot( worldNormal, worldViewDir ) ) );
			float2 cameraRefraction = float2( refractionOffset.x, -( refractionOffset.y * _ProjectionParams.x ) );
			float4 redAlpha = tex2D( RefractionGrab0, ( projScreenPos + cameraRefraction ) );
			float green = tex2D( RefractionGrab0, ( projScreenPos + ( cameraRefraction * ( 1.0 - chomaticAberration ) ) ) ).g;
			float blue = tex2D( RefractionGrab0, ( projScreenPos + ( cameraRefraction * ( 1.0 + chomaticAberration ) ) ) ).b;
			return float4( redAlpha.r, green, blue, redAlpha.a );
		}

		void RefractionF( Input i, SurfaceOutputStandardSpecular o, inout fixed4 color )
		{
			#ifdef UNITY_PASS_FORWARDBASE
				color.rgb = color.rgb + Refraction( i, o, _IndexofRefraction, _ChromaticAberration ) * ( 1 - color.a );
				color.a = 1;
			#endif
		}

		void surf( Input i , inout SurfaceOutputStandardSpecular o )
		{
			o.Normal = float3(0,0,1);
			float3 worldViewDir = normalize( UnityWorldSpaceViewDir( i.worldPos ) );
			float4 temp_cast_0 = _Specular;
			float2 uv_Foam = i.uv_texcoord * _Foam_ST.xy + _Foam_ST.zw;
			float2 temp_cast_1 = ( ( tex2D( _Foam,(abs( uv_Foam+(_SinTime.x*0.5 + 0.5) * float2(1,1 )))).r + ( abs( (uv_Foam.x*2.0 + -1.0) ) * 0.5 ) ) + _Time.x );
			o.Specular = ( ( 1.0 - saturate( ( pow( dot( WorldNormalVector( i, float3(0,0,1) ) , worldViewDir ) , 2.0 ) - 0.1 ) ) ) * lerp( temp_cast_0 , saturate( tex2D( _TextureSample3,temp_cast_1) ) , _SoapAmount ) ).xyz;
			o.Smoothness = _Smoothness;
			o.Alpha = _Opacity;
			o.Normal = o.Normal + 0.00001 * i.screenPos * i.worldPos;
		}

		ENDCG
		CGPROGRAM
		#pragma multi_compile _ALPHAPREMULTIPLY_ON
		#pragma surface surf StandardSpecular keepalpha finalcolor:RefractionF exclude_path:deferred vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_instancing
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			# include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 worldPos : TEXCOORD6;
				float4 tSpace0 : TEXCOORD1;
				float4 tSpace1 : TEXCOORD2;
				float4 tSpace2 : TEXCOORD3;
				float4 texcoords01 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				fixed3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.texcoords01 = float4( v.texcoord.xy, v.texcoord1.xy );
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			fixed4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.texcoords01.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				fixed3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandardSpecular o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandardSpecular, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=5005
1926;62;1067;610;1238.272;72.85294;3.435406;False;False
Node;AmplifyShaderEditor.CommentaryNode;152;-912,192;Float;False;2577.155;665.7997;;24;157;156;155;150;135;151;142;140;153;81;146;132;121;131;116;164;113;171;179;175;181;180;184;185;Chromatic Specular Reflection
Node;AmplifyShaderEditor.CommentaryNode;112;618.4003,1260.8;Float;False;1036;492;;10;106;97;103;105;102;109;104;110;107;111;Wobble
Node;AmplifyShaderEditor.PosVertexDataNode;97;684.4003,1406.801;Float;False
Node;AmplifyShaderEditor.TimeNode;103;668.4003,1550.801;Float;False
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;105;892.4003,1374.801;Float;False;0;FLOAT;0.0;False;1;FLOAT;0.0;False
Node;AmplifyShaderEditor.SimpleAddOpNode;102;1020.399,1502.801;Float;False;0;FLOAT;0.0;False;1;FLOAT;0,0,0;False
Node;AmplifyShaderEditor.CosOpNode;109;1180.399,1406.801;Float;False;0;FLOAT;0.0;False
Node;AmplifyShaderEditor.SinOpNode;104;1180.399,1502.801;Float;False;0;FLOAT;0.0;False
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;110;1324.399,1406.801;Float;False;0;FLOAT;0.0;False;1;FLOAT;0.015;False
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;1324.399,1502.801;Float;False;0;FLOAT;0.0;False;1;FLOAT;0.005;False
Node;AmplifyShaderEditor.SimpleAddOpNode;111;1500.399,1454.801;Float;False;0;FLOAT;0.0;False;1;FLOAT;0.0;False
Node;AmplifyShaderEditor.RangedFloatNode;115;1408,896;Float;False;Property;_Smoothness;Smoothness;5;0;0.8;0;1
Node;AmplifyShaderEditor.RangedFloatNode;41;1408,992;Float;False;Property;_IndexofRefraction;Index of Refraction;4;0;1;-3;4
Node;AmplifyShaderEditor.RangedFloatNode;42;1408,1088;Float;False;Property;_Opacity;Opacity;3;0;0;0;1
Node;AmplifyShaderEditor.SamplerNode;116;-32,240;Float;True;Property;_Foam;Foam;5;0;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False
Node;AmplifyShaderEditor.SinTimeNode;132;-608,384;Float;False
Node;AmplifyShaderEditor.ScaleAndOffsetNode;146;-448,384;Float;False;0;FLOAT;0.0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;153;-112,592;Float;True;0;FLOAT;0.0;False;1;FLOAT;0.5;False
Node;AmplifyShaderEditor.AbsOpNode;140;-336,592;Float;True;0;FLOAT;0.0;False
Node;AmplifyShaderEditor.ScaleAndOffsetNode;142;-624,592;Float;True;0;FLOAT;0.0;False;1;FLOAT;2.0;False;2;FLOAT;-1.0;False
Node;AmplifyShaderEditor.SimpleAddOpNode;135;288,368;Float;False;0;FLOAT;0.0;False;1;FLOAT;1.32,0,0,0;False
Node;AmplifyShaderEditor.RangedFloatNode;106;668.4003,1310.8;Float;False;Constant;_DeformFrequency;Deform Frequency;8;0;5;0;0
Node;AmplifyShaderEditor.PannerNode;131;-224,256;Float;False;1;1;0;FLOAT2;0,0;False;1;FLOAT;0.0;False
Node;AmplifyShaderEditor.SimpleAddOpNode;150;512,608;Float;False;0;FLOAT;0.0;False;1;FLOAT;0.0;False
Node;AmplifyShaderEditor.TimeNode;151;240,624;Float;False
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1856,832;Float;False;True;2;Float;ASEMaterialInspector;StandardSpecular;ASESampleShaders/ReflectRefractSoapBubble;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;3;False;0;0;Translucent;0.5;True;True;0;False;Opaque;Transparent;ForwardOnly;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;False;0;255;255;0;0;0;0;False;0;4;10;25;False;0.5;True;0;Zero;Zero;0;Zero;Zero;Add;Add;0;False;0;0,0,0,0;VertexOffset;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0.0;False;5;FLOAT;0.0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0.0;False;9;FLOAT;0.0;False;10;OBJECT;0.0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;13;OBJECT;0.0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False
Node;AmplifyShaderEditor.TextureCoordinatesNode;121;-864,256;Float;True;0;116;2;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;156;480,400;Float;False;World
Node;AmplifyShaderEditor.WorldNormalVector;155;432,256;Float;False;0;FLOAT3;0,0,0;False
Node;AmplifyShaderEditor.DotProductOpNode;157;640,320;Float;False;0;FLOAT3;0.0;False;1;FLOAT3;0,0,0;False
Node;AmplifyShaderEditor.SaturateNode;171;1072,320;Float;False;0;FLOAT;0.0;False
Node;AmplifyShaderEditor.OneMinusNode;180;1216,320;Float;False;0;FLOAT;0.0;False
Node;AmplifyShaderEditor.PowerNode;175;768,320;Float;False;0;FLOAT;0.0;False;1;FLOAT;2.0;False
Node;AmplifyShaderEditor.SimpleSubtractOpNode;181;928,320;Float;False;0;FLOAT;0.0;False;1;FLOAT;0.1;False
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;179;1440,384;Float;True;0;FLOAT;0.0;False;1;FLOAT4;0.0;False
Node;AmplifyShaderEditor.LerpOp;184;1248,464;Float;False;0;FLOAT;0,0,0,0;False;1;FLOAT4;0.0;False;2;FLOAT;0.0;False
Node;AmplifyShaderEditor.SaturateNode;185;1056,464;Float;False;0;FLOAT4;0.0;False
Node;AmplifyShaderEditor.RangedFloatNode;113;720,768;Float;False;Property;_Specular;Specular;4;0;0;0;1
Node;AmplifyShaderEditor.RangedFloatNode;164;720,672;Float;False;Property;_SoapAmount;Soap Amount;4;0;0;0;1
Node;AmplifyShaderEditor.SamplerNode;81;720,448;Float;True;Property;_TextureSample3;Texture Sample 3;7;0;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False
WireConnection;105;0;106;0
WireConnection;105;1;97;2
WireConnection;102;0;105;0
WireConnection;102;1;103;2
WireConnection;109;0;102;0
WireConnection;104;0;102;0
WireConnection;110;0;109;0
WireConnection;107;0;104;0
WireConnection;111;0;110;0
WireConnection;111;1;107;0
WireConnection;116;1;131;0
WireConnection;146;0;132;1
WireConnection;153;0;140;0
WireConnection;140;0;142;0
WireConnection;142;0;121;1
WireConnection;135;0;116;1
WireConnection;135;1;153;0
WireConnection;131;0;121;0
WireConnection;131;1;146;0
WireConnection;150;0;135;0
WireConnection;150;1;151;1
WireConnection;0;3;179;0
WireConnection;0;4;115;0
WireConnection;0;8;41;0
WireConnection;0;9;42;0
WireConnection;0;11;111;0
WireConnection;157;0;155;0
WireConnection;157;1;156;0
WireConnection;171;0;181;0
WireConnection;180;0;171;0
WireConnection;175;0;157;0
WireConnection;181;0;175;0
WireConnection;179;0;180;0
WireConnection;179;1;184;0
WireConnection;184;0;113;0
WireConnection;184;1;185;0
WireConnection;184;2;164;0
WireConnection;185;0;81;0
WireConnection;81;1;150;0
ASEEND*/
//CHKSM=540670CE8DB5C674C8EF8A5C4884C681FF275FA1
