using System.Collections.Concurrent;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.Rendering.Universal;
using BoolParameter = UnityEngine.Rendering.BoolParameter;
using FloatParameter = UnityEngine.Rendering.PostProcessing.FloatParameter;
using Vector2Parameter = UnityEngine.Rendering.Vector2Parameter;


[VolumeComponentMenu(VolumeDefine.Glitch + "模拟噪声故障 (AnalogNoise Glitch)")]
public class GlitchAnalogNoise : CustomVolumeComponent
{
    public ClampedFloatParameter NoiseSpeed = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);
    public ClampedFloatParameter NoiseFading = new ClampedFloatParameter(0f, 0.0f, 1.0f);
    public ClampedFloatParameter LuminanceJitterThreshold = new ClampedFloatParameter(0.8f, 0.0f, 1.0f);

    private float TimeX = 1.0f;

    Material material;
    const string shaderName = "Hidden/PostProcessing/Glitch/AnalogNoise";

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
    public override bool IsActive() => material != null && NoiseFading.value > 0f;

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;

        TimeX += Time.deltaTime;
        if (TimeX > 100)
        {
            TimeX = 0;
        }

        material.SetFloat("_Speed", NoiseSpeed.value);
        material.SetFloat("_Fading", NoiseFading.value);
        material.SetFloat("_LuminanceJitterThreshold", LuminanceJitterThreshold.value);
        material.SetFloat("_TimeX", TimeX);

        cmd.Blit(source, destination, material, 0);
    }

    public override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        CoreUtils.Destroy(material); //在Dispose中销毁材质
    }
}