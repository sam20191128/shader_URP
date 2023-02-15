using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace XPostProcessing
{
    [VolumeComponentMenu(VolumeDefine.Blur + "双重高斯模糊 (Dual Gaussian Blur)")]
    public class DualGaussianBlur : VolumeSetting
    {
        public override bool IsActive() => BlurRadius.value > 0;
        public FloatParameter BlurRadius = new ClampedFloatParameter(0f, 0f, 15f);
        public IntParameter Iteration = new ClampedIntParameter(4, 1, 8);
        public FloatParameter RTDownScaling = new ClampedFloatParameter(1f, 1f, 10f);
    }

    public class DualGaussianBlurRenderer : VolumeRenderer<DualGaussianBlur>
    {

        public override string PROFILER_TAG => "DualGaussianBlur";
        public override string ShaderName => "Hidden/PostProcessing/Blur/DualGaussianBlur";



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
                    down_vertical = Shader.PropertyToID("_BlurMipDownV" + i),
                    down_horizontal = Shader.PropertyToID("_BlurMipDownH" + i),
                    up_vertical = Shader.PropertyToID("_BlurMipUpV" + i),
                    up_horizontal = Shader.PropertyToID("_BlurMipUpH" + i),

                };
            }
        }

        static class ShaderIDs
        {
            internal static readonly int BlurOffset = Shader.PropertyToID("_BlurOffset");
            internal static readonly int BufferRT1 = Shader.PropertyToID("_BufferRT1");
            internal static readonly int BufferRT2 = Shader.PropertyToID("_BufferRT2");
        }

        struct Level
        {
            internal int down_vertical;
            internal int down_horizontal;
            internal int up_horizontal;
            internal int up_vertical;
        }


        public override void Render(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier target, ref RenderingData renderingData)
        {


            int tw = (int)(Screen.width / settings.RTDownScaling.value);
            int th = (int)(Screen.height / settings.RTDownScaling.value);

            Vector4 BlurOffset = new Vector4(settings.BlurRadius.value / (float)Screen.width, settings.BlurRadius.value / (float)Screen.height, 0, 0);
            blitMaterial.SetVector(ShaderIDs.BlurOffset, BlurOffset);
            // Downsample
            RenderTargetIdentifier lastDown = source;
            for (int i = 0; i < settings.Iteration.value; i++)
            {
                int mipDownV = m_Pyramid[i].down_vertical;
                int mipDowH = m_Pyramid[i].down_horizontal;
                int mipUpV = m_Pyramid[i].up_vertical;
                int mipUpH = m_Pyramid[i].up_horizontal;

                cmd.GetTemporaryRT(mipDownV, tw, th, 0, FilterMode.Bilinear);
                cmd.GetTemporaryRT(mipDowH, tw, th, 0, FilterMode.Bilinear);
                cmd.GetTemporaryRT(mipUpV, tw, th, 0, FilterMode.Bilinear);
                cmd.GetTemporaryRT(mipUpH, tw, th, 0, FilterMode.Bilinear);


                // horizontal blur
                blitMaterial.SetVector(ShaderIDs.BlurOffset, new Vector4(settings.BlurRadius.value / Screen.width, 0, 0, 0));
                cmd.Blit(lastDown, mipDowH, blitMaterial, 0);

                // vertical blur
                blitMaterial.SetVector(ShaderIDs.BlurOffset, new Vector4(0, settings.BlurRadius.value / Screen.height, 0, 0));
                cmd.Blit(mipDowH, mipDownV, blitMaterial, 0);

                lastDown = mipDownV;
                tw = Mathf.Max(tw / 2, 1);
                th = Mathf.Max(th / 2, 1);
            }

            // Upsample
            int lastUp = m_Pyramid[settings.Iteration.value - 1].down_vertical;
            for (int i = settings.Iteration.value - 2; i >= 0; i--)
            {

                int mipUpV = m_Pyramid[i].up_vertical;
                int mipUpH = m_Pyramid[i].up_horizontal;

                // horizontal blur
                blitMaterial.SetVector(ShaderIDs.BlurOffset, new Vector4(settings.BlurRadius.value / Screen.width, 0, 0, 0));
                cmd.Blit(lastUp, mipUpH, blitMaterial, 0);

                // vertical blur
                blitMaterial.SetVector(ShaderIDs.BlurOffset, new Vector4(0, settings.BlurRadius.value / Screen.height, 0, 0));
                cmd.Blit(mipUpH, mipUpV, blitMaterial, 0);

                lastUp = mipUpV;
            }


            // Render blurred texture in blend pass
            cmd.Blit(lastUp, target, blitMaterial, 1);

            // Cleanup
            for (int i = 0; i < settings.Iteration.value; i++)
            {
                if (m_Pyramid[i].down_vertical != lastUp)
                    cmd.ReleaseTemporaryRT(m_Pyramid[i].down_vertical);
                if (m_Pyramid[i].down_horizontal != lastUp)
                    cmd.ReleaseTemporaryRT(m_Pyramid[i].down_horizontal);
                if (m_Pyramid[i].up_horizontal != lastUp)
                    cmd.ReleaseTemporaryRT(m_Pyramid[i].up_horizontal);
                if (m_Pyramid[i].up_vertical != lastUp)
                    cmd.ReleaseTemporaryRT(m_Pyramid[i].up_vertical);
            }


        }
    }

}