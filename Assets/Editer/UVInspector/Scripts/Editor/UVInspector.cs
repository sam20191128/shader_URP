
using UnityEngine;
using UnityEditor;
using System;
using System.Text;
using System.Collections.Generic;


namespace nTools.UVInspector
{
    

    //
    // class UVInspector
    //
    public class UVInspector : EditorWindow
    {

        class InspectedObject
        {
            public UnityEngine.Object   obj = null;
            public GameObject           gameObject = null;
            public Mesh                 mesh = null;
            public List<Vector2>        uv = null;
            public bool[]               hasUV = { false, false, false, false };
            public bool                 hasColors = false;
            public int                  vertexCount = 0;
            public int                  triangleCount = 0;
			public int 					subMeshCount = 0; 
        }

        enum UVSet
        {
            UV1 = 0, UV2 = 1, UV3 = 2, UV4 = 3
        }

		enum PreviewTextureSource
		{
			None,
			Material,
			Custom,
		}
		
		enum ColorChannels
		{
			R, G, B, A, All,
		}

        static class Styles
        {
            public static Color     backgroundColor = new Color32(71, 71, 71, 255);
            public static Color     gridColor       = new Color32(100, 100, 100, 255);
            public static Color     wireframeColor  = new Color32(255, 255, 255, 255);
            public static Color     wireframeColor2 = new Color32(93, 118, 154, 255);

            public static GUIStyle  logoFont;

            public static GUIStyle  hudFont;

            public static GUIStyle  tooltip;

            public static string[]  uvSetNames      = Enum.GetNames (typeof (UVSet));
			public static string[]  colorChannelsNames = Enum.GetNames (typeof (ColorChannels));
            public static string[]  previewTextureSourceNames = Enum.GetNames(typeof(PreviewTextureSource));

            public static GUIStyle  buttonLeft;
			public static GUIStyle  buttonMid;
			public static GUIStyle  buttonRight;

			public const int		kSubMeshButtonWitdh = 30;
			public static string[]  subMeshLabels = new string[32];

			public static Color     foldoutTintColor;

            static Styles()
            {
                logoFont = new GUIStyle(EditorStyles.label);
                logoFont.alignment = TextAnchor.MiddleCenter;
                logoFont.fontSize = 20;

                hudFont = new GUIStyle(EditorStyles.boldLabel);
                hudFont.alignment = TextAnchor.LowerCenter;
                hudFont.normal.textColor = Color.white;

				buttonLeft = GUI.skin.GetStyle("buttonLeft");
				buttonMid = GUI.skin.GetStyle("buttonMid");
				buttonRight = GUI.skin.GetStyle("buttonRight");

                tooltip = GUI.skin.GetStyle("tooltip");

                for (int i = 0; i < 32; i++)
					subMeshLabels[i] = "#" + i.ToString();

				foldoutTintColor = EditorGUIUtility.isProSkin 
					? new Color (1f, 1f, 1f, 0.05f) : new Color (0f, 0f, 0f, 0.05f);
            }
        }

		static class nGUI
		{
			static int	s_ToggleHash = "nTools.nGUI.Toggle".GetHashCode();

			public static bool Toggle(Rect rect, bool value, string label, GUIStyle style)
			{
				Event e = Event.current;
				int controlID = GUIUtility.GetControlID(s_ToggleHash, FocusType.Passive, rect);
				
				switch(e.GetTypeForControl(controlID))
				{
				case EventType.MouseDown:
					if(rect.Contains(e.mousePosition) && e.button == 0)
					{
						GUIUtility.keyboardControl = controlID;
						GUIUtility.hotControl = controlID;
						e.Use();
					}
					break;
				case EventType.MouseUp:
					if (GUIUtility.hotControl == controlID && e.button == 0)
					{
						GUI.changed = true;
						value = !value;
						GUIUtility.hotControl = 0;
						e.Use();
					}
					break;
				case EventType.Repaint:
					{
						style.Draw(rect, label, GUI.enabled && GUIUtility.hotControl == controlID, GUI.enabled && GUIUtility.hotControl == controlID, value, false);
					}
					break;
				}

				return value;
			}

			public static bool Foldout(bool foldout, string content)
			{
				Rect rect = EditorGUILayout.GetControlRect(true, EditorGUIUtility.singleLineHeight, EditorStyles.foldout);
				
				EditorGUI.DrawRect(EditorGUI.IndentedRect(rect), Styles.foldoutTintColor);
				
				Rect foldoutRect = rect;
				foldoutRect.width = EditorGUIUtility.singleLineHeight;
				foldout = EditorGUI.Foldout(rect, foldout, "", true);
				
				rect.x += EditorGUIUtility.singleLineHeight;
				EditorGUI.LabelField(rect, content, EditorStyles.boldLabel);
				
				return foldout;
			}
		}


        //
        // class UVSnapshot
        //
        public class UVSnapshot : EditorWindow
        {            
            UVInspector m_Inspector;

            string m_FilePath;

            int m_TextureWidth = 2048;
            int m_TextureHeight = 2048;            

            float m_UMin = 0.0f;
            float m_UMax = 1.0f;
            float m_VMin = 0.0f;
            float m_VMax = 1.0f;

            Color m_WireColor = Color.white;

            
            void DrawLine(float x1, float y1, float x2, float y2, Texture2D texture)
            {
                float x, y, dx, dy, step;

                float tw = texture.width;
                float th = texture.height;

                dx = (x2 - x1);
                dy = (y2 - y1);

                if (Mathf.Abs(dx) >= Mathf.Abs(dy))
                    step = Mathf.Abs(dx);
                else
                    step = Mathf.Abs(dy);

                x = x1;
                y = y1;

                int i = 0;
                                
                dx = dx / step;
                dy = dy / step;

                while (i <= step)
                {
                    if (x >= 0 && x < tw && y >= 0 && y < th)
                        texture.SetPixel((int)x, (int)y, m_WireColor);

                    x += dx;
                    y += dy;
                    i++;
                }                
            }

            void OnEnable()
            {
                m_FilePath = EditorPrefs.GetString("nTools.UVInspector.UVShapshot.FilePath", "");

                m_TextureWidth = EditorPrefs.GetInt("nTools.UVInspector.UVShapshot.TextureWidth", m_TextureWidth);
                m_TextureHeight = EditorPrefs.GetInt("nTools.UVInspector.UVShapshot.TextureHeight", m_TextureHeight);

                m_UMin = EditorPrefs.GetFloat("nTools.UVInspector.UVShapshot.UMin", m_UMin);
                m_UMax = EditorPrefs.GetFloat("nTools.UVInspector.UVShapshot.UMax", m_UMax);
                m_VMin = EditorPrefs.GetFloat("nTools.UVInspector.UVShapshot.VMin", m_VMin);
                m_VMax = EditorPrefs.GetFloat("nTools.UVInspector.UVShapshot.VMax", m_VMax);

                m_WireColor = UVInspector.IntToColor(EditorPrefs.GetInt("nTools.UVInspector.UVShapshot.WireColor",  UVInspector.ColorToInt(m_WireColor)));                
            }

            void OnDestroy()
            {
                EditorPrefs.SetString("nTools.UVInspector.UVShapshot.FilePath", m_FilePath);

                EditorPrefs.SetInt("nTools.UVInspector.UVShapshot.TextureWidth", m_TextureWidth);
                EditorPrefs.SetInt("nTools.UVInspector.UVShapshot.TextureHeight", m_TextureHeight);

                EditorPrefs.SetFloat("nTools.UVInspector.UVShapshot.UMin", m_UMin);
                EditorPrefs.SetFloat("nTools.UVInspector.UVShapshot.UMax", m_UMax);
                EditorPrefs.SetFloat("nTools.UVInspector.UVShapshot.VMin", m_VMin);
                EditorPrefs.SetFloat("nTools.UVInspector.UVShapshot.VMax", m_VMax);

                EditorPrefs.SetInt("nTools.UVInspector.UVShapshot.WireColor", UVInspector.ColorToInt(m_WireColor));
            }



