using System.Collections.Concurrent;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.Rendering.Universal;
using FloatParameter = UnityEngine.Rendering.PostProcessing.FloatParameter;


[VolumeComponentMenu(VolumeDefine.Glitch + "RGB颜色分离V3多级sin延迟跟随 (RGB SplitV3)")]
public class GlitchRGBSplitV3 : CustomVolumeComponent
{
    public DirectionEXParameter SplitDirection = new DirectionEXParameter(DirectionEX.Horizontal);
    public IntervalTypeParameter intervalType = new IntervalTypeParameter(IntervalType.Random);
    
    public ClampedFloatParameter amount = new ClampedFloatParameter(0f, 0f, 200f);
    public ClampedFloatParameter frequency = new ClampedFloatParameter(3f, 0.1f, 25f);
    public ClampedFloatParameter speed = new ClampedFloatParameter(15f, 0f, 15f);
    
    private float randomFrequency;
    private int frameCount = 0;

    Material material;
    const string shaderName = "Hidden/PostProcessing/Glitch/RGBSplitV3";

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
            if (frameCount > (float) frequency)
            {
                frameCount = 0;
                randomFrequency = UnityEngine.Random.Range(0, (float) frequency);
            }

            frameCount++;
        }

        if (intervalType.value == IntervalType.Infinite)
        {
            material.EnableKeyword("USING_Frequency_INFINITE");
        }
        else
        {
            material.DisableKeyword("USING_Frequency_INFINITE");
        }
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;

        UpdateFrequency(frequency);

        material.SetFloat("_Amount", amount.value);
        material.SetFloat("_Frequency", frequency.value);
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