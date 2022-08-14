using System.Collections.Concurrent;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.Rendering.Universal;
using FloatParameter = UnityEngine.Rendering.PostProcessing.FloatParameter;


[VolumeComponentMenu(VolumeDefine.Glitch + "RGB颜色分离V5 (RGB SplitV5)")]
public class GlitchRGBSplitV5 : CustomVolumeComponent
{
    public DirectionEXParameter SplitDirection = new DirectionEXParameter(DirectionEX.Horizontal);

    public ClampedFloatParameter indensity = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);
    public ClampedFloatParameter speed = new ClampedFloatParameter(10f, 0.0f, 100.0f);

    private float randomFrequency;
    private int frameCount = 0;

    Material material;
    const string shaderName = "Hidden/PostProcessing/Glitch/RGBSplitV5";

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
    public override bool IsActive() => material != null && indensity.value > 0f;

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;

        material.SetFloat("_Indensity", indensity.value);
        material.SetFloat("_Speed", speed.value);


        //临时RT到目标纹理
        cmd.Blit(source, destination, material, (int) SplitDirection.value);
    }

    public override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        CoreUtils.Destroy(material); //在Dispose中销毁材质
    }
}