            void SaveUVSnapshot(string fileName)
            {                
                Texture2D texture = new Texture2D(m_TextureWidth, m_TextureHeight, TextureFormat.ARGB32, false, false);                

                for (int x = 0; x < m_TextureWidth; x++)
                {
                    for (int y = 0; y < m_TextureHeight; y++)
                    {
                        texture.SetPixel(x, y, new Color(0, 0, 0, 0));
                    }
                }

                
                Vector2 uvScale = new Vector2(1f / (m_UMax - m_UMin) * m_TextureWidth-1f, 1f / (m_VMax - m_VMin) * m_TextureHeight-1f);
                Vector2 uvShift = new Vector2(m_UMin, m_VMin);
                
                int objectCount = m_Inspector.m_InspectedObjects.Count;

                for (int i = 0; i < objectCount; i++)
                {
                    Mesh mesh = m_Inspector.m_InspectedObjects[i].mesh;
                    int[] indices = mesh.triangles;
                    Vector2[] uvs;

                    switch (m_Inspector.m_PreviewUVSet)
                    {
                    default:
                    case UVSet.UV1:
                        uvs = mesh.uv;
                        break;
                    case UVSet.UV2:
                        uvs = mesh.uv2;
                        break;
                    case UVSet.UV3:
                        uvs = mesh.uv3;
                        break;
                    case UVSet.UV4:
                        uvs = mesh.uv4;
                        break;
                    }

                    if (uvs == null || uvs.Length == 0)
                    {
                        Debug.LogWarning("UVSnapshot: object \"" + m_Inspector.m_InspectedObjects[i].gameObject.name + "\" has unassigned UV channel " + m_Inspector.m_PreviewUVSet.ToString());
                        continue;
                    }

                    if (objectCount == 1)
                    {
                        int subMeshCount = mesh.subMeshCount;

                        for (int j = 0; j < subMeshCount; j++)
                        {
                            if (!m_Inspector.m_SubMeshToggleField[j])
                                continue;

                            uint indexStart = mesh.GetIndexStart(j);
                            uint indexCount = mesh.GetIndexCount(j);

                            for (uint t = indexStart; t < indexCount; t += 3)
                            {
                                Vector2 a = uvs[indices[t]];
                                Vector2 b = uvs[indices[t + 1]];
                                Vector2 c = uvs[indices[t + 2]];

                                a = Vector2.Scale(a - uvShift, uvScale);
                                b = Vector2.Scale(b - uvShift, uvScale);
                                c = Vector2.Scale(c - uvShift, uvScale);

                                DrawLine(a.x, a.y, b.x, b.y, texture);
                                DrawLine(b.x, b.y, c.x, c.y, texture);
                                DrawLine(c.x, c.y, a.x, a.y, texture);
                            }
                        }
                    }
                    else
                    {
                        int indexCount = indices.Length;

                        for (int t = 0; t < indexCount; t += 3)
                        {
                            Vector2 a = uvs[indices[t]];
                            Vector2 b = uvs[indices[t + 1]];
                            Vector2 c = uvs[indices[t + 2]];

                            a = Vector2.Scale(a - uvShift, uvScale);
                            b = Vector2.Scale(b - uvShift, uvScale);
                            c = Vector2.Scale(c - uvShift, uvScale);

                            DrawLine(a.x, a.y, b.x, b.y, texture);
                            DrawLine(b.x, b.y, c.x, c.y, texture);
                            DrawLine(c.x, c.y, a.x, a.y, texture);
                        }
                    }
                }

                texture.Apply(false, false);

                byte[] pngBytes = texture.EncodeToPNG();

                DestroyImmediate(texture);                

                System.IO.File.WriteAllBytes(fileName, pngBytes);
            }

            void OnGUI()
            {
                if (m_Inspector == null)
                {
                    Close();
                    return;
                }

                Event e = Event.current;

                if (e.isKey && e.keyCode == KeyCode.Escape)
                    Close();

                if (m_Inspector.m_InspectedObjects.Count == 0)
                {
                    EditorGUILayout.Space();
                    EditorGUILayout.HelpBox("Nothing selected.", MessageType.Warning);
                    EditorGUILayout.Space();
                }
                                
                {
                    EditorGUILayout.Space();
                    EditorGUILayout.LabelField("Resolution", EditorStyles.boldLabel);
                    EditorGUILayout.Space();

                    ++EditorGUI.indentLevel;
                    m_TextureWidth = EditorGUILayout.IntSlider("Width", m_TextureWidth, 1, SystemInfo.maxTextureSize);
                    m_TextureHeight = EditorGUILayout.IntSlider("Height", m_TextureHeight, 1, SystemInfo.maxTextureSize);
                    --EditorGUI.indentLevel;

                    EditorGUILayout.Space();
                    EditorGUILayout.LabelField("UV Range", EditorStyles.boldLabel);
                    EditorGUILayout.Space();

                    ++EditorGUI.indentLevel;
                    m_UMin = EditorGUILayout.FloatField("U Min", m_UMin);
                    m_UMax = EditorGUILayout.FloatField("U Max", m_UMax);
                    m_VMin = EditorGUILayout.FloatField("V Min", m_VMin);
                    m_VMax = EditorGUILayout.FloatField("V Max", m_VMax);
                    --EditorGUI.indentLevel;

                    EditorGUILayout.Space();
                    EditorGUILayout.LabelField("Color", EditorStyles.boldLabel);
                    EditorGUILayout.Space();

                    ++EditorGUI.indentLevel;
                    m_WireColor = EditorGUILayout.ColorField("Wire Color", m_WireColor);
                    --EditorGUI.indentLevel;                    
                }

                EditorGUILayout.Space();
                EditorGUILayout.Space();

                EditorGUILayout.BeginHorizontal();
                GUILayout.FlexibleSpace();
                if (GUI.Button(EditorGUILayout.GetControlRect(GUILayout.Width(80)), "Reset"))
                {
                    m_TextureWidth = 2048;
                    m_TextureHeight = 2048;

                    m_UMin = 0.0f;
                    m_UMax = 1.0f;
                    m_VMin = 0.0f;
                    m_VMax = 1.0f;

                    m_WireColor = Color.white;
                }

                if (GUI.Button(EditorGUILayout.GetControlRect(GUILayout.Width(80)), "Save..."))
                {
                    string fileName = EditorUtility.SaveFilePanel("Save UV Snapshot...", m_FilePath, "uvsnapshot.png", "png");
                    m_FilePath = System.IO.Path.GetDirectoryName(fileName);

                    SaveUVSnapshot(fileName);

                    Close();
                }
                GUILayout.FlexibleSpace();
                EditorGUILayout.EndHorizontal();
            }            

            public static void ShowDialog(UVInspector inspector)
            {
                Vector2 size = new Vector2(500, 320);

                UVSnapshot window = (UVSnapshot)EditorWindow.GetWindow(typeof(UVSnapshot));
                window.m_Inspector = inspector;
                window.minSize = size;
                window.maxSize = size;               
                window.titleContent = new GUIContent("UV Snapshot", "");
                window.ShowPopup();
            }
        }


        public class TextureSettingsPopupWindow : PopupWindowContent
        {
            public UVInspector inspector;

            public override Vector2 GetWindowSize()
            {
                return new Vector2(400, 200);
            }

