//#define CINEMACHINE

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;

// Staggart Creations http://staggart.xyz
// Copyright protected under Unity asset store EULA

public sealed class ScreenshotUtility : EditorWindow, IHasCustomMenu
{
    private const string VERSION = "1.0.2";
    
    private static bool captureScene = false;
    private static bool captureGame = true;

    private Camera sourceCamera;
    private List<Camera> cameras = new List<Camera>();
    private string[] cameraNames;
    private int cameraID;

    private int ssWidth = 1920;
    private int ssHeight = 1080;
    private bool transparency;

    private static string[] reslist = new string[] { "720p", "1080p", "1140p", "4K", "8K", "Custom..." };
    
    public static int Resolution
    {
        get { return EditorPrefs.GetInt(PlayerSettings.productName + "_SRCSHOT_RESOLUTION", 1); }
        set { EditorPrefs.SetInt(PlayerSettings.productName + "_SRCSHOT_RESOLUTION", value); }
    }
    
    private static string[] aspectList = new string[] { "16:9", "21:9", "32:9" };
    public static int AspectRatio
    {
        get { return EditorPrefs.GetInt(PlayerSettings.productName + "_SRCSHOT_ASPECT", 0); }
        set { EditorPrefs.SetInt(PlayerSettings.productName + "_SRCSHOT_ASPECT", value); }
    }

    public bool wideScreen = false;
    public static bool OpenAfterCapture
    {
        get { return EditorPrefs.GetBool(PlayerSettings.productName + "_SRCSHOT_OpenAfterCapture", true); }
        set { EditorPrefs.SetBool(PlayerSettings.productName + "_SRCSHOT_OpenAfterCapture", value); }
    }

    public static string SavePath
    {
        get { return EditorPrefs.GetString(PlayerSettings.productName + "_SRCSHOT_DIR", Application.dataPath.Replace("Assets", "Screenshots/")); }
        set { EditorPrefs.SetString(PlayerSettings.productName + "_SRCSHOT_DIR", value); }
    }

    public static string FileNameFormat
    {
        get { return EditorPrefs.GetString(PlayerSettings.productName + "_SRCSHOT_FileNameFormat", "{S}_{R}_{D}_{T}"); }
        set { EditorPrefs.SetString(PlayerSettings.productName + "_SRCSHOT_FileNameFormat", value); }
    }

    public static string[] DateFormats = new string[] { "MM-dd-yyyy", "dd-MM-yyyy", "yyyy-MM-dd" };
    public static int DateFormat
    {
        get { return EditorPrefs.GetInt(PlayerSettings.productName + "_SRCSHOT_DateFormat", 1); }
        set { EditorPrefs.SetInt(PlayerSettings.productName + "_SRCSHOT_DateFormat", value); }
    }
    
    public static string[] TimeFormats = new string[] { "24 Hour", "AM-PM" };
    public static int TimeFormat
    {
        get { return EditorPrefs.GetInt(PlayerSettings.productName + "_SRCSHOT_TimeFormat", 0); }
        set { EditorPrefs.SetInt(PlayerSettings.productName + "_SRCSHOT_TimeFormat", value); }
    }

    public static bool OutputPNG
    {
        get { return EditorPrefs.GetBool(PlayerSettings.productName + "_SRCSHOT_CMPRS", false); }
        set { EditorPrefs.SetBool(PlayerSettings.productName + "_SRCSHOT_CMPRS", value); }
    }
    
    public static bool ListenToPrintButton
    {
        get { return EditorPrefs.GetBool(PlayerSettings.productName + "_SRCSHOT_PRINT_BTN", false); }
        set { EditorPrefs.SetBool(PlayerSettings.productName + "_SRCSHOT_PRINT_BTN", value); }
    }

    GUIStyle pathField;

    // Check if folder exists, otherwise create it
    public static string CheckFolderValidity(string targetFolder)
    {
        //Create folder if it doesn't exist
        if (!Directory.Exists(targetFolder))
        {
            Debug.Log("Directory <i>\"" + targetFolder + "\"</i> didn't exist and was created...");
            Directory.CreateDirectory(targetFolder);

            AssetDatabase.Refresh();
        }

        return targetFolder;
    }

    private static string GetSceneName()
    {
        string name;
        //Screenshot name prefix
        if (SceneManager.sceneCount > 0)
            name = SceneManager.GetActiveScene().name;
        else
            //If there are no scenes in the build, or scene is unsaved
            name = PlayerSettings.productName;

        if (name == string.Empty) name = "Screenshot";

        return name;
    }

