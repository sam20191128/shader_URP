using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace XPostProcessing
{
    [VolumeComponentMenu(VolumeDefine.Pixelate + "LED像素化 (PixelizeLed)")]
    public class PixelizeLed : VolumeSetting
    {
        public override bool IsActive() => pixelSize.value > 0;
        public FloatParameter pixelSize = new ClampedFloatParameter(0f, 0.01f, 1.0f);
        public FloatParameter ledRadius = new ClampedFloatParameter(1f, 0.01f, 1.0f);
        public ColorParameter BackgroundColor = new ColorParameter(Color.black, true, true, true);
        public BoolParameter useAutoScreenRatio = new BoolParameter(true);
        public FloatParameter pixelRatio = new ClampedFloatParameter(1f, 0.2f, 5.0f);
    }


    public class PixelizeLedRenderer : VolumeRenderer<PixelizeLed>
    {
        public override string PROFILER_TAG => "PixelizeLed";
        public override string ShaderName => "Hidden/PostProcessing/Pixelate/PixelizeLed";

        static class ShaderIDs
        {
            internal static readonly int Params = Shader.PropertyToID("_Params");
            internal static readonly int BackgroundColor = Shader.PropertyToID("_BackgroundColor");
        }


        public override void Render(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier target, ref RenderingData renderingData)
        {
            float size = (1.01f - settings.pixelSize.value) * 300f;

            float ratio = settings.pixelRatio.value;
            if (settings.useAutoScreenRatio.value)
            {
                ratio = (float)(Screen.width / (float)Screen.height);
                if (ratio == 0)
                {
                    ratio = 1f;
                }
            }

            blitMaterial.SetVector(ShaderIDs.Params, new Vector4(size, ratio, settings.ledRadius.value));
            blitMaterial.SetColor(ShaderIDs.BackgroundColor, settings.BackgroundColor.value);

            cmd.Blit(source, target, blitMaterial);
        }
    }

}