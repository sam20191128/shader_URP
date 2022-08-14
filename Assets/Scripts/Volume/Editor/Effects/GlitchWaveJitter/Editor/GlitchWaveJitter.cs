using System.Collections.Concurrent;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.Rendering.Universal;
using BoolParameter = UnityEngine.Rendering.BoolParameter;
using FloatParameter = UnityEngine.Rendering.PostProcessing.FloatParameter;
using Vector2Parameter = UnityEngine.Rendering.Vector2Parameter;


[VolumeComponentMenu(VolumeDefine.Glitch + "波形抖动故障 (Wave Jitter Glitch)")]
public class GlitchWaveJitter : CustomVolumeComponent
{
    public DirectionParameter jitterDirection = new DirectionParameter(Direction.Horizontal);
    public IntervalTypeParameter intervalType = new IntervalTypeParameter(IntervalType.Random);

    public ClampedFloatParameter frequency = new ClampedFloatParameter(5f, 0.0f, 50.0f);
    public ClampedFloatParameter RGBSplit = new ClampedFloatParameter(20f, 0.0f, 50.0f);
    public ClampedFloatParameter speed = new ClampedFloatParameter(0.25f, 0.0f, 1.0f);
    public ClampedFloatParameter amount = new ClampedFloatParameter(0f, 0.0f, 2.0f);
    public BoolParameter customResolution = new BoolParameter(false);
    public Vector2Parameter resolution = new Vector2Parameter(new Vector2(640f, 480f));

    private float randomFrequency;

    Material material;
    const string shaderName = "Hidden/PostProcessing/Glitch/WaveJitter";

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
    public override bool IsActive() => material != null && amount.value > 0f;

    void UpdateFrequency(ClampedFloatParameter frequency)
    {
        if (intervalType.value == IntervalType.Random)
        {
            randomFrequency = UnityEngine.Random.Range(0, (float) frequency);
        }

        if (intervalType.value == IntervalType.Infinite)
        {
            material.EnableKeyword("USING_FREQUENCY_INFINITE");
        }
        else
        {
            material.DisableKeyword("USING_FREQUENCY_INFINITE");
        }
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;

        UpdateFrequency(frequency);

        material.SetFloat("_Frequency", intervalType.value == IntervalType.Random ? randomFrequency : frequency.value);
        material.SetFloat("_RGBSplit", RGBSplit.value);
        material.SetFloat("_Speed", speed.value);
        material.SetFloat("_Amount", amount.value);
        material.SetVector("_Resolution", customResolution.value ? resolution.value : new Vector2(Screen.width, Screen.height));

        cmd.Blit(source, destination, material, jitterDirection.value == Direction.Horizontal ? 0 : 1);
    }

    public override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        CoreUtils.Destroy(material); //在Dispose中销毁材质
    }
}