    public static string FormatFileName(int resIndex, string dateFormat)
    {
        string fileName = FileNameFormat.Replace("{S}", GetSceneName());
        fileName = fileName.Replace("{P}", PlayerSettings.productName);
        fileName = fileName.Replace("{R}", reslist[resIndex]);
        fileName = fileName.Replace("{D}", System.DateTime.Now.ToString(dateFormat).Replace("-", "." ));
        fileName = fileName.Replace("{T}", System.DateTime.Now.ToString(TimeFormat == 0 ? "HH-mm-ss" : "hh-mm-ss tt"));
        fileName = fileName.Replace("{U}", System.DateTime.Now.Ticks.ToString());

        return fileName;
    }

    [MenuItem("Tools/Screenshot")]
    public static void Init()
    {
        //Show existing window instance. If one doesn't exist, make one.
        EditorWindow ssWindow = EditorWindow.GetWindow(typeof(ScreenshotUtility), false);

        //Options
        ssWindow.autoRepaintOnSceneChange = true;
        ssWindow.maxSize = new Vector2(250f, 260f);
        ssWindow.minSize = ssWindow.maxSize;
        ssWindow.titleContent.image = EditorGUIUtility.IconContent("Camera Gizmo").image;
        ssWindow.titleContent.text = "Screenshot";

        //Show
        ssWindow.Show();

    }

    private void OnFocus()
    {
        RefreshCameras();
    }

    private void OnEnable()
    {
        RefreshCameras();

        if (focusedWindow != null && focusedWindow.GetType() == typeof(SceneView))
        {
            captureScene = true;
            captureGame = false;
        }
        else
        {
            captureGame = true;
            captureScene = false;
        }

#if !UNITY_2019_1_OR_NEWER
        SceneView.onSceneGUIDelegate += OnSceneGUI;
#else
        SceneView.duringSceneGui += OnSceneGUI;
#endif
    }

    private void OnDisable()
    {
#if !UNITY_2019_1_OR_NEWER
        SceneView.onSceneGUIDelegate -= OnSceneGUI;
#else
        SceneView.duringSceneGui -= OnSceneGUI;
#endif
    }

    private void OnSceneGUI(SceneView sceneView)
    {
        if (!ListenToPrintButton) return;
        
        //Whenever print-screen button is pressed
        if (Event.current.type == EventType.KeyUp && Event.current.keyCode == KeyCode.SysReq)
        {
            RenderScreenshot();
        }
    }

    private void RefreshCameras()
    {
        Camera[] sceneCameras = GameObject.FindObjectsOfType<Camera>();
        cameras.Clear();

        foreach (Camera cam in sceneCameras)
        {
            //Try to exclude any off-screen camera's
            if (cam.activeTexture != null && cam.hideFlags != HideFlags.None && !cam.enabled) continue;

            cameras.Add(cam);
        }

        //Compose list of names
        cameraNames = new string[cameras.Count];
        for (int i = 0; i < cameraNames.Length; i++)
        {
            cameraNames[i] = cameras[i].name;
        }
    }

    void SetResolution()
    {
        switch (Resolution)
        {
            case 0: 
                ssWidth = 1280;
                ssHeight = 720;
                break;
            case 1: 
                ssWidth = 1920;
                ssHeight = 1080;
                break;
            case 2:
                ssWidth = 2560;
                ssHeight = 1440;
                break;
            case 3:
                ssWidth = 3840;
                ssHeight = 2160;
                break;
            case 4:
                ssWidth = 7680;
                ssHeight = 4320;
                break;
        }

        //21:9
        if (AspectRatio == 1 && Resolution != reslist.Length - 1) ssWidth = Mathf.RoundToInt(ssWidth * 1.3215f);
        //32:9
        if (AspectRatio == 2 && Resolution != reslist.Length - 1) ssWidth = Mathf.RoundToInt(ssWidth * 2f);
    }