            public override void OnGUI(Rect rect)
            {
                if (inspector == null)
                {
                    editorWindow.Close();
                    return;
                }
               
                Event e = Event.current;                

                if (e.isKey && e.keyCode == KeyCode.Escape)
                    editorWindow.Close();

                EditorGUILayout.Space();

                EditorGUILayout.LabelField("Texture", EditorStyles.boldLabel);

                EditorGUI.BeginChangeCheck();



                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.PrefixLabel("Texture Source");
                inspector.m_PreviewTextureSource = (PreviewTextureSource)GUILayout.Toolbar((int)inspector.m_PreviewTextureSource, Styles.previewTextureSourceNames, GUILayout.MaxWidth(200), GUILayout.Height(20));
                EditorGUILayout.EndHorizontal();
                                               

                ++EditorGUI.indentLevel;
                if (inspector.m_PreviewTextureSource == PreviewTextureSource.Custom)
                {
                    inspector.m_CustomPreviewTexture = (Texture2D)EditorGUILayout.ObjectField("Image", inspector.m_CustomPreviewTexture, typeof(Texture2D), false);
                }
                else if (inspector.m_PreviewTextureSource == PreviewTextureSource.Material)
                {
                    inspector.UpdateTexture(true);
                }
                --EditorGUI.indentLevel;


                EditorGUILayout.Space();
                EditorGUILayout.Space();

                

                inspector.m_PreviewTextureTintColor = EditorGUILayout.ColorField("Image Tint", inspector.m_PreviewTextureTintColor);

                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.PrefixLabel("Color Channel");
                inspector.m_PreviewTextureChannels = (ColorChannels)GUILayout.Toolbar((int)inspector.m_PreviewTextureChannels, Styles.colorChannelsNames, GUILayout.MaxWidth(160), GUILayout.Height(20));
                EditorGUILayout.EndHorizontal();

                inspector.m_TilePreviewTexture = EditorGUILayout.Toggle("Tiles", inspector.m_TilePreviewTexture);     

                
               

                if (EditorGUI.EndChangeCheck())
                {
                    inspector.Repaint();
                }
            }
        }

        class BitField32
		{
			public int bitfield;
		
			public bool this[int index]
			{
				get
				{
					return (bitfield & (1 << index)) != 0;
				}
				set
				{
					if(value)
						bitfield |= (1 << index);
					else 
						bitfield &= ~(1 << index);
				}
			}

			public static implicit operator BitField32(int value) 
			{
				return new BitField32(value);
			}

			public BitField32(int value)
			{
				bitfield = value;
			}

			public int ToInt()
			{
				return bitfield;
			}

			public int NumberOfSetBits(int bits)
			{
				int i = bitfield & (Mathf.RoundToInt(Mathf.Pow(2, bits)) - 1);	
				i = i - ((i >> 1) & 0x55555555);
				i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
				return (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24;
			}
		}


        static int              s_UVPreviewWindowHash = "nTools.UVInspector.UVPreviewWindow".GetHashCode();
        static GUIContent       s_TempContent = new GUIContent();				
		
		Material                m_uvPreviewMaterial = null;
        Material                m_SimpleMaterial = null;
		Vector2					m_ScroolPosition = Vector2.zero;
		Vector2                 m_PreviewWindowPosition = new Vector2(-0.5f, -0.5f);
		float                   m_PreviewWindowScale = 1.8f;
		Rect                    m_ViewportRect = new Rect();
        Rect                    m_TextureButtonRect = new Rect();

        List<InspectedObject>   m_InspectedObjects = new List<InspectedObject>();

        UVSet                   m_PreviewUVSet = UVSet.UV1;
		BitField32      		m_SubMeshToggleField = ~0;
        bool                    m_ShowVertexColors = false;
        bool                    m_ShowGrid = true;
		bool					m_TilePreviewTexture = false;
		bool					m_ShowSubmeshesByOne = true;
        bool                    m_SettingsFoldout = true;
		bool                    m_PreviewFoldout = true;
		PreviewTextureSource	m_PreviewTextureSource = PreviewTextureSource.None;
		Color                   m_PreviewTextureTintColor = Color.white;
		Texture2D               m_CustomPreviewTexture = null;
		ColorChannels			m_PreviewTextureChannels = ColorChannels.All;

		Texture2D               m_PreviewTexture = null;
		string 					m_PreferredTextureProperty = "_MainTex";

        bool                    m_UVHit = false;
        string                  m_UVHitTooltipText = "";
        Vector2                 m_UVHitPosition = new Vector2();
        float                   m_UVHitPointSize = 7f;


        // Unity Editor Menu Item
        [MenuItem ("Window/nTools/UV Inspector")]
        static void Init ()
        {
            // Get existing open window or if none, make a new one:
            UVInspector window = (UVInspector)EditorWindow.GetWindow (typeof (UVInspector));
            window.ShowUtility(); 
        }


        bool LoadMaterials()
        {
            Shader uvPreviewShader = Shader.Find("Hidden/nTools/UvInspector/UvPreview");
            Shader simpleShader = Shader.Find("Hidden/nTools/UvInspector/Simple");

            if(uvPreviewShader == null || simpleShader == null)
            {
                return false;
            }

            m_uvPreviewMaterial = new Material(uvPreviewShader);
			m_uvPreviewMaterial.hideFlags = HideFlags.HideAndDontSave;

            m_SimpleMaterial = new Material(simpleShader);
			m_SimpleMaterial.hideFlags = HideFlags.HideAndDontSave;
            return true;
        }


        void OnEnable () 
        {
            titleContent = new GUIContent("UV Inspector");

			this.minSize = new Vector2(350, 400);

            wantsMouseMove = true;

			m_PreviewUVSet = (UVSet)EditorPrefs.GetInt("nTools.UVInspector.previewUVSet", (int)m_PreviewUVSet);
			m_SubMeshToggleField = EditorPrefs.GetInt("nTools.UVInspector.subMeshToggleField", m_SubMeshToggleField.bitfield);
			m_ShowVertexColors = EditorPrefs.GetBool("nTools.UVInspector.showVertexColors", m_ShowVertexColors);
			m_ShowGrid = EditorPrefs.GetBool("nTools.UVInspector.showGrid", m_ShowGrid);
			m_ShowSubmeshesByOne = EditorPrefs.GetBool("nTools.UVInspector.showSubmeshesByOne", m_ShowSubmeshesByOne);
			m_TilePreviewTexture = EditorPrefs.GetBool("nTools.UVInspector.tilePreviewTexture", m_TilePreviewTexture);
			m_PreviewTextureSource = (PreviewTextureSource)EditorPrefs.GetInt("nTools.UVInspector.previewTextureSource", (int)m_PreviewTextureSource);
			m_CustomPreviewTexture = (Texture2D)AssetDatabase.LoadAssetAtPath(EditorPrefs.GetString("nTools.UVInspector.customPreviewTexture", ""), typeof(Texture2D));
			m_PreviewTextureTintColor = IntToColor(EditorPrefs.GetInt("nTools.UVInspector.previewTextureTintColor", ColorToInt(m_PreviewTextureTintColor)));
			m_PreferredTextureProperty = EditorPrefs.GetString("nTools.UVInspector.preferredTextureProperty", m_PreferredTextureProperty);
			m_PreviewTextureChannels = (ColorChannels)EditorPrefs.GetInt("nTools.UVInspector.previewTextureChannels", (int)m_PreviewTextureChannels);
			m_SettingsFoldout = EditorPrefs.GetBool("nTools.UVInspector.settingsFoldout", m_SettingsFoldout);
			m_PreviewFoldout = EditorPrefs.GetBool("nTools.UVInspector.previewFoldout", m_PreviewFoldout);


            if(!LoadMaterials())
            {
                Debug.LogWarning("UV Inspector Error: shaders not found. Reimport asset.");
                Close();
                return;
            }

            if(Selection.selectionChanged != OnSelectionChanged)
                Selection.selectionChanged += OnSelectionChanged;

            LoadMeshes();
        }




