using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


namespace XPostProcessing
{
    [VolumeComponentMenu(VolumeDefine.ColorAdjustment + "屏幕灰化 (Screen Binarization)")]
    public class ScreenBinarization : VolumeSetting
    {
        public override bool IsActive() => intensity.value > 0;

        [Tooltip("强度")]
        public ClampedFloatParameter intensity = new ClampedFloatParameter(0f, 0.00f, 1f, true);
    }

    public class ScreenBinarizationRenderer : VolumeRenderer<ScreenBinarization>
    {
        public override string PROFILER_TAG => "Screen Binarization";
        public override string ShaderName => "Hidden/PostProcessing/ScreenBinarization";

        static class ShaderIDs
        {
            public static readonly int BinarizationAmountPID = Shader.PropertyToID("_BinarizationAmount");
        }

        public override void Render(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier target, ref RenderingData renderingData)
        {
            blitMaterial.SetFloat(ShaderIDs.BinarizationAmountPID, settings.intensity.value);
            cmd.Blit(source, target, blitMaterial);

        }
    }

}