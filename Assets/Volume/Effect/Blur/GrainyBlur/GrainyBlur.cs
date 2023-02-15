using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
namespace XPostProcessing
{
    [VolumeComponentMenu(VolumeDefine.Blur + "粒状模糊 (Grainy Blur)")]
    public class GrainyBlur : VolumeSetting
    {
        public override bool IsActive() => BlurRadius.value > 0;
        public FloatParameter BlurRadius = new ClampedFloatParameter(0f, 0f, 50f);
        public IntParameter Iteration = new ClampedIntParameter(4, 1, 8);
        public FloatParameter RTDownScaling = new ClampedFloatParameter(1f, 1f, 10f);
        public FloatParameter BlurRadiusMax = new FloatParameter(5f);
    }

    public class GrainyBlurRenderer : VolumeRenderer<GrainyBlur>
    {

        public override string PROFILER_TAG => "GrainyBlur";
        public override string ShaderName => "Hidden/PostProcessing/Blur/GrainyBlur";


        static class ShaderIDs
        {
            internal static readonly int Params = Shader.PropertyToID("_Params");
            internal static readonly int BufferRT = Shader.PropertyToID("_BufferRT");
        }


        public override void Render(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier target, ref RenderingData renderingData)
        {


            if (settings.RTDownScaling.value > 1)
            {
                int RTWidth = (int)(Screen.width / settings.RTDownScaling.value);
                int RTHeight = (int)(Screen.height / settings.RTDownScaling.value);
                cmd.GetTemporaryRT(ShaderIDs.BufferRT, RTWidth, RTHeight, 0, FilterMode.Bilinear);
                // downsample screen copy into smaller RT
                cmd.Blit(source, ShaderIDs.BufferRT);
            }

            blitMaterial.SetVector(ShaderIDs.Params, new Vector2(settings.BlurRadius.value / Screen.height, settings.Iteration.value));

            if (settings.RTDownScaling.value > 1)
            {
                cmd.Blit(ShaderIDs.BufferRT, target, blitMaterial, 0);
            }
            else
            {
                cmd.Blit(source, target, blitMaterial, 0);
            }

            // release
            cmd.ReleaseTemporaryRT(ShaderIDs.BufferRT);
        }
    }

}