        void OnDisable () 
        {   
            Selection.selectionChanged -= OnSelectionChanged;

            EditorPrefs.SetInt("nTools.UVInspector.previewUVSet", (int)m_PreviewUVSet);
			EditorPrefs.SetInt("nTools.UVInspector.subMeshToggleField", m_SubMeshToggleField.ToInt());
            EditorPrefs.SetBool("nTools.UVInspector.showVertexColors", m_ShowVertexColors);
            EditorPrefs.SetBool("nTools.UVInspector.showGrid", m_ShowGrid);
			EditorPrefs.SetBool("nTools.UVInspector.showSubmeshesByOne", m_ShowSubmeshesByOne);
			EditorPrefs.SetBool("nTools.UVInspector.tilePreviewTexture", m_TilePreviewTexture);
			EditorPrefs.SetInt("nTools.UVInspector.previewTextureSource", (int)m_PreviewTextureSource);
			if(m_CustomPreviewTexture != null)
				EditorPrefs.SetString("nTools.UVInspector.customPreviewTexture", AssetDatabase.GetAssetPath(m_CustomPreviewTexture) ?? "");
			EditorPrefs.SetInt("nTools.UVInspector.previewTextureTintColor", ColorToInt(m_PreviewTextureTintColor));
			EditorPrefs.SetString("nTools.UVInspector.preferredTextureProperty", m_PreferredTextureProperty);
			EditorPrefs.SetInt("nTools.UVInspector.previewTextureChannels", (int)m_PreviewTextureChannels);
            EditorPrefs.SetBool("nTools.UVInspector.settingsFoldout", m_SettingsFoldout);
			EditorPrefs.SetBool("nTools.UVInspector.previewFoldout", m_PreviewFoldout);
        }      


        void OnSelectionChanged()
        {
            LoadMeshes();
        }

		void AddObject(UnityEngine.Object obj, Mesh mesh, GameObject gameObject)
		{
			if (m_InspectedObjects.Count >= 10)
				return;

			InspectedObject inspectedObj = new InspectedObject();
			inspectedObj.obj = obj;
			inspectedObj.gameObject = gameObject;
			inspectedObj.mesh = mesh;

            int[] triangles = mesh.triangles;
            if (triangles != null)
                inspectedObj.triangleCount = triangles.Length/3;
			
			inspectedObj.vertexCount = inspectedObj.mesh.vertexCount;
			inspectedObj.subMeshCount = Mathf.Min (mesh.subMeshCount, 32);

            inspectedObj.uv = new List<Vector2>();
            
			inspectedObj.hasUV[0] = inspectedObj.mesh.uv != null && inspectedObj.mesh.uv.Length > 0;
			inspectedObj.hasUV[1] = inspectedObj.mesh.uv2 != null && inspectedObj.mesh.uv2.Length > 0;
            inspectedObj.hasUV[2] = inspectedObj.mesh.uv3 != null && inspectedObj.mesh.uv3.Length > 0;
            inspectedObj.hasUV[3] = inspectedObj.mesh.uv4 != null && inspectedObj.mesh.uv4.Length > 0;

            Color32[] colors;
			inspectedObj.hasColors = (colors = inspectedObj.mesh.colors32) != null && colors.Length > 0;

			m_InspectedObjects.Add(inspectedObj);
		}


		void AddGameObject(GameObject gameObject)
		{
			MeshFilter meshFilter = gameObject.GetComponent(typeof(MeshFilter)) as MeshFilter;
			if(meshFilter != null && meshFilter.sharedMesh != null)
			{
				AddObject(gameObject, meshFilter.sharedMesh, gameObject);
			}
			else
			{
				SkinnedMeshRenderer skinnedMeshRenderer = gameObject.GetComponent(typeof(SkinnedMeshRenderer)) as SkinnedMeshRenderer;
				if(skinnedMeshRenderer != null && skinnedMeshRenderer.sharedMesh != null)
				{
					AddObject(gameObject, skinnedMeshRenderer.sharedMesh, gameObject);
				}
			}
		}


