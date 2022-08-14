using System.Collections.Concurrent;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.Rendering.Universal;
using BoolParameter = UnityEngine.Rendering.BoolParameter;
using FloatParameter = UnityEngine.Rendering.PostProcessing.FloatParameter;


[VolumeComponentMenu(VolumeDefine.Glitch + "扫描线抖动故障 (ScanLine Jitter)")]
public class GlitchScanLineJitter : CustomVolumeComponent
{
    public DirectionParameter JitterDirection = new DirectionParameter(Direction.Horizontal);
    public IntervalTypeParameter intervalType = new IntervalTypeParameter(IntervalType.Random);

    public ClampedFloatParameter frequency = new ClampedFloatParameter(1f, 0.0f, 25.0f);
    public ClampedFloatParameter JitterIndensity = new ClampedFloatParameter(0f, 0.0f, 1.0f);

    private float randomFrequency;
    private int frameCount = 0;

    Material material;
    const string shaderName = "Hidden/PostProcessing/Glitch/ScanLineJitter";

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
    public override bool IsActive() => material != null && JitterIndensity.value > 0f;

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

        float displacement = 0.005f + Mathf.Pow(JitterIndensity.value, 3) * 0.1f;
        float threshold = Mathf.Clamp01(1.0f - JitterIndensity.value * 1.2f);

        material.SetFloat("_Amount", displacement);
        material.SetFloat("_Threshold", threshold);
        material.SetFloat("_Frequency", intervalType.value == IntervalType.Random ? randomFrequency : frequency.value);

        cmd.Blit(source, destination, material, (int) JitterDirection.value);
    }

    public override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        CoreUtils.Destroy(material); //在Dispose中销毁材质
    }
}