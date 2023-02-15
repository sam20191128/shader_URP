using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace XPostProcessing
{
    [VolumeComponentMenu(VolumeDefine.EdgeDetection + "Scharr")]
    public class EdgeDetectionScharr : VolumeSetting
    {
        public override bool IsActive() => edgeWidth.value > 0;

        public FloatParameter edgeWidth = new ClampedFloatParameter(0, 0f, 5.0f);
        public ColorParameter edgeColor = new ColorParameter(Color.black, true, true, true);
        public FloatParameter backgroundFade = new ClampedFloatParameter(1, 0f, 1.0f);
        public ColorParameter backgroundColor = new ColorParameter(Color.white, true, true, true);

        // [ColorUsageAttribute(true, true, 0f, 20f, 0.125f, 3f)]
        // public ColorParameter edgeColor = new ColorParameter { value = new Color(0.0f, 0.0f, 0.0f, 1) };

        // [Range(0.0f, 1.0f)]
        // public FloatParameter backgroundFade = new FloatParameter { value = 1f };

        // [ColorUsageAttribute(true, true, 0f, 20f, 0.125f, 3f)]
        // public ColorParameter backgroundColor = new ColorParameter { value = new Color(1.0f, 1.0f, 1.0f, 1) };
    }


    public class EdgeDetectionScharrRenderer : VolumeRenderer<EdgeDetectionScharr>
    {
        public override string PROFILER_TAG => "EdgeDetectionScharr";
        public override string ShaderName => "Hidden/PostProcessing/EdgeDetection/Scharr";


        static class ShaderIDs
        {
            internal static readonly int Params = Shader.PropertyToID("_Params");
            internal static readonly int EdgeColor = Shader.PropertyToID("_EdgeColor");
            internal static readonly int BackgroundColor = Shader.PropertyToID("_BackgroundColor");
        }


        public override void Render(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier target, ref RenderingData renderingData)
        {
            blitMaterial.SetVector(ShaderIDs.Params, new Vector2(settings.edgeWidth.value, settings.backgroundFade.value));
            blitMaterial.SetColor(ShaderIDs.EdgeColor, settings.edgeColor.value);
            blitMaterial.SetColor(ShaderIDs.BackgroundColor, settings.backgroundColor.value);

            cmd.Blit(source, target, blitMaterial);
        }
    }

}