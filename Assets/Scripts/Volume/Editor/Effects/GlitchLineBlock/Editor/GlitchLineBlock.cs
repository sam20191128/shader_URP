using System.Collections.Concurrent;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.Rendering.Universal;
using BoolParameter = UnityEngine.Rendering.BoolParameter;
using FloatParameter = UnityEngine.Rendering.PostProcessing.FloatParameter;


[VolumeComponentMenu(VolumeDefine.Glitch + "线条错位故障 (Line Block)")]
public class GlitchLineBlock : CustomVolumeComponent
{
    public DirectionParameter blockDirection = new DirectionParameter(Direction.Horizontal);
    public IntervalTypeParameter intervalType = new IntervalTypeParameter(IntervalType.Random);

    public ClampedFloatParameter frequency = new ClampedFloatParameter(1f, 0.0f, 25.0f);
    public ClampedFloatParameter Amount = new ClampedFloatParameter(0f, 0.0f, 1.0f);
    public ClampedFloatParameter LinesWidth = new ClampedFloatParameter(1f, 0.1f, 10.0f);
    public ClampedFloatParameter Speed = new ClampedFloatParameter(0.8f, 0.0f, 1.0f);
    public ClampedFloatParameter Offset = new ClampedFloatParameter(1f, 0.0f, 13.0f);
    public ClampedFloatParameter Alpha = new ClampedFloatParameter(1f, 0.0f, 1.0f);

    private float TimeX = 1.0f;
    private float randomFrequency;
    private int frameCount = 0;

    Material material;
    const string shaderName = "Hidden/PostProcessing/Glitch/LineBlock";

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
    public override bool IsActive() => material != null && Amount.value > 0f;

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

        TimeX += Time.deltaTime;
        if (TimeX > 100)
        {
            TimeX = 0;
        }

        material.SetFloat("_Frequency", intervalType.value == IntervalType.Random ? randomFrequency : frequency.value);
        material.SetFloat("_TimeX", TimeX * Speed.value * 0.2f);
        material.SetFloat("_Amount", Amount.value);
        material.SetFloat("_Offset", Offset.value);
        material.SetFloat("_LinesWidth", LinesWidth.value);
        material.SetFloat("_Alpha", intervalType.value == IntervalType.Random ? randomFrequency : frequency.value);

        cmd.Blit(source, destination, material, (int) blockDirection.value);
    }

    public override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        CoreUtils.Destroy(material); //在Dispose中销毁材质
    }
}