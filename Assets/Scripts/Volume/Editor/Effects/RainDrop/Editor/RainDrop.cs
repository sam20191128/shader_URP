using System.Collections.Concurrent;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.Rendering.Universal;
using BoolParameter = UnityEngine.Rendering.BoolParameter;
using FloatParameter = UnityEngine.Rendering.PostProcessing.FloatParameter;
using Vector2Parameter = UnityEngine.Rendering.Vector2Parameter;


[VolumeComponentMenu(VolumeDefine.Extra + "雨滴 (RainDrop)")]
public class RainDrop : CustomVolumeComponent
{
    public ClampedFloatParameter Size = new ClampedFloatParameter(0f, 0.0f, 100.0f);
    public ClampedFloatParameter T = new ClampedFloatParameter(1, 0.0f, 50.0f);
    public ClampedFloatParameter Distortion = new ClampedFloatParameter(-5f, 0.0f, 1.0f);
    //public ClampedFloatParameter Blur = new ClampedFloatParameter(0f, 0.0f, 1.0f);

    Material material;
    const string shaderName = "Hidden/PostProcessing/Extra/RainDrop";

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
    public override bool IsActive() => material != null && Size.value > 0f;


    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;

        material.SetFloat("_Size", Size.value);
        material.SetFloat("_T", T.value);
        material.SetFloat("_Distortion", Distortion.value);
        //material.SetFloat("_Blur", Blur.value);

        cmd.Blit(source, destination, material, 0);
    }

    public override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        CoreUtils.Destroy(material); //在Dispose中销毁材质
    }
}