        void LoadMeshes()
        {
            UnityEngine.Object[] selectedObjects = Selection.objects;
            int selectedObjectsCount = selectedObjects.Length;

            m_InspectedObjects.Clear();

            for(int i = 0; i < selectedObjectsCount; i++)
            {
				if(selectedObjects[i] is GameObject)
				{
					ForAllInHierarchy(selectedObjects[i] as GameObject, (go) => { AddGameObject(go);  });
				}
				else
				if(selectedObjects[i] is Mesh)
				{
					AddObject(selectedObjects[i], selectedObjects[i] as Mesh, null);
				}
            }

            Repaint();
        }


        
        void UVPreviewWindow(Rect rect)
        {
            Event e = Event.current;
            int controlID = GUIUtility.GetControlID(s_UVPreviewWindowHash, FocusType.Passive, rect);

			switch(e.GetTypeForControl(controlID))
            {
            case EventType.MouseDown:
                if(rect.Contains(e.mousePosition)/* && e.alt*/)
                {
					if(e.button == 0 || e.button == 1 || e.button == 2)
					{
	                    GUI.changed = true;

                        GUIUtility.keyboardControl = controlID;
	                    GUIUtility.hotControl = controlID;
	                    e.Use();
					}
                }
                break;
            case EventType.MouseUp:
                if (GUIUtility.hotControl == controlID)
                {
                    GUIUtility.hotControl = 0;
                    e.Use();
                }
                break;
            case EventType.MouseDrag:
                if (GUIUtility.hotControl == controlID/* && e.alt*/)
                {
                    GUI.changed = true;

                    if (e.button == 0 || e.button == 2)
                        m_PreviewWindowPosition += new Vector2(e.delta.x, -e.delta.y) * (2.0f / rect.width) / m_PreviewWindowScale;

                    if (e.button == 1)
					{   
						float aspect = Mathf.Min(m_ViewportRect.width, m_ViewportRect.height) / Mathf.Max(m_ViewportRect.width, m_ViewportRect.height, 1f);
                        float scale = e.delta.magnitude / aspect * Mathf.Sign(Vector2.Dot(e.delta, new Vector2(1.0f, 0.0f))) * (2.0f / rect.width) * (m_PreviewWindowScale) * 0.5f;
                        m_PreviewWindowScale += scale;
                        m_PreviewWindowScale = Mathf.Max(m_PreviewWindowScale, 0.01f);
                    }

                    e.Use();
                }
                break;
            case EventType.KeyDown:
                {
                    if(e.keyCode == KeyCode.F)
                    {
                        Vector2 delta = e.mousePosition - rect.center;
                        m_PreviewWindowPosition += new Vector2(-delta.x, delta.y) * (2.0f / rect.width) / m_PreviewWindowScale;
                        e.Use();
                    }
                }
                break;
            case EventType.ScrollWheel:
                if(rect.Contains(e.mousePosition))
                {
                    GUI.changed = true;

					float aspect = Mathf.Min(m_ViewportRect.width, m_ViewportRect.height) / Mathf.Max(m_ViewportRect.width, m_ViewportRect.height, 1f);

					m_PreviewWindowScale += e.delta.magnitude / aspect * Mathf.Sign(Vector2.Dot(e.delta, new Vector2(1.0f, -0.1f).normalized)) * (2.0f / rect.width) * (m_PreviewWindowScale) * 5.5f;                
                    m_PreviewWindowScale = Mathf.Max(m_PreviewWindowScale, 0.01f);

                    e.Use();
                }
                break;
            case EventType.MouseMove:
                if (rect.Contains(e.mousePosition))
                {
                    float aspect = m_ViewportRect.height / m_ViewportRect.width;
                    Matrix4x4 projectionMatrix = Matrix4x4.Ortho(-1f, 1f, -1f * aspect, 1f * aspect, -1f, 1f);
                    
                    Matrix4x4 viewMatrix = Matrix4x4.Scale(new Vector3(m_PreviewWindowScale, m_PreviewWindowScale, m_PreviewWindowScale))
                        * Matrix4x4.Translate(new Vector3(m_PreviewWindowPosition.x, m_PreviewWindowPosition.y, 0));


                    Vector2 mousePos = e.mousePosition - m_ViewportRect.position;
                    Matrix4x4 W2SMatrix = projectionMatrix * viewMatrix;
                    m_UVHit = false;
                    float nearestDistance = float.PositiveInfinity;
                    float pointSizeSq = m_UVHitPointSize * m_UVHitPointSize;

                    for (int i = 0; i < m_InspectedObjects.Count; i++)
                    {
                        if (!m_InspectedObjects[i].hasUV[(int)m_PreviewUVSet])
                            continue;

                        Mesh mesh = m_InspectedObjects[i].mesh;
                        int[] indices = mesh.triangles;
                        mesh.GetUVs((int)m_PreviewUVSet, m_InspectedObjects[i].uv);
                                                

                        if (m_InspectedObjects.Count == 1)
                        {
                            int subMeshCount = mesh.subMeshCount;

                            for (int j = 0; j < subMeshCount; j++)
                            {
                                if (!m_SubMeshToggleField[j])
                                    continue;

                                uint indexStart = mesh.GetIndexStart(j);
                                uint indexCount = mesh.GetIndexCount(j);
                                
                                for (uint t = indexStart; t < indexCount; t ++)
                                {
                                    Vector2 uv = W2SMatrix.MultiplyPoint(m_InspectedObjects[i].uv[indices[t]]);

                                    uv = (uv + Vector2.one) * 0.5f;
                                    uv.x = uv.x * m_ViewportRect.width;
                                    uv.y = uv.y * m_ViewportRect.height;
                                    uv.y = m_ViewportRect.height - uv.y;

                                    float sqDistance = (mousePos - uv).sqrMagnitude;

                                    if (sqDistance < pointSizeSq && sqDistance < nearestDistance)
                                    {
                                        nearestDistance = sqDistance;

                                        m_UVHit = true;
                                        m_UVHitTooltipText = "UV: #" + indices[t] + " : " + m_InspectedObjects[i].uv[indices[t]].ToString("F6");

                                        m_UVHitPosition = m_InspectedObjects[i].uv[indices[t]];
                                        break;
                                    }
                                }
                            }
                        }
                        else
                        {
                            int indexCount = indices.Length;

                            for (int t = 0; t < indexCount; t++)
                            {
                                Vector2 uv = W2SMatrix.MultiplyPoint(m_InspectedObjects[i].uv[indices[t]]);

                                uv = (uv + Vector2.one) * 0.5f;
                                uv.x = uv.x * m_ViewportRect.width;
                                uv.y = uv.y * m_ViewportRect.height;
                                uv.y = m_ViewportRect.height - uv.y;

                                float sqDistance = (mousePos - uv).sqrMagnitude;

                                if (sqDistance < pointSizeSq && sqDistance < nearestDistance)
                                {
                                    nearestDistance = sqDistance;

                                    m_UVHit = true;
                                    m_UVHitTooltipText = "UV: #" + indices[t] + " : " + m_InspectedObjects[i].uv[indices[t]].ToString("F6");

                                    m_UVHitPosition = m_InspectedObjects[i].uv[indices[t]];
                                    break;
                                }
                            }
                        }
                    }

                    
                    HandleUtility.Repaint();                    
                    e.Use();
                }                
                
                break;
            case EventType.Repaint:
                {

                    GUI.BeginGroup(rect);

                    m_ViewportRect = rect;

                    m_ViewportRect.position = m_ViewportRect.position - m_ScroolPosition;// apply scroll
					
                    // clamp rect 
                    if(m_ViewportRect.position.x < 0f)
                    {
                        m_ViewportRect.width += m_ViewportRect.position.x; // -= abs(x)
                        m_ViewportRect.position = new Vector2(0f, m_ViewportRect.position.y);

                        if(m_ViewportRect.width <= 0f)
                            break;
                    }
                    if(m_ViewportRect.position.y < 0f)
                    {
                        m_ViewportRect.height += m_ViewportRect.position.y; // -= abs(y)
                        m_ViewportRect.position = new Vector2(m_ViewportRect.position.x, 0f);

                        if(m_ViewportRect.height <= 0f)
                            break;
                    }


                    
                    
                    Rect screenViewportRect = m_ViewportRect;
                    screenViewportRect.y = this.position.height - screenViewportRect.y - screenViewportRect.height;
                    screenViewportRect.position += new Vector2(1, 3); // hack

                    GL.Viewport(EditorGUIUtility.PointsToPixels(screenViewportRect));                    
                    GL.PushMatrix();

                    // Clear bg
					{
					    GL.LoadIdentity();
						GL.LoadProjectionMatrix(Matrix4x4.Ortho(0f, 1f, 0f, 1f, -1f, 1f));

						SetMaterialKeyword(m_SimpleMaterial, "_COLOR_MASK", false);
						SetMaterialKeyword(m_SimpleMaterial, "_NORMALMAP", false);
						m_SimpleMaterial.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
						m_SimpleMaterial.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
						m_SimpleMaterial.SetTexture("_MainTex", null);
						m_SimpleMaterial.SetColor("_Color", Color.white);
						m_SimpleMaterial.SetPass(0);

						GL.Begin(GL.TRIANGLE_STRIP);
						GL.Color(Styles.backgroundColor);
						GL.Vertex3(1, 0, 0);
						GL.Vertex3(0, 0, 0);
						GL.Vertex3(1, 1, 0);
						GL.Vertex3(0, 1, 0);
						GL.End();
					}

				    GL.LoadIdentity();                    
                    float aspect = m_ViewportRect.height / m_ViewportRect.width;
                    Matrix4x4 projectionMatrix = Matrix4x4.Ortho(-1f, 1f, -1f * aspect, 1f * aspect, -1f, 1f);
				    GL.LoadProjectionMatrix(projectionMatrix);

                    Matrix4x4 viewMatrix = Matrix4x4.Scale(new Vector3(m_PreviewWindowScale, m_PreviewWindowScale, m_PreviewWindowScale))
						* Matrix4x4.Translate(new Vector3(m_PreviewWindowPosition.x, m_PreviewWindowPosition.y, 0));                   
                    GL.MultMatrix(viewMatrix);


					// Preview texture
					if((m_PreviewTextureSource == PreviewTextureSource.Custom && m_CustomPreviewTexture != null) || 
				       (m_PreviewTextureSource == PreviewTextureSource.Material && m_PreviewTexture != null))
					{
						Texture2D texture = (m_PreviewTextureSource == PreviewTextureSource.Custom) ? m_CustomPreviewTexture : m_PreviewTexture;
						
						SetMaterialKeyword(m_SimpleMaterial, "_NORMALMAP", false);
											
						string texPath = AssetDatabase.GetAssetPath(texture);
						if(texPath != null) {
							TextureImporter textureImporter = (TextureImporter)TextureImporter.GetAtPath (texPath);
							if(textureImporter != null) {
								if(textureImporter.textureType == TextureImporterType.NormalMap)
									SetMaterialKeyword(m_SimpleMaterial, "_NORMALMAP", true);
							}
						}							
						
						switch(m_PreviewTextureChannels) {
						case ColorChannels.R:
							SetMaterialKeyword(m_SimpleMaterial, "_COLOR_MASK", true);
							m_SimpleMaterial.SetColor("_Color", new Color(1,0,0,0));
							break;
						case ColorChannels.G:
							SetMaterialKeyword(m_SimpleMaterial, "_COLOR_MASK", true);
							m_SimpleMaterial.SetColor("_Color", new Color(0,1,0,0));
							break;
						case ColorChannels.B:
							SetMaterialKeyword(m_SimpleMaterial, "_COLOR_MASK", true);
							m_SimpleMaterial.SetColor("_Color", new Color(0,0,1,0));
							break;
						case ColorChannels.A:
							SetMaterialKeyword(m_SimpleMaterial, "_COLOR_MASK", true);
							m_SimpleMaterial.SetColor("_Color", new Color(0,0,0,1));
							break;
						case ColorChannels.All:
							SetMaterialKeyword(m_SimpleMaterial, "_COLOR_MASK", false);
							m_SimpleMaterial.SetColor("_Color", new Color(1,1,1,1));
							break;						
						}
						
						m_SimpleMaterial.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
						m_SimpleMaterial.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
												
						m_SimpleMaterial.SetTexture("_MainTex", texture);
						m_SimpleMaterial.SetPass(0);
						
						float min = m_TilePreviewTexture ? -100f : 0;
						float max = m_TilePreviewTexture ? 100f : 1;
					
						GL.Begin(GL.TRIANGLE_STRIP);
						GL.Color(m_PreviewTextureTintColor);
						GL.TexCoord2(max, min);
						GL.Vertex3(max, min, 0);
						GL.TexCoord2(min, min);
						GL.Vertex3(min, min, 0);
						GL.TexCoord2(max, max);
						GL.Vertex3(max, max, 0);
						GL.TexCoord2(min, max);
						GL.Vertex3(min, max, 0);
						GL.End();      
					}
				


                    // grid
                    if(m_ShowGrid)
                    {
                        GL.wireframe = false;

						SetMaterialKeyword(m_SimpleMaterial, "_COLOR_MASK", false);
						SetMaterialKeyword(m_SimpleMaterial, "_NORMALMAP", false);
                        m_SimpleMaterial.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                        m_SimpleMaterial.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                        m_SimpleMaterial.SetTexture("_MainTex", null);
						m_SimpleMaterial.SetColor("_Color", Color.white);
                        m_SimpleMaterial.SetPass(0);


                        GL.Begin(GL.LINES);

                        float x = -1.0f;
                        GL.Color(Styles.gridColor);
                        for(int i = 0; i <= 20; i++, x+=0.1f)
                        {
                            GL.Vertex3(x, 1, 0);
                            GL.Vertex3(x, -1, 0);
                        }


                        float y = -1.0f;
                        GL.Color(Styles.gridColor);
                        for(int i = 0; i <= 20; i++, y+=0.1f)
                        {
                            GL.Vertex3(1, y, 0);
                            GL.Vertex3(-1, y, 0);
                        }

                        GL.Color(Color.gray);
                        GL.Vertex3(1, 0, 0);
                        GL.Vertex3(-1, 0, 0);
                        GL.Vertex3(0, 1, 0);
                        GL.Vertex3(0, -1, 0);

                        GL.Color(Color.red);
                        GL.Vertex3(0.3f, 0, 0);
                        GL.Vertex3(0, 0, 0);


                        GL.Color(Color.green);
                        GL.Vertex3(0, 0.3f, 0);
                        GL.Vertex3(0, 0, 0);

                        GL.End();
                    }

                    


                    // mesh uvs
                    {
                        SetMaterialKeyword(m_uvPreviewMaterial, "_UV1", false);
                        SetMaterialKeyword(m_uvPreviewMaterial, "_UV2", false);
                        SetMaterialKeyword(m_uvPreviewMaterial, "_UV3", false);

                        switch(m_PreviewUVSet)
                        {
                        case UVSet.UV2:
                            SetMaterialKeyword(m_uvPreviewMaterial, "_UV1", true);
                            break;
                        case UVSet.UV3:
                            SetMaterialKeyword(m_uvPreviewMaterial, "_UV2", true);
                            break;
                        case UVSet.UV4:
                            SetMaterialKeyword(m_uvPreviewMaterial, "_UV3", true);
                            break;
                        }


                        GL.wireframe = true;


                        for(int i = 0; i < m_InspectedObjects.Count; i++)
                        {
                            if (!m_InspectedObjects[i].hasUV[(int)m_PreviewUVSet])
                                continue;

                            SetMaterialKeyword(m_uvPreviewMaterial, "_VERTEX_COLORS", m_ShowVertexColors && m_InspectedObjects[i].hasColors);

                            if(i == m_InspectedObjects.Count-1)
                            {
                                m_uvPreviewMaterial.SetColor("_Color", Styles.wireframeColor);
                            }
                            else
                            {
                                m_uvPreviewMaterial.SetColor("_Color", Styles.wireframeColor2);
                            }

                            m_uvPreviewMaterial.SetPass(0);

							if(m_InspectedObjects.Count == 1)
							{
								for(int j = 0; j < m_InspectedObjects[i].subMeshCount && j < 32; j++)
								{
									if(m_SubMeshToggleField[j])
										Graphics.DrawMeshNow(m_InspectedObjects[i].mesh, viewMatrix, j);
								}
							}
							else {
	                            Graphics.DrawMeshNow(m_InspectedObjects[i].mesh, viewMatrix);
							}
						}
                    }


                    if (m_UVHit)
                    {
                        GL.wireframe = false;

                        SetMaterialKeyword(m_SimpleMaterial, "_COLOR_MASK", false);
                        SetMaterialKeyword(m_SimpleMaterial, "_NORMALMAP", false);
                        m_SimpleMaterial.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                        m_SimpleMaterial.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                        m_SimpleMaterial.SetTexture("_MainTex", null);
                        m_SimpleMaterial.SetColor("_Color", Color.white);
                        m_SimpleMaterial.SetPass(0);

                        float pointSize = (1f / Mathf.Max(m_ViewportRect.width, m_ViewportRect.height)) * m_UVHitPointSize * 3.00f;

                        GL.PushMatrix();
                        GL.LoadProjectionMatrix(projectionMatrix);
                        GL.MultMatrix(viewMatrix * Matrix4x4.Translate(m_UVHitPosition) * Matrix4x4.Scale(Vector3.one * pointSize * (1f / m_PreviewWindowScale)));

                        GL.Begin(GL.TRIANGLE_STRIP);
                        GL.Color(Color.red);
                        GL.Vertex3(-.5f, -.5f, 0);
                        GL.Vertex3(.5f, -.5f, 0);
                        GL.Vertex3(-.5f, .5f, 0);
                        GL.Vertex3(.5f, .5f, 0);
                        GL.End();

                        GL.PopMatrix();
                    }

                    GL.PopMatrix();
					GL.wireframe = false;

                    GUI.EndGroup();

                    // grid numbers
                    if (m_ShowGrid)
                    {
                        GUI.BeginGroup (rect);
                        Matrix4x4 MVPMatrix = (projectionMatrix * viewMatrix);
                        DrawLabel(new Vector3(0, 0, 0), rect, MVPMatrix, "0.0", EditorStyles.whiteMiniLabel, TextAnchor.MiddleLeft);
                        DrawLabel(new Vector3(0, 1, 0), rect, MVPMatrix, "1.0", EditorStyles.whiteMiniLabel, TextAnchor.MiddleLeft);
                        DrawLabel(new Vector3(0, -1, 0), rect, MVPMatrix, "-1.0", EditorStyles.whiteMiniLabel, TextAnchor.UpperLeft);
                        DrawLabel(new Vector3(1, 0, 0), rect, MVPMatrix, "1.0", EditorStyles.whiteMiniLabel, TextAnchor.MiddleLeft);
                        DrawLabel(new Vector3(-1, 0, 0), rect, MVPMatrix, "-1.0", EditorStyles.whiteMiniLabel, TextAnchor.MiddleRight);
						GUI.EndGroup();
                    }

                }
                break;
            }

            return;
        }




