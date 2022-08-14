using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu(VolumeDefine.Blur + "移轴模糊 (TiltShift Blur V2)")]
public class TiltShiftBlurV2 : CustomVolumeComponent
{
    public ClampedFloatParameter blurRadius = new ClampedFloatParameter(0f, 0f, 0.01f); //模糊强度
    public ClampedFloatParameter iterations = new ClampedFloatParameter(8, 8f, 128f); //迭代次数
    public ClampedFloatParameter centerOffset = new ClampedFloatParameter(0, -1, 1);
    public ClampedFloatParameter AreaSize = new ClampedFloatParameter(0, 0, 20);
    public ClampedFloatParameter areaSmooth = new ClampedFloatParameter(0, 1, 20);
    public BoolParameter showPreview = new BoolParameter(false); // { value = false };
    
    Material material;
    const string shaderName = "Hidden/PostProcessing/Blur/TiltShiftBlurV2";

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
    public override bool IsActive() => material != null && blurRadius.value > 0f;

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;

        material.SetFloat("_Radius", blurRadius.value);
        material.SetFloat("_Iteration", iterations.value);
        material.SetFloat("_Offset", centerOffset.value);
        material.SetFloat("_Area", AreaSize.value);
        material.SetFloat("_Spread", areaSmooth.value);

        if (showPreview == true)
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