using System.Collections.Concurrent;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.Rendering.Universal;
using BoolParameter = UnityEngine.Rendering.BoolParameter;
using ColorParameter = UnityEngine.Rendering.ColorParameter;
using FloatParameter = UnityEngine.Rendering.PostProcessing.FloatParameter;
using Vector2Parameter = UnityEngine.Rendering.Vector2Parameter;


[VolumeComponentMenu(VolumeDefine.Glitch + "数字条纹故障 (Digital Stripe Glitch)")]
public class GlitchDigitalStripe : CustomVolumeComponent
{
    public ClampedFloatParameter intensity = new ClampedFloatParameter(0f, 0.0f, 1.0f);
    public ClampedIntParameter frequency = new ClampedIntParameter(5, 1, 10);
    public ClampedFloatParameter stripeLength = new ClampedFloatParameter(0.89f, 0.0f, 0.99f);
    public ClampedIntParameter noiseTextureWidth = new ClampedIntParameter(20, 8, 256);
    public ClampedIntParameter noiseTextureHeight = new ClampedIntParameter(20, 8, 256);
    public BoolParameter needStripColorAdjust = new BoolParameter(false);

    [ColorUsageAttribute(true, true, 0f, 20f, 0.125f, 3f)]
    public ColorParameter StripColorAdjustColor = new ColorParameter(new Color(0.1f, 0.1f, 0.1f));

    public ClampedFloatParameter StripColorAdjustIndensity = new ClampedFloatParameter(2f, 0f, 10f);

    Texture2D _noiseTexture;
    RenderTexture _trashFrame1;
    RenderTexture _trashFrame2;

    private float randomFrequency;

    Material material;
    const string shaderName = "Hidden/PostProcessing/Glitch/DigitalStripe";

    public override CustomPostProcessInjectionPoint InjectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    public override void Setup()
    {
        if (material == null)
        {
            //使用CoreUtils.CreateEngineMaterial来从Shader创建材质
            //CreateEngineMaterial：使用提供的着色器路径创建材质。hideFlags将被设置为 HideFlags.HideAndDontSave。
            material = CoreUtils.CreateEngineMaterial(shaderName);
        }
    }

    //需要注意的是，IsActive方法最好要在组件无效时返回false，避免组件未激活时仍然执行了渲染，
    //原因之前提到过，无论组件是否添加到Volume菜单中或是否勾选，VolumeManager总是会初始化所有的VolumeComponent。
    public override bool IsActive() => material != null && intensity.value > 0f;

    public static Color RandomColor()
    {
        return new Color(Random.value, Random.value, Random.value, Random.value);
    }

    void UpdateNoiseTexture(int frame, int noiseTextureWidth, int noiseTextureHeight, float stripLength)
    {
        int frameCount = Time.frameCount;
        if (frameCount % frame != 0)
        {
            return;
        }

        _noiseTexture = new Texture2D(noiseTextureWidth, noiseTextureHeight, TextureFormat.ARGB32, false);
        _noiseTexture.wrapMode = TextureWrapMode.Clamp;
        _noiseTexture.filterMode = FilterMode.Point;

        _trashFrame1 = new RenderTexture(Screen.width, Screen.height, 0);
        _trashFrame2 = new RenderTexture(Screen.width, Screen.height, 0);
        _trashFrame1.hideFlags = HideFlags.DontSave;
        _trashFrame2.hideFlags = HideFlags.DontSave;

        Color32 color = RandomColor();

        for (int y = 0; y < _noiseTexture.height; y++)
        {
            for (int x = 0; x < _noiseTexture.width; x++)
            {
                //随机值若大于给定strip随机阈值，重新随机颜色
                if (UnityEngine.Random.value > stripLength)
                {
                    color = RandomColor();
                }

                //设置贴图像素值
                _noiseTexture.SetPixel(x, y, color);
            }
        }

        _noiseTexture.Apply();

        var bytes = _noiseTexture.EncodeToPNG();
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;

        UpdateNoiseTexture((int) frequency, (int) noiseTextureWidth, (int) noiseTextureHeight, (float) stripeLength);

        material.SetFloat("_Indensity", intensity.value);
        if (_noiseTexture != null)
        {
            material.SetTexture("_NoiseTex", _noiseTexture);
        }

        if (needStripColorAdjust == true)
        {
            material.EnableKeyword("NEED_TRASH_FRAME");
            material.SetColor("_StripColorAdjustColor", StripColorAdjustColor.value);
            material.SetFloat("_StripColorAdjustIndensity", StripColorAdjustIndensity.value);
        }
        else
        {
            material.DisableKeyword("NEED_TRASH_FRAME");
        }

        cmd.Blit(source, destination, material, 0);
    }

    public override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        CoreUtils.Destroy(material); //在Dispose中销毁材质
    }
}