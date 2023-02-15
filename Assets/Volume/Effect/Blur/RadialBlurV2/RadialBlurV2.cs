using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
namespace XPostProcessing
{

    public enum RadialBlurQuality
    {
        RadialBlur_4Tap_Fatest = 0,
        RadialBlur_6Tap = 1,
        RadialBlur_8Tap_Balance = 2,
        RadialBlur_10Tap = 3,
        RadialBlur_12Tap = 4,
        RadialBlur_20Tap_Quality = 5,
        RadialBlur_30Tap_Extreme = 6,
    }

    [System.Serializable]
    public sealed class RadialBlurQualityParameter : VolumeParameter<RadialBlurQuality> { }

    [VolumeComponentMenu(VolumeDefine.Blur + "径向模糊V2 (Radial BlurV2)")]
    public class RadialBlurV2 : VolumeSetting
    {
        public RadialBlurQualityParameter QualityLevel = new RadialBlurQualityParameter { value = RadialBlurQuality.RadialBlur_8Tap_Balance };

        public override bool IsActive() => BlurRadius.value != 0;

        public FloatParameter BlurRadius = new ClampedFloatParameter(0f, -1f, 1f);
        public FloatParameter RadialCenterX = new ClampedFloatParameter(0.5f, 0f, 1f);
        public FloatParameter RadialCenterY = new ClampedFloatParameter(0.5f, 0f, 1f);
    }


    public class RadialBlurV2Renderer : VolumeRenderer<RadialBlurV2>
    {
        public override string PROFILER_TAG => "RadialBlurV2";
        public override string ShaderName => "Hidden/PostProcessing/Blur/RadialBlurV2";



        static class ShaderIDs
        {
            internal static readonly int Params = Shader.PropertyToID("_Params");
        }


        public override void Render(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier target, ref RenderingData renderingData)
        {


            blitMaterial.SetVector(ShaderIDs.Params, new Vector3(settings.BlurRadius.value * 0.02f, settings.RadialCenterX.value, settings.RadialCenterY.value));

            cmd.Blit(source, target, blitMaterial, (int)settings.QualityLevel.value);


        }
    }

}