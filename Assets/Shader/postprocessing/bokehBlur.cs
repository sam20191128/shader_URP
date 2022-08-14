using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode]
public class bokehBlur : ScriptableRendererFeature
{
    [System.Serializable]
    public class setting
    {
        public Material mat;

        [Tooltip("降采样，越大性能越好但是质量越低"), Range(1, 7)]
        public int downsample = 2;

        [Tooltip("迭代次数，越小性能越好但是质量越低"), Range(3, 500)]
        public int loop = 50;

        [Tooltip("采样半径，越大圆斑越大但是采样点越分散"), Range(0.1f, 10)]
        public float R = 1;

        [Tooltip("模糊过渡的平滑度"), Range(0, 0.5f)] public float BlurSmoothness = 0.1f;

        [Tooltip("近处模糊结束距离")] public float NearDis = 5;

        [Tooltip("远处模糊开始距离")] public float FarDis = 9;

        public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;

        public string name = "散景模糊";
    }

    public setting mysetting = new setting();

    class CustomRenderPass : ScriptableRenderPass
    {
        public Material mat;

        public int loop;

        public float BlurSmoothness;

        public int downsample;

        public float R;

        public float NearDis;

        public float FarDis;

        RenderTargetIdentifier sour;

        public string name;

        int width;

        int height;

        readonly static int BlurID = Shader.PropertyToID("blur"); //申请之后就不在变化

        readonly static int SourBakedID = Shader.PropertyToID("_SourTex");

        public void setup(RenderTargetIdentifier Sour)
        {
            this.sour = Sour;

            mat.SetFloat("_loop", loop);

            mat.SetFloat("_radius", R);

            mat.SetFloat("_NearDis", NearDis);

            mat.SetFloat("_FarDis", FarDis);

            mat.SetFloat("_BlurSmoothness", BlurSmoothness);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(name);

            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;

            width = desc.width / downsample;

            height = desc.height / downsample;

            cmd.GetTemporaryRT(BlurID, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

            cmd.GetTemporaryRT(SourBakedID, desc);

            cmd.CopyTexture(sour, SourBakedID); //把相机图像复制到备份RT图，并自动发送到shader里，无需手动指定发送

            cmd.Blit(sour, BlurID, mat, 0); //第一个pass:把屏幕图像计算后存到一个降采样的模糊图里

            cmd.Blit(BlurID, sour, mat, 1); //第二个pass:发送模糊图到shader的maintex,然后混合输出


            cmd.ReleaseTemporaryRT(BlurID);

            cmd.ReleaseTemporaryRT(SourBakedID);

            CommandBufferPool.Release(cmd);
            context.ExecuteCommandBuffer(cmd);
        }
    }

    CustomRenderPass m_ScriptablePass = new CustomRenderPass();

    public override void Create()
    {
        m_ScriptablePass.mat = mysetting.mat;

        m_ScriptablePass.loop = mysetting.loop;

        m_ScriptablePass.BlurSmoothness = mysetting.BlurSmoothness;

        m_ScriptablePass.R = mysetting.R;

        m_ScriptablePass.renderPassEvent = mysetting.Event;

        m_ScriptablePass.name = mysetting.name;

        m_ScriptablePass.downsample = mysetting.downsample;

        m_ScriptablePass.NearDis = Mathf.Max(mysetting.NearDis, 0);

        m_ScriptablePass.FarDis = Mathf.Max(mysetting.NearDis, mysetting.FarDis);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ScriptablePass.setup(renderer.cameraColorTarget);

        renderer.EnqueuePass(m_ScriptablePass);
    }
}