using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
namespace XPostProcessing
{
    [VolumeComponentMenu(VolumeDefine.Blur + "双重Kawase模糊 (Dual Kawase Blur)")]
    public class DualKawaseBlur : VolumeSetting
    {
        public override bool IsActive() => BlurRadius.value > 0;
        public FloatParameter BlurRadius = new ClampedFloatParameter(0f, 0f, 15f);
        public IntParameter Iteration = new ClampedIntParameter(4, 1, 8);
        public FloatParameter RTDownScaling = new ClampedFloatParameter(2f, 1f, 10f);
    }

    public class DualKawaseBlurRenderer : VolumeRenderer<DualKawaseBlur>
    {
        public override string PROFILER_TAG => "DualKawaseBlur";
        public override string ShaderName => "Hidden/PostProcessing/Blur/DualKawaseBlur";



        // [down,up]
        Level[] m_Pyramid;
        const int k_MaxPyramidSize = 16;

        public override void Init()
        {
            base.Init();

            m_Pyramid = new Level[k_MaxPyramidSize];

            for (int i = 0; i < k_MaxPyramidSize; i++)
            {
                m_Pyramid[i] = new Level
                {
                    down = Shader.PropertyToID("_BlurMipDown" + i),
                    up = Shader.PropertyToID("_BlurMipUp" + i)
                };
            }
        }

        static class ShaderIDs
        {
            internal static readonly int BlurOffset = Shader.PropertyToID("_BlurOffset");
        }

        struct Level
        {
            internal int down;
            internal int up;
        }


        public override void Render(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier target, ref RenderingData renderingData)
        {


            int tw = (int)(Screen.width / settings.RTDownScaling.value);
            int th = (int)(Screen.height / settings.RTDownScaling.value);

            blitMaterial.SetFloat(ShaderIDs.BlurOffset, settings.BlurRadius.value);

            // Downsample
            RenderTargetIdentifier lastDown = source;
            for (int i = 0; i < settings.Iteration.value; i++)
            {
                int mipDown = m_Pyramid[i].down;
                int mipUp = m_Pyramid[i].up;
                cmd.GetTemporaryRT(mipDown, tw, th, 0, FilterMode.Bilinear);
                cmd.GetTemporaryRT(mipUp, tw, th, 0, FilterMode.Bilinear);

                // cmd.GetTemporaryRT(cmd, mipDown, 0, RenderTextureReadWrite.Default, FilterMode.Bilinear, tw, th);
                // context.GetScreenSpaceTemporaryRT(cmd, mipUp, 0, context.sourceFormat, RenderTextureReadWrite.Default, FilterMode.Bilinear, tw, th);
                cmd.Blit(lastDown, mipDown, blitMaterial);

                lastDown = mipDown;
                tw = Mathf.Max(tw / 2, 1);
                th = Mathf.Max(th / 2, 1);
            }

            // Upsample
            int lastUp = m_Pyramid[settings.Iteration.value - 1].down;
            for (int i = settings.Iteration.value - 2; i >= 0; i--)
            {
                int mipUp = m_Pyramid[i].up;
                cmd.Blit(lastUp, mipUp, blitMaterial);
                lastUp = mipUp;
            }


            // Render blurred texture in blend pass
            cmd.Blit(lastUp, target, blitMaterial, 1);

            // Cleanup
            for (int i = 0; i < settings.Iteration.value; i++)
            {
                if (m_Pyramid[i].down != lastUp)
                    cmd.ReleaseTemporaryRT(m_Pyramid[i].down);
                if (m_Pyramid[i].up != lastUp)
                    cmd.ReleaseTemporaryRT(m_Pyramid[i].up);
            }

        }
    }

}