    void OnGUI()
    {
        if (cameras.Count == 0)
        {
            EditorGUILayout.HelpBox("No active camera's in the scene", MessageType.Warning);
            return;
        }
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        {
            EditorGUILayout.LabelField("Source", EditorStyles.boldLabel);
            EditorGUILayout.BeginHorizontal();
            {
                if (GUILayout.Toggle(captureScene, new GUIContent("Scene", EditorGUIUtility.IconContent("d_unityeditor.sceneview.png").image), EditorStyles.miniButtonLeft))
                {
                    captureScene = true;
                    captureGame = false;
                }
                if (GUILayout.Toggle(captureGame, new GUIContent("Game", EditorGUIUtility.IconContent("unityeditor.gameview.png").image), EditorStyles.miniButtonRight))
                {
                    captureGame = true;
                    captureScene = false;
                }
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.Space();

            if (cameras.Count > 1)
            {
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Camera", GUILayout.MaxWidth(60f));
                cameraID = EditorGUILayout.Popup(cameraID, cameraNames, GUILayout.MaxWidth(120f));
                sourceCamera = cameras[cameraID];

                EditorGUILayout.EndHorizontal();
            }
            else
            {
                sourceCamera = cameras[0];
            }
        }
        EditorGUILayout.EndVertical();

        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        {
            EditorGUILayout.LabelField("Resolution (" + ssWidth + " x " + ssHeight + ")", EditorStyles.boldLabel);

            EditorGUILayout.BeginHorizontal();
            Resolution = EditorGUILayout.Popup(Resolution, reslist, GUILayout.MinWidth(75f), GUILayout.MaxWidth(75f));
            //If not custom
            if (Resolution != reslist.Length - 1)
            {
                AspectRatio = EditorGUILayout.Popup(AspectRatio, aspectList, GUILayout.MinWidth(75f), GUILayout.MaxWidth(50f));
            }
            else
            {
                EditorGUILayout.BeginHorizontal();
                ssWidth = EditorGUILayout.IntField(ssWidth, GUILayout.MaxWidth(45f));
                EditorGUILayout.LabelField("x", GUILayout.MaxWidth(15f));
                ssHeight = EditorGUILayout.IntField(ssHeight, GUILayout.MaxWidth(45f));
                EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.EndHorizontal();

            //Update resolution
            SetResolution();
        }
        EditorGUILayout.EndVertical();

        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        {
            GUILayout.Label("Output folder", EditorStyles.boldLabel);
            EditorGUILayout.BeginHorizontal();
            {
                EditorGUILayout.TextField(SavePath, Styles.PathField);

                if (SavePath == string.Empty) SavePath = Application.dataPath.Replace("Assets", "Screenshots/");

                if (GUILayout.Button(new GUIContent("...", "Browse"), GUILayout.ExpandWidth(true)))
                {
                    SavePath = EditorUtility.SaveFolderPanel("Screenshot destination folder", SavePath, Application.dataPath);
                }
                if (GUILayout.Button("Open", GUILayout.ExpandWidth(true)))
                {
                    CheckFolderValidity(SavePath);
                    Application.OpenURL("file://" + SavePath);
                }
            }
            EditorGUILayout.EndHorizontal();
        }
        EditorGUILayout.EndVertical();

        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        {
            EditorGUI.BeginDisabledGroup(SavePath == string.Empty);
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    if (GUILayout.Button(new GUIContent("- Capture -"), GUILayout.ExpandHeight(false), GUILayout.Height(25f)))
                    {
                        RenderScreenshot();
                    }
                }
            }

            using (new EditorGUILayout.HorizontalScope(EditorStyles.textArea))
            {
                OutputPNG = GUILayout.Toggle(OutputPNG, "PNG", EditorStyles.miniButtonLeft, GUILayout.Width(50f), GUILayout.ExpandWidth(false));
                OutputPNG = !GUILayout.Toggle(!OutputPNG, "JPG", EditorStyles.miniButtonRight, GUILayout.Width(50f), GUILayout.ExpandWidth(false));
                OpenAfterCapture = EditorGUILayout.ToggleLeft("Auto open", OpenAfterCapture, GUILayout.MaxWidth(80f));
            }
            EditorGUI.EndDisabledGroup();
        }
        EditorGUILayout.EndVertical();

        EditorGUILayout.LabelField(" - Staggart Creations - ", EditorStyles.centeredGreyMiniLabel);
    }

