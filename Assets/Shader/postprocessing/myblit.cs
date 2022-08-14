using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class myblit : ScriptableRendererFeature
{
    [System.Serializable]
    public class mysetting //定义一个设置的类
    {
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents; //默认插到透明完成后

        public Material mymat;

        public int matpassindex = -1;
    }

    public mysetting setting = new mysetting();

    class CustomRenderPass : ScriptableRenderPass //自定义pass
    {
        public Material passMat = null;
        public int passMatInt = 0;
        public FilterMode passfiltermode { get; set; } //图像的模式
        private RenderTargetIdentifier passSource { get; set; } //源图像,目标图像
        RenderTargetHandle passTemplecolorTex; //临时计算图像
        string passTag;

        public CustomRenderPass(RenderPassEvent passEvent, Material material, int passint, string tag) //构造函数
        {
            this.renderPassEvent = passEvent;
            this.passMat = material;
            this.passMatInt = passint;
            passTag = tag;
        }

        public void setup(RenderTargetIdentifier sour) //接收render feather传的图
        {
            this.passSource = sour;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) //类似OnRenderimagePass
        {
            CommandBuffer cmd = CommandBufferPool.Get(passTag);
            RenderTextureDescriptor opaquedesc = renderingData.cameraData.cameraTargetDescriptor;
            opaquedesc.depthBufferBits = 0;
            cmd.GetTemporaryRT(passTemplecolorTex.id, opaquedesc, passfiltermode); //申请一个临时图像
            Blit(cmd, passSource, passTemplecolorTex.Identifier(), passMat, passMatInt); //把源贴图输入到材质对应的pass里处理，并把处理结果的图像存储到临时图像；
            Blit(cmd, passTemplecolorTex.Identifier(), passSource); //然后把临时图像又存到源图像里
            context.ExecuteCommandBuffer(cmd); //执行命令缓冲区的该命令
            CommandBufferPool.Release(cmd); //释放该命令
            cmd.ReleaseTemporaryRT(passTemplecolorTex.id); //释放临时图像
        }
    }

    CustomRenderPass mypass;

    public override void Create() //进行初始化,这里最先开始
    {
        int passint = setting.mymat == null ? 1 : setting.mymat.passCount - 1; //计算材质球里总的pass数，如果没有则为1

        setting.matpassindex = Mathf.Clamp(setting.matpassindex, -1, passint); //把设置里的pass的id限制在-1到材质的最大pass数

        mypass = new CustomRenderPass(setting.passEvent, setting.mymat, setting.matpassindex, name); //实例化一下并传参数,name就是tag
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) //传值到pass里
    {
        var src = renderer.cameraColorTarget;

        mypass.setup(src);

        renderer.EnqueuePass(mypass);
    }
}