		void SubMeshToolbar(int buttonCount)
		{
			if(buttonCount == 0)
				return;
						 

			buttonCount = Mathf.Min (buttonCount, 32);

			Rect rect = EditorGUILayout.GetControlRect(GUILayout.Width(Styles.kSubMeshButtonWitdh * buttonCount), GUILayout.Height(20));
			rect.width = Styles.kSubMeshButtonWitdh;


			if(buttonCount == 1)
			{
				m_SubMeshToggleField[0] = nGUI.Toggle(rect, m_SubMeshToggleField[0], Styles.subMeshLabels[0], "button");
				return;
			}

			int i = 0;

			m_SubMeshToggleField[i] = nGUI.Toggle(rect, m_SubMeshToggleField[i], Styles.subMeshLabels[i], Styles.buttonLeft);
			rect.x += Styles.kSubMeshButtonWitdh;

			for(i = 1; i < buttonCount-1; i++)
			{
				m_SubMeshToggleField[i] = nGUI.Toggle(rect, m_SubMeshToggleField[i], Styles.subMeshLabels[i], Styles.buttonMid);
				rect.x += Styles.kSubMeshButtonWitdh;
			}

			m_SubMeshToggleField[i] = nGUI.Toggle(rect, m_SubMeshToggleField[i], Styles.subMeshLabels[i], Styles.buttonRight);
		}





