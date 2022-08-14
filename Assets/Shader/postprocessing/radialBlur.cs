using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode]
public class radialBlur : ScriptableRendererFeature

{
    [System.Serializable]
    public class setting

    {
        public string PassName = "径向模糊";

        public Material RadialBlurMat = null;

        [Range(0, 1)] public float x = 0.5f;

        [Range(0, 1)] public float y = 0.5f;

        [Range(1, 8)] public int loop = 5;

        [Range(1, 8)] public float blur = 3;

        [Range(1, 5)] public int downsample = 2;

        [Range(0, 1)] public float instensity = 0.5f;

        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    public setting mysetitng = new setting();

    class CustomRenderPass : ScriptableRenderPass

    {
        public Material mymat;

        public string name;

        public float x;

        public float y;

        public int loop;

        public float instensity;

        public float blur;

        public int downsample;

        public RenderTargetIdentifier Source { get; set; }

        public RenderTargetIdentifier BlurTex;

        public RenderTargetIdentifier Temp1;

        public RenderTargetIdentifier Temp2;

        int ssW;

        int ssH;

        public void setupmypass(RenderTargetIdentifier source)

        {
            this.Source = source;
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)

        {
            int BlurTexID = Shader.PropertyToID("_BlurTex");

            int TempID1 = Shader.PropertyToID("Temp1");

            int TempID2 = Shader.PropertyToID("_SourceTex");

            int loopID = Shader.PropertyToID("_Loop");

            int Xid = Shader.PropertyToID("_X");

            int Yid = Shader.PropertyToID("_Y");

            int BlurID = Shader.PropertyToID("_Blur");

            int instenID = Shader.PropertyToID("_Instensity");


            RenderTextureDescriptor SSdesc = renderingData.cameraData.cameraTargetDescriptor;

            ssH = SSdesc.height / downsample;

            ssW = SSdesc.width / downsample;

            CommandBuffer cmd = CommandBufferPool.Get(name);

            cmd.GetTemporaryRT(TempID1, ssW, ssH, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32); //用来存降采样的

            cmd.GetTemporaryRT(BlurTexID, SSdesc); //模糊图

            cmd.GetTemporaryRT(TempID2, SSdesc); //

            BlurTex = new RenderTargetIdentifier(BlurTexID);

            Temp1 = new RenderTargetIdentifier(TempID1);

            Temp2 = new RenderTargetIdentifier(TempID2);

            cmd.SetGlobalFloat(loopID, loop);

            cmd.SetGlobalFloat(Xid, x);

            cmd.SetGlobalFloat(Yid, y);

            cmd.SetGlobalFloat(BlurID, blur);

            cmd.SetGlobalFloat(instenID, instensity);

            cmd.Blit(Source, Temp1); //存储降采样的源图，用于pass0计算模糊图

            cmd.Blit(Source, Temp2); //存储源图，用于计算pass1的混合

            cmd.Blit(Temp1, BlurTex, mymat, 0); //pass0的模糊计算

            cmd.Blit(BlurTex, Source, mymat, 1); //pass1的混合

            context.ExecuteCommandBuffer(cmd);

            cmd.ReleaseTemporaryRT(BlurTexID);

            cmd.ReleaseTemporaryRT(TempID1);

            cmd.ReleaseTemporaryRT(TempID2);

            CommandBufferPool.Release(cmd);
        }
    }

    CustomRenderPass m_ScriptablePass;

    public override void Create()

    {
        m_ScriptablePass = new CustomRenderPass();

        m_ScriptablePass.renderPassEvent = mysetitng.passEvent;

        m_ScriptablePass.blur = mysetitng.blur;

        m_ScriptablePass.x = mysetitng.x;

        m_ScriptablePass.y = mysetitng.y;

        m_ScriptablePass.instensity = mysetitng.instensity;

        m_ScriptablePass.loop = mysetitng.loop;

        m_ScriptablePass.mymat = mysetitng.RadialBlurMat;

        m_ScriptablePass.name = mysetitng.PassName;

        m_ScriptablePass.downsample = mysetitng.downsample;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)

    {
        if (mysetitng.RadialBlurMat != null)

        {
            m_ScriptablePass.setupmypass(renderer.cameraColorTarget);

            renderer.EnqueuePass(m_ScriptablePass);
        }

        else

        {
            Debug.LogError("径向模糊材质球丢失！");
        }
    }
}