using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode]
public class GlitchBlit : ScriptableRendererFeature

{
    [System.Serializable]
    public class setting

    {
        public Material mat = null;

        [Range(0, 1)] public float Instensity = 0.5f;

        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    public setting mysetting;

    class GlitchColorSplit : ScriptableRenderPass

    {
        setting mysetting = null;

        RenderTargetIdentifier sour;

        public void stetup(RenderTargetIdentifier source)

        {
            this.sour = source;
        }


        public GlitchColorSplit(setting set)

        {
            mysetting = set;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)

        {
            mysetting.mat.SetFloat("_Instensity", mysetting.Instensity);

            CommandBuffer cmd = CommandBufferPool.Get("GlitchColorSplit");

            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;

            int sourID = Shader.PropertyToID("_SourTex");

            cmd.GetTemporaryRT(sourID, desc);

            cmd.CopyTexture(sour, sourID);

            cmd.Blit(sourID, sour, mysetting.mat);

            context.ExecuteCommandBuffer(cmd);

            cmd.ReleaseTemporaryRT(sourID);

            CommandBufferPool.Release(cmd);
        }
    }


    GlitchColorSplit m_ColorSplit;


    public override void Create()

    {
        m_ColorSplit = new GlitchColorSplit(mysetting);

        m_ColorSplit.renderPassEvent = mysetting.passEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)

    {
        m_ColorSplit.stetup(renderer.cameraColorTarget);

        renderer.EnqueuePass(m_ColorSplit);
    }
}