    public void RenderScreenshot()
    {
        if (!sourceCamera) return;

        transparency = sourceCamera.clearFlags == CameraClearFlags.Depth;

        Vector3 originalPos = sourceCamera.transform.position;
        Quaternion originalRot = sourceCamera.transform.rotation;
        float originalFOV = sourceCamera.fieldOfView;
        bool originalOrtho = sourceCamera.orthographic;
        float originalOthoSize = sourceCamera.orthographicSize;

#if CINEMACHINE
        Cinemachine.CinemachineBrain cBrain = sourceCamera.GetComponent<Cinemachine.CinemachineBrain>();
        bool cBrainEnable = false;
        if (cBrain) cBrainEnable = cBrain.enabled;
#endif

        if (captureScene)
        {
            //Set focus to scene view
#if !UNITY_2018_2_OR_NEWER
            EditorApplication.ExecuteMenuItem("Window/Scene");
#else
            EditorApplication.ExecuteMenuItem("Window/General/Scene");
#endif

            if (SceneView.lastActiveSceneView)
            {
#if CINEMACHINE
                if (cBrain && cBrainEnable) cBrain.enabled = false;
#endif
                
                sourceCamera.fieldOfView = SceneView.lastActiveSceneView.camera.fieldOfView;
                sourceCamera.orthographic = SceneView.lastActiveSceneView.camera.orthographic;
                sourceCamera.orthographicSize = SceneView.lastActiveSceneView.camera.orthographicSize;
                sourceCamera.transform.position = SceneView.lastActiveSceneView.camera.transform.position;
                sourceCamera.transform.rotation = SceneView.lastActiveSceneView.camera.transform.rotation;
            }
        }

        RenderTexture rt = new RenderTexture(ssWidth, ssHeight, 0, RenderTextureFormat.ARGB32);
        rt.useDynamicScale = true;

        RenderTexture.active = rt;
        sourceCamera.targetTexture = rt;
        sourceCamera.Render();

        Texture2D screenShot = new Texture2D(ssWidth, ssHeight, transparency ? TextureFormat.ARGB32 : TextureFormat.RGB24, false, true);

        EditorUtility.DisplayProgressBar("Screenshot", "Reading pixels " + 1 + "/" + 3, 1f / 3f);
        screenShot.ReadPixels(new Rect(0, 0, ssWidth, ssHeight), 0, 0);
        sourceCamera.targetTexture = null;
        RenderTexture.active = null;

        byte[] bytes;
        EditorUtility.DisplayProgressBar("Screenshot", "Encoding " + 2 + "/" + 3, 2f / 3f);
        bytes = (OutputPNG || transparency) ? screenShot.EncodeToPNG() : screenShot.EncodeToJPG();

        string filename = FormatFileName(Resolution, DateFormats[DateFormat]) + (OutputPNG || transparency == true ? ".png" : ".jpg");

        CheckFolderValidity(SavePath);

        EditorUtility.DisplayProgressBar("Screenshot", "Saving file " + 3 + "/" + 3, 3f / 3f);
        string path = SavePath + "/" + filename;

        System.IO.File.WriteAllBytes(path, bytes);

        if (OpenAfterCapture) Application.OpenURL(path);

        //Restore
#if CINEMACHINE
        if (cBrain && cBrainEnable) cBrain.enabled = true;
#endif
        if (captureScene)
        {
            sourceCamera.orthographic = originalOrtho;
            sourceCamera.orthographicSize = originalOthoSize;
            sourceCamera.fieldOfView = originalFOV;
            sourceCamera.transform.position = originalPos;
            sourceCamera.transform.rotation = originalRot;
        }

        EditorUtility.ClearProgressBar();
    }

    private class Styles
    {
        private static GUIStyle _PathField;
        public static GUIStyle PathField
        {
            get
            {
                if (_PathField == null)
                {
                    _PathField = new GUIStyle(GUI.skin.textField)
                    {
                        alignment = TextAnchor.MiddleRight,
                        stretchWidth = true
                    };
                }

                return _PathField;
            }
        }
    }

    [SettingsProvider]
    public static SettingsProvider ScreenshotSettings()
    {
        var provider = new SettingsProvider("Preferences/Screenshot", SettingsScope.User)
        {
            label = "Screenshot",
            guiHandler = (searchContent) =>
            {
                FileNameFormat = EditorGUILayout.TextField("File name format", FileNameFormat);
                EditorGUILayout.HelpBox("{P} = Project name\n{S} = Scene name\n{R} = Resolution\n{D} = Date\n{T} = Time\n{U} = Unique number", MessageType.None);
                ScreenshotUtility.DateFormat = EditorGUILayout.Popup("Date format", DateFormat, DateFormats, GUILayout.MaxWidth(250f));
                ScreenshotUtility.TimeFormat = EditorGUILayout.Popup("Time format", TimeFormat, TimeFormats, GUILayout.MaxWidth(250f));
                EditorGUILayout.LabelField("Example: " + ScreenshotUtility.FormatFileName(1, DateFormats[DateFormat]), EditorStyles.miniLabel);

                EditorGUILayout.Space();
                
                ListenToPrintButton = EditorGUILayout.Toggle(new GUIContent("Print-screen button", "If the window is open, capture a screenshot whenever the print-screen keyboard button is pressed"), ListenToPrintButton);
            },

            keywords = new HashSet<string>(new[] { "Screenshot" })
        };

        return provider;
    }

    public void AddItemsToMenu(GenericMenu menu)
    {
        menu.AddItem(new GUIContent("Open settings"), false, OpenSettings);
    }

    private void OpenSettings()
    {
        SettingsService.OpenUserPreferences("Preferences/Screenshot");
    }
}