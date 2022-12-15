// Amplify Shader Editor - Visual Shader Editing Tool
// Copyright (c) Amplify Creations, Lda <info@amplify.pt>
using UnityEditor;

namespace AmplifyShaderEditor
{
	public class TemplateMenuItems
	{
		[MenuItem( "Assets/Create/Amplify Shader/Custom Render Texture/Initialize", false, 85 )]
		public static void ApplyTemplateCustomRenderTextureInitialize()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "6ce779933eb99f049b78d6163735e06f" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Custom Render Texture/Update", false, 85 )]
		public static void ApplyTemplateCustomRenderTextureUpdate()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "32120270d1b3a8746af2aca8bc749736" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Legacy/Default Sprites", false, 85 )]
		public static void ApplyTemplateLegacyDefaultSprites()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "0f8ba0101102bb14ebf021ddadce9b49" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Legacy/Image Effect", false, 85 )]
		public static void ApplyTemplateLegacyImageEffect()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "c71b220b631b6344493ea3cf87110c93" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Legacy/Lit", false, 85 )]
		public static void ApplyTemplateLegacyLit()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "ed95fe726fd7b4644bb42f4d1ddd2bcd" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Legacy/Multi Pass Unlit", false, 85 )]
		public static void ApplyTemplateLegacyMultiPassUnlit()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "e1de45c0d41f68c41b2cc20c8b9c05ef" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Legacy/Particles Alpha Blended", false, 85 )]
		public static void ApplyTemplateLegacyParticlesAlphaBlended()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "0b6a9f8b4f707c74ca64c0be8e590de0" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Legacy/Post-Processing Stack", false, 85 )]
		public static void ApplyTemplateLegacyPostProcessingStack()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "32139be9c1eb75640a847f011acf3bcf" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Legacy/Samples/DoublePassUnlit", false, 85 )]
		public static void ApplyTemplateLegacySamplesDoublePassUnlit()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "003dfa9c16768d048b74f75c088119d8" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Legacy/Unlit", false, 85 )]
		public static void ApplyTemplateLegacyUnlit()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "0770190933193b94aaa3065e307002fa" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Legacy/Unlit Lightmap", false, 85 )]
		public static void ApplyTemplateLegacyUnlitLightmap()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "899e609c083c74c4ca567477c39edef0" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/UI/Default", false, 85 )]
		public static void ApplyTemplateUIDefault()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "5056123faa0c79b47ab6ad7e8bf059a4" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Universal/Experimental/2D Lit", false, 85 )]
		public static void ApplyTemplateUniversalExperimental2DLit()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "199187dac283dbe4a8cb1ea611d70c58" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Universal/Experimental/2D Unlit", false, 85 )]
		public static void ApplyTemplateUniversalExperimental2DUnlit()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "cf964e524c8e69742b1d21fbe2ebcc4a" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Universal/Lit", false, 85 )]
		public static void ApplyTemplateUniversalLit()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "94348b07e5e8bab40bd6c8a1e3df54cd" );
		}
		[MenuItem( "Assets/Create/Amplify Shader/Universal/Unlit", false, 85 )]
		public static void ApplyTemplateUniversalUnlit()
		{
			AmplifyShaderEditorWindow.CreateConfirmationTemplateShader( "2992e84f91cbeb14eab234972e07ea9d" );
		}
	}
}
