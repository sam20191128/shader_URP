using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Kawaseblur : ScriptableRendererFeature

{
    [System.Serializable]
    public class mysetting //定义一个设置的类

    {
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents; //默认插到透明完成后

        public Material mymat;

        [Range(2, 10)] public int downsample = 2;

        [Range(2, 10)] public int loop = 2;

        [Range(0.5f, 5)] public float blur = 0.5f;

        public string passTag = "mypassTag";
    }

    public mysetting setting = new mysetting();

    class CustomRenderPass : ScriptableRenderPass //自定义pass

    {
        public Material passMat = null;

        public int passdownsample = 2;

        public int passloop = 2;

        public float passblur = 4;

        public FilterMode passfiltermode { get; set; } //图像的模式

        private RenderTargetIdentifier passSource { get; set; } //源图像,目标图像

        RenderTargetIdentifier buffer1; //临时计算图像1

        RenderTargetIdentifier buffer2; //临时计算图像2

        string passTag;

        public CustomRenderPass(string tag) //构造函数

        {
            passTag = tag;
        }

        public void setup(RenderTargetIdentifier sour) //接收renderfeather传的图

        {
            this.passSource = sour;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) //类似OnRenderimagePass

        {
            int bufferid1 = Shader.PropertyToID("bufferblur1");

            int bufferid2 = Shader.PropertyToID("bufferblur2");

            CommandBuffer cmd = CommandBufferPool.Get(passTag);

            RenderTextureDescriptor opaquedesc = renderingData.cameraData.cameraTargetDescriptor;

            int width = opaquedesc.width / passdownsample;

            int height = opaquedesc.height / passdownsample;

            opaquedesc.depthBufferBits = 0;


            cmd.GetTemporaryRT(bufferid1, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

            cmd.GetTemporaryRT(bufferid2, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

            buffer1 = new RenderTargetIdentifier(bufferid1);

            buffer2 = new RenderTargetIdentifier(bufferid2);

            cmd.SetGlobalFloat("_Blur", 1f);

            cmd.Blit(passSource, buffer1, passMat);


            for (int t = 1; t < passloop; t++)

            {
                cmd.SetGlobalFloat("_Blur", t * passblur + 1);

                cmd.Blit(buffer1, buffer2, passMat);

                var temRT = buffer1;

                buffer1 = buffer2;

                buffer2 = temRT;
            }

            cmd.SetGlobalFloat("_Blur", passloop * passblur + 1);

            cmd.Blit(buffer1, passSource, passMat);


            CommandBufferPool.Release(cmd); //释放该命令
            context.ExecuteCommandBuffer(cmd); //执行命令缓冲区的该命令
        }
    }

    CustomRenderPass mypass;

    public override void Create() //进行初始化,这里最先开始

    {
        mypass = new CustomRenderPass(setting.passTag); //实例化一下并传参数,name就是tag

        mypass.renderPassEvent = setting.passEvent;

        mypass.passblur = setting.blur;

        mypass.passloop = setting.loop;

        mypass.passMat = setting.mymat;

        mypass.passdownsample = setting.downsample;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) //传值到pass里

    {
        mypass.setup(renderer.cameraColorTarget);

        renderer.EnqueuePass(mypass);
    }
}