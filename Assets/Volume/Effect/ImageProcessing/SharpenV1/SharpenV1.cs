using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace XPostProcessing
{
    [VolumeComponentMenu(VolumeDefine.ImageProcessing + "SharpenV1")]
    public class SharpenV1 : VolumeSetting
    {
        public override bool IsActive() => Strength.value > 0;
        public FloatParameter Strength = new ClampedFloatParameter(0f, 0f, 5f);
        public FloatParameter Threshold = new ClampedFloatParameter(0.1f, 0f, 1);
    }

    public class SharpenV1Renderer : VolumeRenderer<SharpenV1>
    {
        public override string PROFILER_TAG => "SharpenV1";
        public override string ShaderName => "Hidden/PostProcessing/ImageProcessing/SharpenV1";


        static class ShaderIDs
        {
            internal static readonly int Strength = Shader.PropertyToID("_Strength");
            internal static readonly int Threshold = Shader.PropertyToID("_Threshold");
        }


        public override void Render(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier target, ref RenderingData renderingData)
        {
            blitMaterial.SetFloat(ShaderIDs.Strength, settings.Strength.value);
            blitMaterial.SetFloat(ShaderIDs.Threshold, settings.Threshold.value);

            cmd.Blit(source, target, blitMaterial);
        }

    }

}