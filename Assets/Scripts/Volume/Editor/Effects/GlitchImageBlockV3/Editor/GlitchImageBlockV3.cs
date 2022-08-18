using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu(VolumeDefine.Glitch + "错位图块故障V3 (ImageBlockV3)")]
public class GlitchImageBlockV3 : CustomVolumeComponent
{
    public ClampedFloatParameter Speed = new ClampedFloatParameter(0.0f, 0.0f, 50.0f);
    public ClampedFloatParameter BlockSize = new ClampedFloatParameter(8f, 0.0f, 50.0f);
    public BoolParameter BlockVisualizeDebug = new BoolParameter(false); // { value = false };

    Material material;
    const string shaderName = "Hidden/PostProcessing/Glitch/ImageBlockV3";

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
    public override bool IsActive() => material != null && Speed.value > 0f;

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;


        material.SetFloat("_Speed", Speed.value);
        material.SetFloat("_BlockSize", BlockSize.value);


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