		void UpdateTexture(bool showGUI)
		{
			if (m_InspectedObjects.Count != 1 || m_SubMeshToggleField.NumberOfSetBits (m_InspectedObjects[0].subMeshCount) != 1)
			{
				goto DISPLAY_DIMMED_PROPERTY;
			}
			
			if(m_InspectedObjects[0].gameObject == null)
				goto DISPLAY_DIMMED_PROPERTY;
			
			Material[] objectMaterials = null;			
			Renderer renderer = m_InspectedObjects[0].gameObject.GetComponent (typeof(Renderer)) as Renderer;
			if (renderer != null) {
				objectMaterials = renderer.sharedMaterials;
			}


			if (objectMaterials == null)
				goto DISPLAY_DIMMED_PROPERTY;
			
			int preferredTexturePropertyIndex = 0;
			int currentSubmesh = Mathf.RoundToInt(Mathf.Log((float)(m_SubMeshToggleField.bitfield & (Mathf.RoundToInt(Mathf.Pow(2, m_InspectedObjects[0].subMeshCount)) - 1)), 2f));

			if(currentSubmesh < 0 || currentSubmesh >= objectMaterials.Length)
				goto DISPLAY_DIMMED_PROPERTY;				
			
			if(objectMaterials[currentSubmesh] == null)
				goto DISPLAY_DIMMED_PROPERTY;
			
			Shader shader = objectMaterials[currentSubmesh].shader;
			if(shader == null)
				goto DISPLAY_DIMMED_PROPERTY;	
				
					
					
			List<string> propertyNames = new List<string>();
			int propertyCount = ShaderUtil.GetPropertyCount(shader);
			
			for(int i = 0; i < propertyCount; i++)
			{
				if(ShaderUtil.GetPropertyType(shader, i) == ShaderUtil.ShaderPropertyType.TexEnv &&
				   ShaderUtil.IsShaderPropertyHidden(shader, i) == false)
				{
					string propertyName = ShaderUtil.GetPropertyName(shader, i);
					propertyNames.Add(propertyName);
					if(propertyName == m_PreferredTextureProperty)
						preferredTexturePropertyIndex = propertyNames.Count-1;
				}
			}
			
			string[] nicePropertyNames = propertyNames.ToArray ();
			for(int i = 0; i < nicePropertyNames.Length; i++)
			{
				Texture t = objectMaterials[currentSubmesh].GetTexture(propertyNames[i]);
				if(t != null)
					nicePropertyNames[i] += " (" + t.name + ")";
				else
					nicePropertyNames[i] += " (none)";
			}

            if (showGUI)
            {
                EditorGUI.BeginChangeCheck();
                preferredTexturePropertyIndex = EditorGUILayout.Popup("Property", preferredTexturePropertyIndex, nicePropertyNames);
                if (EditorGUI.EndChangeCheck())
                {
                    m_PreferredTextureProperty = propertyNames[preferredTexturePropertyIndex];
                }
            }
			
			
			Texture texture = objectMaterials[currentSubmesh].GetTexture(propertyNames[preferredTexturePropertyIndex]);
			
			if(texture is Texture2D)
				m_PreviewTexture = texture as Texture2D;
			else
				m_PreviewTexture = null;			
			
			
			return;
			
			
			DISPLAY_DIMMED_PROPERTY:
                        
            {
                if (showGUI)
                {
                    GUI.enabled = false;
                    string[] empty = { "---" };
                    EditorGUILayout.Popup("Property", 0, empty);
                    GUI.enabled = true;
                }
				
				m_PreviewTexture = null;
			}
			
		}



