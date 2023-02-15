using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace XPostProcessing
{
    [VolumeComponentMenu(VolumeDefine.ColorAdjustment + "ColorReplace")]
    public class ColorAdjustmentColorReplace : VolumeSetting
    {
        public override bool IsActive() => Range.value != 0;

        public FloatParameter Range = new ClampedFloatParameter(0f, 0f, 1);
        public FloatParameter Fuzziness = new ClampedFloatParameter(0.5f, 0f, 1f);
        public ColorParameter FromColor = new ColorParameter(new Color(0.8f, 0.0f, 0.0f, 1), true, true, true);
        public ColorParameter ToColor = new ColorParameter(new Color(0.0f, 0.8f, 0.0f, 1), true, true, true);

    }


    public class ColorAdjustmentColorReplaceRenderer : VolumeRenderer<ColorAdjustmentColorReplace>
    {
        public override string PROFILER_TAG => "ColorAdjustmentColorReplace";
        public override string ShaderName => "Hidden/PostProcessing/ColorAdjustment/ColorReplace";


        static class ShaderIDs
        {

            internal static readonly int Range = Shader.PropertyToID("_Range");
            internal static readonly int Fuzziness = Shader.PropertyToID("_Fuzziness");
            internal static readonly int FromColor = Shader.PropertyToID("_FromColor");
            internal static readonly int ToColor = Shader.PropertyToID("_ToColor");
        }


        public override void Render(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier target, ref RenderingData renderingData)
        {
            blitMaterial.SetFloat(ShaderIDs.Range, settings.Range.value);
            blitMaterial.SetFloat(ShaderIDs.Fuzziness, settings.Fuzziness.value);
            blitMaterial.SetColor(ShaderIDs.FromColor, settings.FromColor.value);
            blitMaterial.SetColor(ShaderIDs.ToColor, settings.ToColor.value);

            cmd.Blit(source, target, blitMaterial);
        }
    }

}