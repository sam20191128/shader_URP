using System.Collections.Concurrent;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.Rendering.Universal;
using BoolParameter = UnityEngine.Rendering.BoolParameter;
using FloatParameter = UnityEngine.Rendering.PostProcessing.FloatParameter;


[VolumeComponentMenu(VolumeDefine.Glitch + "错位图块故障V2 (ImageBlockV2)")]
public class GlitchImageBlockV2 : CustomVolumeComponent
{
    public ClampedFloatParameter Fade = new ClampedFloatParameter(0f, 0.0f, 1.0f);
    public ClampedFloatParameter Speed = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);
    public ClampedFloatParameter Amount = new ClampedFloatParameter(1f, 0.0f, 10.0f);
    public ClampedFloatParameter BlockLayer1_U = new ClampedFloatParameter(2f, 0.0f, 50.0f);
    public ClampedFloatParameter BlockLayer1_V = new ClampedFloatParameter(16f, 0.0f, 50.0f);
    public ClampedFloatParameter BlockLayer1_Indensity = new ClampedFloatParameter(8f, 0.0f, 50.0f);
    public ClampedFloatParameter RGBSplitIndensity = new ClampedFloatParameter(2f, 0.0f, 50.0f);
    public BoolParameter BlockVisualizeDebug = new BoolParameter(false); // { value = false };

    private float TimeX = 1.0f;


    Material material;
    const string shaderName = "Hidden/PostProcessing/Glitch/ImageBlockV2";

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
    public override bool IsActive() => material != null && Fade.value > 0f;

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;

        TimeX += Time.deltaTime;
        if (TimeX > 100)
        {
            TimeX = 0;
        }

        material.SetFloat("_Fade", Fade.value);
        material.SetFloat("_TimeX", TimeX * Speed.value);
        material.SetFloat("_Offset", Amount.value);
        material.SetFloat("_BlockLayer1_U", BlockLayer1_U.value);
        material.SetFloat("_BlockLayer1_V", BlockLayer1_V.value);
        material.SetFloat("_BlockLayer1_Indensity", BlockLayer1_Indensity.value);
        material.SetFloat("_RGBSplit_Indensity", RGBSplitIndensity.value);

        if (BlockVisualizeDebug == true)
        {
            //debug
            cmd.Blit(source, destination, material, 1);
        }
        else
        {
            cmd.Blit(source, destination, material, 0);
        }
    }

    public override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        CoreUtils.Destroy(material); //在Dispose中销毁材质
    }
}