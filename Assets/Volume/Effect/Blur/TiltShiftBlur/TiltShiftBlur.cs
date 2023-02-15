using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace XPostProcessing
{
    public enum TiltShiftBlurQualityLevel
    {
        High_Quality = 0,
        Normal_Quality = 1,
    }

    [System.Serializable]
    public sealed class TiltShiftBlurQualityLevelParameter : VolumeParameter<TiltShiftBlurQualityLevel> { public TiltShiftBlurQualityLevelParameter(TiltShiftBlurQualityLevel value, bool overrideState = false) : base(value, overrideState) { } }


    [VolumeComponentMenu(VolumeDefine.Blur + "移轴模糊 (Tilt Shift Blur)")]
    public class TiltShiftBlur : VolumeSetting
    {
        public override bool IsActive() => BlurRadius.value > 0;
        public TiltShiftBlurQualityLevelParameter QualityLevel = new TiltShiftBlurQualityLevelParameter(TiltShiftBlurQualityLevel.High_Quality);
        public FloatParameter BlurRadius = new ClampedFloatParameter(0f, 0f, 1f);
        public FloatParameter AreaSize = new ClampedFloatParameter(0.5f, 0f, 1f);
        public IntParameter Iteration = new ClampedIntParameter(2, 1, 8);
        public FloatParameter RTDownScaling = new ClampedFloatParameter(1f, 1f, 2f);
    }

    public class TiltShiftBlurRenderer : VolumeRenderer<TiltShiftBlur>
    {

        public override string PROFILER_TAG => "TiltShiftBlur";
        public override string ShaderName => "Hidden/PostProcessing/Blur/TiltShiftBlur";


        static class ShaderIDs
        {
            internal static readonly int Params = Shader.PropertyToID("_Params");
            internal static readonly int BlurredTex = Shader.PropertyToID("_BlurredTex");
            internal static readonly int BufferRT1 = Shader.PropertyToID("_BufferRT1");
            internal static readonly int BufferRT2 = Shader.PropertyToID("_BufferRT2");
        }


        public override void Render(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier target, ref RenderingData renderingData)
        {


            //Get RT
            int RTWidth = (int)(Screen.width / settings.RTDownScaling.value);
            int RTHeight = (int)(Screen.height / settings.RTDownScaling.value);
            cmd.GetTemporaryRT(ShaderIDs.BufferRT1, RTWidth, RTHeight, 0, FilterMode.Bilinear);

            // Set Property
            blitMaterial.SetVector(ShaderIDs.Params, new Vector2(settings.AreaSize.value, settings.BlurRadius.value));

            // Do Blit
            cmd.Blit(source, ShaderIDs.BufferRT1, blitMaterial, (int)settings.QualityLevel.value);

            // Final Blit
            cmd.SetGlobalTexture(ShaderIDs.BlurredTex, ShaderIDs.BufferRT1);
            cmd.Blit(source, target, blitMaterial, 2);

            // release
            cmd.ReleaseTemporaryRT(ShaderIDs.BufferRT1);
        }
    }

}