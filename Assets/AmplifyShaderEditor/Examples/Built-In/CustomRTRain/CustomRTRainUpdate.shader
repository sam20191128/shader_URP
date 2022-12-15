// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASESampleShaders/CustomRTRainUpdate"
{
    Properties
    {
		_Resolution("Resolution", Float) = 1
		_MaxRadius("Max Radius", Int) = 2
		_TimeScale("Time Scale", Float) = 1
    }

	SubShader
	{
		
		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend Off
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		
		
        Pass
        {
			Name "Custom RT Update"
            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex ASECustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0
			#include "UnityShaderVariables.cginc"
			#define DOUBLE_HASH 1


			struct ase_appdata_customrendertexture
			{
				uint vertexID : SV_VertexID;
				
			};

			struct ase_v2f_customrendertexture
			{
				float4 vertex           : SV_POSITION;
				float3 localTexcoord    : TEXCOORD0;    // Texcoord local to the update zone (== globalTexcoord if no partial update zone is specified)
				float3 globalTexcoord   : TEXCOORD1;    // Texcoord relative to the complete custom texture
				uint primitiveID        : TEXCOORD2;    // Index of the update zone (correspond to the index in the updateZones of the Custom Texture)
				float3 direction        : TEXCOORD3;    // For cube textures, direction of the pixel being rendered in the cubemap
				
			};

			uniform float _Resolution;
			uniform int _MaxRadius;
			uniform float _TimeScale;
			float Hash12( float2 pos , float hashScale )
			{
				float3 p3  = frac(float3(pos.xyx) * hashScale);
				p3 += dot(p3, p3.yzx + 19.19);
				return frac((p3.x + p3.y) * p3.z);
			}
			
			float Hash22( float2 pos , float3 hashScale3 )
			{
				float3 p3 = frac(float3(pos.xyx) * hashScale3);
				p3 += dot(p3, p3.yzx+19.19);
				return frac((p3.xx+p3.yz)*p3.zy);
			}
			
			void CalculateRipples( float resolution , float2 uv , int maxRadius , float time , float hashScale , float3 hashScale3 , out float2 rippleUVOffset , out float rippleIntensity )
			{
				uv *= resolution;
				float2 p0 = floor(uv);
				float2 circles = float2(0,0);
				float maxRadiusf = maxRadius;
				for (int j = -maxRadius; j <= maxRadius; ++j)
				{
					for (int i = -maxRadius; i <= maxRadius; ++i)
					{
						float2 pi = p0 + float2(i, j);
						#if DOUBLE_HASH
						float2 hsh = Hash22(pi,hashScale3);
						#else
						float2 hsh = pi;
						#endif
						float2 p = pi + Hash22(hsh,hashScale3);
						float t = frac(0.3*time + Hash12(hsh,hashScale));
						float2 v = p - uv;
						float d = length(v) - (maxRadiusf + 1.0)*t;
						float h = 1e-3;
						float d1 = d - h;
						float d2 = d + h;
						float p1 = sin(31.*d1) * smoothstep(-0.6, -0.3, d1) * smoothstep(0.0, -0.3, d1);
						float p2 = sin(31.*d2) * smoothstep(-0.6, -0.3, d2) * smoothstep(0.0, -0.3, d2);
						circles += 0.5 * normalize(v) * ((p2 - p1) / (2 * h) * (1.0 - t) * (1.0 - t));
					}
				}
				circles /= float((maxRadiusf*2.0+1.0)*(maxRadiusf*2.0+1.0));
				float intensity = lerp(0.01, 0.15, smoothstep(0.1, 0.6, abs(frac(0.05*time + 0.5)*2.0-1.0)));
				float3 n = float3(circles, sqrt(1.0 - dot(circles, circles)));
				rippleUVOffset = intensity*n.xy;
				rippleIntensity = 5.0*pow(clamp(dot(n, normalize(float3(1.0, 0.7, 0.5))), 0.0, 1.0), 6.0);
				return;
			}
			

			ase_v2f_customrendertexture ASECustomRenderTextureVertexShader(ase_appdata_customrendertexture IN  )
			{
				ase_v2f_customrendertexture OUT;
				
			#if UNITY_UV_STARTS_AT_TOP
				const float2 vertexPositions[6] =
				{
					{ -1.0f,  1.0f },
					{ -1.0f, -1.0f },
					{  1.0f, -1.0f },
					{  1.0f,  1.0f },
					{ -1.0f,  1.0f },
					{  1.0f, -1.0f }
				};

				const float2 texCoords[6] =
				{
					{ 0.0f, 0.0f },
					{ 0.0f, 1.0f },
					{ 1.0f, 1.0f },
					{ 1.0f, 0.0f },
					{ 0.0f, 0.0f },
					{ 1.0f, 1.0f }
				};
			#else
				const float2 vertexPositions[6] =
				{
					{  1.0f,  1.0f },
					{ -1.0f, -1.0f },
					{ -1.0f,  1.0f },
					{ -1.0f, -1.0f },
					{  1.0f,  1.0f },
					{  1.0f, -1.0f }
				};

				const float2 texCoords[6] =
				{
					{ 1.0f, 1.0f },
					{ 0.0f, 0.0f },
					{ 0.0f, 1.0f },
					{ 0.0f, 0.0f },
					{ 1.0f, 1.0f },
					{ 1.0f, 0.0f }
				};
			#endif

				uint primitiveID = IN.vertexID / 6;
				uint vertexID = IN.vertexID % 6;
				float3 updateZoneCenter = CustomRenderTextureCenters[primitiveID].xyz;
				float3 updateZoneSize = CustomRenderTextureSizesAndRotations[primitiveID].xyz;
				float rotation = CustomRenderTextureSizesAndRotations[primitiveID].w * UNITY_PI / 180.0f;

			#if !UNITY_UV_STARTS_AT_TOP
				rotation = -rotation;
			#endif

				// Normalize rect if needed
				if (CustomRenderTextureUpdateSpace > 0.0) // Pixel space
				{
					// Normalize xy because we need it in clip space.
					updateZoneCenter.xy /= _CustomRenderTextureInfo.xy;
					updateZoneSize.xy /= _CustomRenderTextureInfo.xy;
				}
				else // normalized space
				{
					// Un-normalize depth because we need actual slice index for culling
					updateZoneCenter.z *= _CustomRenderTextureInfo.z;
					updateZoneSize.z *= _CustomRenderTextureInfo.z;
				}

				// Compute rotation

				// Compute quad vertex position
				float2 clipSpaceCenter = updateZoneCenter.xy * 2.0 - 1.0;
				float2 pos = vertexPositions[vertexID] * updateZoneSize.xy;
				pos = CustomRenderTextureRotate2D(pos, rotation);
				pos.x += clipSpaceCenter.x;
			#if UNITY_UV_STARTS_AT_TOP
				pos.y += clipSpaceCenter.y;
			#else
				pos.y -= clipSpaceCenter.y;
			#endif

				// For 3D texture, cull quads outside of the update zone
				// This is neeeded in additional to the preliminary minSlice/maxSlice done on the CPU because update zones can be disjointed.
				// ie: slices [1..5] and [10..15] for two differents zones so we need to cull out slices 0 and [6..9]
				if (CustomRenderTextureIs3D > 0.0)
				{
					int minSlice = (int)(updateZoneCenter.z - updateZoneSize.z * 0.5);
					int maxSlice = minSlice + (int)updateZoneSize.z;
					if (_CustomRenderTexture3DSlice < minSlice || _CustomRenderTexture3DSlice >= maxSlice)
					{
						pos.xy = float2(1000.0, 1000.0); // Vertex outside of ncs
					}
				}

				OUT.vertex = float4(pos, 0.0, 1.0);
				OUT.primitiveID = asuint(CustomRenderTexturePrimitiveIDs[primitiveID]);
				OUT.localTexcoord = float3(texCoords[vertexID], CustomRenderTexture3DTexcoordW);
				OUT.globalTexcoord = float3(pos.xy * 0.5 + 0.5, CustomRenderTexture3DTexcoordW);
			#if UNITY_UV_STARTS_AT_TOP
				OUT.globalTexcoord.y = 1.0 - OUT.globalTexcoord.y;
			#endif
				OUT.direction = CustomRenderTextureComputeCubeDirection(OUT.globalTexcoord.xy);

				return OUT;
			}

            float4 frag(ase_v2f_customrendertexture IN ) : COLOR
            {
				float4 finalColor;
				float localCalculateRipples8 = ( 0.0 );
				float resolution8 = _Resolution;
				float2 uv12 = IN.globalTexcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv8 = uv12;
				int maxRadius8 = _MaxRadius;
				float mulTime16 = _Time.y * _TimeScale;
				float time8 = mulTime16;
				float hashScale8 = 0.1031;
				float3 hashScale38 = float3(0.1031,0.103,0.0973);
				float2 rippleUVOffset8 = float2( 0,0 );
				float rippleIntensity8 = 0.0;
				CalculateRipples( resolution8 , uv8 , maxRadius8 , time8 , hashScale8 , hashScale38 , rippleUVOffset8 , rippleIntensity8 );
				float4 appendResult10 = (float4(rippleUVOffset8 , 0.0 , rippleIntensity8));
				
                finalColor = appendResult10;
				return finalColor;
            }
            ENDCG
		}
    }
	
	CustomEditor "ASEMaterialInspector"
	
}
/*ASEBEGIN
Version=15701
556;185;1066;843;1042.542;874.718;1.026785;True;False
Node;AmplifyShaderEditor.CommentaryNode;5;-778.9706,-438.6071;Float;False;1110.81;785.8901;Rain ripple effect based on https://www.shadertoy.com/view/ldfyzl;11;10;8;16;15;18;17;12;19;13;7;6;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-688.2086,4.02002;Float;False;Property;_TimeScale;Time Scale;2;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;15;-595.8566,-89.22518;Float;False;Property;_MaxRadius;Max Radius;1;0;Create;True;0;0;False;0;2;2;0;1;INT;0
Node;AmplifyShaderEditor.SimpleTimeNode;16;-532.8568,0.7747045;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;12;-662.8566,-214.2252;Float;False;1;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;18;-498.9513,187.6462;Float;False;Constant;_Vector0;Vector 0;1;0;Create;True;0;0;False;0;0.1031,0.103,0.0973;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;17;-498.9513,91.64619;Float;False;Constant;_Float3;Float 3;1;0;Create;True;0;0;False;0;0.1031;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-433.7168,-259.9484;Float;False;Property;_Resolution;Resolution;0;0;Create;True;0;0;False;0;1;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;8;-271.7881,-124.8105;Float;False;uv *= resolution@$float2 p0 = floor(uv)@$float2 circles = float2(0,0)@$float maxRadiusf = maxRadius@$for (int j = -maxRadius@ j <= maxRadius@ ++j)${$	for (int i = -maxRadius@ i <= maxRadius@ ++i)$	{$		float2 pi = p0 + float2(i, j)@$		#if DOUBLE_HASH$		float2 hsh = Hash22(pi,hashScale3)@$		#else$		float2 hsh = pi@$		#endif$		float2 p = pi + Hash22(hsh,hashScale3)@$$		float t = frac(0.3*time + Hash12(hsh,hashScale))@$		float2 v = p - uv@$		float d = length(v) - (maxRadiusf + 1.0)*t@$$		float h = 1e-3@$		float d1 = d - h@$		float d2 = d + h@$		float p1 = sin(31.*d1) * smoothstep(-0.6, -0.3, d1) * smoothstep(0.0, -0.3, d1)@$		float p2 = sin(31.*d2) * smoothstep(-0.6, -0.3, d2) * smoothstep(0.0, -0.3, d2)@$		circles += 0.5 * normalize(v) * ((p2 - p1) / (2 * h) * (1.0 - t) * (1.0 - t))@$	}$}$circles /= float((maxRadiusf*2.0+1.0)*(maxRadiusf*2.0+1.0))@$$float intensity = lerp(0.01, 0.15, smoothstep(0.1, 0.6, abs(frac(0.05*time + 0.5)*2.0-1.0)))@$float3 n = float3(circles, sqrt(1.0 - dot(circles, circles)))@$rippleUVOffset = intensity*n.xy@$rippleIntensity = 5.0*pow(clamp(dot(n, normalize(float3(1.0, 0.7, 0.5))), 0.0, 1.0), 6.0)@$return@$;7;False;8;True;resolution;FLOAT;0;In;;Float;True;uv;FLOAT2;0,0;In;;Float;True;maxRadius;INT;0;In;;Float;True;time;FLOAT;0;In;;Float;True;hashScale;FLOAT;0;In;;Float;True;hashScale3;FLOAT3;0,0,0;In;;Float;True;rippleUVOffset;FLOAT2;0,0;Out;;Float;True;rippleIntensity;FLOAT;0;Out;;Float;CalculateRipples;False;True;2;6;7;9;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT2;0,0;False;3;INT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT2;0,0;False;8;FLOAT;0;False;3;FLOAT;0;FLOAT2;8;FLOAT;9
Node;AmplifyShaderEditor.DynamicAppendNode;10;52.82076,-98.82591;Float;False;FLOAT4;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CustomExpressionNode;7;-418.4158,-384.8599;Float;False;float3 p3 = frac(float3(pos.xyx) * hashScale3)@$p3 += dot(p3, p3.yzx+19.19)@$return frac((p3.xx+p3.yz)*p3.zy)@;1;False;2;True;pos;FLOAT2;0,0;In;;Float;True;hashScale3;FLOAT3;0,0,0;In;;Float;Hash22;False;True;0;2;0;FLOAT2;0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;6;-629.6786,-364.2099;Float;False;float3 p3  = frac(float3(pos.xyx) * hashScale)@$p3 += dot(p3, p3.yzx + 19.19)@$return frac((p3.x + p3.y) * p3.z)@;1;False;2;True;pos;FLOAT2;0,0;In;;Float;True;hashScale;FLOAT;0;In;;Float;Hash12;False;True;0;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;370.1,-27.79996;Float;False;True;2;Float;ASEMaterialInspector;0;3;ASESampleShaders/CustomRTRainUpdate;32120270d1b3a8746af2aca8bc749736;0;0;Custom RT Update;1;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;True;2;0;False;False;False;False;False;False;False;False;False;True;2;1;Define;DOUBLE_HASH 1;False;;;0;0;Standard;0;1;0;FLOAT4;0,0,0,0;False;0
WireConnection;16;0;19;0
WireConnection;8;1;13;0
WireConnection;8;2;12;0
WireConnection;8;3;15;0
WireConnection;8;4;16;0
WireConnection;8;5;17;0
WireConnection;8;6;18;0
WireConnection;10;0;8;8
WireConnection;10;3;8;9
WireConnection;0;0;10;0
ASEEND*/
//CHKSM=4BEA9D858F5ACD9F0B77FA9792D5600FAB5C27B1