        void OnGUI ()
        {
            if(m_uvPreviewMaterial == null || m_SimpleMaterial == null)
            {
                if(!LoadMaterials())
                    return;                
            }
            
			for(int i = 0; i < m_InspectedObjects.Count; i++)
			{
				if(m_InspectedObjects[i].obj == null)
				{
					m_InspectedObjects.RemoveAt(i);
					i = 0;
				}
			}

			m_ScroolPosition = EditorGUILayout.BeginScrollView(m_ScroolPosition);

            EditorGUILayout.BeginVertical();

            Rect logoRect = EditorGUILayout.GetControlRect(GUILayout.Height(56));
            if(Event.current.type == EventType.Repaint)
                Styles.logoFont.Draw(logoRect, "nTools|UVInspector", false, false, false, false);
            


			// info box
			if(m_InspectedObjects.Count == 0)
			{
				EditorGUILayout.BeginVertical(EditorStyles.helpBox);
				EditorGUILayout.LabelField("Select object with mesh.");
				EditorGUILayout.EndVertical();
			}
			else if(m_InspectedObjects.Count == 1)
			{
				StringBuilder sb = new StringBuilder();
				InspectedObject obj = m_InspectedObjects[0];
				
				EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                EditorGUILayout.LabelField("Object: " + obj.obj.name + ", Mesh: " + obj.mesh.name);				
				
				sb.AppendFormat("Submeshes: {0}", obj.subMeshCount);
				sb.AppendFormat(", Triangles: {0}", obj.triangleCount);
				sb.AppendFormat(", Vertices: {0}", obj.vertexCount);
				if(obj.hasColors) sb.Append(", Colors");
				if(obj.hasUV[0]) sb.Append(", UV1");
				if(obj.hasUV[1]) sb.Append(", UV2");
				if(obj.hasUV[2]) sb.Append(", UV3");
				if(obj.hasUV[3]) sb.Append(", UV4");
				
				EditorGUILayout.LabelField(sb.ToString());
				EditorGUILayout.EndVertical();
			}
			else
			{
				StringBuilder sb = new StringBuilder();
				
				for(int i = 0; i < m_InspectedObjects.Count; i++)
				{
					sb.Append(m_InspectedObjects[i].obj.name + "(" + m_InspectedObjects[i].mesh.name + "), ");
				}
				
				EditorGUILayout.BeginVertical(EditorStyles.helpBox);
				EditorGUILayout.LabelField("Multiple objects:");
				EditorGUILayout.LabelField(sb.ToString(), EditorStyles.wordWrappedMiniLabel);
				EditorGUILayout.EndVertical();
			}



            // Toolbar buttons
            EditorGUILayout.BeginHorizontal();

            m_ShowGrid = GUILayout.Toggle(m_ShowGrid, "Grid", EditorStyles.toolbarButton);
            m_ShowVertexColors = GUILayout.Toggle(m_ShowVertexColors, "Vertex Colors", EditorStyles.toolbarButton);            
            GUI.enabled = IsCanFrameSelected();


            if (GUILayout.Button("Texture", EditorStyles.toolbarButton))
            {
                TextureSettingsPopupWindow textureSettingsPopupWindow = new TextureSettingsPopupWindow();
                textureSettingsPopupWindow.inspector = this;
                PopupWindow.Show(m_TextureButtonRect, textureSettingsPopupWindow);
            }
            if (Event.current.type == EventType.Repaint)
                m_TextureButtonRect = GUILayoutUtility.GetLastRect();


            if (GUILayout.Toggle(false, "Frame View", EditorStyles.toolbarButton))
            {
                FrameSelected();
            }
            GUI.enabled = true;


            if (GUILayout.Toggle(false, "Reset View", EditorStyles.toolbarButton))
            {
                m_PreviewWindowPosition = new Vector2(-0.5f, -0.5f);

                float aspect = Mathf.Min(m_ViewportRect.width, m_ViewportRect.height) / Mathf.Max(m_ViewportRect.width, m_ViewportRect.height, 1);
                m_PreviewWindowScale = 1.8f * aspect;
            }

            

            if (GUILayout.Toggle(false, "UV Snapshot...", EditorStyles.toolbarButton))
            {
                UVSnapshot.ShowDialog(this);
            }

            EditorGUILayout.EndHorizontal();


            
            // UI Window            
            float previewWindowHeight = this.position.height - 200;
            Rect previewWindowRect = EditorGUILayout.GetControlRect(GUILayout.Height(previewWindowHeight));

            UVPreviewWindow(previewWindowRect);



            if (m_InspectedObjects.Count == 1 && !m_InspectedObjects[0].hasUV[(int)m_PreviewUVSet])
                EditorGUI.LabelField(previewWindowRect, "Unassigned UV Channel", Styles.hudFont);


            EditorGUILayout.Space();            
            {
				++EditorGUI.indentLevel;

				EditorGUILayout.BeginHorizontal();
				EditorGUILayout.PrefixLabel ("UV Channel");
				m_PreviewUVSet = (UVSet)GUILayout.Toolbar((int)m_PreviewUVSet, Styles.uvSetNames, GUILayout.Height(20));
				EditorGUILayout.EndHorizontal();

				EditorGUILayout.BeginHorizontal();
				EditorGUILayout.PrefixLabel ("Sub Mesh");
				if (m_InspectedObjects.Count == 1)
				{
					SubMeshToolbar(m_InspectedObjects[0].mesh.subMeshCount);
				} else {
					GUI.enabled = false;
					GUI.Button(EditorGUILayout.GetControlRect(GUILayout.MaxWidth (160), GUILayout.Height(20)), m_InspectedObjects.Count > 1 ? "<Multyply Objects>" : "---");
					GUI.enabled = true;
				}
				EditorGUILayout.EndHorizontal();
				
				--EditorGUI.indentLevel;
			}


            if (m_UVHit && m_UVHitTooltipText != null)
            {
                Rect rect = new Rect(Event.current.mousePosition + new Vector2(10, 0), Styles.tooltip.CalcSize(new GUIContent(m_UVHitTooltipText)));
                EditorGUI.LabelField(rect, m_UVHitTooltipText, Styles.tooltip);
            }
            




            EditorGUILayout.EndVertical();

			EditorGUILayout.EndScrollView();

            UpdateTexture(false);
        }



        bool IsCanFrameSelected()
        {
            for(int i = 0; i < m_InspectedObjects.Count; i++)
            {
                if(m_InspectedObjects[i].hasUV[(int)m_PreviewUVSet])
                    return true;
            }
            return false;
        }


        void FrameSelected()
        {
            bool hasFirstPoint = true;
            Bounds bounds = new Bounds(Vector3.zero, Vector3.zero);

            for(int i = 0; i < m_InspectedObjects.Count; i++)
            {
                m_InspectedObjects[i].mesh.GetUVs((int)m_PreviewUVSet, m_InspectedObjects[i].uv);

                int uvCount = m_InspectedObjects[i].uv.Count;

                for (int j = 0; j < uvCount; j++)
                {
                    if(!hasFirstPoint)
                    {
                        bounds = new Bounds(m_InspectedObjects[i].uv[j], Vector3.zero);
                        hasFirstPoint = true;
                    }
                    bounds.Encapsulate(m_InspectedObjects[i].uv[j]);
                }                
            }

            if(!hasFirstPoint) // no points
            {
                return;
            }

            m_PreviewWindowPosition = Vector3.zero - bounds.center;
            if(bounds.size.magnitude != 0.0f && m_ViewportRect.width != 0 && m_ViewportRect.height != 0)
            {
                float aspect = Mathf.Min(m_ViewportRect.width, m_ViewportRect.height) / Mathf.Max(m_ViewportRect.width, m_ViewportRect.height);
                m_PreviewWindowScale = aspect / bounds.extents.magnitude;
            }
        }

		static Rect AlignTextRect(Rect rect, TextAnchor anchor)
		{
			switch (anchor)
			{
			case TextAnchor.UpperCenter:
				rect.xMin -= rect.width  * 0.5f;
				break;
			case TextAnchor.UpperRight:
				rect.xMin -= rect.width;
				break;
			case TextAnchor.LowerLeft:
				rect.yMin -= rect.height * 0.5f;
				break;
			case TextAnchor.LowerCenter:
				rect.xMin -= rect.width  * 0.5f;
				rect.yMin -= rect.height;
				break;
			case TextAnchor.LowerRight:
				rect.xMin -= rect.width;
				rect.yMin -= rect.height;
				break;
			case TextAnchor.MiddleLeft:
				rect.yMin -= rect.height * 0.5f;
				break;
			case TextAnchor.MiddleCenter:
				rect.xMin -= rect.width  * 0.5f;
				rect.yMin -= rect.height * 0.5f;
				break;
			case TextAnchor.MiddleRight:
				rect.xMin -= rect.width;
				rect.yMin -= rect.height * 0.5f;
				break;
			}
			
			return rect;
		}


        public void DrawLabel(Vector3 worldPoint, Rect viewport, Matrix4x4 MVPMatrix, string text, GUIStyle style, TextAnchor alignment = TextAnchor.MiddleCenter)
        {
            Vector2 guiPoint = MVPMatrix.MultiplyPoint(worldPoint);

            guiPoint = new Vector2(guiPoint.x * 0.5f + 0.5f, 0.5f - guiPoint.y * 0.5f);
			guiPoint = new Vector2(guiPoint.x * viewport.width, guiPoint.y * viewport.height);

            s_TempContent.text = text;
            Vector2 size = style.CalcSize(s_TempContent);

            Rect labelRect = new Rect(guiPoint.x, guiPoint.y, size.x, size.y);

            labelRect = AlignTextRect(labelRect, alignment);

            labelRect = style.padding.Add(labelRect);


            GUI.Label(labelRect, s_TempContent, style);
            
        }

		static void SetMaterialKeyword(Material material, string keyword, bool state)
        {
            if (state)
                material.EnableKeyword (keyword);
            else
                material.DisableKeyword (keyword);
        }



		public static Color32 IntToColor(int c)
        {
            return new Color32((byte)(c & 0xff), (byte)((c>>8) & 0xff), (byte)((c>>16) & 0xff), (byte)((c>>24) & 0xff));
        }

		public static int ColorToInt(Color32 c)
        {
            return c.r | (c.g << 8) | (c.b << 16) | (c.a << 24);
        }

		static void ForAllInHierarchy(GameObject gameObject, Action<GameObject> action)
		{
			action(gameObject);
			
			for (int i = 0; i < gameObject.transform.childCount; i++)
				ForAllInHierarchy(gameObject.transform.GetChild(i).gameObject, action);
		}
    }
}
